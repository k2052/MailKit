
#import <Foundation/Foundation.h>
#import "MKCoreAccount.h"
#import "MKCoreFolder.h"
#import "MKCoreMessage.h"
#import "MKSMTPConnection.h"
#import "MKCoreAddress.h"
#import "MailKitTypes.h"

#import "MKMIME_TextPart.h"
#import "MKMIME_SinglePart.h"
#import "MKMIME_MultiPart.h"
#import "MKMIME_MessagePart.h"
#import "MKMIME.h"

#import "MKMIMEFactory.h"

const NSString *filePrefix = @"/Users/local/Projects/MailKit/";

int main( int argc, char *argv[ ] )
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	MKCoreMessage *msgOne = [[MKCoreMessage alloc] init];
	[msgOne setTo:[NSSet setWithObject:[MKCoreAddress addressWithName:@"Bob" email:@"mronge@theronge.com"]]];
	[msgOne setFrom:[NSSet setWithObject:[MKCoreAddress addressWithName:@"test" email:@"test@test.com"]]];
	MKMIME_TextPart *text = [MKMIME_TextPart mimeTextPartWithString:@"Hell this is a mime test"];
	MKMIME_SinglePart *part = [MKMIME_SinglePart mimeSinglePartWithData:[NSData dataWithContentsOfFile:@"/tmp/DSC_6201.jpg"]];
	part.contentType = @"image/jpeg";
	MKMIME_MultiPart *multi = [MKMIME_MultiPart mimeMultiPart];
	[multi addMIMEPart:text];
	[multi addMIMEPart:part];
	MKMIME_MessagePart *messagePart = [MKMIME_MessagePart mimeMessagePartWithContent:multi];
	[msgOne setSubject:@"MIME Test"];	
	msgOne.mime = messagePart;
	[MKSMTPConnection sendMessage:msgOne server:@"mail.theronge.com" username:@"mronge" password:@"" port:25 useTLS:YES useAuth:YES];
	[msgOne release];
	[pool release];
		
	return 0;
}
