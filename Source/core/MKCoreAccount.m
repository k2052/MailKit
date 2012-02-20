#import "MKCoreAccount.h"
#import "MKCoreFolder.h"
#import "MailKitTypes.h"

@interface MKCoreAccount (Private)
@end

@implementation MKCoreAccount
- (id) init 
{  
	self = [super init];  
	
	if(self) 
	{
		connected = NO;
		myStorage = mailstorage_new(NULL);
		
		assert(myStorage != NULL);	
	}     
	
	return self;
}


- (void) dealloc 
{
	mailstorage_disconnect(myStorage);
	mailstorage_free(myStorage);
	[super dealloc]; 
}


- (BOOL) isConnected 
{
	return connected;
}

- (void) connectToServer:(NSString *) server port:(int) port 
		connectionType:(int) conType authType:(int) authType
		login:(NSString *) login password:(NSString *) password 
{
	int err         = 0;
	int imap_cached = 0;

	const char* auth_type_to_pass = NULL;
	
	if(authType == IMAP_AUTH_TYPE_SASL_CRAM_MD5) {
		auth_type_to_pass = "CRAM-MD5";
	}
	
	err = imap_mailstorage_init_sasl(myStorage,
   (char *) [server cStringUsingEncoding:NSUTF8StringEncoding],
   (uint16_t) port,
   NULL,
   conType,
   auth_type_to_pass,
   NULL,
   NULL,
   NULL,
   (char *) [login cStringUsingEncoding:NSUTF8StringEncoding], 
   (char *) [login cStringUsingEncoding:NSUTF8StringEncoding],
   (char *) [password cStringUsingEncoding:NSUTF8StringEncoding],
    NULL,
   imap_cached,
   NULL);    
		
	if(err != MAIL_NO_ERROR)
	{
		NSException *exception = [NSException
      exceptionWithName:MKMemoryError
      reason:MKMemoryErrorDesc
      userInfo:nil];   
      
		[exception raise];
	}
						
	err = mailstorage_connect(myStorage);
	if(err == MAIL_ERROR_LOGIN) 
	{
		NSException *exception = [NSException
      exceptionWithName:MKLoginError
      reason:MKLoginErrorDesc
      userInfo:nil];  
		[exception raise];
	}
	else if(err != MAIL_NO_ERROR) 
	{
		NSException *exception = [NSException
      exceptionWithName:MKUnknownError
      reason:[NSString stringWithFormat:@"Error number: %d",err]
      userInfo:nil];  
		[exception raise];
	}
	else	
		connected = YES;
}

- (void) disconnect 
{
	connected = NO;
	mailstorage_disconnect(myStorage);
}

- (MKCoreFolder *) folderWithPath:(NSString *) path 
{
	MKCoreFolder *folder = [[MKCoreFolder alloc] initWithPath:path inAccount:self];
	return [folder autorelease];
}


- (mailimap *) session 
{
	struct imap_cached_session_state_data * cached_data;
	struct imap_session_state_data * data;
	mailsession *session;
   
	session = myStorage->sto_session;
	if(session == nil) {
		return nil;
	}   
	
	if(strcasecmp(session->sess_driver->sess_name, "imap-cached") == 0) 
	{
  	cached_data = session->sess_data;
  	session     = cached_data->imap_ancestor;
  }

	data = session->sess_data;
	return data->imap_session;
}

- (struct mailstorage *) storageStruct 
{
	return myStorage;
}

- (NSSet *) subscribedFolders 
{
	struct mailimap_mailbox_list * mailboxStruct;
	clist *subscribedList;
	clistiter *cur;
	
	NSString *mailboxNameObject;
	char *mailboxName;
	int err;
	
	NSMutableSet *subscribedFolders = [NSMutableSet set];	
	
	err = mailimap_lsub([self session], "", "*", &subscribedList);
	if(err != MAIL_NO_ERROR) 
	{
		NSException *exception = [NSException
      exceptionWithName:MKUnknownError
      reason:[NSString stringWithFormat:@"Error number: %d",err]
      userInfo:nil];  
		[exception raise];
	}
	else if(clist_isempty(subscribedList)) 
	{
		NSException *exception = [NSException
      exceptionWithName:MKNoSubscribedFolders
      reason:MKNoSubscribedFoldersDesc
      userInfo:nil];    
		[exception raise];
	}            
	
	for(cur = clist_begin(subscribedList); cur != NULL; cur = cur->next)
	{
		mailboxStruct     =   cur->data;
		mailboxName       = mailboxStruct->mb_name;
		mailboxNameObject = [NSString stringWithCString:mailboxName encoding:NSUTF8StringEncoding];    
		
		[subscribedFolders addObject:mailboxNameObject];
	}      
	
	mailimap_list_result_free(subscribedList);
	return subscribedFolders;
}

- (NSSet *) allFolders 
{
	struct mailimap_mailbox_list * mailboxStruct;
	clist *allList;
	clistiter *cur;
	
	NSString *mailboxNameObject;
	char *mailboxName;
	int err;
	
	NSMutableSet *allFolders = [NSMutableSet set];

	err = mailimap_list([self session], "", "*", &allList);		
	if(err != MAIL_NO_ERROR)
	{
		NSException *exception = [NSException
      exceptionWithName:MKUnknownError
      reason:[NSString stringWithFormat:@"Error number: %d",err]
      userInfo:nil];   
		[exception raise];
	}
	else if(clist_isempty(allList))
	{
		NSException *exception = [NSException
      exceptionWithName:MKTNoFolders
      reason:MKNoFoldersDesc
      userInfo:nil];     
		[exception raise];
	}    
	
	for(cur = clist_begin(allList); cur != NULL; cur = cur->next)
	{
		mailboxStruct     = cur->data;
		mailboxName       = mailboxStruct->mb_name;
		mailboxNameObject = [NSString stringWithCString:mailboxName encoding:NSUTF8StringEncoding];
		[allFolders addObject:mailboxNameObject];
	}    
	
	mailimap_list_result_free(allList);
	return allFolders;
}
@end