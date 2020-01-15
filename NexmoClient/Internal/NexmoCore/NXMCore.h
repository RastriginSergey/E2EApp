//
//  NXMCore.h
//  NexmoCore
//
//  Copyright © 2018 Vonage. All rights reserved.
//


#import <Foundation/Foundation.h>

#import "NXMCoreDelegate.h"
#import "NXMUser.h"
#import "NXMNetworkCallbacks.h"
#import "NXMBlocks.h"
#import "NXMErrors.h"
#import "NXMSipEvent.h"
#import "NXMRtcAnswerEvent.h"
#import "NXMConversationsPage.h"
#import "NXMConversationIdsPage.h"
#import "NXMClientConfig.h"
#import "NXMPagePrivate.h"

#import "NXMGetConversationsRequest.h" // remove


@interface NXMCore : NSObject <NXMPageProxy>

@property (readonly) NXMConnectionStatus connectionStatus;
@property (nonatomic, strong, readonly, nullable) NXMUser *user;
@property (nonatomic, strong, readwrite, nullable) NSString *token;

- (nullable instancetype)initWithToken:(nonnull NSString *)authToken
                         configuration:(nonnull NXMClientConfig *)configuration;

- (void)login;

- (void)refreshAuthToken:(nonnull NSString *)authToken;

- (void)logout;

- (void)setDelgate:(nonnull id<NXMCoreDelegate>)delegate;

#pragma mark - Push Notifications

- (void)enablePushNotificationsWithPushKitToken:(nullable NSData *)pushKitToken
                          userNotificationToken:(nullable NSData *)userNotificationToken
                                      isSandbox:(BOOL)isSandbox
                                      onSuccess:(NXMSuccessCallback _Nullable)onSuccess
                                        onError:(NXMErrorCallback _Nullable)onError;

- (void)disablePushNotificationsWithOnSuccess:(NXMSuccessCallback _Nullable)onSuccess
                        onError:(NXMErrorCallback _Nullable)onError;

- (BOOL)isNexmoPushWithUserInfo:(nonnull NSDictionary *)userInfo;

- (void)processNexmoPushWithUserInfo:(nonnull NSDictionary *)userInfo onSuccess:(NXMSuccessCallbackWithEvent _Nullable)onSuccess onError:(NXMErrorCallback _Nullable)onError;

#pragma mark - Conversation Methods

- (void)createConversationWithName:(nonnull NSString *)name
             onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
               onError:(NXMErrorCallback _Nullable)onError;

- (nonnull NSString *)joinToConversation:(nonnull NSString *)conversationId
                            withUsername:(nonnull NSString *)username
                               onSuccess:(NXMSuccessCallbackWithObject _Nullable)onSuccess
                                 onError:(NXMErrorCallback _Nullable)onError;

- (nonnull NSString *)joinToConversation:(nonnull NSString *)conversationId
                            withMemberId:(nonnull NSString *)memberId
                               onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                                 onError:(NXMErrorCallback _Nullable)onError;

- (void)inviteToConversation:(nonnull NSString *)conversationId
    withUsername:(nonnull NSString *)userId
     onSuccess:(NXMSuccessCallbackWithObject _Nullable)onSuccess
       onError:(NXMErrorCallback _Nullable)onError;

- (void)inviteToConversation:(nonnull NSString *)conversationId
                  withUsername:(nonnull NSString *)userId
                  withMedia:(BOOL)mediaEnabled
                   onSuccess:(NXMSuccessCallbackWithObject _Nullable)onSuccess
                     onError:(NXMErrorCallback _Nullable)onError;

- (void)inviteToConversation:(nonnull NSString *)conversationId
    withUserId:(nonnull NSString *)userId
withPhoneNumber:(nonnull NSString *)phoneNumber
     onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
       onError:(NXMErrorCallback _Nullable)onError;

- (nonnull NSString *)inviteToConversation:(nonnull NSString *)userName
withPhoneNumber:(nonnull NSString *)phoneNumber
     onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
       onError:(NXMErrorCallback _Nullable)onError;

- (void)deleteMember:(nonnull NSString *)memberId
fromConversationWithId:(nonnull NSString *)conversationId
           onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
             onError:(NXMErrorCallback _Nullable)onError;

- (void)getLatestEventInConversation:(nonnull NSString *)conversationId
                      onSuccess:(NXMSuccessCallbackWithEvent _Nullable)onSuccess
                        onError:(NXMErrorCallback _Nullable)onError;

- (void)getEventsInConversation:(nonnull NSString *)conversationId
        onSuccess:(NXMSuccessCallbackWithEvents _Nullable)onSuccess
          onError:(NXMErrorCallback _Nullable)onError;

- (void)getEventsInConversation:(nonnull NSString *)conversationId
          startId:(nullable NSNumber *)startId
            endId:(nullable NSNumber *)endId
        onSuccess:(NXMSuccessCallbackWithEvents _Nullable)onSuccess
          onError:(NXMErrorCallback _Nullable)onError;

- (void)getEventsPageWithSize:(NSInteger)size
                        order:(NXMPageOrder)order
               conversationId:(nonnull NSString *)conversationId
                    eventType:(nullable NSString *)eventType
            completionHandler:(void(^_Nullable)(NSError * _Nullable error, NXMEventsPage * _Nullable page))completionHandler;

- (void)getConversationDetails:(nonnull NSString *)conversationId
                     onSuccess:(NXMSuccessCallbackWithConversationDetails _Nullable)onSuccess
                       onError:(NXMErrorCallback _Nullable)onError;

- (void)getConversationsForUser:(nonnull NSString *)userId
                   onSuccess:(NXMSuccessCallbackWithConversations _Nullable)onSuccess
                     onError:(NXMErrorCallback _Nullable)onError;

- (void)getConversationIdsPageWithSize:(NSUInteger)size
                                cursor:(nullable NSString *)cursor
                                userId:(nonnull NSString *)userId
                                 order:(NXMPageOrder)order
                             onSuccess:(void(^ _Nullable)(NXMConversationIdsPage * _Nullable page))onSuccess
                               onError:(void(^ _Nullable)(NSError * _Nullable error))onError;

- (void)getConversationIdsPageForURL:(nonnull NSURL *)url
                           onSuccess:(void (^ _Nullable)(NXMConversationIdsPage * _Nullable page))onSuccess
                             onError:(void (^ _Nullable)(NSError * _Nullable error))onError;

#pragma mark - Custom events Methods

- (void)sendCustomEvent:(nonnull NSString *)eventType
                   body:(nonnull NSDictionary *)body
         conversationId:(nonnull NSString *)conversationId
           fromMemberId:(nonnull NSString *)fromMemberId
              onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                onError:(NXMErrorCallback _Nullable)onError;

#pragma mark - Messages Methods

- (void)sendDTMF:(nonnull NSString *)digit
  conversationId:(nonnull NSString *)conversationId
    fromMemberId:(nonnull NSString *)fromMemberId
       onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
         onError:(NXMErrorCallback _Nullable)onError;

- (void)sendText:(nonnull NSString *)text
  conversationId:(nonnull NSString *)conversationId
    fromMemberId:(nonnull NSString *)fromMemberId
       onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
         onError:(NXMErrorCallback _Nullable)onError;

- (void)sendImageWithName:(nonnull NSString *)imageName
            image:(nonnull NSData *)image
   conversationId:(nonnull NSString *)conversationId
     fromMemberId:(nonnull NSString *)fromMemberId
        onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
          onError:(NXMErrorCallback _Nullable)onError;

- (void)deleteEvent:(NSInteger)eventId
     conversationId:(nonnull NSString *)conversationId
       fromMemberId:(nonnull NSString *)memberId
          onSuccess:(NXMSuccessCallback _Nullable)onSuccess
            onError:(NXMErrorCallback _Nullable)onError;

- (void)markAsSeen:(NSInteger)messageId
    conversationId:(nonnull NSString *)conversationId
  fromMemberWithId:(nonnull NSString *)memberId
         onSuccess:(NXMSuccessCallback _Nullable)onSuccess
           onError:(NXMErrorCallback _Nullable)onError;

- (void)markAsDelivered:(NSInteger)messageId
         conversationId:(nonnull NSString *)conversationId
       fromMemberWithId:(nonnull NSString *)memberId
              onSuccess:(NXMSuccessCallback _Nullable)onSuccess
                onError:(NXMErrorCallback _Nullable)onError;

- (void)startTypingWithConversationId:(nonnull NSString *)conversationId
           memberId:(nonnull NSString *)memberId;

- (void)stopTypingWithConversationId:(nonnull NSString *)conversationId
          memberId:(nonnull NSString *)memberId;

#pragma mark - Media Methods

- (NXMErrorCode)enableMedia:(nonnull NSString *)conversationId
                         memberId:(nonnull NSString *)memberId;

- (NXMErrorCode)disableMedia:(nonnull NSString *)conversationId;

- (NXMErrorCode)suspendMyMedia:(NXMMediaType)mediaType
                    inConversation:(nonnull NSString *)conversationId;

//TODO: add callback functionality?
//                         onSuccess:(SuccessCallback _Nullable)onSuccess
//                           onError:(ErrorCallback _Nullable)onError;
//TODO: not have a return error and a callback.
- (NXMErrorCode)resumeMyMedia:(NXMMediaType)mediaType
                   inConversation:(nonnull NSString *)conversationId;
//TODO: add callback functionality?
//                         onSuccess:(SuccessCallback _Nullable)onSuccess
//                           onError:(ErrorCallback _Nullable)onError;

//
//- (NXMErrorCode)sendDTMFWithDigits:(nonnull NSString*)digits
//                       andConversationId:(nonnull NSString*)conversationId
//                             andMemberId:(nonnull NSString*)memberId
//                             andDuration:(int) duration
//                                  andGap:(int) gap;

//TODO: integrate properly with miniRTC - today this only works with CS
- (void)suspendMedia:(NXMMediaType)mediaType
            ofMember:(nonnull NSString *)memberId
      inConversation:(nonnull NSString *)conversationId
          fromMember:(nonnull NSString *)fromMemberId
           onSuccess:(NXMSuccessCallback _Nullable)onSuccess
             onError:(NXMErrorCallback _Nullable)onError;

- (void)resumeMedia:(NXMMediaType)mediaType
           ofMember:(nonnull NSString *)memberId
     inConversation:(nonnull NSString *)conversationId
         fromMember:(nonnull NSString *)fromMemberId
          onSuccess:(NXMSuccessCallback _Nullable)onSuccess
            onError:(NXMErrorCallback _Nullable)onError;


@end
