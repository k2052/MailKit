#import "MKMIME_MultiPart.h"
#import "MKMIME_MessagePart.h"
#import <libetpan/libetpan.h>
#import "MailKitTypes.h"
#import "MKMIMEFactory.h"


@implementation MKMIME_MultiPart
+ (id) mimeMultiPart 
{
	return [[[MKMIME_MultiPart alloc] init] autorelease];
}

- (id) initWithMIMEStruct:(struct mailmime *) mime forMessage:(struct mailmessage *) message 
{
	self = [super initWithMIMEStruct:mime forMessage:message];
	
	if(self) 
	{
		myContentList = [[NSMutableArray alloc] init];
 		clistiter *cur = clist_begin(mime->mm_data.mm_multipart.mm_mp_list);      
 		
		for(; cur != NULL; cur=clist_next(cur)) 
		{
			MKMIME *content = [MKMIMEFactory createMIMEWithMIMEStruct:clist_content(cur) forMessage:message];
			if(content != nil) {
				[myContentList addObject:content];
			}
		}
	}    
	
	return self;			
}

- (id) init 
{
	self = [super init];
	if(self) {
		myContentList = [[NSMutableArray alloc] init];
	}    
	
	return self;
}

- (void) dealloc 
{
	[myContentList release];
	[super dealloc];
}

- (void) addMIMEPart:(MKMIME *) mime 
{
	[myContentList addObject:mime];
}

- (id) content 
{
	return myContentList;
}

- (struct mailmime *) buildMIMEStruct 
{
  struct mailmime *mime = mailmime_multiple_new("multipart/mixed");
  NSEnumerator *enumer = [myContentList objectEnumerator];
	
	MKMIME *part;
	int r;
	while((part = [enumer nextObject])) {
		r = mailmime_smart_add_part(mime, [part buildMIMEStruct]);
		assert(r == 0);
	}      
	
	return mime;
}
@end