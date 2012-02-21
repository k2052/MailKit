#import <Foundation/Foundation.h>
#import <libetpan/libetpan.h>

@class MKCoreFolder;

@interface MKCoreAccount : NSObject {	
	struct mailstorage *myStorage;
	BOOL connected;
}

- (NSSet *) allFolders;      
- (NSSet *) subscribedFolders;     
- (MKCoreFolder *) folderWithPath:(NSString *)path;

- (void) connectToServer:(NSString *) server port:(int) port connectionType:(int) conType authType:(int) authType 
						login:(NSString *) login password:(NSString *) password; 
						
- (BOOL) isConnected;
- (void) disconnect;

- (mailimap *) session;
- (struct mailstorage *) storageStruct;
@end
