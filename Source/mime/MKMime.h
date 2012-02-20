#import <Foundation/Foundation.h>
#import <libetpan/libetpan.h>

@class MKMIME_Enumerator;

@interface MKMIME : NSObject {
	NSString *mContentType;
}
@property(retain) NSString *contentType;
@property(readonly) id content;

- (id) initWithMIMEStruct:(struct mailmime *) mime 
		forMessage:(struct mailmessage *) message;
- (struct mailmime *) buildMIMEStruct;
- (NSString *) render;
- (MKMIME_Enumerator *) mimeEnumerator;
@end
