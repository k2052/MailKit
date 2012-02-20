#import <Foundation/Foundation.h>
#import "MKBareAttachment.h"

@interface MKCoreAttachment : MKBareAttachment {
	NSData *mData;
}
@property(retain) NSData *data;

- (id) initWithContentsOfFile:(NSString *) path;
- (id) initWithData:(NSData *) data contentType:(NSString *) contentType 
  filename:(NSString *) filename;
- (BOOL) writeToFile:(NSString *) path;
@end
