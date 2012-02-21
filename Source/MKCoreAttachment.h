#import <Foundation/Foundation.h>
#import "MKBareAttachment.h"

@interface MKCoreAttachment : MKBareAttachment {
	NSData *mData;    
}  

@property(retain) NSData *data;   
@property(retain) NSString *filename;
@property(retain) NSString *contentType;

- (id) initWithContentsOfFile:(NSString *) path;
- (id) initWithData:(NSData *) data contentType:(NSString *) contentType 
  filename:(NSString *) filename;
- (BOOL) writeToFile:(NSString *) path;
@end
