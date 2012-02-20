#import <Foundation/Foundation.h>

@interface MKBareMessage : NSObject {
	NSString *mUid;
	unsigned int mFlags;
}         

@property (retain) NSString *uid;
@property unsigned int flags;

- (id) init;
- (NSUInteger) hash;
- (BOOL) isEqual:(id) anObject;
@end