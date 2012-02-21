//
//  MKSMTPAsyncConnection.h
//  MailKit
//
//  Created by Juan Leon on 5/6/10.
//  Copyright 2010 NotOptimal.net. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libetpan/libetpan.h>
#import "MailKitTypes.h"

@protocol MKSMTPConnectionDelegate

- (void) smtpProgress:(unsigned int) aProgress;

- (void) smtpDidFinishSendingMessage:(MKSMTPAsyncStatus) aStatus;
@end

@class MKCoreMessage;
@class MKCoreAddress;
@class MKSMTP;

@interface MKSMTPAsyncConnection : NSObject 
{
  MKSMTP* mSMTPObj;
  mailsmtp* mSMTP;
  MKCoreMessage* mMessage;
  NSDictionary* mServerSettings;
  NSThread* mMailThread;
  id <MKSMTPConnectionDelegate> mDelegate;
  unsigned int mLastProgress;
  MKSMTPAsyncStatus mStatus;      
}

@property (readonly) NSDictionary* serverSettings;
@property (retain) MKCoreMessage* message;
@property (readonly) MKSMTPAsyncStatus status;

- (id) initWithServer:(NSString *) aServer 
  username:(NSString *) aUsername
  password:(NSString *) aPassword 
  port:(unsigned int) aPort 
  useTLS:(BOOL) aTls 
  useAuth:(BOOL) aAuth
  delegate:(id<MKSMTPConnectionDelegate>) aDelegate;
                                                     

- (void) sendMessageInBackgroundAndNotify:(MKCoreMessage*) aMessage;
- (void) cancel;
- (BOOL) isBusy;
         
@end