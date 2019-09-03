//
//  NXMCallMember.m
//  NexmoClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMCallMember.h"
#import "NXMCallProxy.h"
#import "NXMMember.h"
#import "NXMCoreEvents.h"
#import "NXMLegPrivate.h"
#import "NXMChannelPrivate.h"
#import "NXMLoggerInternal.h"

@interface NXMCallMember()

@property (nonatomic, readwrite) NXMMember *member;
@property (nonatomic, readwrite) NXMCallMemberStatus currentStatus;
@property (nonatomic, readwrite) BOOL isMuted;

@property (nonatomic, readwrite, weak) id<NXMCallProxy> callProxy;

@end

@implementation NXMCallMember

- (nullable instancetype)initWithMember:(NXMMember *)member andCallProxy:(id<NXMCallProxy>)callProxy {
    if (self = [self init]) {
        self.member = member;
        self.callProxy = callProxy;
        self.currentStatus = [self status];
        self.isMuted = member.media.isSuspended;
    }
    
    return self;
}

#pragma public

- (NSString *)memberId {
    return self.member.memberId;
}

- (NXMUser *)user {
    return self.member.user;
}

- (NXMChannel *)channel {
    return self.member.channel;
}


- (NXMCallMemberStatus)status {
    switch (self.channel.leg.legStatus) {
        case NXMLegStatusCalling:
            return NXMCallMemberStatusRinging;
        case NXMLegStatusStarted:
            return NXMCallMemberStatusStarted;
        case NXMLegStatusAnswered:
            return NXMCallMemberStatusAnswered;
        case NXMLegStatusCompleted:
            return NXMCallMemberStatusCompleted;
        default:
            break;
    }
    
    return NXMCallMemberStatusRinging;
}

- (NSString *)statusDescription {
    switch (self.status) {

        case NXMCallMemberStatusRinging:
            return @"Calling";
        case NXMCallMemberStatusStarted:
            return @"Started";
        case NXMCallMemberStatusAnswered:
            return @"Answered";
        case NXMCallMemberStatusCompleted:
            return @"Completed";
        default:
            return @"Unknown";
    }
}

- (void)hangup {
    [self.callProxy hangup:self];
}

- (void)hold:(BOOL)isHold {
    [self.callProxy hold:self isHold:isHold];
}

- (void)mute:(BOOL)isMute {
    [self.callProxy mute:self isMuted:isMute];
}

- (void)earmuff:(BOOL)isEarmuff {
    [self.callProxy earmuff:self isEarmuff:isEarmuff];
}

#pragma private

- (void)memberUpdated {
    LOG_DEBUG([self.description UTF8String]);
    
    if (self.isMuted != self.member.media.isSuspended) {
        self.isMuted = self.member.media.isSuspended;
    }
    
    LOG_DEBUG("NXMCallMember member status prev %ld current %ld", (long)self.currentStatus, (long)self.status);


    if (self.currentStatus != self.status) {
        self.currentStatus = self.status;
    }
    
    // TODO: notify on change
    [self.callProxy onChange:self];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> memberId=%@ user=%@ channel=%@ isMuted=%i statusDescription=%@",
            NSStringFromClass([self class]),
            self,
            self.memberId,
            self.user,
            self.channel,
            self.isMuted,
            self.statusDescription];
}



@end
