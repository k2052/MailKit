#import <Foundation/Foundation.h>
#import "MKMIME.h"

@interface MKMIME_MessagePart : MKMIME {
	MKMIME *myMessageContent;
	struct mailimf_fields *myFields;
}
+ (id) mimeMessagePartWithContent:(MKMIME *) mime;
- (id) initWithContent:(MKMIME *) messageContent;
- (void) setContent:(MKMIME *) aContent;
- (MKMIME *) content;
- (void) setIMFFields:(struct mailimf_fields *) imfFields;
@end
