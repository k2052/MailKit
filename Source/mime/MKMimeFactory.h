#import <Foundation/Foundation.h>

@class MKMIME, MKMIME_SinglePart;

@interface MKMIMEFactory : NSObject {

}
+ (MKMIME *) createMIMEWithMIMEStruct:(struct mailmime *) mime 
  	forMessage:(struct mailmessage *) message;
+ (MKMIME_SinglePart *) createMIMESinglePartWithMIMEStruct:(struct mailmime *) mime
  forMessage:(struct mailmessage *) message;
@end
