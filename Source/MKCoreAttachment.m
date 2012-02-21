#import "MKCoreAttachment.h"
#import "MailKitTypes.h"

@implementation MKCoreAttachment
@synthesize data=mData;

- (id) initWithContentsOfFile:(NSString *) path 
{
	NSData *data          = [NSData dataWithContentsOfFile:path];
	NSString *filePathExt = [path pathExtension];
	
	NSString *contentType      = nil;
	NSDictionary *contentTypes = [NSDictionary dictionaryWithContentsOfFile:MKContentTypesPath];
	for(NSString *key in [contentTypes allKeys]) 
	{
		NSArray *fileExtensions = [contentTypes objectForKey:key];
		for(NSString *ext in fileExtensions) 
		{
			if([filePathExt isEqual:ext]) {
				contentType = key;
				break;
			}
		}
		if(contentType != nil)
			break;
	}
	
	if(contentType == nil) {
		contentType = @"application/octet-stream";
	}
	
	NSString *filename = [path lastPathComponent]; 
	
	return [self initWithData:data contentType:contentType filename:filename];
}

- (id) initWithData:(NSData *) data contentType:(NSString *) contentType 
		filename:(NSString *) filename 
{
	self = [super init];
	
	if(self) {
		self.data        = data;
		self.contentType = contentType;
		self.filename    = filename;
	}   
	
	return self;
}

- (BOOL) writeToFile:(NSString *) path 
{
	return [mData writeToFile:path atomically:YES];
}

- (void) dealloc 
{
	[mData release];
	[super dealloc];
}
@end