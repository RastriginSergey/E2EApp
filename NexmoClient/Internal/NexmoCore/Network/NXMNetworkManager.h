//
//  NXMNetworkManager.h
//  NexmoConversationObjC
//
//  Created by Chen Lev on 4/24/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NXMNetworkCallbacks.h"
#import "NXMNetworkDelegate.h"
#import "NXMSocketClientDelegate.h"


#import "NXMAddUserRequest.h"
#import "NXMInviteUserRequest.h"
#import "NXMInvitePstnRequest.h"
#import "NXMInvitePstnKnockingRequest.h"
#import "NXMJoinMemberRequest.h"
#import "NXMRemoveMemberRequest.h"
#import "NXMSendTextEventRequest.h"
#import "NXMDeleteEventRequest.h"
#import "NXMGetConversationsRequest.h"
#import "NXMCreateConversationRequest.h"
#import "NXMSendImageRequest.h"
#import "NXMGetEventsRequest.h"
#import "NXMGetEventsPageRequest.h"
#import "NXMEnablePushRequest.h"
#import "NXMSuspendResumeMediaRequest.h"
#import "NXMSendCustomEventRequest.h"
#import "NXMSendDTMFRequest.h"
#import "NXMConversationsPage.h"
#import "NXMConversationIdsPage.h"
#import "NXMPagePrivate.h"
#import "NXMClientConfig.h"


@interface NXMNetworkManager : NSObject <NXMSocketClientDelegate>

- (nullable instancetype)initWithConfiguration:(nonnull NXMClientConfig *)configuration;

- (NXMConnectionStatus)connectionStatus;

- (void)setDelegate:(nonnull id<NXMNetworkDelegate>)delegate;

- (void)login;

- (void)refreshAuthToken;

- (void)logout;

- (void)enablePushNotifications:(nonnull NXMEnablePushRequest *)request
                      onSuccess:(NXMSuccessCallback _Nullable)onSuccess
                        onError:(NXMErrorCallback _Nullable)onError;

- (void)disablePushNotificationsWithOnSuccess:(NXMSuccessCallback _Nullable)onSuccess
                        onError:(NXMErrorCallback _Nullable)onError;

- (void)createConversation:(nonnull NXMCreateConversationRequest*)createConversationRequest
                 onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                   onError:(NXMErrorCallback _Nullable)onError;

- (nonnull NSString *)joinUserToConversation:(nonnull NXMAddUserRequest*)addUserRequest
                                   onSuccess:(NXMSuccessCallbackWithObject _Nullable)onSuccess
                                     onError:(NXMErrorCallback _Nullable)onError;

- (void)inviteUserToConversation:(nonnull NXMInviteUserRequest *)inviteUserRequest
                       onSuccess:(NXMSuccessCallbackWithObject _Nullable)onSuccess
                         onError:(NXMErrorCallback _Nullable)onError;

- (void)invitePstnToConversation:(nonnull NXMInvitePstnRequest *)invitePstnRequest
                       onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                         onError:(NXMErrorCallback _Nullable)onError;

- (nonnull NSString *)invitePstnKnockingToConversation:(nonnull NXMInvitePstnKnockingRequest *)invitePstnRequest
                                             onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                                               onError:(NXMErrorCallback _Nullable)onError;

- (nonnull NSString *)joinMemberToConversation:(nonnull NXMJoinMemberRequest *)joinMembetRequest
                                     onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                                       onError:(NXMErrorCallback _Nullable)onError;

- (void)removeMemberFromConversation:(nonnull NXMRemoveMemberRequest *)removeMemberRequest
                           onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                             onError:(NXMErrorCallback _Nullable)onError;

- (void)sendCustomEvent:(nonnull NXMSendCustomEventRequest *)sendCustomEventRequest
              onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                onError:(NXMErrorCallback _Nullable)onError;

- (void)sendDTMFToConversation:(nonnull NXMSendDTMFRequest*)sendDTMFRequest
                     onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                       onError:(NXMErrorCallback _Nullable)onError;

- (void)sendTextToConversation:(nonnull NXMSendTextEventRequest*)sendTextEventRequest
                     onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                       onError:(NXMErrorCallback _Nullable)onError;

- (void)sendImage:(nonnull NXMSendImageRequest *)sendImageRequest
        onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
          onError:(NXMErrorCallback _Nullable)onError;

- (void)deleteEventFromConversation:(nonnull NXMDeleteEventRequest*)deleteEventRequest
                         onSuccess:(NXMSuccessCallback _Nullable)onSuccess
                           onError:(NXMErrorCallback _Nullable)onError;

- (void)seenTextEvent:(nonnull NSString *)conversationId
             memberId:(nonnull NSString *)memberId
              eventId:(NSInteger)eventId;


- (void)deliverTextEvent:(nonnull NSString *)conversationId
                memberId:(nonnull NSString *)memberId
                 eventId:(NSInteger)eventId;

- (void)textTypingOn:(nonnull NSString *)conversationId
            memberId:(nonnull NSString *)memberId;

- (void)textTypingOff:(nonnull NSString *)conversationId
             memberId:(nonnull NSString *)memberId;

- (void)getConversationIdsPageWithSize:(NSUInteger)size
                                cursor:(nullable NSString *)cursor
                                userId:(nonnull NSString *)userId
                                 order:(NXMPageOrder)order
                             onSuccess:(void(^ _Nullable)(NXMConversationIdsPage * _Nullable page))onSuccess
                               onError:(void(^ _Nullable)(NSError * _Nullable error))onError;

- (void)getConversationIdsPageForURL:(nonnull NSURL *)url
                           onSuccess:(void (^ _Nullable)(NXMConversationIdsPage * _Nullable page))onSuccess
                             onError:(void (^ _Nullable)(NSError * _Nullable error))onError;

- (void)getLatestEvent:(nonnull NXMGetEventsRequest *)getEventsRequest
        onSuccess:(NXMSuccessCallbackWithEvent _Nullable)onSuccess
          onError:(NXMErrorCallback _Nullable)onError;

- (void)getEvents:(nonnull NXMGetEventsRequest *)getEventsRequest
        onSuccess:(NXMSuccessCallbackWithEvents _Nullable)onSuccess
          onError:(NXMErrorCallback _Nullable)onError;

- (void)getEventsPageWithRequest:(nonnull NXMGetEventsPageRequest *)request
               eventsPagingProxy:(nonnull id<NXMPageProxy>)pagingProxy
                       onSuccess:(void(^ _Nullable)(NXMEventsPage * _Nullable page))onSuccess
                         onError:(void(^ _Nullable)(NSError * _Nullable error))onError;

- (void)getEventsPageForURL:(nonnull NSURL *)url
          eventsPagingProxy:(nonnull id<NXMPageProxy>)proxy
                  onSuccess:(void (^ _Nullable)(NXMEventsPage * _Nullable page))onSuccess
                    onError:(void (^ _Nullable)(NSError * _Nullable error))onError;
        
- (void)getConversationDetails:(nonnull NSString*)conversationId
                     onSuccess:(NXMSuccessCallbackWithConversationDetails _Nullable)onSuccess
                       onError:(NXMErrorCallback _Nullable)onError;

- (void)getConversationsForUser:(nonnull NSString *)userId
                   onSuccess:(NXMSuccessCallbackWithConversations _Nullable)onSuccess
                     onError:(NXMErrorCallback _Nullable)onError;

- (void)enableMedia:(nonnull NSString *)conversationId
           memberId:(nonnull NSString *)memberId
                sdp:(nonnull NSString *)sdp
          mediaType:(nonnull NSString *)mediaType // TODO: enum
          onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
            onError:(NXMErrorCallback _Nullable)onError;

- (void)disableMedia:(nonnull NSString *)conversationId
               rtcId:(nonnull NSString *)rtcId
            memberId:(nonnull NSString *)memberId
           onSuccess:(NXMSuccessCallback _Nullable)onSuccess
             onError:(NXMErrorCallback _Nullable)onError;

- (void)suspendMediaWithMediaRequest:(nonnull NXMSuspendResumeMediaRequest *)mediaRequest
                 onSuccess:(NXMSuccessCallback _Nullable)onSuccess
                   onError:(NXMErrorCallback _Nullable)onError;

- (void)resumeMediaWithMediaRequest:(nonnull NXMSuspendResumeMediaRequest *)mediaRequest
                onSuccess:(NXMSuccessCallback _Nullable)onSuccess
                  onError:(NXMErrorCallback _Nullable)onError;

@end
