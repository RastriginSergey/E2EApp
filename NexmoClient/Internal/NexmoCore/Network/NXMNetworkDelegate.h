//
//  NXMNetworkDelegate.h
//  NexmoConversationObjC
//
//  Created by Chen Lev on 5/23/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMCoreEvents.h"
#import "NXMSipEvent.h"
#import "NXMRtcAnswerEvent.h"
#import "NXMErrors.h"

@protocol NXMNetworkDelegate

- (nullable NSString *)authToken;

- (void)connectionStatusChanged:(NXMConnectionStatus)status reason:(NXMConnectionStatusReason)reason;
- (void)userUpdated:(nullable NXMUser *)user;

- (void)sipRinging:(nonnull NXMSipEvent *)sipEvent;
- (void)sipAnswered:(nonnull NXMSipEvent *)sipEvent;
- (void)sipHangup:(nonnull NXMSipEvent *)sipEvent;
- (void)sipStatus:(nonnull NXMSipEvent *)sipEvent;

- (void)memberJoined:(nonnull NXMMemberEvent *)memberEvent;
- (void)memberRemoved:(nonnull NXMMemberEvent *)memberEvent;
- (void)memberInvited:(nonnull NXMMemberEvent *)memberEvent;

- (void)customEvent:(nonnull NXMCustomEvent *)customEvent;

- (void)textRecieved:(nonnull NXMTextEvent *)textEvent;
- (void)textDelivered:(nonnull NXMMessageStatusEvent *)statusEvent;
- (void)textSeen:(nonnull NXMMessageStatusEvent *)statusEvent;

- (void)textTypingOn:(nonnull NXMTextTypingEvent *)textTypingEvent;
- (void)textTypingOff:(nonnull NXMTextTypingEvent *)textTypingEvent;

- (void)imageRecieved:(nonnull NXMImageEvent *)textEvent;
- (void)imageDelivered:(nonnull NXMMessageStatusEvent *)statusEvent;
- (void)imageSeen:(nonnull NXMMessageStatusEvent *)statusEvent;

- (void)messageDeleted:(nonnull NXMMessageStatusEvent *)messageEvent;

- (void)mediaEvent:(nonnull NXMMediaEvent *)mediaEvent;

- (void)rtcAnswerEvent:(nonnull NXMRtcAnswerEvent *)rtcEvent;
- (void)DTMFEvent:(nonnull NXMDTMFEvent *)dtmfEvent;
- (void)legStatus:(nonnull NXMLegStatusEvent *)legEvent;

- (void)onError:(NXMErrorCode)errorCode;

@end
