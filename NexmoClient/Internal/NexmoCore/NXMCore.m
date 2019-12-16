//
//  NXMCore.m
//  NexmoCore
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMCore.h"
#import "NXMLogger.h"
#import "NXMNetworkManager.h"
#import "RTCMediaWrapper.h"
#import "NXMPushParserManager.h"
#import "NXMGetConversationsRequest.h"
#import "RTCMediaWrapperDelegate.h"
#import "NXMNetworkDelegate.h"
#import "NXMNetworkCallbacks.h"
#import "NXMEventInternal.h"
#import "NXMConversationIdsPage.h"

@interface NXMCore() <RTCMediaWrapperDelegate, NXMNetworkDelegate>

@property (weak) id<NXMCoreDelegate> delegate;
@property NXMNetworkManager *network;
@property RTCMediaWrapper *rtcMedia;
@property NXMUser* user;
@property (readwrite, nonnull, nonatomic) NXMPushParserManager *pushParser;

@end

@implementation NXMCore

- (instancetype)initWithToken:(NSString *)authToken configuration:(NXMClientConfig *)configuration {
    if (self = [super init]) {
        self.token = authToken;
        self.network = [[NXMNetworkManager alloc] initWithConfiguration:configuration];

        [self.network setDelegate:(id<NXMNetworkDelegate>)self];
        
        self.rtcMedia = [[RTCMediaWrapper alloc] initWithIceServerUrls:configuration.iceServerUrls];
        [self.rtcMedia setDelegate:self];
        
        self.pushParser = [NXMPushParserManager sharedInstance];
    }
    return self;
}

- (void)login {
    [self.network login];
}

- (void)logout {
    if (self.connectionStatus != NXMConnectionStatusConnected) {
        return;
    }
    
    [self.network logout];
}

- (void)refreshAuthToken:(nonnull NSString *)authToken {
    self.token = authToken;
    [self.network refreshAuthToken];
}

- (void)setDelgate:(nonnull id<NXMCoreDelegate>)delegate {
    self.delegate = delegate;
}

- (NXMConnectionStatus)connectionStatus {
    return [self.network connectionStatus];
}

#pragma mark - Push

- (void)enablePushNotificationsWithPushKitToken:(nullable NSData *)pushKitToken
                          userNotificationToken:(nullable NSData *)userNotificationToken
                                      isSandbox:(BOOL)isSandbox
                                      onSuccess:(NXMSuccessCallback _Nullable)onSuccess
                                        onError:(NXMErrorCallback _Nullable)onError {
    NXMEnablePushRequest *request = [[NXMEnablePushRequest alloc] initWithPushKitToken:pushKitToken userNotificationToken:userNotificationToken isSandbox:isSandbox];
    
    [self.network enablePushNotifications:request onSuccess:onSuccess onError:onError];
}

- (void)disablePushNotificationsWithOnSuccess:(NXMSuccessCallback _Nullable)onSuccess
                                      onError:(NXMErrorCallback _Nullable)onError {
    [self.network disablePushNotificationsWithOnSuccess:onSuccess onError:onError];
}

- (BOOL)isNexmoPushWithUserInfo:(nonnull NSDictionary *)userInfo {
    return [self.pushParser isStitchPushWithUserInfo:userInfo];
}

- (void)processNexmoPushWithUserInfo:(nonnull NSDictionary *)userInfo onSuccess:(NXMSuccessCallbackWithEvent _Nullable)onSuccess onError:(NXMErrorCallback _Nullable)onError {
    if(![self isNexmoPushWithUserInfo:userInfo]) {
        if(onError) {
            onError([NXMErrors nxmErrorWithErrorCode:NXMErrorCodePushNotANexmoPush]);
            return;
        }
    }
    
    NXMEvent *parsedEvent = [self.pushParser parseStitchPushEventWithUserInfo:userInfo];
    if(!parsedEvent) {
        if(onError) {
            onError([NXMErrors nxmErrorWithErrorCode:NXMErrorCodePushParsingFailed]);
        }
        return;
    }
    
    switch (parsedEvent.type) {
        case NXMEventTypeMember:
            if(((NXMMemberEvent *)parsedEvent).state == NXMMemberStateInvited) {
                [self memberInvited:(NXMMemberEvent *)parsedEvent];
            }
            break;
        case NXMEventTypeText:
            [self textRecieved:(NXMTextEvent *)parsedEvent];
        case NXMEventTypeImage:
            [self imageRecieved:(NXMImageEvent *)parsedEvent];
        default:
            break;
    }
    
    if(onSuccess) {
        onSuccess(parsedEvent);
    }
}

#pragma mark - Conversation Methods

- (void)createConversationWithName:(nonnull NSString *)name
             onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
               onError:(NXMErrorCallback _Nullable)onError {
    NXMCreateConversationRequest *request = [[NXMCreateConversationRequest alloc] initWithDisplayName:name];
    [self.network createConversation:request onSuccess:onSuccess onError:onError];
}

- (nonnull NSString *)joinToConversation:(nonnull NSString *)conversationId
                            withUsername:(nonnull NSString *)username
                               onSuccess:(NXMSuccessCallbackWithObject _Nullable)onSuccess
                                 onError:(NXMErrorCallback _Nullable)onError {
    NXMAddUserRequest *request = [[NXMAddUserRequest alloc] initWithConversationId:conversationId andUsername:username];
    return [self.network joinUserToConversation:request onSuccess:onSuccess onError:onError];
}

- (nonnull NSString *)joinToConversation:(nonnull NSString *)conversationId
                            withMemberId:(nonnull NSString *)memberId
                               onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                                 onError:(NXMErrorCallback _Nullable)onError {
    NXMJoinMemberRequest *request = [[NXMJoinMemberRequest alloc] initWithConversationId:conversationId andMemberId:memberId];
    return [self.network joinMemberToConversation:request onSuccess:onSuccess onError:onError];
}

- (void)inviteToConversation:(nonnull NSString *)conversationId
    withUsername:(nonnull NSString *)username
     onSuccess:(NXMSuccessCallbackWithObject _Nullable)onSuccess
       onError:(NXMErrorCallback _Nullable)onError {
    NXMInviteUserRequest *request = [[NXMInviteUserRequest alloc] initWithConversationId:conversationId username:username];
    [self.network inviteUserToConversation:request onSuccess:onSuccess onError:onError];
}

- (void)inviteToConversation:(nonnull NSString *)conversationId
                  withUsername:(nonnull NSString *)username
                   withMedia:(BOOL)mediaEnabled
                   onSuccess:(NXMSuccessCallbackWithObject _Nullable)onSuccess
                     onError:(NXMErrorCallback _Nullable)onError {
    NXMInviteUserRequest *request = [[NXMInviteUserRequest alloc] initWithConversationId:conversationId username:username mediaEnabled:mediaEnabled];
    [self.network inviteUserToConversation:request onSuccess:onSuccess onError:onError];
}

- (NSString *)inviteToConversation:(nonnull NSString*)userName
    withPhoneNumber:(nonnull NSString*)phoneNumber
     onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
       onError:(NXMErrorCallback _Nullable)onError {
    NXMInvitePstnKnockingRequest *request = [[NXMInvitePstnKnockingRequest alloc] initWithUserName:userName andPhoneNumber:phoneNumber];
    return [self.network invitePstnKnockingToConversation:request onSuccess:onSuccess onError:onError];
}

- (void)inviteToConversation:(nonnull NSString *)conversationId
    withUserId:(nonnull NSString *)userId
withPhoneNumber:(nonnull NSString *)phoneNumber
     onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
       onError:(NXMErrorCallback _Nullable)onError {
    NXMInvitePstnRequest *request = [[NXMInvitePstnRequest alloc] initWithConversationId:conversationId andUserID:userId andPhoneNumber:phoneNumber];
    [self.network invitePstnToConversation:request onSuccess:onSuccess onError:onError];
}

- (void)deleteMember:(nonnull NSString *)memberId
fromConversationWithId:(nonnull NSString *)conversationId
           onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
             onError:(NXMErrorCallback _Nullable)onError {
    NXMRemoveMemberRequest *request = [[NXMRemoveMemberRequest alloc] initWithConversationId:conversationId andMemberId:memberId];
    [self.network removeMemberFromConversation:request onSuccess:onSuccess onError:onError];
}

- (void)getConversationDetails:(nonnull NSString*)conversationId
                     onSuccess:(NXMSuccessCallbackWithConversationDetails _Nullable)onSuccess
                       onError:(NXMErrorCallback _Nullable)onError {
    [self.network getConversationDetails:conversationId onSuccess:onSuccess onError:onError];
}

- (void)getConversationsForUser:(nonnull NSString *)userId
                   onSuccess:(NXMSuccessCallbackWithConversations _Nullable)onSuccess
                     onError:(NXMErrorCallback _Nullable)onError {
    [self.network getConversationsForUser:userId onSuccess:onSuccess onError:onError];
}

- (void)getConversationIdsPageWithSize:(NSUInteger)size
                                cursor:(NSString *)cursor
                                userId:(NSString *)userId
                                 order:(NXMPageOrder)order
                             onSuccess:(void (^)(NXMConversationIdsPage * _Nullable))onSuccess
                               onError:(void (^)(NSError * _Nullable))onError {
    [self.network getConversationIdsPageWithSize:size
                                          cursor:cursor
                                          userId:userId
                                           order:order
                                       onSuccess:onSuccess
                                         onError:onError];
}

- (void)getConversationIdsPageForURL:(NSURL *)url
                           onSuccess:(void (^)(NXMConversationIdsPage * _Nullable))onSuccess
                             onError:(void (^)(NSError * _Nullable))onError {
    [self.network getConversationIdsPageForURL:url onSuccess:onSuccess onError:onError];
}


- (void)getLatestEventInConversation:(nonnull NSString *)conversationId
                      onSuccess:(NXMSuccessCallbackWithEvent _Nullable)onSuccess
                        onError:(NXMErrorCallback _Nullable)onError{
    NXMGetEventsRequest *request = [NXMGetEventsRequest new];
    request.conversationId = conversationId;
    [self.network getLatestEvent:request onSuccess:onSuccess onError:onError];
}

- (void)getEventsInConversation:(nonnull NSString *)conversationId
        onSuccess:(NXMSuccessCallbackWithEvents _Nullable)onSuccess
          onError:(NXMErrorCallback _Nullable)onError{
    NXMGetEventsRequest *request = [NXMGetEventsRequest new];
    request.conversationId = conversationId;
    [self.network getEvents:request onSuccess:onSuccess onError:onError];
}

- (void)getEventsInConversation:(nonnull NSString *)conversationId
          startId:(nullable NSNumber *)startId
            endId:(nullable NSNumber *)endId
        onSuccess:(NXMSuccessCallbackWithEvents _Nullable)onSuccess
          onError:(NXMErrorCallback _Nullable)onError{
    NXMGetEventsRequest *request = [NXMGetEventsRequest new];
    request.conversationId = conversationId;
    request.startId = startId;
    request.endId = endId;
    [self.network getEvents:request onSuccess:onSuccess onError:onError];
}


#pragma mark - Messages Methods

- (void)sendCustomEvent:(nonnull NSString *)customType
                   body:(nonnull NSDictionary *)body
         conversationId:(nonnull NSString *)conversationId
           fromMemberId:(nonnull NSString *)fromMemberId
              onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
                onError:(NXMErrorCallback _Nullable)onError {
    
    NXMSendCustomEventRequest *request = [[NXMSendCustomEventRequest alloc] initWithConversationId:conversationId
                                                                                          memberId:fromMemberId
                                                                                         customType:customType
                                                                                              body:body];
    [self.network sendCustomEvent:request onSuccess:onSuccess onError:onError];
}

- (void)sendDTMF:(nonnull NSString *)digit
  conversationId:(nonnull NSString *)conversationId
    fromMemberId:(nonnull NSString *)fromMemberId
       onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
         onError:(NXMErrorCallback _Nullable)onError {
    NXMSendDTMFRequest *request = [[NXMSendDTMFRequest alloc] initWithConversationId:conversationId  memberId:fromMemberId digit:digit];
    [self.network sendDTMFToConversation:request onSuccess:onSuccess onError:onError];
}

- (void)sendText:(nonnull NSString *)text
  conversationId:(nonnull NSString *)conversationId
    fromMemberId:(nonnull NSString *)fromMemberId
       onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
         onError:(NXMErrorCallback _Nullable)onError {
    NXMSendTextEventRequest *request = [[NXMSendTextEventRequest alloc] initWithText:text conversationId:conversationId memberId:fromMemberId];
    
    [self.network sendTextToConversation:request onSuccess:onSuccess onError:onError];
}

- (void)sendImageWithName:(NSString *)imageName
            image:(nonnull NSData *)image
   conversationId:(nonnull NSString *)conversationId
     fromMemberId:(nonnull NSString *)fromMemberId
        onSuccess:(NXMSuccessCallbackWithId _Nullable)onSuccess
          onError:(NXMErrorCallback _Nullable)onError {
    NXMSendImageRequest *request = [[NXMSendImageRequest alloc] initWithImage:imageName image:image conversationId:conversationId memberId:fromMemberId];
    [self.network sendImage:request onSuccess:onSuccess onError:onError];
}

- (void)deleteEvent:(NSInteger)eventId
     conversationId:(nonnull NSString *)conversationId
       fromMemberId:(nonnull NSString *)memberId
          onSuccess:(NXMSuccessCallback _Nullable)onSuccess
            onError:(NXMErrorCallback _Nullable)onError {
    NXMDeleteEventRequest *request = [[NXMDeleteEventRequest alloc] initWithEventId:eventId conversationId:conversationId memberId:memberId];
    [self.network deleteEventFromConversation:request onSuccess:onSuccess onError:onError];
}

- (void)markAsSeen:(NSInteger)messageId
    conversationId:(nonnull NSString *)conversationId
  fromMemberWithId:(nonnull NSString *)memberId
         onSuccess:(NXMSuccessCallback _Nullable)onSuccess
           onError:(NXMErrorCallback _Nullable)onError {
    [self.network seenTextEvent:conversationId memberId:memberId eventId:messageId];
}

- (void)markAsDelivered:(NSInteger)messageId
         conversationId:(nonnull NSString *)conversationId
       fromMemberWithId:(nonnull NSString *)memberId
              onSuccess:(NXMSuccessCallback _Nullable)onSuccess
                onError:(NXMErrorCallback _Nullable)onError {
    [self.network deliverTextEvent:conversationId memberId:memberId eventId:messageId];
}

- (void)startTypingWithConversationId:(nonnull NSString *)conversationId
           memberId:(nonnull NSString *)memberId {
    [self.network textTypingOn:conversationId memberId:memberId];
}

- (void)stopTypingWithConversationId:(nonnull NSString *)conversationId
          memberId:(nonnull NSString *)memberId {
    [self.network textTypingOff:conversationId memberId:memberId];
}

#pragma mark - Media Methods

- (NXMErrorCode)enableMedia:(nonnull NSString *)conversationId
                         memberId:(nonnull NSString *)memberId {
    [self.rtcMedia enableMediaWithMediaID:conversationId memberId:memberId andWithAudio:NXMMediaStreamTypeSendReceive andWithVideo:NXMMediaStreamTypeNone];
    
    return NXMErrorCodeNone;
}

- (NXMErrorCode)disableMedia:(nonnull NSString *)conversationId {
    [self.rtcMedia disableMedia:conversationId];
    
    return NXMErrorCodeNone;
}

- (NXMErrorCode)suspendMyMedia:(NXMMediaType)mediaType
                    inConversation:(nonnull NSString *)conversationId{
    if(![self isSupportedMediaType:mediaType]) {
        return NXMErrorCodeMediaNotSupported;
    }
    return [self.rtcMedia suspendMediaWithMediaId:conversationId andMediaType:mediaType];
}

- (NXMErrorCode)resumeMyMedia:(NXMMediaType)mediaType
                    inConversation:(nonnull NSString *)conversationId{
    if(![self isSupportedMediaType:mediaType]) {
        return NXMErrorCodeMediaNotSupported;
    }
    return [self.rtcMedia resumeMediaWithMediaId:conversationId andMediaType:mediaType];
}

//- (NXMErrorCode)sendDTMFWithDigits:(nonnull NSString*)digits
//                      andConversationId:(nonnull NSString*)conversationId
//                            andMemberId:(nonnull NSString*)memberId
//                            andDuration:(int) duration
//                                 andGap:(int) gap{
//    return [self.network sendDTMFWithDigit:digit andConversartionId:conversationId andMemberId:memberId];
//
//    return [self.rtcMedia sendDTMFWithDigits:digits andConversationId:conversationId andMemberId:memberId andDuration:duration andGap:gap];
//}

- (void)suspendMedia:(NXMMediaType)mediaType
            ofMember:(NSString *)memberId
      inConversation:(nonnull NSString *)conversationId
          fromMember:(NSString *)fromMemberId
           onSuccess:(NXMSuccessCallback _Nullable)onSuccess
             onError:(NXMErrorCallback _Nullable)onError {
    if(![self isSupportedMediaType:mediaType]) {
        onError([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeMediaNotSupported andUserInfo:nil]);
    }
    NXMSuspendResumeMediaRequest *mediaRequest = [[NXMSuspendResumeMediaRequest alloc] initWithConversationId:conversationId fromMemberId:fromMemberId toMemberId:memberId rtcId:nil mediaType:mediaType];
    [self.network suspendMediaWithMediaRequest:mediaRequest onSuccess:onSuccess onError:onError];
}

- (void)resumeMedia:(NXMMediaType)mediaType
           ofMember:(NSString *)memberId
     inConversation:(nonnull NSString *)conversationId
         fromMember:(NSString *)fromMemberId
          onSuccess:(NXMSuccessCallback _Nullable)onSuccess
            onError:(NXMErrorCallback _Nullable)onError {
    if(![self isSupportedMediaType:mediaType]) {
        onError([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeMediaNotSupported andUserInfo:nil]);
    }
    NXMSuspendResumeMediaRequest *mediaRequest = [[NXMSuspendResumeMediaRequest alloc] initWithConversationId:conversationId fromMemberId:fromMemberId toMemberId:memberId rtcId:nil mediaType:mediaType];
    [self.network resumeMediaWithMediaRequest:mediaRequest onSuccess:onSuccess onError:onError];
}

#pragma mark - NXMNetworkDelegate

- (void)onError:(NXMErrorCode)errorCode {
    [self.delegate onError:errorCode];
}

- (NSString *)authToken {
    return self.token;
}

- (void)connectionStatusChanged:(NXMConnectionStatus)status reason:(NXMConnectionStatusReason)reason {
    [self.delegate connectionStatusChanged:status reason:reason];
}

- (void)userUpdated:(NXMUser *)user {
    if ([self.user.uuid isEqualToString:user.uuid]) {
        self.user.displayName = user.displayName;
        return;
    }
    self.user = user;
}


- (void)memberJoined:(nonnull NXMMemberEvent *)member {
    [self.delegate memberJoined:member];
}

- (void)memberRemoved:(nonnull NXMMemberEvent *)member {
    [self.delegate memberRemoved:member];
}

- (void)memberInvited:(nonnull NXMMemberEvent *)memberEvent {
    [self.delegate memberInvited:memberEvent];
}

- (void)textRecieved:(nonnull NXMTextEvent *)textEvent {
    [self.delegate textRecieved:textEvent];
}

- (void)textDelivered:(nonnull NXMMessageStatusEvent *)statusEvent{
    [self.delegate textDelivered:statusEvent];
    
}
- (void)textSeen:(nonnull NXMMessageStatusEvent *)statusEvent{
    [self.delegate textSeen:statusEvent];
    
}

- (void)imageRecieved:(nonnull NXMImageEvent *)imageEvent {
    [self.delegate imageRecieved:imageEvent];
}

- (void)imageDelivered:(nonnull NXMMessageStatusEvent *)statusEvent {
    [self.delegate imageDelivered:statusEvent];
}


- (void)imageSeen:(nonnull NXMMessageStatusEvent *)statusEvent {
    [self.delegate imageSeen:statusEvent];
}

- (void)textTypingOn:(nonnull NXMTextTypingEvent *)textTypingEvent {
    [self.delegate textTypingOn:textTypingEvent];
}

- (void)textTypingOff:(nonnull NXMTextTypingEvent *)textTypingEvent {
    [self.delegate textTypingOff:textTypingEvent];
}

- (void)messageDeleted:(nonnull NXMMessageStatusEvent *)messageEvent {
    [self.delegate messageDeleted:messageEvent];
}

- (void)mediaEvent:(nonnull NXMMediaEvent *)mediaEvent {
    [self.delegate informOnMedia:mediaEvent];
}

- (void)mediaActionEvent:(nonnull NXMMediaActionEvent *)mediaActionEvent {
    [self.delegate actionOnMedia:mediaActionEvent];
}

- (void)rtcAnswerEvent:(nonnull NXMRtcAnswerEvent *)rtcEvent {
    [self.rtcMedia answerWithMediaId:rtcEvent.rtcId convId:rtcEvent.conversationId andSDP:rtcEvent.sdp];
}

- (void)DTMFEvent:(nonnull NXMDTMFEvent *)dtmfEvent {
    [self.delegate DTMFEvent:dtmfEvent];
}

- (void)legStatus:(NXMLegStatusEvent *)legEvent {
    [self.delegate legStatus:legEvent];
}

- (void)sipRinging:(nonnull NXMSipEvent *)sipEvent{
    [self.delegate sipRinging:sipEvent];
}

- (void)sipAnswered:(nonnull NXMSipEvent *)sipEvent{
    [self.delegate sipAnswered:sipEvent];
}
- (void)sipHangup:(nonnull NXMSipEvent *)sipEvent{
    [self.delegate sipHangup:sipEvent];
}
- (void)sipStatus:(nonnull NXMSipEvent *)sipEvent{
    [self.delegate sipStatus:sipEvent];
}

- (void)customEvent:(nonnull NXMCustomEvent *)customEvent {
    [self.delegate customEvent:customEvent];
}




#pragma mark - RTCMediaWrapperDelegate

- (void)onMediaStatusChangedWithConversationId:(NSString *)conversationId andStatus:(NSString *)status {
    // TODO:
}

- (void)sendSDP:(NSString *)sdp
   andMediaInfo:(MRTCMediaInfo *)mediaInfo
      onSuccess:(NXMSuccessCallbackWithId)onSuccess
        onError:(NXMErrorCallback)onError {
    [self.network enableMedia:mediaInfo._conversationId memberId:mediaInfo._memberId sdp:sdp mediaType:@"" onSuccess:onSuccess onError:onError];
}

- (void)terminateRtc:(MRTCMediaInfo *)mediaInfo rtcId:(NSString *)rtcId  completionHandler:(void (^)(NSError *))completionHandler {
    [self.network disableMedia:mediaInfo._conversationId rtcId:rtcId memberId:mediaInfo._memberId onSuccess:^{
        completionHandler(nil);
    } onError:^(NSError * _Nullable error) {
        completionHandler(error);
    }];
}

- (void)didMuteStateChangeWithMediaInfo:(NXMMediaInfo *)mediaInfo andIsMute:(bool)isMute andMediaType:(NXMMediaType)mediaType {
    NXMMediaSuspendEvent *mediaEvent = [NXMMediaSuspendEvent new];
    mediaEvent.fromMemberId = mediaInfo.memberId;
    mediaEvent.toMemberUuid = mediaInfo.memberId;
    mediaEvent.conversationUuid = mediaInfo.conversationId;
    mediaEvent.type = NXMEventTypeMediaAction;
    mediaEvent.creationDate = [NSDate date];
    mediaEvent.actionType = NXMMediaActionTypeSuspend;
    mediaEvent.mediaType = mediaType;
    mediaEvent.isSuspended = isMute;

    [self.delegate localActionOnMedia:mediaEvent];
}


- (void)sendMuteStateWithMediaInfo:(NXMMediaInfo *)mediaInfo andIsMute:(bool)isMute andMediaType:(NXMMediaType)mediaType onSuccess:(void (^) (void))onSuccess onError:(void (^) (NSError * _Nullable error))onError {
    
    NXMSuspendResumeMediaRequest *mediaRequest = [[NXMSuspendResumeMediaRequest alloc] initWithConversationId:mediaInfo.conversationId fromMemberId:mediaInfo.memberId toMemberId:mediaInfo.memberId rtcId:mediaInfo.rtcId mediaType:mediaType];
    
    if(isMute) {
        [self.network suspendMediaWithMediaRequest:mediaRequest onSuccess:onSuccess onError:onError];
    }
    else {
        [self.network resumeMediaWithMediaRequest:mediaRequest onSuccess:onSuccess onError:onError];
    }
}

#pragma mark - private
-(bool)isSupportedMediaType:(NXMMediaType)mediaType {
    switch (mediaType) {
        case NXMMediaTypeAudio:
            return true;
        case NXMMediaTypeVideo:
        case NXMMediaTypeNone:
        default:
            return false;
    }
}


@end
