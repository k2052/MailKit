#import <Foundation/Foundation.h>
#import <libetpan/libetpan.h>

@interface MKSMTP : NSObject {
	mailsmtp *mySMTP; 
}        

- (id) initWithResource:(mailsmtp *) smtp;
- (void) connectToServer:(NSString *) server port:(unsigned int) port;
- (bool) helo;
- (void) startTLS;
- (void) authenticateWithUsername:(NSString *) username password:(NSString *) password server:(NSString *) server;
- (void) setFrom:(NSString *) fromAddress;
- (void) setRecipients:(id) recipients;
- (void) setRecipientAddress:(NSString *) recAddress;
- (void) setData:(NSString *) data;
- (int) setData:(NSString *) data raiseExceptions:(BOOL) aShouldRaise;
- (mailsmtp *) resource;
@end
