#import <Foundation/Foundation.h>
#import <libetpan/libetpan.h>
#import <MKCoreAttachment.h>

@class MKCoreFolder, MKCoreAddress, MKMIME;          

@interface MKCoreMessage : NSObject {
	struct mailmessage *myMessage;
	struct mailimf_single_fields *myFields;
	MKMIME *myParsedMIME;
	NSUInteger mySequenceNumber;     
	
	NSMutableArray *_attachments;
 	NSDate *_sentDate;
	NSString *_cachedRenderString;
	NSArray* _contentTypes;
}
@property(readonly) BOOL isMultipart;

@property(retain) NSArray* contentTypes;
@property(retain) MKMIME *mime;
@property(retain) NSMutableArray* mutableAttachments;

- (id) init;
- (id) initWithMessageStruct:(struct mailmessage *) message;
- (id) initWithFileAtPath:(NSString *) path;
- (id) initWithString:(NSString *) msgData;

- (int) fetchBody;
- (NSString *) body;
- (NSString *) htmlBody;
- (NSString *) editableHtmlBody;
- (NSString *) bodyPreferringPlainText;
- (void) setBody:(NSString *) body;
- (void) setHTMLBody:(NSString *) body;

- (NSArray *) attachments;
- (void) addAttachment:(MKCoreAttachment *)attachment;

- (NSString *) subject;
- (void) setSubject:(NSString *) subject;

- (NSTimeZone*) senderTimeZone;
- (NSDate *) senderDate; 
- (NSDate *) sentDateGMT; 
- (NSDate *) sentDateLocalTimeZone;     
- (NSComparisonResult) sentDateCompare:(MKCoreMessage*) other;

- (BOOL) isUnread;     
- (void) setUnread:(BOOL) unread;       
- (void) setDeleted;
- (BOOL) isDeleted;
- (BOOL) isNew;

- (NSString *) messageId;
- (NSString *) uid;

- (NSUInteger) sequenceNumber;
- (NSUInteger) messageSize;

- (void) setSequenceNumber:(NSUInteger) sequenceNumber;    

- (NSSet *) from;
- (void) setFrom:(NSSet *) addresses;

- (MKCoreAddress *) sender;

- (NSSet *) to;
- (void) setTo:(NSSet *) addresses;


- (NSSet *) cc;
- (void) setCc:(NSSet *) addresses;

- (NSSet *) bcc;
- (void) setBcc:(NSSet *) addresses;

- (NSSet *) replyTo;
- (void) setReplyTo:(NSSet *) addresses;

- (NSString *) render;
- (NSData *) messageAsEmlx;
- (NSString *) rfc822;  
- (uint32_t) flags;

- (struct mailmessage *) messageStruct; 

- (mailimap *) imapSession;
@end