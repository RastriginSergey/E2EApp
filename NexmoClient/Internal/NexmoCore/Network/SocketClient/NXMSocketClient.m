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

#import "NXMLoggerInternal.h"

#import "NXMErrorsPrivate.h"
#import "NXMCoreEventsPrivate.h"
#import "NXMUserPrivate.h"
#import "NXMLegPrivate.h"

#import "NXMUtils.h"
#import "NXMImageInfoInternal.h"




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
    LOG_DEBUG("");

    //TODO: question - what happens if we try to log in while already logged in to the server for example after a reconnect?
    [self serverLogin];
}

- (void)didSocketDisconnect {
    [self updateConnetionStatus:NXMConnectionStatusDisconnected reason:NXMConnectionStatusReasonTerminated];
}

- (void)socketDidChangeStatus {
    switch (self.socket.status) {
        case VPSocketIOClientStatusConnected:
            
             LOG_DEBUG("socket connected"  );
            [self socketDidConnect];
            break;
        case VPSocketIOClientStatusNotConnected:
             LOG_DEBUG("socket not connected"  );
            [self didSocketDisconnect];
            break;
        case VPSocketIOClientStatusDisconnected:
             LOG_DEBUG("socket disconnected"  );
            [self didSocketDisconnect];
            break;
        case VPSocketIOClientStatusConnecting: //TODO: support reporting reconnect? or keep it boolean
             LOG_DEBUG("socket connecting"  );
            [self updateConnetionStatus:NXMConnectionStatusConnecting reason:NXMConnectionStatusReasonUnknown];
            break;
        case VPSocketIOClientStatusOpened:
             LOG_DEBUG("socket opened"  );
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
     LOG_DEBUG("did server logout"  );
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
        LOG_ERROR([kSocketEventError UTF8String]);
    }];
}

- (void)subscribeGeneralEvents {
    __weak NXMSocketClient *weakSelf = self;
    
    [self.socket on:kNXMSocketEventBadPermission callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        LOG_ERROR("socket kNXMSocketEventBadPermission");
        [weakSelf.delegate onError:NXMErrorCodeEventBadPermission];
    }];

    [self.socket on:kNXMSocketEventInvalidEvent callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        LOG_ERROR("socket kNXMSocketEventInvalidEvent"  );
    }];
    
    [self.socket on:kNXMSocketEventUserNotFound callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        LOG_ERROR("socket kNXMSocketEventUserNotFound"  );
        [weakSelf didFailLoginWithError:NXMErrorCodeUserNotFound];
    }];
}

- (void)subscribeLoginEvents {
    __weak NXMSocketClient *weakSelf = self;

    [self.socket on:kNXMSocketEventLoginSuccess callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("$$--------Socket Login Success-------------$$");
        [weakSelf didServerLoginWithData:data];
    }];
    
    [self.socket on:kNXMSocketEventSessionLogoutSuccess callback:^(NSString *event, NSArray *array, VPSocketAckEmitter *emitter) {
        LOG_DEBUG("$$--------Socket Session Logout--------$$");
        [weakSelf didServerLogout];
    }];
    
    [self.socket on:kNXMSocketEventSessionTerminated callback:^(NSString *event, NSArray *array, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("$$--------Socket Session Terminated--------$$");
        [weakSelf didServerLogout];
    }];
    
    [self.socket on:kNXMSocketEventSessionInvalid callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        LOG_ERROR("socket kNXMSocketEventSessionInvalid"  );
        [weakSelf didFailLoginWithError:NXMErrorCodeSessionInvalid];
    }];
    
    [self.socket on:kNXMSocketEventSessionErrorInvalid callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        LOG_ERROR("socket kNXMSocketEventSessionErrorInvalid"  );
        [weakSelf didFailLoginWithError:NXMErrorCodeSessionInvalid];
    }];
    
    [self.socket on:kNXMSocketEventMaxOpenedSessions callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        LOG_ERROR("socket kNXMSocketEventMaxOpenedSessions"  );
        [weakSelf didFailLoginWithError:NXMErrorCodeMaxOpenedSessions];
    }];
    
    [self.socket on:kNXMSocketEventInvalidToken callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        LOG_ERROR("socket kNXMSocketEventInvalidToken"  );
        [weakSelf didFailLoginWithError:NXMErrorCodeTokenInvalid]; //TODO: check if this might happen without meaning a logout
    }];
    
    [self.socket on:kNXMSocketEventExpiredToken callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        LOG_ERROR("socket kNXMSocketEventExpiredToken"  );
        [weakSelf didFailLoginWithError:NXMErrorCodeTokenExpired]; //TODO: check if this might happen without meaning a logout
    }];
    
    [self.socket on:kNXMSocketEventRefreshTokenDone callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("socket kNXMSocketEventRefreshTokenDone"  );
        [weakSelf.delegate connectionStatusChanged:NXMConnectionStatusConnected reason:NXMConnectionStatusReasonTokenRefreshed];
    }];
}

- (void)subscribeMemberEvents {
    __weak NXMSocketClient *weakSelf = self;

    [self.socket on:kNXMSocketEventMemberJoined callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("socket kNXMSocketEventMemberJoined"  );
        [weakSelf onMemberJoined:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventMemberInvited callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("socket kNXMSocketEventMemberInvited"  );
        [weakSelf onMemberInvited:data emitter:emitter];
    }];
    
    
    [self.socket on:kNXMSocketEventMemberLeft callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("socket kNXMSocketEventMemberLeft"  );
        [weakSelf onMemberLeft:data emitter:emitter];
    }];
}

- (void)subscribeTextEvents {
    __weak NXMSocketClient *weakSelf = self;

    [self.socket on:kNXMSocketEventText callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("socket kNXMSocketEventText"  );
        [weakSelf onTextRecevied:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventTextSuccess callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("socket kNXMSocketEventTextSuccess"  );
     //   [weakSelf onTextRecevied:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventMessageDelete callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("socket kNXMSocketEventTextDelete"  );
        [weakSelf onMessageDeleted:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventTextSeen callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("socket kNXMSocketEventTextSeen"  );
        [weakSelf onTextSeen:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventTextDelivered callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("socket kNXMSocketEventTextDelivered"  );
        [weakSelf onTextDelivered:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventImage callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("socket kNXMSocketEventImage"  );
        [weakSelf onImageRecevied:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventImageSeen callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("socket kNXMSocketEventImageSeen"  );
        [weakSelf onImageSeen:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventImageDelivered callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("socket kNXMSocketEventImageDelivered"  );
        [weakSelf onImageDelivered:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventTypingOn callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("socket kNXMSocketEventTypingOn"  );
        [weakSelf onTextTypingOn:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventTypingOff callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("socket kNXMSocketEventTypingOff"  );
        [weakSelf onTextTypingOff:data emitter:emitter];
    }];
}

- (void)subscribeRTCEvents {
    __weak NXMSocketClient *weakSelf = self;

    [self.socket on:kNXMSocketEventRtcAnswer callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("socket kNXMSocketEventRtcAnswer"  );
        [weakSelf onRTCAnswer:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventMemebrMedia callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("Socket kNXMSocketEventMemebrMedia"  );
        [weakSelf onRTCMemberMedia:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventAudioMuteOn callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("Socket kNXMSocketEventAudioMuteOn"  );
        [weakSelf onRTCAudioMuteOn:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventAudioMuteOff callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("Socket kNXMSocketEventAudioMuteOff"  );
        [weakSelf onRTCAudioMuteOff:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventAudioDtmf callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("Socket kNXMSocketEventAudioDtmf"  );
        [weakSelf onAudioDTMF:data emitter:emitter];
    }];
    
    // TODO: customEvent
    [self.socket onPrefix:kNXMEventCustom callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("Socket kNXMEventCustom"  );
        [weakSelf onCustomEvent:event data:data emitter:emitter];
    }];
}
- (void)subscribeSipEvents{
    __weak NXMSocketClient *weakSelf = self;

    [self.socket on:kNXMSocketEventSipRinging callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("Socket kNXMSocketEventSipRinging"  );
        [weakSelf onSipRinging:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventSipAnswered callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("Socket kNXMSocketEventSipAnswered"  );
        [weakSelf onSipAnswered:data emitter:emitter];
    }];

    [self.socket on:kNXMSocketEventSipHangup callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("Socket kNXMSocketEventSipHangup"  );
        [weakSelf onSipHangup:data emitter:emitter];
    }];
    
    [self.socket on:kNXMSocketEventSipStatus callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
         LOG_DEBUG("Socket kNXMSocketEventSipStatus"  );
        [weakSelf onSipStatus:data emitter:emitter];
    }];
}

- (void)subscribeLegStatusEvents{
    __weak NXMSocketClient *weakSelf = self;
    
    [self.socket on:kNXMSocketEventLegStatus callback:^(NSString *event, NSArray *data, VPSocketAckEmitter *emitter) {
        LOG_DEBUG("Socket kNXMSocketEventSipRinging");
        [weakSelf onLegStatus:data emitter:emitter];
    }];
}



#pragma mark - Socket Events

#pragma mark members
- (void)onMemberJoined:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    
    NSDictionary *json = data[0];
    NXMMemberEvent *memberEvent = [[NXMMemberEvent alloc] initWithConversationId:json[@"cid"]
                                                                      sequenceId:[json[@"id"] integerValue]
                                                                        andState:NXMMemberStateJoined
                                                                 clientRef:json[@"client_ref"]
                                                                         andData:json[@"body"]
                                                                    creationDate:[NXMUtils dateFromISOString:json[@"timestamp"]]
                                                                        memberId:json[@"from"]];
    
    //    memberEvent.joinDate = json[@"body"][@"timestamp"][@"joined"]; // TODO: NSDate
    [self.delegate memberJoined:memberEvent];
}

- (void)onMemberInvited:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    
    NSDictionary *json = data[0];
    NXMMemberEvent *memberEvent = [[NXMMemberEvent alloc] initWithConversationId:json[@"cid"]
                                                                      sequenceId:[json[@"id"] integerValue]
                                                                        andState:NXMMemberStateInvited
                                                                 clientRef:json[@"client_ref"]
                                                                         andData:json[@"body"]
                                                                    creationDate:[NXMUtils dateFromISOString:json[@"timestamp"]]
                                                                        memberId:json[@"from"]];
    
    [self.delegate memberInvited:memberEvent];
}

- (void)onMemberLeft:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    
    NSDictionary *json = data[0];
    NXMMemberEvent *memberEvent = [[NXMMemberEvent alloc] initWithConversationId:json[@"cid"]
                                                                      sequenceId:[json[@"id"] integerValue]
                                                                        andState:NXMMemberStateLeft
                                                                clientRef:json[@"client_ref"]
                                                                         andData:json[@"body"]
                                                                    creationDate:[NXMUtils dateFromISOString:json[@"timestamp"]]
                                                                        memberId:json[@"from"]];
    
    [self.delegate memberRemoved:memberEvent];
}


#pragma mark messages

- (void)onCustomEvent:(NSString *)event data:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    
    NSDictionary *json = data[0];
    
    NXMCustomEvent *customEvent = [[NXMCustomEvent alloc] initWithCustomType:[event substringFromIndex:[kNXMEventCustom length] + 1]
                                                                     andData:json];
    
    [self.delegate customEvent:customEvent];
    
}

- (void)onTextRecevied:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    
    NSDictionary *json = data[0];
    
    NXMTextEvent *textEvent = [NXMTextEvent new];
    textEvent.text = json[@"body"][@"text"];
    textEvent.conversationUuid = json[@"cid"];
    textEvent.fromMemberId = json[@"from"];
    textEvent.creationDate = [NXMUtils dateFromISOString:json[@"timestamp"]];
    textEvent.uuid = [json[@"id"] integerValue];
    textEvent.type = NXMEventTypeText;
    
    [self.delegate textRecieved:textEvent];
    
}

- (void)onImageRecevied:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    
    NSDictionary *json = data[0];
    
    NXMImageEvent *imageEvent = [[NXMImageEvent alloc] initWithConversationId:json[@"cid"]
                                                                   sequenceId:[json[@"id"] integerValue]
                                                                 fromMemberId:json[@"from"]
                                                                 creationDate:[NXMUtils dateFromISOString:json[@"timestamp"]]
                                                                         type:NXMEventTypeImage];
    NSDictionary *body = json[@"body"];
    imageEvent.imageUuid = body[@"id"];
    NSDictionary *originalJSON = body[@"original"];
    imageEvent.originalImage = [[NXMImageInfo alloc] initWithId:originalJSON[@"id"]
                                                             size:[originalJSON[@"size"] integerValue]
                                                              url:originalJSON[@"url"]
                                                             type:NXMImageSizeOriginal];
    
    NSDictionary *mediumJSON = body[@"medium"];
    imageEvent.mediumImage = [[NXMImageInfo alloc] initWithId:mediumJSON[@"id"]
                                                           size:[mediumJSON[@"size"] integerValue]
                                                            url:mediumJSON[@"url"]
                                                           type:NXMImageSizeMedium];
    
    
    NSDictionary *thumbnailJSON = body[@"thumbnail"];
    imageEvent.thumbnailImage = [[NXMImageInfo alloc] initWithId:thumbnailJSON[@"id"]
                                                              size:[thumbnailJSON[@"size"] integerValue]
                                                               url:thumbnailJSON[@"url"]
                                                              type:NXMImageSizeThumbnail];
    
    
    [self.delegate imageRecieved:imageEvent];
    
}

- (void)onMessageDeleted:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    
    NSDictionary *json = data[0];
    
    NXMMessageStatusEvent *messageEvent = [NXMMessageStatusEvent new];
    messageEvent.uuid = [json[@"body"][@"event_id"] integerValue];
    messageEvent.conversationUuid = json[@"cid"];
    messageEvent.fromMemberId = json[@"from"];
    messageEvent.creationDate = [NXMUtils dateFromISOString:json[@"timestamp"]];
    messageEvent.referenceEventUuid = [json[@"id"] integerValue];
    messageEvent.status = NXMMessageStatusTypeDeleted;
    messageEvent.type = NXMEventTypeMessageStatus;
    
    [self.delegate messageDeleted:messageEvent];
}

- (void)onTextSeen:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    
    NSDictionary *json = data[0];
    NXMMessageStatusEvent *statusEvent = [NXMMessageStatusEvent new];
    statusEvent.uuid = [json[@"body"][@"event_id"] integerValue];
    statusEvent.conversationUuid = json[@"cid"];
    statusEvent.fromMemberId = json[@"from"];
    statusEvent.creationDate = [NXMUtils dateFromISOString:json[@"timestamp"]];
    statusEvent.referenceEventUuid = [json[@"id"] integerValue];
    statusEvent.status = NXMMessageStatusTypeSeen;
    statusEvent.type = NXMEventTypeMessageStatus;
    
    [self.delegate textSeen:statusEvent];
}

- (void)onTextDelivered:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    
    NSDictionary *json = data[0];
    NXMMessageStatusEvent *statusEvent = [NXMMessageStatusEvent new];
    statusEvent.uuid = [json[@"body"][@"event_id"] integerValue];
    statusEvent.conversationUuid = json[@"cid"];
    statusEvent.fromMemberId = json[@"from"];
    statusEvent.creationDate = [NXMUtils dateFromISOString:json[@"timestamp"]];
    statusEvent.referenceEventUuid = [json[@"id"] integerValue];
    statusEvent.status = NXMMessageStatusTypeDelivered;
    statusEvent.type = NXMEventTypeMessageStatus;
    
    [self.delegate textDelivered:statusEvent];
    
}

- (void)onImageSeen:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    
    NSDictionary *json = data[0];
    NXMMessageStatusEvent *statusEvent = [NXMMessageStatusEvent new];
    statusEvent.uuid = [json[@"body"][@"event_id"] integerValue];
    statusEvent.conversationUuid = json[@"cid"];
    statusEvent.fromMemberId = json[@"from"];
    statusEvent.creationDate = [NXMUtils dateFromISOString:json[@"timestamp"]];
    statusEvent.referenceEventUuid = [json[@"id"] integerValue];
    statusEvent.status = NXMMessageStatusTypeSeen;
    statusEvent.type = NXMEventTypeMessageStatus;
    
    [self.delegate imageSeen:statusEvent];
}

- (void)onImageDelivered:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    
    NSDictionary *json = data[0];
    NXMMessageStatusEvent *statusEvent = [NXMMessageStatusEvent new];
    statusEvent.uuid = [json[@"body"][@"event_id"] integerValue];
    statusEvent.conversationUuid = json[@"cid"];
    statusEvent.fromMemberId = json[@"from"];
    statusEvent.creationDate = [NXMUtils dateFromISOString:json[@"timestamp"]];
    statusEvent.referenceEventUuid = [json[@"id"] integerValue];
    statusEvent.status = NXMMessageStatusTypeDelivered;
    statusEvent.type = NXMEventTypeMessageStatus;
    
    [self.delegate imageDelivered:statusEvent];
}

#pragma mark typing
- (void)onTextTypingOn:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    NSDictionary *json = data[0];
    
    NXMTextTypingEvent *textTypingEvent = [NXMTextTypingEvent new];
    textTypingEvent.conversationUuid = json[@"cid"];
    textTypingEvent.fromMemberId = json[@"from"];
    textTypingEvent.creationDate = [NXMUtils dateFromISOString:json[@"timestamp"]];
    textTypingEvent.uuid = [json[@"id"] integerValue];
    textTypingEvent.status = NXMTextTypingEventStatusOn;
    textTypingEvent.type = NXMEventTypeTextTyping;
    
    [self.delegate textTypingOn:textTypingEvent];
}

- (void)onTextTypingOff:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    NSDictionary *json = data[0];
    
    NXMTextTypingEvent *textTypingEvent = [NXMTextTypingEvent new];
    textTypingEvent.conversationUuid = json[@"cid"];
    textTypingEvent.fromMemberId = json[@"from"];
    textTypingEvent.creationDate = [NXMUtils dateFromISOString:json[@"timestamp"]];
    textTypingEvent.uuid = [json[@"id"] integerValue];
    textTypingEvent.status = NXMTextTypingEventStatusOff;
    textTypingEvent.type = NXMEventTypeTextTyping;
    
    [self.delegate textTypingOff:textTypingEvent];
}
#pragma mark media sip

- (void)onSipRinging:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    NSDictionary *json = data[0];
    NXMSipEvent * sipEvent = [self fillSipEventFromJson:json];
    sipEvent.status = NXMSipEventRinging;
    
    [self.delegate sipRinging:sipEvent];
}
- (void)onSipAnswered:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    NSDictionary *json = data[0];
    NXMSipEvent * sipEvent = [self fillSipEventFromJson:json];
    sipEvent.status = NXMSipEventAnswered;
    
    [self.delegate sipAnswered:sipEvent];
}
- (void)onSipHangup:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    NSDictionary *json = data[0];
    NXMSipEvent * sipEvent = [self fillSipEventFromJson:json];
    sipEvent.status = NXMSipEventHangup;
    
    [self.delegate sipHangup:sipEvent];
}
- (void)onSipStatus:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    NSDictionary *json = data[0];
    NXMSipEvent * sipEvent = [self fillSipEventFromJson:json];
    sipEvent.status = NXMSipEventStatus;
    
    [self.delegate sipStatus:sipEvent];
}

- (void)onLegStatus:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    NSDictionary *json = data[0];
    
    NXMLegStatusEvent * legStatusEvent= [[NXMLegStatusEvent alloc]
                                         initWithConversationId:json[@"cid"]
                                         andData:json];
    
    [self.delegate legStatus:legStatusEvent];
}

- (NXMSipEvent*) fillSipEventFromJson:(NSDictionary*) json{
    NXMSipEvent * sipEvent= [NXMSipEvent new];
    sipEvent.fromMemberId = json[@"from"];
    sipEvent.uuid = [json[@"id"] integerValue];
    sipEvent.conversationUuid = json[@"cid"];
    sipEvent.phoneNumber = json[@"body"][@"channel"][@"to"][@"number"];
    sipEvent.applicationId = json[@"application_id"];
    sipEvent.type = NXMEventTypeSip;
    return sipEvent;
}
#pragma mark media rtc

- (void)onRTCAnswer:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    
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
    LOG_DEBUG([data.description UTF8String]);
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
    LOG_DEBUG([data.description UTF8String]);
    NSDictionary *json = data[0];
    
    NXMMediaEvent *mediaEvent = [NXMMediaEvent new];
    mediaEvent.conversationUuid = json[@"cid"];
    mediaEvent.fromMemberId = json[@"from"];
    mediaEvent.creationDate = [NXMUtils dateFromISOString:json[@"timestamp"]];
    mediaEvent.uuid = [json[@"id"] integerValue];
    mediaEvent.mediaSettings = [NXMMediaSettings new];
    mediaEvent.mediaSettings.isEnabled = [json[@"body"][@"media"][@"audio_settings"][@"enabled"] boolValue];
    mediaEvent.mediaSettings.isSuspended = [json[@"body"][@"media"][@"audio_settings"][@"muted"] boolValue];
    mediaEvent.type = NXMEventTypeMedia;
    
    [self.delegate mediaEvent:mediaEvent];
}

- (void)onRTCAudioMuteOn:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    NSDictionary *json = data[0];
    
    NXMMediaSuspendEvent *mediaEvent = [NXMMediaSuspendEvent new];
    mediaEvent.toMemberUuid = json[@"to"];
    mediaEvent.conversationUuid = json[@"cid"];
    mediaEvent.fromMemberId = json[@"from"];
    mediaEvent.creationDate = [NXMUtils dateFromISOString:json[@"timestamp"]];
    mediaEvent.uuid = [json[@"id"] integerValue];
    mediaEvent.type = NXMEventTypeMediaAction;
    mediaEvent.actionType = NXMMediaActionTypeSuspend;
    mediaEvent.mediaType = NXMMediaTypeAudio;
    mediaEvent.isSuspended = true;
    
    [self.delegate mediaActionEvent:mediaEvent];
}

- (void)onRTCAudioMuteOff:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    NSDictionary *json = data[0];
    
    NXMMediaSuspendEvent *mediaEvent = [NXMMediaSuspendEvent new];
    mediaEvent.toMemberUuid = json[@"to"];
    mediaEvent.conversationUuid = json[@"cid"];
    mediaEvent.fromMemberId = json[@"from"];
    mediaEvent.creationDate = [NXMUtils dateFromISOString:json[@"timestamp"]];
    mediaEvent.uuid = [json[@"id"] integerValue];
    mediaEvent.type = NXMEventTypeMediaAction;
    mediaEvent.actionType = NXMMediaActionTypeSuspend;
    mediaEvent.mediaType = NXMMediaTypeAudio;
    mediaEvent.isSuspended = false;
    
    [self.delegate mediaActionEvent:mediaEvent];
}

- (void)onAudioDTMF:(NSArray *)data emitter:(VPSocketAckEmitter *)emitter {
    LOG_DEBUG([data.description UTF8String]);
    NSDictionary *json = data[0];
    
    NXMDTMFEvent *event = [[NXMDTMFEvent alloc] initWithDigit:json[@"body"][@"digit"]
                                                   andDuration:[NSNumber numberWithInteger:[json[@"body"][@"duration"] integerValue]]];
    event.conversationUuid = json[@"cid"];
    event.fromMemberId = json[@"from"];
    event.creationDate = [NXMUtils dateFromISOString:json[@"timestamp"]];
    event.uuid = [json[@"id"] integerValue];
    event.type = NXMEventTypeDTMF;
    
    [self.delegate DTMFEvent:event];
}

@end
