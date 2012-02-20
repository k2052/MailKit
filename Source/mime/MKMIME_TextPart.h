#import <Foundation/Foundation.h>
#import "MKMIME_SinglePart.h"

@interface MKMIME_TextPart : MKMIME_SinglePart {
}
+ (id) mimeTextPartWithString:(NSString *) str;
- (id) initWithString:(NSString *) string;
- (void) setString:(NSString *) str;
@end
