#import "MKSMTPConnection.h"
#import <libetpan/libetpan.h>
#import "MKCoreAddress.h"
#import "MKCoreMessage.h"
#import "MailKitTypes.h"

#import "MKSMTP.h"
#import "MKESMTP.h"

@implementation MKSMTPConnection
+ (void) sendMessage:(MKCoreMessage *) message server:(NSString *) server username:(NSString *) username
  password:(NSString *) password port:(unsigned int) port useTLS:(BOOL) tls useAuth:(BOOL) auth {
  	
  mailsmtp *smtp = NULL;
	smtp           = mailsmtp_new(0, NULL);       
	
	assert(smtp != NULL);

	MKSMTP *smtpObj = [[MKESMTP alloc] initWithResource:smtp];
	@try 
	{
		[smtpObj connectToServer:server port:port];
		if([smtpObj helo] == false) {
			[smtpObj release];
			smtpObj = [[MKSMTP alloc] initWithResource:smtp];
			[smtpObj helo];
		}
		if(tls)
			[smtpObj startTLS];
		if(auth)
			[smtpObj authenticateWithUsername:username password:password server:server];

		[smtpObj setFrom:[[[message from] anyObject] email]];

		NSMutableSet *rcpts = [NSMutableSet set];
		[rcpts unionSet:[message to]];
		[rcpts unionSet:[message bcc]];
		[rcpts unionSet:[message cc]];
		[smtpObj setRecipients:rcpts];
	 
		[smtpObj setData:[message render]];
	}     
	
	@finally {
		[smtpObj release];	
		mailsmtp_free(smtp);
	}
}
@end