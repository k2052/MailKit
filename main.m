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
	
//	MKCoreMessage *msg = [[MKCoreMessage alloc] initWithFileAtPath:[NSString stringWithFormat:@"%@%@",filePrefix,@"TestData/mime-tests/imagetest"]];
//	MKMIME *mime = [MKMIMEFactory createMIMEWithMIMEStruct:[msg messageStruct]->msg_mime forMessage:[msg messageStruct]];
	
	
//	MKCoreAccount *account = [[MKCoreAccount alloc] init];
//	MKCoreFolder *folder;
//////	MKCoreFolder *inbox, *newFolder, *archive;
//////	MKCoreMessage *msgOne;
//////	
////
////	MailCoreEnableLogging();
//	[account connectToServer:@"mail.theronge.com" port:143 connectionType:CONNECTION_TYPE_STARTTLS 
//				authType:IMAP_AUTH_TYPE_PLAIN login:@"mronge" password:@""];
//	
//	folder = [account folderWithPath:@"INBOX.Trash"];
//	for (MKCoreMessage *msg in [folder messageObjectsFromIndex:0 toIndex:10]) {
//		NSLog(@"%@ / %@", msg.subject, msg.uid);
//	}
//	
//	MKCoreMessage *msg = [folder messageWithUID:@"1163997146-103"];
//	unsigned int flags = [folder flagsForMessage:msg];
//	flags = flags | MKFlagDeleted;
//	[folder setFlags:flags forMessage:msg];
//	[folder expunge];
//	
	
	//[folder copyMessageWithUID:@"1163978737-3691" toFolderWithPath:@"INBOX.Trash"];
	//NSLog(@"%d", [folder totalMessageCount]);
/*	for (MKCoreMessage *msg in [folder messageObjectsFromIndex:10 toIndex:18]) {
		NSLog(@"%d", [msg sequenceNumber]);
		NSLog([msg uid]);
	}*/
	//	14
	//1163978737-3518
	//MKCoreMessage *msg = [folder messageWithUID:@"1163978737-3518"];
	//NSLog([msg subject]);
//	NSLog(@"%d", [folder sequenceNumberForUID:@"1163978737-3518"]);
//	[account release];
//	MKCoreMessage *msg;
//	NSEnumerator *enumer = [set objectEnumerator];
//	while ((msg == [enumer nextObject])) {
//		
//	}
//	//NSLog(@"%@", [inbox messageObjectsFromIndex:500 toIndex:600]);
//	
//	msgOne = [inbox messageWithUID:@"1146070022-553"];
//	NSLog(@"%@ %@", [msgOne flags], [msgOne subject]);
//	NSMutableDictionary *flags = [[msgOne flags] mutableCopy];
//	[flags setObject:MKFlagSet forKey:MKFlagSeen];
//	[msgOne setFlags:flags];
	//[inbox disconnect];
	//	[inbox expunge];

	/*
	NSSet *messageList = [inbox messageListFromIndex:nil];
	NSLog(@"Message List....");
	NSLog(@"%@",messageList);
	NSEnumerator *enumerator = [messageList objectEnumerator];
	id obj;
	MKCoreMessage *tempMsg;
	while(obj = [enumerator nextObject])
	{
		tempMsg = [inbox messageWithUID:obj];
		NSLog(@"%@",[tempMsg subject]);
	}
	
	NSSet *archiveMessageList;
	archive = [account folderWithPath:@"INBOX.TheArchive"];
	archiveMessageList = [archive messageListFromIndex:nil];
	NSEnumerator *objEnum = [archiveMessageList objectEnumerator];
	id aMessage;

	NSLog(@"INBOX.TheArchive");
	NSLog(@"%@",archiveMessageList);
	while(aMessage = [objEnum nextObject])
	{
		tempMsg = [archive messageWithUID:aMessage];
		NSLog(@"%@",[tempMsg subject]);
		NSLog(@"%@",[tempMsg from]);
		NSLog(@"%@",[tempMsg to]);
	}
	
	msgOne =[inbox messageWithUID:@"1142229815-9"];
	[msgOne setBody:@"Muhahahaha. Libetpan!"];
	[msgOne setSubject:@"Hahaha"];
	[msgOne setTo:[NSSet setWithObject:[MKCoreAddress addressWithName:@"Bob" email:@"mronge2@uiuc.edu"]]];
	[msgOne setFrom:[NSSet setWithObject:[MKCoreAddress addressWithName:@"Matt" email:@"mronge@theronge.com"]]];
	*/
	
	//MKCoreAddress *addr = [MKCoreAddress address];
	//[addr setEmail:@"Test"];
	//[addr setEmail:@"Test2"];
	
	/* GMAIL Test */
	
//	MailCoreEnableLogging();
	
	MKCoreMessage *msgOne = [[MKCoreMessage alloc] init];
	[msgOne setTo:[NSSet setWithObject:[MKCoreAddress addressWithName:@"Bob" email:@"mronge@theronge.com"]]];
	[msgOne setFrom:[NSSet setWithObject:[MKCoreAddress addressWithName:@"test" email:@"test@test.com"]]];
	//[msgOne setBody:@"Test"];
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

	//[MKSMTPConnection sendMessage:msgOne server:@"mail.dls.net" username:@"" password:@"" port:25 useTLS:NO shouldAuth:NO];
	//[archive disconnect];
	//[account disconnect];
	//[account release];
	
	[pool release];
		
	//while(1) {}
	return 0;
}
