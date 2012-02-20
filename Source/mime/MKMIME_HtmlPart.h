#import <Foundation/Foundation.h>
#import "MKMIME_SinglePart.h"

@interface MKMIME_HtmlPart : MKMIME_SinglePart {
}
+ (id) mimeTextPartWithString:(NSString *) str;
- (id) initWithString:(NSString *) string;
- (void) setString:(NSString *) str;
@end
