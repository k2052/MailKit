#import "MailKitUtilities.h"
#import "JRLog.h"

void mailkit_logger(int direction, const char * str, size_t size) 
{
	char *str2 = malloc(size+1);
	strncpy(str2,str,size);        
	
	str2[size] = 0;
	id self    = nil; 
	
	if(direction == 1) {
		JRLogInfo(@"Client: %s\n", str2);
	}
	else if(direction == 0) {
		JRLogInfo(@"Server: %s\n", str2);
	}
	else {
		JRLogInfo(@"%s\n", str2);
	}    
	
	free(str2);
}

void MailKitEnableLogging() 
{
	mailstream_debug  = 1;
	mailstream_logger = mailkit_logger;
}

void MailKitDisableLogging() 
{
    mailstream_debug  = 0;
    mailstream_logger = nil;
}

void IfFalse_RaiseException(bool value, NSString *exceptionName, NSString *exceptionDesc) 
{
	if(!value)
		RaiseException(exceptionName, exceptionDesc);
}


void IfTrue_RaiseException(bool value, NSString *exceptionName, NSString *exceptionDesc) 
{
	if(value)
		RaiseException(exceptionName, exceptionDesc);
}


void RaiseException(NSString *exceptionName, NSString *exceptionDesc)
{
	NSException *exception = [NSException
    exceptionWithName:exceptionName
    reason:exceptionDesc
    userInfo:nil];  
    
	[exception raise];
}

BOOL StringStartsWith(NSString *string, NSString *subString) 
{
	if([string length] < [subString length]) {
		return NO;
	}
	
	NSString* comp = [string substringToIndex:[subString length]];                 
	
	return [comp isEqualToString:subString];
}