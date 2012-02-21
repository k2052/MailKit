#import <libetpan/libetpan.h>

#import "MKCoreAddress.h"
#import "MKCoreMessage.h"
#import "MKESMTP.h"
#import "MKSMTP.h"
#import "MKSMTPAsyncConnection.h"

MKSMTPAsyncConnection* ptrToSelf;

void smtpProgress(size_t aCurrent, size_t aTotal)
{
  if(ptrToSelf != nil)
  {
    float theProgress = (float)aCurrent / (float)aTotal * 100;
    [ptrToSelf performSelector:@selector(handleSmtpProgress:) 
      withObject:[NSNumber numberWithFloat:theProgress]];   
  }          
}

@interface MKSMTPAsyncConnection (PrivateMethods)

- (void) sendMailThread;
- (void) handleSmtpProgress:(NSNumber*) aProgress;
- (void) threadWillExitHandler:(NSNotification*) aNote;
- (void) cleanupAfterThread;
@end

@implementation MKSMTPAsyncConnection

@synthesize message        = mMessage;
@synthesize serverSettings = mServerSettings;
@synthesize status         = mStatus;

- (id) initWithServer:(NSString *) aServer 
  username:(NSString *) aUsername
  password:(NSString *) aPassword 
      port:(unsigned int) aPort 
    useTLS:(BOOL) aTls 
   useAuth:(BOOL) aAuth
  delegate:(id<MKSMTPConnectionDelegate>) aDelegate  
{
  self = [super init];
  if(self)
  {
    mStatus         = MKSMTPAsyncSuccess;
    ptrToSelf       = self;
    mSMTPObj        = nil;
    mSMTP           = NULL;
    mMailThread     = nil;
    mDelegate       = aDelegate;
    
    mServerSettings = [[NSDictionary dictionaryWithObjectsAndKeys:aServer, @"server",
      aUsername, @"username",
      aPassword, @"password",
      [NSNumber numberWithInt:aPort], @"port",
      [NSNumber numberWithBool:aTls], @"tls",
      [NSNumber numberWithBool:aAuth], @"auth", nil] retain];   

    [[NSNotificationCenter defaultCenter] removeObserver:self];        
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
      selector:@selector(threadWillExitHandler:) 
         name:NSThreadWillExitNotification 
       object:nil];           
  }    
  
  return self;
}               
              
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self cleanupAfterThread];
  [super dealloc]; 
}

- (void) finalize
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self cleanupAfterThread];
  [super finalize];    
}

- (void) sendMessageInBackgroundAndNotify:(MKCoreMessage*) aMessage
{
  if(aMessage == nil) {
    NSLog(@"MKCoreMessage param cannot be nil");
    return;     
  }

  if (mMailThread != nil && [mMailThread isExecuting]) {
    NSLog(@"Can only send one message at a time, we're busy, sheesh.");
    return;        
  }

  NSAssert( mMailThread == nil, @"Invalid smtp thread state" );

  self.message = aMessage;

  mMailThread = [NSThread alloc];     
  
  [mMailThread initWithTarget:self selector:@selector(sendMailThread) object:nil];
  [mMailThread start];    
}

- (void) cancel
{
  if(![mMailThread isExecuting] || [mMailThread isCancelled]) {
    return;
  }                      
  
  [mMailThread cancel];
  mailstream_cancel(mSMTP->stream);
  mailstream_close(mSMTP->stream);          
  
  mSMTP->stream = NULL;
  mailsmtp_free(mSMTP);
  mSMTP = NULL; 
}

- (BOOL) isBusy
{
  return(mMailThread != nil && [mMailThread isExecuting]);
}
@end

@implementation MKSMTPAsyncConnection (PrivateMethods)

- (void) sendMailThread
{
  NSAutoreleasePool* thePool      = [[NSAutoreleasePool alloc] init];
  void (*progFxn)(size_t, size_t) = &smtpProgress;  
  
  mSMTP = NULL;
  mSMTP = mailsmtp_new(30, progFxn); 
  
  assert(mSMTP != NULL);
  mSMTPObj = [[MKESMTP alloc] initWithResource:mSMTP];

  NSDictionary* theSettings = self.serverSettings;     

	@try 
  {
    [mSMTPObj connectToServer:[theSettings objectForKey:@"server"] 
    port:[[theSettings objectForKey:@"port"] unsignedIntValue]];   
    
    if([mSMTPObj helo] == false) 
    {
      [mSMTPObj release];
      mSMTPObj = [[MKSMTP alloc] initWithResource:mSMTP];
      [mSMTPObj helo];      
    }  
    
    if([(NSNumber*) [theSettings objectForKey:@"tls"] boolValue])
      [mSMTPObj startTLS];
    if([(NSNumber*) [theSettings objectForKey:@"auth"] boolValue])
      [mSMTPObj authenticateWithUsername:[theSettings objectForKey:@"username"] 
        password:[theSettings objectForKey:@"password"] 
          server:[theSettings objectForKey:@"server"]];  

    MKCoreMessage* theMessage = self.message;
    [mSMTPObj setFrom:[[[theMessage from] anyObject] email]];

    NSMutableSet *rcpts = [NSMutableSet set];
    [rcpts unionSet:[theMessage to]];
    [rcpts unionSet:[theMessage bcc]];
    [rcpts unionSet:[theMessage cc]];
    [mSMTPObj setRecipients:rcpts];  
	 
		int theReturn = [mSMTPObj setData:[theMessage render] raiseExceptions:NO];
		if(theReturn == MAILSMTP_NO_ERROR ) {
      mStatus = MKSMTPAsyncSuccess;
    } 
    else if(theReturn == MAILSMTP_ERROR_STREAM && [mMailThread isCancelled]) {
      mStatus = MKSMTPAsyncCanceled;
    }
    else {
      mStatus = MKSMTPAsyncError;
    }     
	}
  @catch(NSException* aException) {
    mStatus = MKSMTPAsyncError;
  }              
  
  [thePool drain];  
}

- (void) handleSmtpProgress:(NSNumber*) aProgress
{
  if([mMailThread isCancelled] && [NSThread currentThread] == mMailThread) {
    return;
  }

  unsigned int theProgress = [aProgress unsignedIntValue];
  if(theProgress > mLastProgress)
  {
    mLastProgress = theProgress;
    if(mDelegate) {
      [mDelegate smtpProgress:mLastProgress];
    }  
  }       
}

- (void) threadWillExitHandler:(NSNotification*) aNote
{
	if([aNote object] != mMailThread) {
    return;
  }
  if(mDelegate) {
    [mDelegate smtpDidFinishSendingMessage:mStatus];
  } 

  [self cleanupAfterThread];
}

- (void) cleanupAfterThread
{
  [mSMTPObj release];
  mSMTPObj = nil;

  if(mSMTP)
  {
    mailstream_cancel(mSMTP->stream);
    mailstream_close(mSMTP->stream);
    mSMTP->stream = NULL;
    mailsmtp_free(mSMTP);
    mSMTP = NULL; 
  }

  [mServerSettings release];
  mServerSettings = nil;

  [mMessage release];
  mMessage = nil;

  [mMailThread release];
  mMailThread = nil;    
}
@end