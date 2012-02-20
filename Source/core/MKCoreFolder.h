#import <Foundation/Foundation.h>
#import <libetpan/libetpan.h>

@class MKCoreMessage, MKCoreAccount;

@interface MKCoreFolder : NSObject {
	struct mailfolder *myFolder;
	MKCoreAccount *myAccount;
	NSString *myPath;
	BOOL connected;
}

- (id) initWithPath:(NSString *)  path inAccount:(MKCoreAccount *) account;

- (void) connect;
- (void) disconnect;
- (NSSet *) messageObjectsFromIndex:(unsigned int) start toIndex:(unsigned int) end;

- (MKCoreMessage *) messageWithUID:(NSString *) uid;
- (NSSet *) messageListWithFetchAttributes:(NSArray *) attributes;
- (BOOL) isUIDValid:(NSString *) uid;

- (NSUInteger) sequenceNumberForUID:(NSString *) uid;

- (void) check;

- (NSString *) name;  

- (NSString *) path;
- (void) setPath:(NSString *) path;

- (void) create;
- (void) delete;

- (void) subscribe;
- (void) unsubscribe;                       

- (unsigned int) flagsForMessage:(MKCoreMessage *) msg;
- (void) setFlags:(unsigned int) flags forMessage:(MKCoreMessage *) msg;

- (void) expunge;

- (void) copyMessage: (NSString *) path forMessage:(MKCoreMessage *) msg;
- (void) moveMessage: (NSString *) path forMessage:(MKCoreMessage *) msg;

- (NSUInteger) unreadMessageCount;
- (NSUInteger) totalMessageCount;
- (NSUInteger) uidValidity;

- (struct mailfolder *) folderStruct;
- (mailsession *) folderSession;
- (mailimap *) imapSession;
@end