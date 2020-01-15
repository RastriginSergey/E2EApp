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
#import "NXMLoggerInternal.h"

@interface NXMNetworkManager()
@property NXMSocketClient *socketClient;
@property NXMRouter *router;
@property (nonatomic, weak) id<NXMNetworkDelegate> delegate;

@property NXMSuccessCallbackWithObject loginSuccessCallback;
@property NXMErrorCallback loginErrorCallback;

@end

@implementation NXMNetworkManager

- (instancetype)initWithConfiguration:(NXMClientConfig *)configuration {
    if (self = [super init]) {
        self.socketClient = [[NXMSocketClient alloc] initWithHost:configuration.websocketUrl];
        [self.socketClient setDelegate:(id<NXMSocketClientDelegate>)self];
        self.router = [[NXMRouter alloc] initWithHost:configuration.apiUrl
                                               ipsURL:[NSURL URLWithString:configuration.ipsUrl]];
    }
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

- (nonnull NSString *)joinUserToConversation:(nonnull NXMAddUserRequest*)addUserRequest
                                   onSuccess:(NXMSuccessCallbackWithObject _Nullable)onSuccess
                                     onError:(NXMErrorCallback _Nullable)onError {
    return [self.router joinUserToConversation:addUserRequest onSuccess:onSuccess onError:onError];
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


- (NSString *)invitePstnKnockingToConversation:(nonnull NXMInvitePstnKnockingRequest *)invitePstnRequest
                               onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                                 onError:(NXMErrorCallback _Nullable)onError{
    return [self.router invitePstnKnockingToConversation:invitePstnRequest onSuccess:onSuccess onError:onError];
}

- (NSString *)joinMemberToConversation:(nonnull NXMJoinMemberRequest *)joinMemberRequest
                             onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                               onError:(NXMErrorCallback _Nullable)onError {
   return [self.router joinMemberToConversation:joinMemberRequest onSuccess:onSuccess onError:onError];
}

- (void)removeMemberFromConversation:(nonnull NXMRemoveMemberRequest *)removeMemberRequest
                           onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                             onError:(NXMErrorCallback _Nullable)onError {
    [self.router removeMemberFromConversation:removeMemberRequest onSuccess:onSuccess onError:onError];
}

- (void)sendCustomEvent:(nonnull NXMSendCustomEventRequest *)sendCustomEventRequest
              onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                onError:(NXMErrorCallback _Nullable)onError {
    [self.router sendCustomEvent:sendCustomEventRequest onSuccess:onSuccess onError:onError];
}
- (void)sendTextToConversation:(nonnull NXMSendTextEventRequest*)sendTextEventRequest
                     onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                       onError:(NXMErrorCallback _Nullable)onError {
    [self.router sendTextToConversation:sendTextEventRequest onSuccess:onSuccess onError:onError];
}

- (void)sendDTMFToConversation:(nonnull NXMSendDTMFRequest*)sendDTMFRequest
                     onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                       onError:(NXMErrorCallback _Nullable)onError {
    [self.router sendDTMFToConversation:sendDTMFRequest onSuccess:onSuccess onError:onError];
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


- (void)getConversationsForUser:(nonnull NSString *)userId
                   onSuccess:(NXMSuccessCallbackWithConversations _Nullable)onSuccess
                     onError:(NXMErrorCallback _Nullable)onError {
    [self.router getConversationsForUser:userId onSuccess:onSuccess onError:onError];
}

- (void)getConversationIdsPageWithSize:(NSUInteger)size
                                cursor:(NSString *)cursor
                                userId:(NSString *)userId
                                 order:(NXMPageOrder)order
                             onSuccess:(void (^)(NXMConversationIdsPage * _Nullable))onSuccess
                               onError:(void (^)(NSError * _Nullable))onError {
    [self.router getConversationIdsPageWithSize:size
                                         cursor:cursor
                                         userId:userId
                                          order:order
                                      onSuccess:onSuccess
                                        onError:onError];
}

- (void)getConversationIdsPageForURL:(NSURL *)url
                           onSuccess:(void (^)(NXMConversationIdsPage * _Nullable))onSuccess
                             onError:(void (^)(NSError * _Nullable))onError {
    [self.router getConversationIdsPageForURL:url onSuccess:onSuccess onError:onError];
}


- (void)getLatestEvent:(nonnull NXMGetEventsRequest*)getEventsRequest
        onSuccess:(NXMSuccessCallbackWithEvent _Nullable)onSuccess
          onError:(NXMErrorCallback _Nullable)onError{
    [self.router getLatestEvent:getEventsRequest onSuccess:onSuccess onError:onError];
}

- (void)getEvents:(nonnull NXMGetEventsRequest*)getEventsRequest
        onSuccess:(NXMSuccessCallbackWithEvents _Nullable)onSuccess
          onError:(NXMErrorCallback _Nullable)onError{
    [self.router getEvents:getEventsRequest onSuccess:onSuccess onError:onError];
}

- (void)getEventsPageWithRequest:(NXMGetEventsPageRequest *)request
               eventsPagingProxy:(id<NXMPageProxy>)pagingProxy
                       onSuccess:(void (^)(NXMEventsPage * _Nullable))onSuccess
                         onError:(void (^)(NSError * _Nullable))onError {
    [self.router getEventsPageWithRequest:request
                     eventsPagingProxy:pagingProxy
                             onSuccess:onSuccess
                               onError:onError];
}

- (void)getEventsPageForURL:(NSURL *)url
          eventsPagingProxy:(id<NXMPageProxy>)proxy
                  onSuccess:(void (^)(NXMEventsPage * _Nullable))onSuccess
                    onError:(void (^)(NSError * _Nullable))onError {
    [self.router getEventsPageForURL:url eventsPagingProxy:proxy onSuccess:onSuccess onError:onError];
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
            NXM_LOG_ERROR("mediaType %ld is not supported",(long)mediaRequest.mediaType);
            onError([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeMediaNotSupported]);
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
            NXM_LOG_ERROR("mediaType %ld is not supported", (long)mediaRequest.mediaType);
            onError([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeMediaNotSupported]);
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
    
    [self.delegate userUpdated:user];
    [self.router getUser:user.uuid completionBlock:^(NSError * _Nullable error, NXMUser * _Nullable data) {
        if (error) {
            [self.delegate userUpdated:user];
            return;
        }
        
        [self.delegate userUpdated:data];
    }];
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

- (void)DTMFEvent:(nonnull NXMDTMFEvent *)dtmfEvent {
    [self.delegate DTMFEvent:dtmfEvent];
}

- (void)legStatus:(NXMLegStatusEvent *)legEvent {
    [self.delegate legStatus:legEvent];
}

- (void)customEvent:(nonnull NXMCustomEvent *)customEvent {
    [self.delegate customEvent:customEvent];
}

- (void)onError:(NXMErrorCode)errorCode {
    [self.delegate onError:errorCode];
}


@end
