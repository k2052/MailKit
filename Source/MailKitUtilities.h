#import <Foundation/Foundation.h>
#import <libetpan/libetpan.h>

void MailKitEnableLogging();
void MailKitDisableLogging();

void IfFalse_RaiseException(bool value, NSString *exceptionName, NSString *exceptionDesc);
void IfTrue_RaiseException(bool value, NSString *exceptionName, NSString *exceptionDesc);
void RaiseException(NSString *exceptionName, NSString *exceptionDesc);

BOOL StringStartsWith(NSString *string, NSString *subString);