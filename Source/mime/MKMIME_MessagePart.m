#import "MKMIME_MessagePart.h"
#import <libetpan/libetpan.h>
#import "MailKitTypes.h"
#import "MKMIMEFactory.h"

@implementation MKMIME_MessagePart
+ (id) mimeMessagePartWithContent:(MKMIME *) mime 
{
	return [[[MKMIME_MessagePart alloc] initWithContent:mime] autorelease];
}

- (id) initWithMIMEStruct:(struct mailmime *) mime 
			  forMessage:(struct mailmessage *) message 
{
	self = [super initWithMIMEStruct:mime forMessage:message];   
	
	if(self) 
	{
		struct mailmime *content = mime->mm_data.mm_message.mm_msg_mime;     
		
		myMessageContent = [[MKMIMEFactory createMIMEWithMIMEStruct:content 
      forMessage:message] retain];            
      
		myFields = mime->mm_data.mm_message.mm_fields;
	}     
	
	return self;
}

- (id) initWithContent:(MKMIME *) messageContent 
{
	self = [super init];
	
	if(self) {
		[self setContent:messageContent];
	}     
	
	return self;
}

- (void) dealloc 
{
	[myMessageContent release];
	[super dealloc];
}

- (void) setContent:(MKMIME *) aContent 
{
	[aContent retain];
	[myMessageContent release];
	myMessageContent = aContent;
}

- (id) content
{
	return myMessageContent;
}

- (struct mailmime *) buildMIMEStruct 
{
	struct mailmime *mime = mailmime_new_message_data([myMessageContent buildMIMEStruct]);      
	
	if(myFields != NULL) {
		mailmime_set_imf_fields(mime, myFields);		
	}          
	
	return mime;
}

- (void) setIMFFields:(struct mailimf_fields *) imfFields 
{
	myFields = imfFields;
}
@end