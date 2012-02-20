#import <Foundation/Foundation.h>

@class MKMIME_SinglePart;
@class MKCoreAttachment;

@interface MKBareAttachment : NSObject {
	MKMIME_SinglePart *mMIMEPart;
	NSString *mFilename;
	NSString *mContentType;
}                

@property(retain) NSString *filename;
@property(retain) NSString *contentType;

- (NSString*) decodedFilename;
- (id) initWithMIMESinglePart: (MKMIME_SinglePart *) part;
- (MKCoreAttachment *) fetchFullAttachment;
@end