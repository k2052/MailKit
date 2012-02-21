#import "MKCoreAddress.h"

@implementation MKCoreAddress
+ (id) address 
{
	MKCoreAddress *aAddress = [[MKCoreAddress alloc] init];
	return [aAddress autorelease];
}

+ (id) addressWithName:(NSString *) aName email:(NSString *) aEmail 
{
	MKCoreAddress *aAddress = [[MKCoreAddress alloc] initWithName:aName email:aEmail];
	return [aAddress autorelease];
}

- (id) initWithName:(NSString *) aName email:(NSString *) aEmail 
{
	self = [super init]; 
	
	if(self) {
		[self setName:aName];
		[self setEmail:aEmail];
	}       
	
	return self;
}


- (id) init 
{
	self = [super init];       
	
	if(self) {
		[self setName:@""];
		[self setEmail:@""];
	}  
	
	return self;
}

-(NSString*) decodedName 
{
	if(StringStartsWith(self.name, @"=?ISO-8859-1?Q?")) 
	{
		NSString* newName = [self.name substringFromIndex:[@"=?ISO-8859-1?Q?" length]];      
		
		newName = [newName stringByReplacingOccurrencesOfString:@"?=" withString:@""];
		newName = [newName stringByReplacingOccurrencesOfString:@"__" withString:@" "];
		newName = [newName stringByReplacingOccurrencesOfString:@"=" withString:@"%"];		
		newName = [newName stringByReplacingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding];  
		
		return newName;
	}   
	
	return self.name;
}

- (NSString *) name 
{
	return name;
}

- (void) setName:(NSString *) aValue 
{
	NSString *oldName = name;
	name              = [aValue retain];
	[oldName release];
}

- (NSString *) email 
{
	return email;
}

- (void) setEmail:(NSString *) aValue 
{
	NSString *oldEmail = email;
	email              = [aValue retain];
	[oldEmail release];
}

- (NSString *) description 
{
	return [NSString stringWithFormat:@"<%@,%@>", [self name],[self email]];
}

- (BOOL) isEqual:(id) object 
{
	if (![object isKindOfClass:[MKCoreAddress class]])
		return NO; 
		
	return [[object name] isEqualToString:[self name]] && [[object email] isEqualToString:[self email]];
}

- (void) dealloc 
{
	[email release];
	[name release];
	[super dealloc];
}
@end