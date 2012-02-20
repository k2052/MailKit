#import <Foundation/Foundation.h>

@interface MKCoreAddress : NSObject {
	NSString *email;
	NSString *name;
}

+ (id) address;
+ (id) addressWithName:(NSString *) aName email:(NSString *) aEmail;
- (id) initWithName:(NSString *) aName email:(NSString *) aEmail;

- (NSString *) name;
- (NSString*) decodedName; 
- (void) setName:(NSString *) aValue;      

- (NSString *) email;
- (void) setEmail:(NSString *) aValue;
- (BOOL) isEqual:(id) object;   

- (NSString *) description;    
@end