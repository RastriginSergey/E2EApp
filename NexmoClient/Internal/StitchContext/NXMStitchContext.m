//
//  NXMStitchContext.m
//  StitchClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMStitchContext.h"
#import "NXMCoreEvents.h"

@interface NXMStitchContext()
@property (readwrite, nonnull, nonatomic) NXMCore *coreClient;
@property (readwrite, nonnull, nonatomic) NXMEventsDispatcher *eventsDispatcher;
@property (readwrite, weak, nonatomic) NSObject<NXMStitchContextDelegate> *stitchContextDelegate;

@end

@implementation NXMStitchContext

-(instancetype)initWithCoreClient:(NXMCore *)coreClient{
    if(self = [super init]) {
        self.coreClient = coreClient;
        [self.coreClient setDelgate:self];
        self.eventsDispatcher = [NXMEventsDispatcher new];
    }
    return self;
}

-(NXMUser *)currentUser {
    return self.coreClient.user;
}

-(void)setDelegate:(NSObject<NXMStitchContextDelegate> *)stitchContextDelegate {
    self.stitchContextDelegate = stitchContextDelegate;
}

- (void)imageDelivered:(nonnull NXMMessageStatusEvent *)statusEvent {
    [self.eventsDispatcher imageDelivered:statusEvent];
}

- (void)imageRecieved:(nonnull NXMImageEvent *)imageEvent {
    [self.eventsDispatcher imageRecieved:imageEvent];
}

- (void)imageSeen:(nonnull NXMMessageStatusEvent *)statusEvent {
    [self.eventsDispatcher  imageSeen:statusEvent];
}

- (void)informOnMedia:(nonnull NXMMediaEvent *)mediaEvent {
    [self.eventsDispatcher informOnMedia:mediaEvent];
}

- (void)localInformOnMedia:(nonnull NXMMediaEvent *)mediaEvent {
    [self.eventsDispatcher localInformOnMedia:mediaEvent];
}

- (void)memberInvited:(nonnull NXMMemberEvent *)memberEvent {
    [self.eventsDispatcher memberInvited:memberEvent];
}

- (void)memberJoined:(nonnull NXMMemberEvent *)memberEvent {
    [self.eventsDispatcher memberJoined:memberEvent];
}

- (void)memberRemoved:(nonnull NXMMemberEvent *)memberEvent {
    [self.eventsDispatcher memberRemoved:memberEvent];
}

- (void)messageDeleted:(nonnull NXMMessageStatusEvent *)statusEvent {
    [self.eventsDispatcher messageDeleted:statusEvent];
}

- (void)sipAnswered:(nonnull NXMSipEvent *)sipEvent {
    [self.eventsDispatcher sipAnswered:sipEvent];
}

- (void)sipHangup:(nonnull NXMSipEvent *)sipEvent {
    [self.eventsDispatcher sipHangup:sipEvent];
}

- (void)sipRinging:(nonnull NXMSipEvent *)sipEvent {
    [self.eventsDispatcher sipRinging:sipEvent];
}

- (void)sipStatus:(nonnull NXMSipEvent *)sipEvent {
    [self.eventsDispatcher sipStatus:sipEvent];
}

- (void)textDelivered:(nonnull NXMMessageStatusEvent *)statusEvent {
    [self.eventsDispatcher textDelivered:statusEvent];
}

- (void)textRecieved:(nonnull NXMTextEvent *)textEvent {
    [self.eventsDispatcher textRecieved:textEvent];
}

- (void)textSeen:(nonnull NXMMessageStatusEvent *)statusEvent {
    [self.eventsDispatcher textSeen:statusEvent];
}

- (void)textTypingOff:(nonnull NXMTextTypingEvent *)textTypingEvent {
    [self.eventsDispatcher textTypingOff:textTypingEvent];
}

- (void)textTypingOn:(nonnull NXMTextTypingEvent *)textTypingEvent {
    [self.eventsDispatcher textTypingOn:textTypingEvent];
}

- (void)DTMFEvent:(nonnull NXMDTMFEvent *)dtmfEvent {
    [self.eventsDispatcher DTMFEvent:dtmfEvent];
}

- (void)legStatus:(NXMLegStatusEvent *)legEvent {
    [self.eventsDispatcher legStatus:legEvent];
}

- (void)connectionStatusChanged:(NXMConnectionStatus)status reason:(NXMConnectionStatusReason)reason {
    [self.eventsDispatcher connectionStatusChanged:status reason:reason];
    [self.stitchContextDelegate connectionStatusChanged:status reason:reason];
}

- (void)customEvent:(nonnull NXMCustomEvent *)customEvent {
    [self.eventsDispatcher customEvent:customEvent];
}

- (void)onError:(NXMErrorCode)errorCode {
    [self.stitchContextDelegate onError:errorCode];
}




@end
