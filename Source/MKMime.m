#import "MKMIME.h"
#import "MKMIME_Enumerator.h"

@implementation MKMIME
@synthesize contentType=mContentType;

- (id) initWithMIMEStruct:(struct mailmime *) mime 
		forMessage:(struct mailmessage *) message 
{
	self = [super init];   
	
	if(self) 
	{
		// We couldn't find a content-type, set it to something generic		
		NSString *mainType = @"application";
		NSString *subType = @"octet-stream";		
		if (mime != NULL && mime->mm_content_type != NULL) 
		{
			struct mailmime_content *content = mime->mm_content_type;
			if(content->ct_type != NULL) 
			{
				subType = [NSString stringWithCString:content->ct_subtype encoding:NSUTF8StringEncoding];
				subType = [subType lowercaseString];       
				
				struct mailmime_type *type = content->ct_type;
				if(type->tp_type == MAILMIME_TYPE_DISCRETE_TYPE && type->tp_data.tp_discrete_type != NULL) 
				{
					switch(type->tp_data.tp_discrete_type->dt_type) 
					{
						case MAILMIME_DISCRETE_TYPE_TEXT:
							mainType = @"text";
						break;
						case MAILMIME_DISCRETE_TYPE_IMAGE:
							mainType = @"image";
						break;
						case MAILMIME_DISCRETE_TYPE_AUDIO:
							mainType = @"audio";
						break;
						case MAILMIME_DISCRETE_TYPE_VIDEO:
							mainType = @"video";
						break;
						case MAILMIME_DISCRETE_TYPE_APPLICATION:
							mainType = @"application";
						break;
					}			
				}
				else if(type->tp_type == MAILMIME_TYPE_COMPOSITE_TYPE && type->tp_data.tp_composite_type != NULL) 
				{
					switch(type->tp_data.tp_discrete_type->dt_type) 
					{
						case MAILMIME_COMPOSITE_TYPE_MESSAGE:
							mainType = @"message";
						break;
						case MAILMIME_COMPOSITE_TYPE_MULTIPART:
							mainType = @"multipart";
						break;
					}			
				}
			}
		}          
		
		mContentType = [[NSString alloc] initWithFormat:@"%@/%@", mainType, subType];
	}              
	
	return self;
}

- (id) content 
{
	return nil;
}

- (NSString *) contentType 
{
	return mContentType;
}

- (struct mailmime *) buildMIMEStruct 
{
	return NULL;
}

- (NSString *) render 
{
	MMAPString * str = mmap_string_new("");
	int col          = 0;
	int err          = 0;    
	
 	NSString *resultStr;
	
	mailmime_write_mem(str, &col, [self buildMIMEStruct]);     
	
	err = mmap_string_ref(str);         
	assert(err == 0);      
	
	resultStr = [[NSString alloc] initWithBytes:str->str length:str->len encoding:NSUTF8StringEncoding];        
	
	mmap_string_free(str);    
	
	return [resultStr autorelease];
}

- (MKMIME_Enumerator *) mimeEnumerator 
{
	MKMIME_Enumerator *enumerator;
	enumerator = [[MKMIME_Enumerator alloc] initWithMIME:self]; 
	
	return [enumerator autorelease];
}

- (void) dealloc 
{
	[mContentType release];
	[super dealloc];
}
@end