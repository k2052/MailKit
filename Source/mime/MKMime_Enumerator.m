#import "MKMIME_Enumerator.h"
#import "MKMIME.h"
#import "MKMIME_MultiPart.h"
#import "MKMIME_MessagePart.h"

@implementation MKMIME_Enumerator
- (id) initWithMIME:(MKMIME *) mime 
{
	self = [super init];
	
	if(self) {
		mToVisit = [[NSMutableArray alloc] init];
		[mToVisit addObject:mime];
	}  
	
	return self;
}

- (NSArray *) allObjects 
{
	NSMutableArray *objects = [NSMutableArray array];
	
	id obj;
	while((obj = [self nextObject])) {
		[objects addObject:obj];
	}  
	
	return objects;
}

- (id) nextObject 
{
	if([mToVisit count] == 0) {
		return nil;
	}
	
	id mime = [mToVisit objectAtIndex:0];
	if([mime isKindOfClass:[MKMIME_MessagePart class]]) 
	{
		if([mime content] != nil) {
			[mToVisit addObject:[mime content]];
		}
	}
	else if([mime isKindOfClass:[MKMIME_MultiPart class]]) 
	{
		NSEnumerator *enumer = [[mime content] objectEnumerator];
		MKMIME *subpart;
		while((subpart = [enumer nextObject])) {
			[mToVisit addObject:subpart];
		}
	}    
	
	[mToVisit removeObjectAtIndex:0]; 
	
	return mime;
}

- (void) dealloc 
{
	[mToVisit release];
	[super dealloc];
}
@end
