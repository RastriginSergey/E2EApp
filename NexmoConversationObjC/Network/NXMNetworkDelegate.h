//
//  NXMNetworkDelegate.h
//  NexmoConversationObjC
//
//  Created by Chen Lev on 5/23/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMMemberEvent.h"
#import "NXMTextEvent.h"
#import "NXMTextStatusEvent.h"
#import "NXMTextTypingEvent.h"
#import "NXMMediaEvent.h"
#import "NXMMediaAnswerEvent.h"
#import "NXMImageEvent.h"

@protocol NXMNetworkDelegate

- (void)connectionStatusChanged:(BOOL)isOpen;
- (void)userStatusChanged:(nullable NXMUser *)user sessionId:(nullable NSString*)sessionId;

- (void)memberJoined:(nonnull NXMMemberEvent *)memberEvent;
- (void)memberRemoved:(nonnull NXMMemberEvent *)memberEvent;
- (void)memberInvited:(nonnull NXMMemberEvent *)memberEvent;

- (void)textRecieved:(nonnull NXMTextEvent *)textEvent;
- (void)textDeleted:(nonnull NXMTextStatusEvent *)textEvent;
- (void)textDelivered:(nonnull NXMTextStatusEvent *)textEvent;
- (void)textSeen:(nonnull NXMTextStatusEvent *)textEvent;

- (void)textTypingOn:(nonnull NXMTextTypingEvent *)textEvent;
- (void)textTypingOff:(nonnull NXMTextTypingEvent *)textEvent;

- (void)imageRecieved:(nonnull NXMImageEvent *)textEvent;

- (void)mediaEvent:(nonnull NXMMediaEvent *)mediaEvent;
- (void)mediaAnswerEvent:(nonnull NXMMediaAnswerEvent *)mediaEvent;


@end
