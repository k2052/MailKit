#import "MKMIMEFactory.h"

#import "MailKitTypes.h"
#import <libetpan/libetpan.h>
#import "MKMIME_SinglePart.h"
#import "MKMIME_MessagePart.h"
#import "MKMIME_MultiPart.h"
#import "MKMIME_TextPart.h"
#import "MKMIME.h"


@implementation MKMIMEFactory
+ (MKMIME *) createMIMEWithMIMEStruct:(struct mailmime *) mime 
  forMessage:(struct mailmessage *) message 
{
	if(mime == nil) {
		RaiseException(MKMIMEParseError, MKMIMEParseErrorDesc);
		return nil;
	}
	
	switch (mime->mm_type) 
	{
		case MAILMIME_SINGLE:
			return [MKMIMEFactory createMIMESinglePartWithMIMEStruct:mime
  		  forMessage:message];
			break;
		case MAILMIME_MULTIPLE:
			return [[[MKMIME_MultiPart alloc] initWithMIMEStruct:mime
        forMessage:message] autorelease];
			break;
		case MAILMIME_MESSAGE:
			return [[[MKMIME_MessagePart alloc] initWithMIMEStruct:mime
    		forMessage:message] autorelease];
			break;
	}      
	
	return NULL;
}

+ (MKMIME_SinglePart *) createMIMESinglePartWithMIMEStruct:(struct mailmime *) mime 
  forMessage:(struct mailmessage *) message 
{
	struct mailmime_type *aType = mime->mm_content_type->ct_type;
	if(aType->tp_type != MAILMIME_TYPE_DISCRETE_TYPE) {
		return nil;
	}           
	
	MKMIME_SinglePart *content = nil;
	switch (aType->tp_data.tp_discrete_type->dt_type) 
	{
		case MAILMIME_DISCRETE_TYPE_TEXT:
			content = [[MKMIME_TextPart alloc] initWithMIMEStruct:mime 
        forMessage:message];
			break;
		default:
			content = [[MKMIME_SinglePart alloc] initWithMIMEStruct:mime 
        forMessage:message];
		break;
	}                 
	
	return [content autorelease];
}
@end 