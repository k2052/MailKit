#import "MKSMTP.h"
#import "MKCoreAddress.h"
#import "MKCoreMessage.h"
#import "MailKitTypes.h"

@implementation MKSMTP
- (id) initWithResource:(mailsmtp *) smtp 
{
	self = [super init];
	
	if(self) {
		mySMTP = smtp;
	} 
	
	return self;
}

- (void) connectToServer:(NSString *) server port:(unsigned int) port 
{
	int ret = mailsmtp_socket_connect([self resource], [server cStringUsingEncoding:NSUTF8StringEncoding], port);
	IfTrue_RaiseException(ret != MAILSMTP_NO_ERROR, MKSMTPSocket, MKSMTPSocketDesc);
}

- (bool) helo 
{
	int ret = mailsmtp_helo([self resource]);
	IfTrue_RaiseException(ret != MAILSMTP_NO_ERROR, MKSMTPHello, MKSMTPHelloDesc); 
	
	return YES; 
}

- (void) startTLS 
{
}

- (void) authenticateWithUsername:(NSString *) username password:(NSString *) password server:(NSString *) server 
{
}

- (void) setFrom:(NSString *) fromAddress 
{
	int ret = mailsmtp_mail([self resource], [fromAddress cStringUsingEncoding:NSUTF8StringEncoding]);
	IfTrue_RaiseException(ret != MAILSMTP_NO_ERROR, MKSMTPFrom, MKSMTPFromDesc);
}

- (void) setRecipients:(id) recipients 
{
	NSEnumerator *objEnum = [recipients objectEnumerator];
	MKCoreAddress *rcpt;
	while(rcpt = [objEnum nextObject]) {
		[self setRecipientAddress:[rcpt email]];
	}
}

- (void) setRecipientAddress:(NSString *) recAddress 
{
	int ret = mailsmtp_rcpt([self resource], [recAddress cStringUsingEncoding:NSUTF8StringEncoding]);
	IfTrue_RaiseException(ret != MAILSMTP_NO_ERROR, MKSMTPRecipients, MKSMTPRecipientsDesc);
}

- (void) setData:(NSString *) data 
{
	[self setData:data raiseExceptions:YES];
}

- (int) setData:(NSString *) data raiseExceptions:(BOOL) aShouldRaise 
{
	NSData *dataObj = [data dataUsingEncoding:NSUTF8StringEncoding];     
	
	int ret = mailsmtp_data([self resource]);
	if(aShouldRaise) {
    IfTrue_RaiseException(ret != MAILSMTP_NO_ERROR, MKSMTPData, MKSMTPDataDesc);
	}         
	
  ret = mailsmtp_data_message([self resource], [dataObj bytes], [dataObj length]);
	if(aShouldRaise) {
    IfTrue_RaiseException(ret != MAILSMTP_NO_ERROR, MKSMTPData, MKSMTPDataDesc);
	}  
	
  return ret;
}

- (mailsmtp *) resource 
{
	return mySMTP;
}
@end