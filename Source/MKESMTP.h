#import <Foundation/Foundation.h>
#import "MKSMTP.h"

@interface MKESMTP : MKSMTP {

}    

- (bool) helo;
- (void) startTLS;
- (void) authenticateWithUsername:(NSString *) username password:(NSString *) password server:(NSString *) server;
- (void) setFrom:(NSString *) fromAddress;
- (void) setRecipientAddress:(NSString *) recAddress;
@end
