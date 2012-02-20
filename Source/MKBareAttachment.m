#import "MKBareAttachment.h"

#import "MailKitTypes.h"
#import "MKMIME_SinglePart.h"
#import "MKCoreAttachment.h"

@implementation MKBareAttachment
@synthesize contentType=mContentType;
@synthesize filename=mFilename;

- (id) initWithMIMESinglePart:(MKMIME_SinglePart *) part 
{
	self = [super init];  
	
	if(self) {
		mMIMEPart        = [part retain];
		self.filename    = mMIMEPart.filename;
		self.contentType = mMIMEPart.contentType;
	} 
	
	return self;
}

- (NSString*) decodedFilename 
{        
  
	if(StringStartsWith(self.filename, @"=?ISO-8859-1?Q?")) 
	{
		NSString* newName = [self.filename substringFromIndex:[@"=?ISO-8859-1?Q?" length]];
		newName = [newName stringByReplacingOccurrencesOfString:@"?=" withString:@""];
		newName = [newName stringByReplacingOccurrencesOfString:@"__" withString:@" "];
		newName = [newName stringByReplacingOccurrencesOfString:@"=" withString:@"%"];		
		newName = [newName stringByReplacingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding];
		return newName;
	}
	
	return self.filename;
}


- (NSString *) description 
{
	return [NSString stringWithFormat:@"ContentType: %@\tFilename: %@", self.contentType, self.filename];
}

- (MKCoreAttachment *) fetchFullAttachment 
{
	[mMIMEPart fetchPart];     
	
	MKCoreAttachment *attach = [[MKCoreAttachment alloc] initWithData:mMIMEPart.data
  	contentType:self.contentType filename:self.filename];     
  	
	return [attach autorelease];
}

- (void) dealloc 
{
	[mMIMEPart release];
	[mFilename release];
	[mContentType release];
	[super dealloc];
}
@end