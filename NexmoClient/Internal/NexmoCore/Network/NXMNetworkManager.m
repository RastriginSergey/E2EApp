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
#import "NXMErrorsPrivate.h"
#import "NXMLogger.h"

@interface NXMNetworkManager()
@property NXMSocketClient *socketClient;
@property NXMRouter *router;
@property (nonatomic) id<NXMNetworkDelegate> delegate;

@property NXMSuccessCallbackWithObject loginSuccessCallback;
@property NXMErrorCallback loginErrorCallback;

@end

@implementation NXMNetworkManager

- (nullable instancetype)initWithHost:(nonnull NSString *)httpHost andWsHost:(nonnull NSString *)wsHost {
    if (self = [super init]) {
        
    }
    
    self.socketClient = [[NXMSocketClient alloc] initWithHost:wsHost];
    [self.socketClient setDelegate:(id<NXMSocketClientDelegate>)self];
    self.router = [[NXMRouter alloc] initWithHost:httpHost];
    
    return self;
}

- (NXMConnectionStatus)connectionStatus {
    return self.socketClient.connectionStatus;
}

- (void)setDelegate:(id<NXMNetworkDelegate>)delegate {
    _delegate = delegate;
}

- (void)login {
    [self.socketClient loginWithToken:self.delegate.authToken];
    [self.router setToken:self.delegate.authToken];
}

- (void)refreshAuthToken {
    [self.socketClient refreshAuthToken:self.delegate.authToken];
    [self.router setToken:self.delegate.authToken];
}

- (void)logout {
    [self.socketClient logout];
}

- (void)enablePushNotifications:(nonnull NXMEnablePushRequest *)request
                      onSuccess:(NXMSuccessCallback _Nullable)onSuccess
                        onError:(NXMErrorCallback _Nullable)onError {
    [self.router enablePushNotifications:request onSuccess:onSuccess onError:onError];
}

- (void)disablePushNotificationsWithOnSuccess:(NXMSuccessCallback _Nullable)onSuccess
                                      onError:(NXMErrorCallback _Nullable)onError {
    [self.router disablePushNotificationsWithOnSuccess:onSuccess onError:onError];
}

- (void)createConversation:(nonnull NXMCreateConversationRequest*)createConversationRequest
                 onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                   onError:(NXMErrorCallback _Nullable)onError {
    [self.router createConversation:createConversationRequest onSuccess:onSuccess onError:onError];
}

- (void)addUserToConversation:(nonnull NXMAddUserRequest*)addUserRequest
                    onSuccess:(NXMSuccessCallbackWithObject _Nullable)onSuccess
                      onError:(NXMErrorCallback _Nullable)onError {
    [self.router addUserToConversation:addUserRequest onSuccess:onSuccess onError:onError];
}

- (void)inviteUserToConversation:(nonnull NXMInviteUserRequest *)inviteUserRequest
                       onSuccess:(NXMSuccessCallbackWithObject _Nullable)onSuccess
                         onError:(NXMErrorCallback _Nullable)onError {
    [self.router inviteUserToConversation:inviteUserRequest onSuccess:onSuccess onError:onError];
}

- (void)invitePstnToConversation:(nonnull NXMInvitePstnRequest *)invitePstnRequest
                       onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                         onError:(NXMErrorCallback _Nullable)onError{
    [self.router invitePstnToConversation:invitePstnRequest onSuccess:onSuccess onError:onError];
}


- (void)invitePstnKnockingToConversation:(nonnull NXMInvitePstnKnockingRequest *)invitePstnRequest
                               onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                                 onError:(NXMErrorCallback _Nullable)onError{
    [self.router invitePstnKnockingToConversation:invitePstnRequest onSuccess:onSuccess onError:onError];
}

- (void)joinMemberToConversation:(nonnull NXMJoinMemberRequest *)joinMemberRequest
                       onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                         onError:(NXMErrorCallback _Nullable)onError {
   [self.router joinMemberToConversation:joinMemberRequest onSuccess:onSuccess onError:onError];
}

- (void)removeMemberFromConversation:(nonnull NXMRemoveMemberRequest *)removeMemberRequest
                           onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                             onError:(NXMErrorCallback _Nullable)onError {
    [self.router removeMemberFromConversation:removeMemberRequest onSuccess:onSuccess onError:onError];
}

- (void)sendTextToConversation:(nonnull NXMSendTextEventRequest*)sendTextEventRequest
                     onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                       onError:(NXMErrorCallback _Nullable)onError {
    [self.router sendTextToConversation:sendTextEventRequest onSuccess:onSuccess onError:onError];
}

- (void)sendImage:(nonnull NXMSendImageRequest *)sendImageRequest
        onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
          onError:(NXMErrorCallback _Nullable)onError {
    [self.router sendImage:sendImageRequest onSuccess:onSuccess onError:onError];
}

- (void)deleteEventFromConversation:(nonnull NXMDeleteEventRequest*)deleteEventRequest
                         onSuccess:(NXMSuccessCallback _Nullable)onSuccess
                           onError:(NXMErrorCallback _Nullable)onError {
    [self.router deleteEventFromConversation:deleteEventRequest onSuccess:onSuccess onError:onError];
}

- (void)seenTextEvent:(nonnull NSString *)conversationId
             memberId:(nonnull NSString *)memberId
              eventId:(NSInteger)eventId {
    [self.socketClient seenTextEvent:conversationId memberId:memberId eventId:eventId];
}

- (void)deliverTextEvent:(nonnull NSString *)conversationId
                memberId:(nonnull NSString *)memberId
                 eventId:(NSInteger)eventId {
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
               onSuccess:(NXMSuccessCallbackWithConversations _Nullable)onSuccess
                 onError:(NXMErrorCallback _Nullable)onError {
    [self.router getConversations:getConvetsationsRequest onSuccess:onSuccess onError:onError];
}

- (void)getConversationsForUser:(nonnull NSString *)userId
                   onSuccess:(NXMSuccessCallbackWithConversations _Nullable)onSuccess
                     onError:(NXMErrorCallback _Nullable)onError {
    [self.router getConversationsForUser:userId onSuccess:onSuccess onError:onError];
}

- (void)getEvents:(nonnull NXMGetEventsRequest*)getEventsRequest
        onSuccess:(NXMSuccessCallbackWithEvents _Nullable)onSuccess
          onError:(NXMErrorCallback _Nullable)onError{
    [self.router getEvents:getEventsRequest onSuccess:onSuccess onError:onError];
}
- (void)getConversationDetails:(nonnull NSString*)conversationId
                     onSuccess:(NXMSuccessCallbackWithConversationDetails _Nullable)onSuccess
                       onError:(NXMErrorCallback _Nullable)onError {
    [self.router getConversationDetails:conversationId onSuccess:onSuccess onError:onError];
}

- (void)enableMedia:(NSString *)conversationId memberId:(NSString *)memberId sdp:(NSString *)sdp mediaType:(NSString *)mediaType // TODO: enum
          onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
            onError:(NXMErrorCallback _Nullable)onError {
    [self.router enableMedia:conversationId memberId:memberId sdp:sdp mediaType:mediaType onSuccess:onSuccess onError:onError];
}

- (void)disableMedia:(NSString *)conversationId
               rtcId:(NSString *)rtcId
            memberId:(NSString *)memberId
           onSuccess:(NXMSuccessCallback _Nullable)onSuccess
             onError:(NXMErrorCallback _Nullable)onError {
    [self.router disableMedia:conversationId rtcId:rtcId memberId:memberId onSuccess:onSuccess onError:onError];
}

- (void)suspendMediaWithMediaRequest:(nonnull NXMSuspendResumeMediaRequest *)mediaRequest
                 onSuccess:(NXMSuccessCallback _Nullable)onSuccess
                   onError:(NXMErrorCallback _Nullable)onError {
    
    switch (mediaRequest.mediaType) {
        case NXMMediaTypeAudio:
            [self.router muteAudioInConversation:mediaRequest.conversationId fromMember:mediaRequest.fromMemberId toMember:mediaRequest.toMemberId withRtcId:mediaRequest.rtcId onSuccess:onSuccess onError:onError];
            break;
        case NXMMediaTypeVideo:
        default:{
            [NXMLogger error:[NSString stringWithFormat:@"mediaType %ld is not supported",(long)mediaRequest.mediaType]];
            onError([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeMediaNotSupported andUserInfo:nil]);
        }
    }
}

- (void)resumeMediaWithMediaRequest:(nonnull NXMSuspendResumeMediaRequest *)mediaRequest
                onSuccess:(NXMSuccessCallback _Nullable)onSuccess
                  onError:(NXMErrorCallback _Nullable)onError {
    switch (mediaRequest.mediaType) {
        case NXMMediaTypeAudio:
            [self.router unmuteAudioInConversation:mediaRequest.conversationId fromMember:mediaRequest.fromMemberId toMember:mediaRequest.toMemberId withRtcId:mediaRequest.rtcId onSuccess:onSuccess onError:onError];
            break;
        case NXMMediaTypeVideo:
        default:{
            [NXMLogger error:[NSString stringWithFormat:@"mediaType %ld is not supported",(long)mediaRequest.mediaType]];
            onError([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeMediaNotSupported andUserInfo:nil]);
        }
    }
}

# pragma mark - NXMSocketClientDelegate

- (void)sipRinging:(nonnull NXMSipEvent *)sipEvent {
    [self.delegate sipRinging:sipEvent];
}

- (void)sipAnswered:(nonnull NXMSipEvent *)sipEvent {
    [self.delegate sipAnswered:sipEvent];
}

- (void)sipHangup:(nonnull NXMSipEvent *)sipEvent {
    [self.delegate sipHangup:sipEvent];
}

- (void)sipStatus:(nonnull NXMSipEvent *)sipEvent {
    [self.delegate sipStatus:sipEvent];
}

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

- (void)messageDeleted:(nonnull NXMMessageStatusEvent *)messageEvent {
    [self.delegate messageDeleted:messageEvent];
}

- (void)textTypingOn:(nonnull NXMTextTypingEvent *)textTypingEvent{
    [self.delegate textTypingOn:textTypingEvent];
}

- (void)textTypingOff:(nonnull NXMTextTypingEvent *)textTypingEvent{
    [self.delegate textTypingOff:textTypingEvent];
}

- (void)textDelivered:(nonnull NXMMessageStatusEvent *)statusEvent{
    [self.delegate textDelivered:statusEvent];
}

- (void)textSeen:(nonnull NXMMessageStatusEvent *)statusEvent{
    [self.delegate textSeen:statusEvent];
}

- (void)imageRecieved:(nonnull NXMImageEvent *)textEvent {
    [self.delegate imageRecieved:textEvent];
}

- (void)imageDelivered:(nonnull NXMMessageStatusEvent *)statusEvent {
    [self.delegate imageDelivered:statusEvent];
}


- (void)imageSeen:(nonnull NXMMessageStatusEvent *)statusEvent {
    [self.delegate imageSeen:statusEvent];
}


- (void)connectionStatusChanged:(NXMConnectionStatus)status reason:(NXMConnectionStatusReason)reason {
    [self.delegate connectionStatusChanged:status reason:reason];
}

- (void)userChanged:(NXMUser *)user withSessionId:(NSString *)sessionId {
    [self.router setSessionId:sessionId];
    [self.delegate userChanged:user];
}

- (void)mediaEvent:(nonnull NXMMediaEvent *)mediaEvent{
    [self.delegate mediaEvent:mediaEvent];
}

- (void)mediaActionEvent:(nonnull NXMMediaActionEvent *)mediaActionEvent{
    [self.delegate mediaActionEvent:mediaActionEvent];
}

- (void)rtcAnswerEvent:(nonnull NXMRtcAnswerEvent *)rtcEvent {
    [self.delegate rtcAnswerEvent:rtcEvent];
}



@end
