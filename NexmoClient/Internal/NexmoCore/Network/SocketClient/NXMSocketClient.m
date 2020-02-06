//
//  NXMSocketClient.m
//  NexmoClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VPSocketIO.h"

#import "NXMSocketClient.h"
#import "NXMClientDefine.h"

#import "NXMCoreEvents.h"
#import "NXMEventCreator.h"

#import "NXMLoggerInternal.h"
#import "NXMErrorsPrivate.h"
#import "NXMUserPrivate.h"

#import "NXMUtils.h"


@interface NXMSocketClient()

@property (weak) id<NXMSocketClientDelegate> delegate;
@property VPSocketIOClient *socket;
@property NSString *token;
@property NXMConnectionStatus status;

@end

@implementation NXMSocketClient

#pragma mark - Public
- (instancetype)initWithHost:(NSString *)host {
    if (self = [super init]) {
        
        VPSocketLogger *logger = [VPSocketLogger new];
        
        NSString *urlString = host;
        NSDictionary *connectParams = @{@"EIO":@"3"};
        self.socket = [[VPSocketIOClient alloc] init:[NSURL URLWithString:urlString]
                                          withConfig:@{@"log": @YES,
                                                       @"secure": @YES,
                                                       @"forceNew":@YES,
                                                       @"path":@"/rtc/",
                                                       @"forceWebsockets":@YES,
                                                       @"selfSigned":@YES,
                                                       @"reconnectWait":@2,
                                                       @"nsp":@"/",
                                                       @"connectParams":connectParams,
                                                       @"logger":logger
                                                       }];
        
        [self subscribeSocketEvent];
    }
    
    return self;
}
#pragma mark login

- (NXMConnectionStatus)connectionStatus {
    return self.status;
}

- (void)loginWithToken:(NSString *)token {
    self.token = token;
    [self connectSocket];
}

- (void)refreshAuthToken:(nonnull NSString *)authToken {
    
    if (self.status != NXMConnectionStatusConnected) {
        [self loginWithToken:authToken];
        return;
    }
    
    self.token = authToken;

    NSDictionary * msg = @{ @"body" : @{
                                    @"token":authToken
                                    }};
    
    [self.socket emit:kNXMSocketEventRefreshToken items:@[msg]];
}

- (void)logout {
    if (self.status == NXMConnectionStatusConnected) {
        [self serverLogout];
    }
}

#pragma mark conversation actions
- (void)seenTextEvent:(nonnull NSString *)conversationId
             memberId:(nonnull NSString *)memberId
              eventId:(NSInteger)eventId
{
    NSDictionary * msg = @{
                           @"cid": conversationId,
                           @"from":memberId,
                           @"body" : @{
                                   @"event_id":[NSNumber numberWithInteger:eventId]
                                   }};
    
    [self.socket emit:kNXMSocketEventTextSeen items:@[msg]];
}


- (void)deliverTextEvent:(nonnull NSString *)conversationId
                memberId:(nonnull NSString *)memberId
                 eventId:(NSInteger)eventId
{
    NSDictionary * msg = @{
                           @"cid": conversationId,
                           @"from":memberId,
                           @"body" : @{
                                   @"event_id":[NSNumber numberWithInteger:eventId]
                                   }};
    
    [self.socket emit:kNXMSocketEventTextDelivered items:@[msg]];
    
}

- (void)textTypingOn:(nonnull NSString *)conversationId
            memberId:(nonnull NSString *)memberId;
{
    
    NSDictionary * msg = @{
                           @"cid": conversationId,
                           @"from":memberId,
                           @"body" : @{
                                   }};
    
    [self.socket emit:kNXMSocketEventTypingOn items:@[msg]];
}

- (void)textTypingOff:(nonnull NSString *)conversationId
             memberId:(nonnull NSString *)memberId
{
    NSDictionary * msg = @{
                           @"cid": conversationId,
                           @"from":memberId,
                           @"body" : @{
                                   }};
    
    [self.socket emit:kNXMSocketEventTypingOff items:@[msg]];
}


#pragma mark - Private
#pragma mark Socket
- (void)connectSocket {
    switch (self.socket.status) {
        case VPSocketIOClientStatusNotConnected:
        case VPSocketIOClientStatusDisconnected:
            self.socket.reconnects = YES;
            [self.socket connect];
            break;
        case VPSocketIOClientStatusConnecting:
        case VPSocketIOClientStatusOpened:
        case VPSocketIOClientStatusConnected:
        default:
            break;
    }
}

- (void)disconnectSocket {
    switch (self.socket.status) {
        case VPSocketIOClientStatusConnected:
        case VPSocketIOClientStatusOpened:
        case VPSocketIOClientStatusConnecting:
            [self.socket disconnect];
            break;
        case VPSocketIOClientStatusNotConnected:
        case VPSocketIOClientStatusDisconnected:
        default:
            break;
    }
}

- (void)socketDidConnect {
    NXM_LOG_DEBUG("");

    //TODO: question - what happens if we try to log in while already logged in to the server for example after a reconnect?
    [self serverLogin];
}

- (void)didSocketDisconnect {
    [self updateConnetionStatus:NXMConnectionStatusDisconnected reason:NXMConnectionStatusReasonTerminated];
}

- (void)socketDidChangeStatus {
    switch (self.socket.status) {
        case VPSocketIOClientStatusConnected:
            
             NXM_LOG_DEBUG("socket connected"  );
            [self socketDidConnect];
            break;
        case VPSocketIOClientStatusNotConnected:
             NXM_LOG_DEBUG("socket not connected"  );
            [self didSocketDisconnect];
            break;
        case VPSocketIOClientStatusDisconnected:
             NXM_LOG_DEBUG("socket disconnected"  );
            [self didSocketDisconnect];
            break;
        case VPSocketIOClientStatusConnecting: //TODO: support reporting reconnect? or keep it boolean
             NXM_LOG_DEBUG("socket connecting"  );
            [self updateConnetionStatus:NXMConnectionStatusConnecting reason:NXMConnectionStatusReasonUnknown];
            break;
        case VPSocketIOClientStatusOpened:
             NXM_LOG_DEBUG("socket opened"  );
            break;
    }
}

#pragma mark login
- (void)serverLogin {
    NSDictionary * msg = @{@"tid": [[NSUUID UUID] UUIDString],
                           @"body" : @{
                                   @"token": self.token,
                                   @"device_id": [NXMUtils nexmoDeviceId],
                                   @"device_type": @"iphone",
                                   @"SDK_version": [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
                                   @"OS_family": @"iOS"
                                   //TODO: check what the js sdk mean by OS_revision: (typeof navigator !== "undefined") ? navigator.userAgent : (typeof window !== "undefined") ? window.navigator.userAgent : "Generic JS navigator"
                                   }};
    
    [self.socket emit:kNXMSocketEventLogin items:@[msg]];
}

- (void)serverLogout {
    NSDictionary * msg = @{@"tid": [[NSUUID UUID] UUIDString]};
    [self.socket emit:kNXMSocketEventLogout items:@[msg]];
}

- (void)didFailLoginWithError:(NXMErrorCode)error {
    self.token = nil;
    
    NXMConnectionStatusReason reason = NXMConnectionStatusReasonUnknown;
    
    switch (error) {
        case NXMErrorCodeSessionInvalid:
        case NXMErrorCodeMaxOpenedSessions:
            reason = NXMConnectionStatusReasonTerminated;
            break;
        case NXMErrorCodeTokenInvalid:
            reason = NXMConnectionStatusReasonTokenInvalid;
            break;
        case NXMErrorCodeTokenExpired:
            reason = NXMConnectionStatusReasonTokenExpired;
            break;
        case NXMErrorCodeUserNotFound:
            reason = NXMConnectionStatusReasonUserNotFound;
            break;
        default:
            break;
    }
    
    [self updateConnetionStatus:NXMConnectionStatusDisconnected reason:reason];
    
    [self disconnectSocket];
}

- (void)didServerLoginWithData:(NSArray *)data {
    NSDictionary *response = ((NSDictionary *)data[0])[@"body"];
    NXMUser *user = [[NXMUser alloc] initWithData:response];
    
    NSString * sessionid = response[@"id"];
    [self.delegate userChanged:user withSessionId:sessionid];
    
    [self updateConnetionStatus:NXMConnectionStatusConnected reason:NXMConnectionStatusReasonLogin];
}

- (void)didServerLogout {
     NXM_LOG_DEBUG("did server logout"  );
    self.token = nil;
    
    [self updateConnetionStatus:NXMConnectionStatusDisconnected reason:NXMConnectionStatusReasonLogout];

    [self disconnectSocket];
}

// TODO: thread safe
- (void)updateConnetionStatus:(NXMConnectionStatus)newStatus reason:(NXMConnectionStatusReason)reason {
    if (self.status != newStatus) {
        self.status = newStatus;
        [self.delegate connectionStatusChanged:newStatus reason:reason];
    }
}


#pragma mark subscribe

- (void)subscribeSocketEvent {
    [self subscribeVPSocketEvents];
    [self subscribeGeneralEvents];
    [self subscribeLoginEvents];
    [self subscribeMemberEvents];
    [self subscribeTextEvents];
    [self subscribeRTCEvents];
    [self subscribeSipEvents];
    [self subscribeLegStatusEvents];
}

- (void)subscribeVPSocketEvents {
    __weak NXMSocketClient *weakSelf = self;
    [self.socket on:kSocketEventStatusChange callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        [weakSelf socketDidChangeStatus];
    }];

    [self.socket on:kSocketEventError callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        NXM_LOG_ERROR([kSocketEventError UTF8String]);
    }];
}

- (void)subscribeGeneralEvents {
    __weak NXMSocketClient *weakSelf = self;
    
    [self.socket on:kNXMSocketEventBadPermission callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        NXM_LOG_ERROR("socket kNXMSocketEventBadPermission");
        [weakSelf.delegate onError:NXMErrorCodeEventBadPermission];
    }];

    [self.socket on:kNXMSocketEventInvalidEvent callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        NXM_LOG_ERROR("socket kNXMSocketEventInvalidEvent"  );
    }];
    
    [self.socket on:kNXMSocketEventUserNotFound callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        NXM_LOG_ERROR("socket kNXMSocketEventUserNotFound"  );
        [weakSelf didFailLoginWithError:NXMErrorCodeUserNotFound];
    }];
}

- (void)subscribeLoginEvents {
    __weak NXMSocketClient *weakSelf = self;

    [self.socket on:kNXMSocketEventLoginSuccess callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("$$--------Socket Login Success-------------$$");
        [weakSelf didServerLoginWithData:data];
    }];
    
    [self.socket on:kNXMSocketEventSessionLogoutSuccess callback:^(NSString *event, NSArray *array, VPSocketAckEmitter *emitter) {
        NXM_LOG_DEBUG("$$--------Socket Session Logout--------$$");
        [weakSelf didServerLogout];
    }];
    
    [self.socket on:kNXMSocketEventSessionTerminated callback:^(NSString *event, NSArray *array, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("$$--------Socket Session Terminated--------$$");
        [weakSelf didServerLogout];
    }];
    
    [self.socket on:kNXMSocketEventSessionInvalid callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        NXM_LOG_ERROR("socket kNXMSocketEventSessionInvalid"  );
        [weakSelf didFailLoginWithError:NXMErrorCodeSessionInvalid];
    }];
    
    [self.socket on:kNXMSocketEventSessionErrorInvalid callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        NXM_LOG_ERROR("socket kNXMSocketEventSessionErrorInvalid"  );
        [weakSelf didFailLoginWithError:NXMErrorCodeSessionInvalid];
    }];
    
    [self.socket on:kNXMSocketEventMaxOpenedSessions callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        NXM_LOG_ERROR("socket kNXMSocketEventMaxOpenedSessions"  );
        [weakSelf didFailLoginWithError:NXMErrorCodeMaxOpenedSessions];
    }];
    
    [self.socket on:kNXMSocketEventInvalidToken callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        NXM_LOG_ERROR("socket kNXMSocketEventInvalidToken"  );
        [weakSelf didFailLoginWithError:NXMErrorCodeTokenInvalid]; //TODO: check if this might happen without meaning a logout
    }];
    
    [self.socket on:kNXMSocketEventExpiredToken callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        NXM_LOG_ERROR("socket kNXMSocketEventExpiredToken"  );
        [weakSelf didFailLoginWithError:NXMErrorCodeTokenExpired]; //TODO: check if this might happen without meaning a logout
    }];
    
    [self.socket on:kNXMSocketEventRefreshTokenDone callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("socket kNXMSocketEventRefreshTokenDone"  );
        [weakSelf.delegate connectionStatusChanged:NXMConnectionStatusConnected reason:NXMConnectionStatusReasonTokenRefreshed];
    }];
}

- (void)subscribeMemberEvents {
    __weak NXMSocketClient *weakSelf = self;

    [self.socket on:kNXMSocketEventMemberJoined callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("socket kNXMSocketEventMemberJoined"  );
        [weakSelf onMemberJoined:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventMemberInvited callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("socket kNXMSocketEventMemberInvited"  );
        [weakSelf onMemberInvited:data emitter:emitter];
    }];
    
    
    [self.socket on:kNXMSocketEventMemberLeft callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("socket kNXMSocketEventMemberLeft"  );
        [weakSelf onMemberLeft:data emitter:emitter];
    }];
}

- (void)subscribeTextEvents {
    __weak NXMSocketClient *weakSelf = self;

    [self.socket on:kNXMSocketEventText callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("socket kNXMSocketEventText"  );
        [weakSelf onTextRecevied:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventTextSuccess callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("socket kNXMSocketEventTextSuccess"  );
     //   [weakSelf onTextRecevied:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventMessageDelete callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("socket kNXMSocketEventTextDelete"  );
        [weakSelf onMessageDeleted:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventTextSeen callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("socket kNXMSocketEventTextSeen"  );
        [weakSelf onTextSeen:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventTextDelivered callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("socket kNXMSocketEventTextDelivered"  );
        [weakSelf onTextDelivered:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventImage callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("socket kNXMSocketEventImage"  );
        [weakSelf onImageRecevied:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventImageSeen callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("socket kNXMSocketEventImageSeen"  );
        [weakSelf onImageSeen:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventImageDelivered callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("socket kNXMSocketEventImageDelivered"  );
        [weakSelf onImageDelivered:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventTypingOn callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("socket kNXMSocketEventTypingOn"  );
        [weakSelf onTextTypingOn:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventTypingOff callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("socket kNXMSocketEventTypingOff"  );
        [weakSelf onTextTypingOff:data emitter:emitter];
    }];
}

- (void)subscribeRTCEvents {
    __weak NXMSocketClient *weakSelf = self;

    [self.socket on:kNXMSocketEventRtcAnswer callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("socket kNXMSocketEventRtcAnswer"  );
        [weakSelf onRTCAnswer:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventMemebrMedia callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("Socket kNXMSocketEventMemebrMedia"  );
        [weakSelf onRTCMemberMedia:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventAudioMuteOn callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("Socket kNXMSocketEventAudioMuteOn"  );
        [weakSelf onRTCAudioMuteOn:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventAudioMuteOff callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("Socket kNXMSocketEventAudioMuteOff"  );
        [weakSelf onRTCAudioMuteOff:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventAudioDtmf callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("Socket kNXMSocketEventAudioDtmf"  );
        [weakSelf onAudioDTMF:data emitter:emitter];
    }];
    
    // TODO: customEvent
    [self.socket onPrefix:kNXMEventCustom callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("Socket kNXMEventCustom"  );
        [weakSelf onCustomEvent:event data:data emitter:emitter];
    }];
}
- (void)subscribeSipEvents{
    __weak NXMSocketClient *weakSelf = self;

    [self.socket on:kNXMSocketEventSipRinging callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("Socket kNXMSocketEventSipRinging"  );
        [weakSelf onSipRinging:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventSipAnswered callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("Socket kNXMSocketEventSipAnswered"  );
        [weakSelf onSipAnswered:data emitter:emitter];
    }];

    [self.socket on:kNXMSocketEventSipHangup callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("Socket kNXMSocketEventSipHangup"  );
        [weakSelf onSipHangup:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventSipStatus callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         NXM_LOG_DEBUG("Socket kNXMSocketEventSipStatus"  );
        [weakSelf onSipStatus:data emitter:emitter];
    }];
}

- (void)subscribeLegStatusEvents{
    __weak NXMSocketClient *weakSelf = self;
    
    [self.socket on:kNXMSocketEventLegStatus callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        NXM_LOG_DEBUG("Socket kNXMSocketEventSipRinging");
        [weakSelf onLegStatus:data emitter:emitter];
    }];
}



#pragma mark - Socket Events

+ (NXMEvent *)onConversationEvent:(NSString *)eventName data:(NSDictionary *)data {
    return [NXMEventCreator createEvent:eventName data:data];
}

#pragma mark members
- (void)onMemberJoined:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMMemberEvent *memberEvent = (NXMMemberEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventMemberJoined data:data[0]];

    [self.delegate memberJoined:memberEvent];
}

- (void)onMemberInvited:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMMemberEvent *memberEvent = (NXMMemberEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventMemberInvited data:data[0]];
    
    [self.delegate memberInvited:memberEvent];
}

- (void)onMemberLeft:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMMemberEvent *memberEvent = (NXMMemberEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventMemberLeft data:data[0]];
    [self.delegate memberRemoved:memberEvent];
}


#pragma mark messages

- (void)onCustomEvent:(NSString *)event data:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMCustomEvent *customEvent = (NXMCustomEvent *)[NXMSocketClient onConversationEvent:kNXMEventCustom data:data[0]];
    [self.delegate customEvent:customEvent];
}

- (void)onTextRecevied:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMTextEvent *textEvent = (NXMTextEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventText data:data[0]];
    [self.delegate textRecieved:textEvent];
}

- (void)onImageRecevied:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMImageEvent *imageEvent = (NXMImageEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventImage data:data[0]];
    [self.delegate imageRecieved:imageEvent];
    
}

- (void)onMessageDeleted:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMMessageStatusEvent *messageEvent = (NXMMessageStatusEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventMessageDelete data:data[0]];

    [self.delegate messageDeleted:messageEvent];
}

- (void)onTextSeen:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMMessageStatusEvent *messageEvent = (NXMMessageStatusEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventTextSeen data:data[0]];
    [self.delegate textSeen:messageEvent];
}

- (void)onTextDelivered:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMMessageStatusEvent *messageEvent = (NXMMessageStatusEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventTextDelivered data:data[0]];
    [self.delegate textDelivered:messageEvent];
}

- (void)onImageSeen:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMMessageStatusEvent *messageEvent = (NXMMessageStatusEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventImageSeen data:data[0]];
    [self.delegate imageSeen:messageEvent];
}

- (void)onImageDelivered:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMMessageStatusEvent *messageEvent = (NXMMessageStatusEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventImageDelivered data:data[0]];
    [self.delegate imageDelivered:messageEvent];
}

#pragma mark typing
- (void)onTextTypingOn:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMTextTypingEvent *textTypingEvent = (NXMTextTypingEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventTypingOn data:data[0]];
    [self.delegate textTypingOn:textTypingEvent];
}

- (void)onTextTypingOff:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMTextTypingEvent *textTypingEvent = (NXMTextTypingEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventTypingOff data:data[0]];
    [self.delegate textTypingOff:textTypingEvent];
}
#pragma mark media sip

- (void)onSipRinging:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMSipEvent *sipEvent = (NXMSipEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventSipRinging data:data[0]];
    [self.delegate sipRinging:sipEvent];
}
- (void)onSipAnswered:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMSipEvent *sipEvent = (NXMSipEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventSipAnswered data:data[0]];
    [self.delegate sipAnswered:sipEvent];
}
- (void)onSipHangup:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMSipEvent *sipEvent = (NXMSipEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventSipHangup data:data[0]];
    [self.delegate sipHangup:sipEvent];
}

- (void)onSipStatus:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMSipEvent *sipEvent = (NXMSipEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventSipStatus data:data[0]];
    [self.delegate sipStatus:sipEvent];
}

- (void)onLegStatus:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMLegStatusEvent * legStatusEvent = (NXMLegStatusEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventLegStatus data:data[0]];
    [self.delegate legStatus:legStatusEvent];
}

#pragma mark media rtc

- (void)onRTCAnswer:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NSDictionary *json = data[0];
    
    NXMRtcAnswerEvent *mediaEvent = [NXMRtcAnswerEvent new];
    mediaEvent.conversationId = json[@"cid"];
    mediaEvent.sessionId = json[@"session_destination"];
    mediaEvent.timestamp = json[@"timestamp"];
    mediaEvent.sdp = json[@"body"][@"answer"];
    mediaEvent.rtcId = json[@"body"][@"rtc_id"];
    
    [self.delegate rtcAnswerEvent:mediaEvent];
}


- (void)onRTCTerminate:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    // TODO:
    // should we use it? should we use member media?
    //    {
    //        "timestamp": 1525248500583,
    //        "type": "rtc:terminate",
    //        "payload": {
    //            "cid": "CON-b2b067e6-ef07-45e5-a9f3-138e66373359",
    //            "from": "MEM-164379b3-a819-4964-99a0-bfaed993d739",
    //            "rtc_id": "70bbf7bc-c2fc-4f51-9946-d974b2fc521a"
    //        },
    //        "direction": "emitted"
    //    }
}

- (void)onRTCMemberMedia:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMMediaEvent * mediaEvent = (NXMMediaEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventMemebrMedia data:data[0]];
    [self.delegate mediaEvent:mediaEvent];
}

- (void)onRTCAudioMuteOn:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMMediaEvent* event = (NXMMediaEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventAudioMuteOn data:data[0]];
    [self.delegate mediaEvent:event];
}

- (void)onRTCAudioMuteOff:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMMediaEvent* event = (NXMMediaEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventAudioMuteOff data:data[0]];
    [self.delegate mediaEvent:event];
}

- (void)onAudioDTMF:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    NXM_LOG_DEBUG([data.description UTF8String]);
    
    NXMDTMFEvent *event = (NXMDTMFEvent *)[NXMSocketClient onConversationEvent:kNXMSocketEventAudioDtmf data:data[0]];
    [self.delegate DTMFEvent:event];
}

@end
