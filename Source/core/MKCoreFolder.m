#import "MKCoreFolder.h"
#import <libetpan/libetpan.h>
#import "MKCoreMessage.h"
#import "MKCoreAccount.h"
#import "MailKitTypes.h"
#import "MKBareMessage.h"

@interface MKCoreFolder (Private)
@end
	
@implementation MKCoreFolder
- (id) initWithPath:(NSString *) path inAccount:(MKCoreAccount *) account;
 {
	struct mailstorage *storage = (struct mailstorage *) [account storageStruct];   
	
	self = [super init]; 
	
	if(self)
	{
		myPath    = [path retain];
		connected = NO;
		myAccount = [account retain];
		myFolder  = mailfolder_new(storage, (char *) [myPath cStringUsingEncoding:NSUTF8StringEncoding], NULL);	 
		
		assert(myFolder != NULL);
	}   
	
	return self;
}

- (void) dealloc 
{	
	if(connected)
		[self disconnect];
		
	mailfolder_free(myFolder);
	[myAccount release];
	[myPath release];
	[super dealloc];
}

- (void) connect 
{
	int err = MAIL_NO_ERROR;
	err     =  mailfolder_connect(myFolder);   
	
	IfTrue_RaiseException(err != MAILIMAP_NO_ERROR, MKUnknownError, [NSString stringWithFormat:@"Error number: %d",err]);	
	
	connected = YES;
}


- (void) disconnect 
{
	if(connected)
		mailfolder_disconnect(myFolder);
}


- (NSString *) name 
{
	NSArray *pathParts = [myPath componentsSeparatedByString:@"."];
	return [pathParts objectAtIndex:[pathParts count]-1];
}

- (NSString *) path 
{
	return myPath;
}

- (void) setPath:(NSString *) path; 
{
	int err;
	const char *newPath = [path cStringUsingEncoding:NSUTF8StringEncoding];
	const char *oldPath = [myPath cStringUsingEncoding:NSUTF8StringEncoding];
	
	[self connect];	
	[self unsubscribe];                                        
	
	err =  mailimap_rename([myAccount session], oldPath, newPath);
	IfTrue_RaiseException(err != MAILIMAP_NO_ERROR, MKUnknownError, [NSString stringWithFormat:@"Error number: %d",err]);	     
		
	[path retain];
	[myPath release];
	myPath = path;
	[self subscribe];
}

- (void) create 
{
	int err;
	const char *path = [myPath cStringUsingEncoding:NSUTF8StringEncoding];
	
	err =  mailimap_create([myAccount session], path);
	IfTrue_RaiseException(err != MAILIMAP_NO_ERROR, MKUnknownError, [NSString stringWithFormat:@"Error number: %d",err]);   
	
	[self connect];
	[self subscribe];	
}


- (void) delete 
{
	int err;
	const char *path = [myPath cStringUsingEncoding:NSUTF8StringEncoding];
	
	[self connect];
	[self unsubscribe];  
	
	err =  mailimap_delete([myAccount session], path);
	IfTrue_RaiseException(err != MAILIMAP_NO_ERROR, MKUnknownError, [NSString stringWithFormat:@"Error number: %d",err]);
}

- (void) subscribe 
{
	int err;
	const char *path = [myPath cStringUsingEncoding:NSUTF8StringEncoding];
	
	[self connect];    
	
	err =  mailimap_subscribe([myAccount session], path);
	IfTrue_RaiseException(err != MAILIMAP_NO_ERROR, MKUnknownError, [NSString stringWithFormat:@"Error number: %d",err]);
}

- (void) unsubscribe 
{
	int err;
	const char *path = [myPath cStringUsingEncoding:NSUTF8StringEncoding];
	
	[self connect];
	err =  mailimap_unsubscribe([myAccount session], path);   
	
	IfTrue_RaiseException(err != MAILIMAP_NO_ERROR, MKUnknownError, [NSString stringWithFormat:@"Error number: %d",err]);	
}

- (struct mailfolder *) folderStruct 
{
	return myFolder;
}

- (BOOL) isUIDValid:(NSString *) uid 
{
	uint32_t uidvalidity, check_uidvalidity;     
	
	uidvalidity       = [self uidValidity];
	check_uidvalidity = (uint32_t)[[[uid componentsSeparatedByString:@"-"] objectAtIndex:0] doubleValue];   
	
	return (uidvalidity == check_uidvalidity);
}

- (NSUInteger) uidValidity 
{
	[self connect]; 
	
	mailimap *imapSession;       
	
	imapSession = [self imapSession];
	if(imapSession->imap_selection_info != NULL) {
		return imapSession->imap_selection_info->sel_uidvalidity;
	}      
	
	return 0;
}

- (void) check 
{
	[self connect];      
	
	int err = mailfolder_check(myFolder);
	IfTrue_RaiseException(err != MAILIMAP_NO_ERROR, MKUnknownError, [NSString stringWithFormat:@"Error number: %d",err]);	
}

- (NSUInteger) sequenceNumberForUID:(NSString *) uid 
{
	int r;
	struct mailimap_fetch_att * fetch_att;
	struct mailimap_fetch_type * fetch_type;
	struct mailimap_set * set;
	clist * fetch_result;

	NSUInteger uidnum = (unsigned int)[[[uid componentsSeparatedByString:@"-"] objectAtIndex:1] doubleValue];

	[self connect];       
	
	set = mailimap_set_new_single(uidnum);
	if(set == NULL) 
		return 0;

	fetch_type = mailimap_fetch_type_new_fetch_att_list_empty();
	fetch_att  = mailimap_fetch_att_new_uid();
	r          = mailimap_fetch_type_new_fetch_att_list_add(fetch_type, fetch_att);
	if(r != MAILIMAP_NO_ERROR) {
		mailimap_fetch_att_free(fetch_att);
		return 0;
	}

	r = mailimap_uid_fetch([self imapSession], set, fetch_type, &fetch_result);
	if(r != MAIL_NO_ERROR) 
	{
		NSException *exception = [NSException
      exceptionWithName:MKUnknownError
      reason:[NSString stringWithFormat:@"Error number: %d",r]
      userInfo:nil];   
      
		[exception raise];
	}

	mailimap_fetch_type_free(fetch_type);
	mailimap_set_free(set);

	if(r != MAILIMAP_NO_ERROR) 
		return 0; //Add exception   
		
	NSUInteger sequenceNumber = 0;	
	if(!clist_isempty(fetch_result)) {
		struct mailimap_msg_att *msg_att = (struct mailimap_msg_att *)clist_nth_data(fetch_result, 0);
		sequenceNumber = msg_att->att_number;
	}     
	
	mailimap_fetch_list_free(fetch_result);	
	return sequenceNumber;
}

- (NSSet *) messageListWithFetchAttributes:(NSArray *) attributes 
{
	int r;
	struct mailimap_fetch_att * fetch_att;
	struct mailimap_fetch_type * fetch_type;
	struct mailimap_set * set;
	clist * fetch_result;

	[self connect];      
	
	set = mailimap_set_new_interval(1, 0);
	if(set == NULL) 
		return nil;

	fetch_type = mailimap_fetch_type_new_fetch_att_list_empty();
	fetch_att  = mailimap_fetch_att_new_uid();
	r          = mailimap_fetch_type_new_fetch_att_list_add(fetch_type, fetch_att);
	if(r != MAILIMAP_NO_ERROR) {
		mailimap_fetch_att_free(fetch_att);
		return nil;
	}

	fetch_att = mailimap_fetch_att_new_flags();
	if(fetch_att == NULL) {
		mailimap_fetch_type_free(fetch_type);
		return nil;
	}

	r = mailimap_fetch_type_new_fetch_att_list_add(fetch_type, fetch_att);
	if(r != MAILIMAP_NO_ERROR) 
	{
		mailimap_fetch_att_free(fetch_att);
		mailimap_fetch_type_free(fetch_type);
		return nil;
	}

	r = mailimap_fetch([self imapSession], set, fetch_type, &fetch_result);
	if(r != MAIL_NO_ERROR) 
	{
		NSException *exception = [NSException
      exceptionWithName:MKUnknownError
      reason:[NSString stringWithFormat:@"Error number: %d",r]
      userInfo:nil];    
		[exception raise];
	}

	mailimap_fetch_type_free(fetch_type);
	mailimap_set_free(set);

	if(r != MAILIMAP_NO_ERROR) 
		return nil; //Add exception

	NSMutableSet *messages = [NSMutableSet set];
	NSUInteger uidValidity = [self uidValidity];
	clistiter *iter;
	for(iter = clist_begin(fetch_result); iter != NULL; iter = clist_next(iter)) 
	{
		MKBareMessage *msg = [[MKBareMessage alloc] init];
		
		struct mailimap_msg_att *msg_att = clist_content(iter);
		clistiter * item_cur;
		uint32_t uid;
		struct mail_flags *flags;

		uid = 0;
		for(item_cur = clist_begin(msg_att->att_list); item_cur != NULL; 
			item_cur = clist_next(item_cur)) 
		{
			struct mailimap_msg_att_item * item;

			NSString *str;
			item = clist_content(item_cur);
			switch(item->att_type) 
			{
				case MAILIMAP_MSG_ATT_ITEM_STATIC:
				switch (item->att_data.att_static->att_type) 
				{
					case MAILIMAP_MSG_ATT_UID:
					str = [[NSString alloc] initWithFormat:@"%d-%d", uidValidity,
  					item->att_data.att_static->att_data.att_uid];
					msg.uid = str;
					[str release];
					break;
				}
				break;
				case MAILIMAP_MSG_ATT_ITEM_DYNAMIC:
				r = imap_flags_to_flags(item->att_data.att_dyn, &flags);
			 	if(r == MAIL_NO_ERROR) {
  				msg.flags = flags->fl_flags;
			  }
				mail_flags_free(flags);					
				break;
			}
		}           
		
  		[messages addObject:msg];
  		[msg release];   
  	}         
  	
	mailimap_fetch_list_free(fetch_result);	    
	
	return messages;
}

- (NSSet *) messageObjectsFromIndex:(unsigned int) start toIndex:(unsigned int) end 
{
	struct mailmessage_list * env_list;
	int r;
	struct mailimap_fetch_att * fetch_att;
	struct mailimap_fetch_type * fetch_type;
	struct mailimap_set * set;
	clist * fetch_result;

	[self connect]; 
	
	set = mailimap_set_new_interval(start, end);
	if(set == NULL) 
		return nil;

	fetch_type = mailimap_fetch_type_new_fetch_att_list_empty();
	fetch_att  = mailimap_fetch_att_new_uid();
	r          = mailimap_fetch_type_new_fetch_att_list_add(fetch_type, fetch_att);
	if(r != MAILIMAP_NO_ERROR) {
		mailimap_fetch_att_free(fetch_att);
		return nil;
	}

	fetch_att = mailimap_fetch_att_new_rfc822_size();
	if(fetch_att == NULL) {
		mailimap_fetch_type_free(fetch_type);
		return nil;
	}

	r = mailimap_fetch_type_new_fetch_att_list_add(fetch_type, fetch_att);
	if(r != MAILIMAP_NO_ERROR) 
	{
		mailimap_fetch_att_free(fetch_att);
		mailimap_fetch_type_free(fetch_type);
		return nil;
	}

	r = mailimap_fetch([self imapSession], set, fetch_type, &fetch_result);
	if(r != MAIL_NO_ERROR) 
	{
		NSException *exception = [NSException
      exceptionWithName:MKUnknownError
      reason:[NSString stringWithFormat:@"Error number: %d",r]
      userInfo:nil];  
		[exception raise];
	}

	mailimap_fetch_type_free(fetch_type);
	mailimap_set_free(set);

	if(r != MAILIMAP_NO_ERROR) return nil; 

	env_list = NULL;
	r        = uid_list_to_env_list(fetch_result, &env_list, [self folderSession], imap_message_driver);
	r        = mailfolder_get_envelopes_list(myFolder, env_list);
	if(r != MAIL_NO_ERROR) 
	{
		if( env_list != NULL )
			mailmessage_list_free(env_list); 
			
		NSException *exception = [NSException
      exceptionWithName:MKUnknownError
      reason:[NSString stringWithFormat:@"Error number: %d",r]
      userInfo:nil];      
      
		[exception raise];
	}
	
	int len = carray_count(env_list->msg_tab);
	int i;
	MKCoreMessage *msgObject;
	struct mailmessage *msg;
	clistiter *fetchResultIter = clist_begin(fetch_result);
	NSMutableSet *messages = [NSMutableSet set];
	for(i=0; i<len; i++) 
	{
		msg       = carray_get(env_list->msg_tab, i);
		msgObject = [[MKCoreMessage alloc] initWithMessageStruct:msg];    
		
		struct mailimap_msg_att *msg_att = (struct mailimap_msg_att *)clist_content(fetchResultIter);  
		
		if(msg_att != nil) {
			[msgObject setSequenceNumber:msg_att->att_number];
			[messages addObject:msgObject];
		}     
		
		[msgObject release];           
		
		fetchResultIter = clist_next(fetchResultIter);
	}    
	
	if(env_list != NULL ) {
		carray_free(env_list->msg_tab); 
		free(env_list);
	}           
	
	mailimap_fetch_list_free(fetch_result);	            
	
	return messages;
}

- (MKCoreMessage *) messageWithUID:(NSString *) uid 
{
	int err;
	struct mailmessage *msgStruct;
	
	[self connect];   
	
	err = mailfolder_get_message_by_uid([self folderStruct], [uid cStringUsingEncoding:NSUTF8StringEncoding], &msgStruct);
	if(err == MAIL_ERROR_MSG_NOT_FOUND) {
		return nil;
	}
	else if(err != MAIL_NO_ERROR) 
	{
		NSException *exception = [NSException
      exceptionWithName:MKUnknownError
      reason:[NSString stringWithFormat:@"Error number: %d",err]
      userInfo:nil];        
      
		[exception raise];
	}  
	
	err = mailmessage_fetch_envelope(msgStruct,&(msgStruct->msg_fields));
	if(err != MAIL_NO_ERROR) 
	{
		NSException *exception = [NSException
      exceptionWithName:MKUnknownError
      reason:[NSString stringWithFormat:@"Error number: %d",err]
      userInfo:nil];  
			        
		[exception raise];
	}
	
	err = mailmessage_get_flags(msgStruct, &(msgStruct->msg_flags));
	if(err != MAIL_NO_ERROR) 
	{
		NSException *exception = [NSException
      exceptionWithName:MKUnknownError
      reason:[NSString stringWithFormat:@"Error number: %d",err]
      userInfo:nil];  
      
		[exception raise];
	}          
	
	return [[[MKCoreMessage alloc] initWithMessageStruct:msgStruct] autorelease];
}

- (unsigned int) flagsForMessage:(MKCoreMessage *) msg 
{
	int err;
	struct mail_flags *flagStruct;   
	
	err = mailmessage_get_flags([msg messageStruct], &flagStruct);
	if(err != MAILIMAP_NO_ERROR) 
	{
		NSException *exception = [NSException
      exceptionWithName:MKUnknownError
      reason:[NSString stringWithFormat:@"Error number: %d",err]
      userInfo:nil];      
      
		[exception raise];	
	}               
	
	return flagStruct->fl_flags;
}


- (void) setFlags:(unsigned int) flags forMessage:(MKCoreMessage *) msg 
{
	int err;

	[msg messageStruct]->msg_flags->fl_flags=flags;
	err = mailmessage_check([msg messageStruct]);       
	IfTrue_RaiseException(err != MAILIMAP_NO_ERROR, MKUnknownError, [NSString stringWithFormat:@"Error number: %d",err]);  
	
	[self check];
}

- (void) expunge 
{
	int err;
	[self connect];
	err = mailfolder_expunge(myFolder);
	IfTrue_RaiseException(err != MAILIMAP_NO_ERROR, MKUnknownError, [NSString stringWithFormat:@"Error number: %d",err]);	
}

- (void) copyMessage: (NSString *) path forMessage:(MKCoreMessage *) msg 
{
	[self connect];

	const char *mbPath = [path cStringUsingEncoding:NSUTF8StringEncoding];
	NSString *uid      = [msg uid];
	NSUInteger uidnum  = (unsigned int)[[[uid componentsSeparatedByString:@"-"] objectAtIndex:1] doubleValue];
	int err            = mailsession_copy_message([self folderSession], uidnum, mbPath);  
	
	IfTrue_RaiseException(err != MAILIMAP_NO_ERROR, MKUnknownError, [NSString stringWithFormat:@"Error number: %d",err]);		
}

- (void) moveMessage: (NSString *) path forMessage:(MKCoreMessage *) msg 
{
	[self connect];
	
	const char *mbPath = [path cStringUsingEncoding:NSUTF8StringEncoding];
	NSString *uid      = [msg uid];
	NSUInteger uidnum  = (unsigned int)[[[uid componentsSeparatedByString:@"-"] objectAtIndex:1] doubleValue];
	int err            = mailsession_move_message([self folderSession], uidnum, mbPath);  
	
	IfTrue_RaiseException(err != MAILIMAP_NO_ERROR, MKUnknownError, [NSString stringWithFormat:@"Error number: %d",err]);		
}

- (NSUInteger) unreadMessageCount 
{
	unsigned int unseenCount = 0;
	unsigned int junk;
	int err;
	
	[self connect];
	err =  mailfolder_status(myFolder, &junk, &junk, &unseenCount);
	IfTrue_RaiseException(err != MAILIMAP_NO_ERROR, MKUnknownError, [NSString stringWithFormat:@"Error number: %d",err]);   
	
	return unseenCount;
}


- (NSUInteger) totalMessageCount 
{
	[self connect];			
	return [self imapSession]->imap_selection_info->sel_exists;
}

- (mailsession *) folderSession; 
{
	return myFolder->fld_session;
}

- (mailimap *) imapSession; 
{
	struct imap_cached_session_state_data * cached_data;
	struct imap_session_state_data * data;
	mailsession *session;
   
	session = [self folderSession];
	if(strcasecmp(session->sess_driver->sess_name, "imap-cached") == 0) {
    cached_data = session->sess_data;
    session    = cached_data->imap_ancestor;      
  }

	data = session->sess_data;
	return data->imap_session;	
}

int uid_list_to_env_list(clist * fetch_result, struct mailmessage_list ** result, 
						mailsession * session, mailmessage_driver * driver) 
{
	clistiter * cur;
	struct mailmessage_list * env_list;
	int r;
	int res;
	carray * tab;
	unsigned int i;
	mailmessage * msg;

	tab = carray_new(128);
	if(tab == NULL) {
		res = MAIL_ERROR_MEMORY;
		goto err;
	}

	for(cur = clist_begin(fetch_result); cur != NULL; cur = clist_next(cur)) 
	{
		struct mailimap_msg_att * msg_att;
		clistiter * item_cur;
		uint32_t uid;
		size_t size;

		msg_att = clist_content(cur);
		uid     = 0;
		size    = 0;          
		
		for(item_cur = clist_begin(msg_att->att_list); item_cur != NULL; item_cur = clist_next(item_cur)) 
		{
			struct mailimap_msg_att_item * item;

			item = clist_content(item_cur);
			switch(item->att_type) 
			{
				case MAILIMAP_MSG_ATT_ITEM_STATIC:
				switch (item->att_data.att_static->att_type) 
				{
					case MAILIMAP_MSG_ATT_UID:
						uid = item->att_data.att_static->att_data.att_uid;
					break;

					case MAILIMAP_MSG_ATT_RFC822_SIZE:
						size = item->att_data.att_static->att_data.att_rfc822_size;
					break;
				}    
				
				break;
			}
		}

		msg = mailmessage_new();
		if(msg == NULL) {
			res = MAIL_ERROR_MEMORY;
			goto free_list;
		}

		r = mailmessage_init(msg, session, driver, uid, size);
		if(r != MAIL_NO_ERROR) {
			res = r;
			goto free_msg;
		}

		r = carray_add(tab, msg, NULL);
		if(r < 0) {
			res = MAIL_ERROR_MEMORY;
			goto free_msg;
		}
	}

	env_list = mailmessage_list_new(tab);
	if(env_list == NULL) {
		res = MAIL_ERROR_MEMORY;
		goto free_list;
	}

	* result = env_list;

	return MAIL_NO_ERROR;

	free_msg:
		mailmessage_free(msg);
	free_list:
		for(i = 0 ; i < carray_count(tab) ; i++)
		mailmessage_free(carray_get(tab, i));
	err:
		return res;
}
@end