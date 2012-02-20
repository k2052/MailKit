#import "MKMIME_SinglePart.h"

#import <libetpan/libetpan.h>
#import "MailKitTypes.h"

@implementation MKMIME_SinglePart
@synthesize attached=mAttached;
@synthesize filename=mFilename;
@synthesize data=mData;
@synthesize fetched=mFetched;

+ (id) mimeSinglePartWithData:(NSData *) data 
{
	return [[[MKMIME_SinglePart alloc] initWithData:data] autorelease];
}

- (id) initWithData:(NSData *) data 
{
	self = [super init]; 
	
	if(self) {
		self.data    = data;
		self.fetched = YES;
	}    
	
	return self;
}

- (id) initWithMIMEStruct:(struct mailmime *) mime 
		forMessage:(struct mailmessage *) message 
{
	self = [super initWithMIMEStruct:mime forMessage:message];
	if(self) 
	{
		self.data    = nil;
		mMime        = mime;
		mMessage     = message;
		self.fetched = NO;
				
		mMimeFields = mailmime_single_fields_new(mMime->mm_mime_fields, mMime->mm_content_type);
		if(mMimeFields != NULL) 
		{
			struct mailmime_disposition *disp = mMimeFields->fld_disposition;
			if(disp != NULL) 
			{
				if(disp->dsp_type != NULL) {
					self.attached = (disp->dsp_type->dsp_type == MAILMIME_DISPOSITION_TYPE_ATTACHMENT);
				}
			}
			
      if (mMimeFields->fld_disposition_filename != NULL)		 
      { 
				self.filename           = [NSString stringWithCString:mMimeFields->fld_disposition_filename 
  				encoding:NSUTF8StringEncoding];               
  				
				NSString* lowercaseName = [self.filename lowercaseString];  
				
				if([lowercaseName hasSuffix:@".pdf"] ||
					[lowercaseName hasSuffix:@".jpg"] ||
					[lowercaseName hasSuffix:@".png"] ||
					[lowercaseName hasSuffix:@".gif"]) 
				{ 
					self.attached = YES;
				}
			}

		}
	}  
	
	return self;
}

- (void) fetchPart 
{
	if(self.fetched == NO) 
	{
		struct mailmime_single_fields *mimeFields = NULL;
		
		int encoding = MAILMIME_MECHANISM_8BIT;
		mimeFields = mailmime_single_fields_new(mMime->mm_mime_fields, mMime->mm_content_type);
		if(mimeFields != NULL && mimeFields->fld_encoding != NULL)
			encoding = mimeFields->fld_encoding->enc_type;
		
		char *fetchedData;
		size_t fetchedDataLen;
		int r;
		r = mailmessage_fetch_section(mMessage, mMime, &fetchedData, &fetchedDataLen);
		if(r != MAIL_NO_ERROR) {
			mailmessage_fetch_result_free(mMessage, fetchedData);
			RaiseException(MKMIMEParseError, MKMIMEParseErrorDesc);
		}

		size_t current_index = 0;
		char * result;
		size_t result_len;
		r = mailmime_part_parse(fetchedData, fetchedDataLen, &current_index, 
									encoding, &result, &result_len);
		if(r != MAILIMF_NO_ERROR) {
			mailmime_decoded_part_free(result);
			RaiseException(MKMIMEParseError, MKMIMEParseErrorDesc);
		}     
		
		NSData *data = [NSData dataWithBytes:result length:result_len];
		mailmessage_fetch_result_free(mMessage, fetchedData);
		mailmime_decoded_part_free(result);
		mailmime_single_fields_free(mimeFields);		 
		
		self.data    = data;
		self.fetched = YES;
	}
}

- (struct mailmime *) buildMIMEStruct 
{
	struct mailmime_mechanism * encoding;
	struct mailmime_fields *mime_fields;
	struct mailmime *mime_sub;
	struct mailmime_content *content;
	int r;
    struct mailmime_disposition * disposition;

	if(mFilename )
  {
    mime_fields = mailmime_fields_new_filename( MAILMIME_DISPOSITION_TYPE_ATTACHMENT, 
      (char *)[mFilename cStringUsingEncoding:NSUTF8StringEncoding], 
      MAILMIME_MECHANISM_BASE64 );  
	}
  else {
    mime_fields = mailmime_fields_new_encoding(MAILMIME_MECHANISM_BASE64);
  }  

	assert(mime_fields != NULL);

	content = mailmime_content_new_with_str([self.contentType cStringUsingEncoding:NSUTF8StringEncoding]);
	assert(content != NULL);
	
	mime_sub = mailmime_new_empty(content, mime_fields);
	assert(mime_sub != NULL);
	
	r = mailmime_set_body_text(mime_sub, (char *)[self.data bytes], [self.data length]);
	assert(r == MAILIMF_NO_ERROR);      
	
	return mime_sub;
}


- (void) dealloc 
{
	mailmime_single_fields_free(mMimeFields);
	[mData release];
	[mFilename release];

	[super dealloc];
}
@end