//
//  NXMNetworkManager.m
//  NexmoConversationObjC
//
//  Created by Chen Lev on 4/24/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMNetworkManager.h"
#import "NXMNetworkDelegate.h"
#import "NXMRouter.h"
#import "NXMSocketClient.h"

@interface NXMNetworkManager()
@property NXMSocketClient *socketClient;
@property NXMRouter *router;
@property (nonatomic) id<NXMNetworkDelegate> delegate;

@property SuccessCallbackWithObject loginSuccessCallback;
@property ErrorCallback loginErrorCallback;

@end

@implementation NXMNetworkManager

- (nullable instancetype)initWitHost:(nonnull NSString *)httpHost andWsHost:(nonnull NSString *)wsHost {
    if (self = [super init]) {
        
    }
    
    self.socketClient = [[NXMSocketClient alloc] initWitHost:wsHost];
    [self.socketClient setDelegate:(id<NXMSocketClientDelegate>)self];
    
    self.router = [[NXMRouter alloc] initWitHost:httpHost];
    
    return self;
}

- (void)setDelegate:(id<NXMNetworkDelegate>)delegate {
    _delegate = delegate;
}

- (void)loginWithToken:(NSString * _Nonnull)token
             onSuccess:(SuccessCallbackWithObject _Nullable)onSuccess
               onError:(ErrorCallback _Nullable)onError {
    self.loginSuccessCallback = onSuccess;
    self.loginErrorCallback = onError;
    
    [self.socketClient loginWithToken:token];
    [self.router setToken:token];
}

- (void)logout {
    [self.socketClient logout];
}

- (void)createConversation:(nonnull NXMCreateConversationRequest*)createConversationRequest
                 onSuccess:(SuccessCallbackWithId _Nullable)onSuccess
                   onError:(ErrorCallback _Nullable)onError {
    [self.router createConversation:createConversationRequest onSuccess:onSuccess onError:onError];
}

- (void)addUserToConversation:(nonnull NXMAddUserRequest*)addUserRequest
                    onSuccess:(SuccessCallbackWithId _Nullable)onSuccess
                      onError:(ErrorCallback _Nullable)onError {
    [self.router addUserToConversation:addUserRequest onSuccess:onSuccess onError:onError];
}

- (void)inviteUserToConversation:(nonnull NXMInviteUserRequest *)inviteUserRequest
                       onSuccess:(SuccessCallbackWithId _Nullable)onSuccess
                         onError:(ErrorCallback _Nullable)onError {
    [self.router inviteUserToConversation:inviteUserRequest onSuccess:onSuccess onError:onError];
}

- (void)joinMemberToConversation:(nonnull NXMJoinMemberRequest *)joinMemberRequest
                       onSuccess:(SuccessCallbackWithId _Nullable)onSuccess
                         onError:(ErrorCallback _Nullable)onError {
   [self.router joinMemberToConversation:joinMemberRequest onSuccess:onSuccess onError:onError];
}

- (void)removeMemberFromConversation:(nonnull NXMRemoveMemberRequest *)removeMemberRequest
                           onSuccess:(SuccessCallbackWithId _Nullable)onSuccess
                             onError:(ErrorCallback _Nullable)onError {
    [self.router removeMemberFromConversation:removeMemberRequest onSuccess:onSuccess onError:onError];
}

- (void)sendTextToConversation:(nonnull NXMSendTextEventRequest*)sendTextEventRequest
                     onSuccess:(SuccessCallbackWithId _Nullable)onSuccess
                       onError:(ErrorCallback _Nullable)onError {
    [self.router sendTextToConversation:sendTextEventRequest onSuccess:onSuccess onError:onError];
}

- (void)sendImage:(nonnull NXMSendImageRequest *)sendImageRequest
        onSuccess:(SuccessCallbackWithId _Nullable)onSuccess
          onError:(ErrorCallback _Nullable)onError {
    [self.router sendImage:sendImageRequest onSuccess:onSuccess onError:onError];
}

- (void)deleteTextFromConversation:(nonnull NXMDeleteEventRequest*)deleteEventRequest
                         onSuccess:(SuccessCallback _Nullable)onSuccess
                           onError:(ErrorCallback _Nullable)onError {
    [self.router deleteTextFromConversation:deleteEventRequest onSuccess:onSuccess onError:onError];
}

- (void)seenTextEvent:(nonnull NSString *)conversationId
             memberId:(nonnull NSString *)memberId
              eventId:(nonnull NSString *)eventId {
    [self.socketClient seenTextEvent:conversationId memberId:memberId eventId:eventId];
}

- (void)deliverTextEvent:(nonnull NSString *)conversationId
                memberId:(nonnull NSString *)memberId
                 eventId:(nonnull NSString *)eventId {
    [self.socketClient deliverTextEvent:conversationId memberId:memberId eventId:eventId];
}

- (void)textTypingOn:(nonnull NSString *)conversationId
            memberId:(nonnull NSString *)memberId {
    [self.socketClient textTypingOn:conversationId memberId:memberId];
}

- (void)textTypingOff:(nonnull NSString *)conversationId
             memberId:(nonnull NSString *)memberId {
    [self.socketClient textTypingOff:conversationId memberId:memberId];
}

- (void)getConversations:(nonnull NXMGetConversationsRequest*)getConvetsationsRequest
               onSuccess:(SuccessCallbackWithConversations _Nullable)onSuccess
                 onError:(ErrorCallback _Nullable)onError {
    [self.router getConversations:getConvetsationsRequest onSuccess:onSuccess onError:onError];
}

- (void)getConversationDetails:(nonnull NSString*)conversationId
                     onSuccess:(SuccessCallbackWithConversationDetails _Nullable)onSuccess
                       onError:(ErrorCallback _Nullable)onError {
    [self.router getConversationDetails:conversationId onSuccess:onSuccess onError:onError];
}

- (void)enableMedia:(NSString *)conversationId memberId:(NSString *)memberId sdp:(NSString *)sdp mediaType:(NSString *)mediaType // TODO: enum
          onSuccess:(SuccessCallbackWithId _Nullable)onSuccess
            onError:(ErrorCallback _Nullable)onError {
    [self.router enableMedia:conversationId memberId:memberId sdp:sdp mediaType:mediaType onSuccess:onSuccess onError:onError];
}

- (void)disableMedia:(NSString *)conversationId rtcId:(NSString *)rtcId // TODO: memberId
           onSuccess:(SuccessCallback _Nullable)onSuccess
             onError:(ErrorCallback _Nullable)onError {
    [self.router disableMedia:conversationId rtcId:rtcId onSuccess:onSuccess onError:onError];
}

# pragma mark - NXMSocketClientDelegate

- (void)memberJoined:(nonnull NXMMemberEvent *)memberEvent {
    [self.delegate memberJoined:memberEvent];
}

- (void)memberRemoved:(nonnull NXMMemberEvent *)memberEvent {
    [self.delegate memberRemoved:memberEvent];
}

- (void)memberInvited:(nonnull NXMMemberEvent *)memberEvent {
    [self.delegate memberInvited:memberEvent];
}



- (void)textRecieved:(nonnull NXMTextEvent *)textEvent{
    [self.delegate textRecieved:textEvent];
}

- (void)textDeleted:(nonnull NXMTextStatusEvent *)textEvent{
    [self.delegate textDeleted:textEvent];
}

- (void)messageReceived:(nonnull NXMTextEvent *)message{
    [self.delegate messageReceived:message];
}

- (void)messageSent:(nonnull NXMTextEvent *)message{
    [self.delegate messageSent:message];
}

- (void)textTypingOn:(nonnull NXMTextTypingEvent *)textEvent{
    [self.delegate textTypingOn:textEvent];
}

- (void)textTypingOff:(nonnull NXMTextTypingEvent *)textEvent{
    [self.delegate textTypingOff:textEvent];
}

- (void)textDelivered:(nonnull NXMTextStatusEvent *)textEvent{
    [self.delegate textDelivered:textEvent];
}

- (void)textSeen:(nonnull NXMTextStatusEvent *)textEvent{
    [self.delegate textSeen:textEvent];
}

- (void)connectionStatusChanged:(BOOL)isOpen {
    [self.delegate connectionStatusChanged:isOpen];
}

- (void)userStatusChanged:(nullable NXMUser *)user sessionId:(nullable NSString*)sessionId {
    [self.router setSessionId:sessionId];
    
    [self.delegate userStatusChanged:user sessionId:sessionId];
    
    self.loginSuccessCallback(user);
}

- (void)mediaEvent:(nonnull NXMMediaEvent *)mediaEvent{
    [self.delegate mediaEvent:mediaEvent];
}
- (void)mediaAnswerEvent:(nonnull NXMMediaAnswerEvent *)mediaEvent {
    [self.delegate mediaAnswerEvent:mediaEvent];
}

@end
