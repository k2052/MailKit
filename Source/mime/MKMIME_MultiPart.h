
#import <Foundation/Foundation.h>
#import "MKMIME.h"

@interface MKMIME_MultiPart : MKMIME {
	NSMutableArray *myContentList;
}
+ (id) mimeMultiPart;
- (void) addMIMEPart:(MKMIME *) mime;
@end
