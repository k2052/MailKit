#import "MKCoreMessage.h"
#import "MKCoreFolder.h"
#import "MailKitTypes.h"
#import "MKCoreAddress.h"
#import "MKMIMEFactory.h"
#import "MKMIME_MessagePart.h"
#import "MKMIME_TextPart.h"
#import "MKMIME_MultiPart.h"
#import "MKMIME_SinglePart.h"
#import "MKBareAttachment.h"
#import "MKMIME_HtmlPart.h"

@interface MKCoreMessage (Private)
- (MKCoreAddress *) _addressFromMailbox:(struct mailimf_mailbox *) mailbox;
- (NSSet *) _addressListFromMailboxList:(struct mailimf_mailbox_list *) mailboxList;
- (struct mailimf_mailbox_list *) _mailboxListFromAddressList:(NSSet *) addresses;
- (NSSet *) _addressListFromIMFAddressList:(struct mailimf_address_list *) imfList;
- (struct mailimf_address_list *) _IMFAddressListFromAddresssList:(NSSet *) addresses; 

- (void) _buildUpBodyText:(MKMIME *) mime result:(NSMutableString *) result;
- (void) _buildUpHtmlBodyText:(MKMIME *) mime result:(NSMutableString *) result; 

- (NSString *) _decodeMIMEPhrase:(char *) data;
@end

@implementation MKCoreMessage
@synthesize mime=myParsedMIME, mutableAttachments = _attachments;
@synthesize contentTypes = _contentTypes;

- (id) init 
{
	[super init];  
	
	if(self) 
	{
		struct mailimf_fields *fields = mailimf_fields_new_empty();
		myFields                      = mailimf_single_fields_new(fields);     
		mailimf_fields_free(fields);  
		
		_sentDate           = nil;
		_cachedRenderString = nil;
	}  
	
	return self;
}

- (id) initWithMessageStruct:(struct mailmessage *) message 
{
	self = [super init];   
	
	if(self) 
	{
		assert(message != NULL);  
		
		myMessage = message;
		myFields  = mailimf_single_fields_new(message->msg_fields);
	}    
	
	return self;
}

- (id) initWithFileAtPath:(NSString *) path 
{
	return [self initWithString:[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL]];
}

- (id) initWithString:(NSString *) msgData
{
  struct mailmessage *msg = data_message_init((char *)[msgData cStringUsingEncoding:NSUTF8StringEncoding], 
    [msgData lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
	int err;
	struct mailmime *dummyMime;        
	
	err = mailmessage_get_bodystructure(msg, &dummyMime);
	assert(err == 0);   
	
	return [self initWithMessageStruct:msg];
}

- (void) dealloc 
{
	if(myMessage != NULL) {
		mailmessage_flush(myMessage);
		mailmessage_free(myMessage);
	}
	if(myFields != NULL) {
		mailimf_single_fields_free(myFields);
	}   
	
	[myParsedMIME release];
	[_sentDate release];
	[_cachedRenderString release];
  [super dealloc];
}

- (int) fetchBody 
{        
  if(myParsedMIME) return 0;
	
	int err;
	struct mailmime *dummyMime;

	err = mailmessage_get_bodystructure(myMessage, &dummyMime);
	if(err != MAIL_NO_ERROR) {
		return err;
	}
	myParsedMIME = [[MKMIMEFactory createMIMEWithMIMEStruct:[self messageStruct]->msg_mime 
  	forMessage:[self messageStruct]] retain];
	
	return 0;
}

- (NSString *) body 
{
	NSMutableString *result = [NSMutableString string];
	[self _buildUpBodyText:myParsedMIME result:result]; 
	
	return result;
}

- (NSString *) htmlBody 
{
	NSMutableString *result = [NSMutableString string];
	[self _buildUpHtmlBodyText:myParsedMIME result:result];
	return result;
}

- (NSString *) editableHtmlBody
{
  NSMutableString *result = [NSMutableString string]; 
    
	[self _buildUpHtmlBodyText:myParsedMIME result:result];
    NSString *str = [NSString stringWithFormat:@"<div id = 'myDiv' contentEditable>"];
    str = [str stringByAppendingFormat:@"%@",[NSString stringWithString:result]];
    str = [str stringByAppendingString:@"</div>"];
    str = [str stringByAppendingString:@"<script type = 'text/javascript'> function getHtmlContent() { return document.getElementById('myDiv').innerHTML;}</script>"];
    
	return str;
}

- (NSString *) bodyPreferringPlainText
{
  NSString *body = [self body];
  if([body length] == 0) {
    body = [self htmlBody];
  }  
  
  return body;    
}


- (void) _buildUpBodyText:(MKMIME *) mime result:(NSMutableString *) result 
{
	if(mime == nil) return;
	
	if([mime isKindOfClass:[MKMIME_MessagePart class]]) {
		[self _buildUpBodyText:[mime content] result:result];
	}
	else if([mime isKindOfClass:[MKMIME_TextPart class]]) 
	{
		if([mime.contentType isEqualToString:@"text/plain"]) 
		{
			[(MKMIME_TextPart *)mime fetchPart];
			NSString* y = [mime content];   
			
			if(y != nil) {
				[result appendString:y];
			}
		}
	}
	else if([mime isKindOfClass:[MKMIME_MultiPart class]]) 
	{
		NSEnumerator *enumer = [[mime content] objectEnumerator];
		MKMIME *subpart;
		while((subpart = [enumer nextObject])) {
			[self _buildUpBodyText:subpart result:result];
		}
	}
}

- (void) _buildUpHtmlBodyText:(MKMIME *) mime result:(NSMutableString *) result 
{
	if(mime == nil) return;
	
	if([mime isKindOfClass:[MKMIME_MessagePart class]]) {
		[self _buildUpHtmlBodyText:[mime content] result:result];
	}
	else if([mime isKindOfClass:[MKMIME_TextPart class]]) 
	{
		if([mime.contentType isEqualToString:@"text/html"]) 
		{
			[(MKMIME_TextPart *)mime fetchPart];
			NSString* y = [mime content];
			if(y != nil) {
				[result appendString:y];
			}
		}
	}
	else if([mime isKindOfClass:[MKMIME_MultiPart class]]) 
	{
		NSEnumerator *enumer = [[mime content] objectEnumerator];
		MKMIME *subpart;    
		
		while((subpart = [enumer nextObject])) {
			[self _buildUpHtmlBodyText:subpart result:result];
		}
	}
}

- (void) setBody:(NSString *) body 
{
	MKMIME *oldMIME       = myParsedMIME;
	MKMIME_TextPart *text = [MKMIME_TextPart mimeTextPartWithString:body];
	
	if([myParsedMIME isKindOfClass:[MKMIME_MultiPart class]]) {
		[(MKMIME_MultiPart *) myParsedMIME addMIMEPart:text];
	} 
	else 
	{
		MKMIME_MessagePart *messagePart = [MKMIME_MessagePart mimeMessagePartWithContent:text];
		myParsedMIME                    = [messagePart retain];
		[oldMIME release];		
	}
}

- (void) setHTMLBody:(NSString *) body
{
  MKMIME *oldMIME                 = myParsedMIME;
  MKMIME_HtmlPart *text           = [MKMIME_HtmlPart mimeTextPartWithString:body];
  MKMIME_MessagePart *messagePart = [MKMIME_MessagePart mimeMessagePartWithContent:text];
  myParsedMIME                    = [messagePart retain];   
  
  [oldMIME release];	   
}
    
// TODO: Fix This
- (NSArray *) attachments 
{
	if(_attachments) return _attachments;
	
	_attachments = [[NSMutableArray alloc] init];

	MKMIME_Enumerator *enumerator = [myParsedMIME mimeEnumerator];
	MKMIME *mime;
	while((mime = [enumerator nextObject])) 
	{
		if([mime isKindOfClass:[MKMIME_SinglePart class]]) 
		{
			MKMIME_SinglePart *singlePart = (MKMIME_SinglePart *)mime;
			if(singlePart.attached) 
			{
				MKBareAttachment *attach = [[MKBareAttachment alloc] 
  				initWithMIMESinglePart:singlePart];
				[_attachments addObject:attach];
				[attach release];
			}
		}
	}     
	
	return _attachments;
}

- (void) addAttachment:(MKCoreAttachment *) attachment 
{
  [self attachments];

  MKMIME_SinglePart *attachmentPart = [MKMIME_SinglePart mimeSinglePartWithData:attachment.data];
  attachmentPart.contentType        = attachment.contentType;
  attachmentPart.filename           = attachment.filename;
  [attachmentPart setAttached:YES];     

  MKBareAttachment *attach = [[MKBareAttachment alloc] 
    initWithMIMESinglePart:attachmentPart];
  [_attachments addObject:attach];
  [attach release];

  MKMIME *oldMIME = myParsedMIME;
  
  MKMIME_MessagePart *message = nil;
  MKMIME *content = nil;     
    
  if([oldMIME isKindOfClass:[MKMIME_MessagePart class]]) {
    message = [oldMIME retain];
    content = [oldMIME.content retain];        
  } 
  else {
    message = [[MKMIME_MessagePart mimeMessagePartWithContent:nil] retain];    
    content = [oldMIME retain];     
  }  
    
  MKMIME_MultiPart *multi = nil;
  if([content isKindOfClass:[MKMIME_MultiPart class]]) {
    multi = (MKMIME_MultiPart*)content;
  } 
  else 
  {
    multi = [MKMIME_MultiPart mimeMultiPart];
    MKMIME_Enumerator *enumerator = [content mimeEnumerator];
    MKMIME *mime;
    while((mime = [enumerator nextObject])) {
      [multi addMIMEPart:mime];
    }     
  }  
    
  [multi addMIMEPart:attachmentPart];
  [message setContent:multi];
  myParsedMIME = [message retain];

  [oldMIME release];
  [message release];
  [content release];     
}

- (NSString *) subject 
{
	if(myFields->fld_subject == NULL)
		return @"";      
		
	NSString *decodedSubject = [self _decodeMIMEPhrase:myFields->fld_subject->sbj_value];
	if(decodedSubject == nil)
		return @"";     
		
	return decodedSubject;
}

- (void) setSubject:(NSString *) subject 
{
	struct mailimf_subject *subjectStruct;
	
	subjectStruct = mailimf_subject_new(strdup([subject cStringUsingEncoding:NSUTF8StringEncoding]));    
	
	if(myFields->fld_subject != NULL)
		mailimf_subject_free(myFields->fld_subject);  
		
	myFields->fld_subject = subjectStruct;
}

- (struct mailimf_date_time*) libetpanDateTime 
{    
  if(!myFields || !myFields->fld_orig_date || !myFields->fld_orig_date->dt_date_time)
    return NULL;

  return myFields->fld_orig_date->dt_date_time; 
}

- (NSTimeZone*) senderTimeZone 
{
  struct mailimf_date_time *d;

  if((d = [self libetpanDateTime]) == NULL)
    return nil;

  NSInteger timezoneOffsetInSeconds = 3600*d->dt_zone/100;

  return [NSTimeZone timeZoneForSecondsFromGMT:timezoneOffsetInSeconds];  
}

- (NSDate *) senderDate 
{
  if(myFields->fld_orig_date == NULL) {
    return [NSDate distantPast];
  }
  else 
  {
    struct mailimf_date_time *d;

    if((d = [self libetpanDateTime]) == NULL)
      return nil;

    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [[NSDateComponents alloc] init];

    [comps setYear:d->dt_year];
    [comps setMonth:d->dt_month];
    [comps setDay:d->dt_day];
    [comps setHour:d->dt_hour];
    [comps setMinute:d->dt_min];
    [comps setSecond:d->dt_sec];

    NSDate *messageDateNoTimezone = [calendar dateFromComponents:comps];

    [comps release];
    [calendar release];

    return messageDateNoTimezone;
  }    
}

- (NSDate *) sentDateGMT 
{
  struct mailimf_date_time *d;

  if((d = [self libetpanDateTime]) == NULL)
    return nil;

  NSInteger timezoneOffsetInSeconds = 3600*d->dt_zone/100;

  NSDate *date = [self senderDate];

  return [date addTimeInterval:timezoneOffsetInSeconds * -1];          
}

- (NSDate*) sentDateLocalTimeZone 
{
  return [[self sentDateGMT] addTimeInterval:[[NSTimeZone localTimeZone] secondsFromGMT]];
}

- (BOOL) isUnread 
{
	struct mail_flags *flags = myMessage->msg_flags;  
	
	if(flags != NULL) {
		BOOL flag_seen = (flags->fl_flags & MAIL_FLAG_SEEN);
		return !flag_seen;
	}    
	
	return NO;
}

- (BOOL) isNew 
{
	struct mail_flags *flags = myMessage->msg_flags;
	if(flags != NULL) 
	{
		BOOL flag_seen = (flags->fl_flags & MAIL_FLAG_SEEN);
		BOOL flag_new  = (flags->fl_flags & MAIL_FLAG_NEW);
		return !flag_seen && flag_new;
	}    
	
	return NO;
}

- (NSString *) messageId 
{
  if(myFields->fld_message_id != NULL) {
    char *value = myFields->fld_message_id->mid_value;
    return [NSString stringWithCString:value encoding:NSUTF8StringEncoding];  
  }         
  
  return nil;  
}

- (NSString *) uid 
{
  return [NSString stringWithCString:myMessage->msg_uid encoding:NSUTF8StringEncoding];
}

- (NSUInteger) messageSize 
{
  return [self messageStruct]->msg_size;
}

- (NSUInteger) sequenceNumber 
{
  return mySequenceNumber;
}

- (void) setSequenceNumber:(NSUInteger) sequenceNumber 
{
  mySequenceNumber = sequenceNumber;
}

- (NSSet *) from 
{
  if(myFields->fld_from == NULL)
    return [NSSet set]; 

  return [self _addressListFromMailboxList:myFields->fld_from->frm_mb_list];    
}

- (void) setFrom:(NSSet *) addresses 
{
	struct mailimf_mailbox_list *imf = [self _mailboxListFromAddressList:addresses];
	
	if(myFields->fld_from != NULL)
		mailimf_from_free(myFields->fld_from);     
		
	myFields->fld_from = mailimf_from_new(imf);	
}

- (MKCoreAddress *) sender 
{
	if(myFields->fld_sender == NULL)
  	return [MKCoreAddress address];
		
	return [self _addressFromMailbox:myFields->fld_sender->snd_mb];
}

- (NSSet *) to 
{
	if(myFields->fld_to == NULL)
		return [NSSet set];
	else
		return [self _addressListFromIMFAddressList:myFields->fld_to->to_addr_list];
}

- (void) setTo:(NSSet *) addresses 
{
	struct mailimf_address_list *imf = [self _IMFAddressListFromAddresssList:addresses];
	
	if(myFields->fld_to != NULL) {
		mailimf_address_list_free(myFields->fld_to->to_addr_list);
		myFields->fld_to->to_addr_list = imf;
	}
	else
		myFields->fld_to = mailimf_to_new(imf);
}

- (NSSet *) cc 
{
	if(myFields->fld_cc == NULL)
		return [NSSet set];
	else
		return [self _addressListFromIMFAddressList:myFields->fld_cc->cc_addr_list];
}

- (void) setCc:(NSSet *) addresses 
{
	struct mailimf_address_list *imf = [self _IMFAddressListFromAddresssList:addresses];    
	
	if(myFields->fld_cc != NULL) {
		mailimf_address_list_free(myFields->fld_cc->cc_addr_list);
		myFields->fld_cc->cc_addr_list = imf;
	}
	else
		myFields->fld_cc = mailimf_cc_new(imf);
}

- (NSSet *) bcc 
{
	if(myFields->fld_bcc == NULL)
		return [NSSet set];
	else
		return [self _addressListFromIMFAddressList:myFields->fld_bcc->bcc_addr_list];
}

- (void) setBcc:(NSSet *) addresses 
{
	struct mailimf_address_list *imf = [self _IMFAddressListFromAddresssList:addresses];    
	
	if(myFields->fld_bcc != NULL) {
		mailimf_address_list_free(myFields->fld_bcc->bcc_addr_list);
		myFields->fld_bcc->bcc_addr_list = imf;
	}
	else
		myFields->fld_bcc = mailimf_bcc_new(imf);
}

- (NSSet *) replyTo 
{
	if(myFields->fld_reply_to == NULL)
		return [NSSet set];
	else
		return [self _addressListFromIMFAddressList:myFields->fld_reply_to->rt_addr_list];
}

- (void) setReplyTo:(NSSet *) addresses 
{
	struct mailimf_address_list *imf = [self _IMFAddressListFromAddresssList:addresses]; 
	
	if(myFields->fld_reply_to != NULL) {
		mailimf_address_list_free(myFields->fld_reply_to->rt_addr_list);
		myFields->fld_reply_to->rt_addr_list = imf;
	}
	else
		myFields->fld_reply_to = mailimf_reply_to_new(imf);
}

- (NSString *) render 
{
	MKMIME *msgPart = myParsedMIME;

	if([myParsedMIME isKindOfClass:[MKMIME_MessagePart class]]) 
	{
		struct mailimf_fields *fields;     
		
		struct mailimf_mailbox *sender       = (myFields->fld_sender != NULL) ? (myFields->fld_sender->snd_mb) : NULL;
		struct mailimf_mailbox_list *from    = (myFields->fld_from != NULL) ? (myFields->fld_from->frm_mb_list) : NULL;
		struct mailimf_address_list *replyTo = (myFields->fld_reply_to != NULL) ? (myFields->fld_reply_to->rt_addr_list) : NULL;
		struct mailimf_address_list *to      = (myFields->fld_to != NULL) ? (myFields->fld_to->to_addr_list) : NULL;
		struct mailimf_address_list *cc      = (myFields->fld_cc != NULL) ? (myFields->fld_cc->cc_addr_list) : NULL;
		struct mailimf_address_list *bcc     = (myFields->fld_bcc != NULL) ? (myFields->fld_bcc->bcc_addr_list) : NULL; 
		
		clist *inReplyTo  = (myFields->fld_in_reply_to != NULL) ? (myFields->fld_in_reply_to->mid_list) : NULL;
		clist *references = (myFields->fld_references != NULL) ? (myFields->fld_references->mid_list) : NULL;
		char *subject     = (myFields->fld_subject != NULL) ? (myFields->fld_subject->sbj_value) : NULL;
		
		fields = mailimf_fields_new_with_data(from, sender, replyTo, to, cc, bcc, inReplyTo, references, subject);
		[(MKMIME_MessagePart *)msgPart setIMFFields:fields];
	}   
	
	return [myParsedMIME render];
}

- (NSData *) messageAsEmlx 
{
  NSString *msgContent     = [[self rfc822] stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
  NSData *msgContentAsData = [msgContent dataUsingEncoding:NSUTF8StringEncoding];
  NSMutableData *emlx      = [NSMutableData data];         

  [emlx appendData:[[NSString stringWithFormat:@"%-10d\n", msgContentAsData.length] dataUsingEncoding:NSUTF8StringEncoding]];
  [emlx appendData:msgContentAsData];   


	struct mail_flags *flagsStruct = myMessage->msg_flags;
  long long flags = 0;  
  
	if(flagsStruct != NULL) 
	{
    BOOL seen = (flagsStruct->fl_flags & MKFlagSeen) > 0;
    flags |= seen << 0;     
    
    BOOL answered = (flagsStruct->fl_flags & MKFlagAnswered) > 0;
    flags |= answered << 2;    
    
    BOOL flagged = (flagsStruct->fl_flags & MKFlagFlagged) > 0;
    flags |= flagged << 4; 
    
    BOOL forwarded = (flagsStruct->fl_flags & MKFlagForwarded) > 0;
    flags |= forwarded << 8;   
  }

  NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
  [dictionary setValue:[NSNumber numberWithDouble:[[self senderDate] timeIntervalSince1970]] forKey:@"date-sent"];
  [dictionary setValue:[NSNumber numberWithUnsignedLongLong:flags] forKey:@"flags"];
  [dictionary setValue:[self subject] forKey:@"subject"];

  NSError *error;
  NSData *propertyList = [NSPropertyListSerialization dataWithPropertyList:dictionary
    format:NSPropertyListXMLFormat_v1_0
    options:0
    error:&error];  
    
  [emlx appendData:propertyList];    
   
  return emlx;
}

- (NSString *) rfc822 
{
  char *result = NULL;
  NSString *nsresult;
  int r = mailimap_fetch_rfc822([self imapSession], [self sequenceNumber], &result);     
  
  if(r == 0) {
    nsresult = [[NSString alloc] initWithCString:result encoding:NSUTF8StringEncoding];
  } 
  else 
  {
  	NSException *exception = [NSException
      exceptionWithName:MKUnknownError
      reason:[NSString stringWithFormat:@"Error number: %d",r]
      userInfo:nil];      
		        
  	[exception raise]; 
  }                      

  mailimap_msg_att_rfc822_free(result);    
  
  return [nsresult autorelease];  
} 

- (uint32_t) flags
{
	struct mail_flags *flags = myMessage->msg_flags;
	if(flags != NULL)
		return flags->fl_flags;
		
	return -1;
}

- (struct mailmessage *) messageStruct 
{
	return myMessage;
}

- (mailimap *) imapSession; 
{
	struct imap_cached_session_state_data * cached_data;
	struct imap_session_state_data * data;
	mailsession *session = [self messageStruct]->msg_session;

	if(strcasecmp(session->sess_driver->sess_name, "imap-cached") == 0) {
  	cached_data = session->sess_data;
  	session     = cached_data->imap_ancestor; 
	}

	data = session->sess_data;  
	
	return data->imap_session;	
}

- (MKCoreAddress *) _addressFromMailbox:(struct mailimf_mailbox *) mailbox; 
{
	MKCoreAddress *address = [MKCoreAddress address];   
	
	if(mailbox == NULL) {
		return address;
  }         
  
	if(mailbox->mb_display_name != NULL) 
	{
		NSString *decodedName = [self _decodeMIMEPhrase:mailbox->mb_display_name];
		if(decodedName == nil) {
			decodedName = @"";
    }
    
		[address setName:decodedName];
	}                              
	
	if(mailbox->mb_addr_spec != NULL) {
		[address setEmail:[NSString stringWithCString:mailbox->mb_addr_spec encoding:NSUTF8StringEncoding]];
  }      
  
	return address;
}

- (NSSet *) _addressListFromMailboxList:(struct mailimf_mailbox_list *) mailboxList;
{
	clist *list;
	clistiter * iter;
	struct mailimf_mailbox *address;
	NSMutableSet *addressSet = [NSMutableSet set];
	
	if(mailboxList == NULL)
		return addressSet;
		
	list = mailboxList->mb_list;      
	
	for(iter = clist_begin(list); iter != NULL; iter = clist_next(iter)) 
	{
    address = clist_content(iter);
		[addressSet addObject:[self _addressFromMailbox:address]];
  }  
  
	return addressSet;
}

- (struct mailimf_mailbox_list *) _mailboxListFromAddressList:(NSSet *) addresses 
{
	struct mailimf_mailbox_list *imfList = mailimf_mailbox_list_new_empty();
	NSEnumerator *objEnum = [addresses objectEnumerator];
	MKCoreAddress *address;
	int err;    
	
	const char *addressName;
	const char *addressEmail;

	while(address = [objEnum nextObject]) 
	{
		addressName  = [[address name] cStringUsingEncoding:NSUTF8StringEncoding];
		addressEmail = [[address email] cStringUsingEncoding:NSUTF8StringEncoding];
		err          =  mailimf_mailbox_list_add_mb(imfList, strdup(addressName), strdup(addressEmail));            
		
		assert(err == 0);
	}         
	
	return imfList;	
}

- (NSSet *) _addressListFromIMFAddressList:(struct mailimf_address_list *) imfList 
{
	clist *list;
	clistiter * iter;
	struct mailimf_address *address;
	NSMutableSet *addressSet = [NSMutableSet set];
	
	if(imfList == NULL)
		return addressSet;
		
	list = imfList->ad_list;
	for(iter = clist_begin(list); iter != NULL; iter = clist_next(iter)) 
	{
    address = clist_content(iter);
		if(address->ad_type == MAILIMF_ADDRESS_MAILBOX) {
			[addressSet addObject:[self _addressFromMailbox:address->ad_data.ad_mailbox]];
		}
		else 
		{
      if(address->ad_data.ad_group->grp_mb_list != NULL)
        [addressSet unionSet:[self _addressListFromMailboxList:address->ad_data.ad_group->grp_mb_list]];
      }  
  	}    
  	
	return addressSet;
}

- (struct mailimf_address_list *) _IMFAddressListFromAddresssList:(NSSet *) addresses 
{
	struct mailimf_address_list *imfList = mailimf_address_list_new_empty();
	
	NSEnumerator *objEnum = [addresses objectEnumerator];
	MKCoreAddress *address;
	int err;
	const char *addressName;
	const char *addressEmail;

	while(address = [objEnum nextObject]) 
	{
		addressName  = [[address name] cStringUsingEncoding:NSUTF8StringEncoding];
		addressEmail = [[address email] cStringUsingEncoding:NSUTF8StringEncoding];
		err          =  mailimf_address_list_add_mb(imfList, strdup(addressName), strdup(addressEmail));
		assert(err == 0);
	}           
	
	return imfList;
}

- (NSString *) _decodeMIMEPhrase:(char *) data 
{
	int err;
	size_t currToken = 0;
	char *decodedSubject;
	NSString *result;
	
	if(*data != '\0') 
	{
		err = mailmime_encoded_phrase_parse(DEST_CHARSET, data, strlen(data), &currToken, DEST_CHARSET, &decodedSubject);
			
		if(err != MAILIMF_NO_ERROR) 
		{
			if(decodedSubject == NULL)
				free(decodedSubject); 
				
			return nil;
		}
	}
	else {
		return @"";
	}
		
	result = [NSString stringWithCString:decodedSubject encoding:NSUTF8StringEncoding];
	free(decodedSubject);     
	
	return result;
}
@end