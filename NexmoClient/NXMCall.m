//
//  NXMCall.m
//  NexmoClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMCall.h"
#import "NXMCallProxy.h"
#import "NXMErrorsPrivate.h"
#import "NXMStitchContext.h"
#import "NXMConversationEventsQueue.h"
#import "NXMCallMemberPrivate.h"
#import "NXMConversation.h"
#import "NXMConversationPrivate.h"
#import "NXMBlocksHelper.h"
#import "NXMLoggerInternal.h"
#import "NXMMemberPrivate.h"


@interface NXMCall() <NXMCallProxy,NXMConversationDelegate, NXMConversationUpdateDelegate>

@property (readwrite, nonatomic) NXMConversation *conversation;
@property (readwrite, nonatomic) NSMutableArray<NXMCallMember *> *otherCallMembers;
@property (readwrite, nonatomic) NXMCallMember *myCallMember;

@property (readwrite, nonatomic, weak) id<NXMCallDelegate> delegate;
@property (readwrite, nonatomic) NXMConversationEventsQueue *eventsQueue;

@property NSInteger lastEventId;
@property NSObject *membersSyncToken;
@property BOOL pendingToAnswer;
@property NSString *clientRef;
@end

@implementation NXMCall

- (nullable instancetype)initWithConversation:(nonnull NXMConversation *)conversation {
    LOG_DEBUG([conversation.uuid UTF8String]);
    
    if (self = [super init]) {
        self.membersSyncToken = [NSObject new];
        self.lastEventId = conversation.lastEventId;
        self.conversation = conversation;
        self.pendingToAnswer = NO;
        self.otherCallMembers = [[NSMutableArray<NXMCallMember *>  alloc] init];
        
        if (self.conversation.allMembers){
            for (NXMMember *member in self.conversation.allMembers) {
                [self findOrAddCallMember:member];
            }
        }
        
        [conversation setDelegate:self];
        conversation.updatesDelegate = self;
    }
    return self;
}

#pragma mark - public

- (void)setDelegate:(id<NXMCallDelegate>)delegate {
    _delegate = delegate;
}

- (void)answer:(NXMErrorCallback _Nullable)completionHandler {
    LOG_DEBUG("%s clientRef: %s", self.conversation.uuid.UTF8String, self.clientRef.UTF8String);
    
    self.clientRef = [self.conversation joinClientRef:^(NSError * _Nullable error, NXMMember * _Nullable member) {
        if (error{
            [NXMBlocksHelper runWithError:error completion:completionHandler]; // TODO: error;
            return;
        }
        
        [NXMBlocksHelper runWithError:nil completion:completionHandler];
    }];
}

- (void)reject:(NXMErrorCallback _Nullable)completionHandler {
    LOG_DEBUG(self.conversation.uuid.UTF8String);
    
    if (self.myCallMember.status != NXMCallMemberStatusRinging) {
        [NXMBlocksHelper runWithError:[NXMErrors nxmErrorWithErrorCode:NXMErrorCodeUnknown]
                           completion:completionHandler]; // TODO: error;
        return;
    }

    [self.conversation leave:^(NSError * _Nullable error) {
        if (error) {
            [NXMBlocksHelper runWithError:error completion:completionHandler]; // TODO: error;
            return;
        }
        
        [NXMBlocksHelper runWithError:nil completion:completionHandler];
    }];
}

- (void)addCallMemberWithUsername:(NSString *)username completionHandler:(NXMErrorCallback _Nullable)completionHandler {
    LOG_DEBUG("%s username: %s", self.conversation.uuid.UTF8String, username.UTF8String);
    if (username == self.conversation.myMember.user.name){
        
        [NXMBlocksHelper runWithError:[NXMErrors nxmErrorWithErrorCode:NXMErrorCodeUnknown]
                           completion:completionHandler]; // TODO: error;

        return;
    }
    
    if ([self isCallDone]) {
        [NXMBlocksHelper runWithError:[NXMErrors nxmErrorWithErrorCode:NXMErrorCodeUnknown]
                           completion:completionHandler]; // TODO: error;

        return;
    }
    
    [self.conversation inviteMemberWithUsername:username withMedia:YES completion:^(NSError * _Nullable error, NXMMember * _Nullable member) {
        if (member) {
            [NXMBlocksHelper runWithError:nil completion:completionHandler];
            return;
        }
        
        [NXMBlocksHelper runWithError:[NXMErrors nxmErrorWithErrorCode:NXMErrorCodeUnknown]
                           completion:completionHandler]; // TODO: error;
    }];

}

- (void)addCallMemberWithNumber:(NSString *)number completionHandler:(NXMErrorCallback _Nullable)completionHandler {
    LOG_DEBUG("%s username: %s", self.conversation.uuid.UTF8String, number.UTF8String);

    if ([self isCallDone]) {
        
        [NXMBlocksHelper runWithError:[NXMErrors nxmErrorWithErrorCode:NXMErrorCodeUnknown]
                           completion:completionHandler]; // TODO: error;

        return;
    }
    
    [self.conversation inviteToConversationWithPhoneNumber:number completion:^(NSError * _Nullable error, NSString * _Nullable knockingId) {
        if (knockingId){
            //TODO: register the knockingId with the call object
            return;
        }
        
        [NXMBlocksHelper runWithError:[NXMErrors nxmErrorWithErrorCode:NXMErrorCodeUnknown]
                           completion:completionHandler]; // TODO: error;
    }];
}

- (void)sendDTMF:(NSString *)dtmf {
    LOG_DEBUG("%s dtmf: %s", self.conversation.uuid.UTF8String, dtmf.UTF8String);

    if ([self isCallDone]) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.conversation sendDTMF:dtmf completion:^(NSError * _Nullable error) {
        [weakSelf.delegate call:self didReceive:error];
    }];
}

#pragma mark - callProxy

- (void)hangup:(NXMCallMember *)callMember {
    LOG_DEBUG("%s callMember: %s", self.conversation.uuid.UTF8String, callMember.description.UTF8String);

    if (callMember != self.myCallMember) {
        // TODO: error
        return;
    }
    
    [self.conversation disableMedia];
    __weak typeof(self) weakSelf = self;
    [self.conversation kickMemberWithMemberId:callMember.memberId completion:^(NSError * _Nullable error) {
        if (error) {
            LOG_ERROR("hangup kick failed:%s",[error.description UTF8String]);
            [weakSelf.delegate call:self didReceive:error];
        }
    }];
}

- (void)hold:(NXMCallMember *)callMember isHold:(BOOL)isHold {
    
}

- (void)mute:(NXMCallMember *)callMember isMuted:(BOOL)isMuted {
    LOG_DEBUG("%s callmember:%s isMuted:%i", self.conversation.uuid.UTF8String, [callMember.description UTF8String], isMuted);
    if ([self isCallDone]) { return; }
    
    if (![callMember.memberId isEqualToString:self.myCallMember.memberId]) {
        return;
    }
    
    [self.conversation mute:isMuted];
}

- (void)earmuff:(NXMCallMember *)callMember isEarmuff:(BOOL)isEarmuff {
    
}

- (void)hangup {
    LOG_DEBUG(self.conversation.uuid.UTF8String);

    if ([self isCallDone]) { return; }

    [self.myCallMember hangup];
}

#pragma mark - callProxy

- (void)didUpdate:(nonnull NXMCallMember *)callMember status:(NXMCallMemberStatus)status {
    LOG_DEBUG("%s callMemberId:%s %d", self.conversation.uuid.UTF8String, callMember.memberId, status);

    if (callMember == self.myCallMember &&
        callMember.status == NXMCallMemberStatusCompleted) {
        
        __weak typeof(self) weakSelf = self;
        [self.conversation leave:^(NSError * _Nullable error) {
            if (error) {
                [weakSelf.delegate call:self didReceive:error];
            }
        }];
    }
    
    [self.delegate call:self didUpdate:callMember withStatus:status];
}

- (void)didUpdate:(nonnull NXMCallMember *)callMember muted:(BOOL)muted {
    [self.delegate call:self didUpdate:callMember isMuted:muted];
}

#pragma mark - NXMConversationDelegate

- (void)conversation:(nonnull NXMConversation *)conversation
     didUpdateMember:(nonnull NXMMember *)member
            withType:(NXMMemberUpdateType)type {
    LOG_DEBUG("%s member:%s", self.conversation.uuid.UTF8String, member.description.UTF8String);

    NXMCallMember *callMember = [self findOrAddCallMember:member];
    
    if (type == NXMMemberUpdateTypeState &&
        member.state == NXMMemberStateJoined &&
        [callMember isEqual:self.myCallMember] &&
        [self.clientRef isEqualToString:member.clientRef]) {
        [self.conversation enableMedia];
    }

    [callMember memberUpdated];
}

- (void)conversation:(nonnull NXMConversation *)conversation didReceiveDTMFEvent:(nonnull NXMDTMFEvent *)event {
    LOG_DEBUG("%s dtmfEvent:%s", [conversation.uuid UTF8String], [event.digit UTF8String]);
    if ([self.delegate respondsToSelector:@selector(call:didReceive:fromCallMember:)]) {
        [self.delegate call:self
                 didReceive:event.digit
             fromCallMember:[self findCallMember:event.fromMember.memberUuid]];
    }
}


- (void)conversationExpired {
    LOG_DEBUG(self.conversation.uuid.UTF8String);

    [self.myCallMember hangup];
}


#pragma mark - Private Methods

- (BOOL)isCallDone {
    return self.myCallMember.status == NXMCallMemberStatusCompleted;
}

- (NXMCallMember *)findCallMember:(NSString *)memberId {
    if ([memberId isEqualToString:self.myCallMember.memberId]) {
        return self.myCallMember;
    }
    
    for (NXMCallMember *callMember in self.otherCallMembers) {
        if ([callMember.memberId isEqualToString:memberId]) {
            return callMember;
        }
    }
    
    return nil;
}

- (NXMCallMember *)findOrAddCallMember:(NXMMember *)member {
    NXMCallMember *callMember = nil;

    @synchronized (self.membersSyncToken) {
        callMember = [self findCallMember:member.memberUuid];
        if(!callMember) {

            callMember = [[NXMCallMember alloc] initWithMember:member andCallProxy:self];
            if([callMember.user.uuid isEqualToString:self.conversation.currentUser.uuid]) {
                self.myCallMember = callMember;
            } else {
                [self.otherCallMembers addObject:callMember];
            }
        }
    }

    return callMember;
}

- (BOOL)isEventTypeSupported:(NXMEvent *)event {
    return !(event.type == NXMEventTypeMember ||
             event.type == NXMEventTypeMedia);
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> otherCallMembers=%@ myCallMember=%@",
            NSStringFromClass([self class]),
            self,
            self.otherCallMembers,
            self.myCallMember];
}

- (void)conversation:(nonnull NXMConversation *)conversation didReceive:(nonnull NSError *)error {
    if (error.code == NXMErrorCodeConversationExpired) {
        [self conversationExpired];
    }
}

@end
