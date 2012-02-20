
#import <Foundation/Foundation.h>

@class MKMIME;

@interface MKMIME_Enumerator : NSEnumerator {
	NSMutableArray *mToVisit;
}     

- (id) initWithMIME:(MKMIME *) mime;

- (NSArray *) allObjects;
- (id) nextObject;
@end
