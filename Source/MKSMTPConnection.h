#import <Foundation/Foundation.h>

@class MKCoreMessage, MKCoreAddress;

@interface MKSMTPConnection : NSObject {

}

+ (void) sendMessage:(MKCoreMessage *) message server:(NSString *) server username:(NSString *) username
  password:(NSString *) password port:(unsigned int) port useTLS:(BOOL) tls useAuth:(BOOL) auth;
@end
