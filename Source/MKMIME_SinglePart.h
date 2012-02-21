#import <Foundation/Foundation.h>
#import "MKMIME.h"

@interface MKMIME_SinglePart : MKMIME {
	struct mailmime *mMime;
	struct mailmessage *mMessage;
	struct mailmime_single_fields *mMimeFields;	

	NSData *mData;
	BOOL mAttached;
	BOOL mFetched;
	NSString *mFilename;
}
@property BOOL attached;
@property BOOL fetched;
@property(retain) NSString *filename;
@property(retain) NSData *data; 

+ (id) mimeSinglePartWithData:(NSData *) data;
- (id) initWithData:(NSData *) data;
- (void) fetchPart;
@end
