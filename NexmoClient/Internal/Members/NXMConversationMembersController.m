//
//  NXMMembersController.m
//  NexmoClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMConversationMembersController.h"

#import "NXMConversation.h"
#import "NXMStitchContext.h"
#import "NXMCoreEvents.h"
#import "NXMMemberPrivate.h"
#import "NXMLoggerInternal.h"
#import "NXMMediaSettingsInternal.h"
#import "NXMEventInternal.h"
#import "NXMMemberEventPrivate.h"


@interface NXMConversationMembersController ()
@property (nonatomic, readwrite, nullable) NXMMember *myMember;
@property (nonatomic, readwrite, nullable) NSMutableDictionary<NSString *, NXMMember *> *membersDictionary;
@property (nonatomic, readwrite, nullable, weak) id <NXMConversationMembersControllerDelegate> delegate;
@property (nonatomic, readwrite, nonnull) NXMConversationDetails *conversationDetails;
@property (nonatomic, readwrite, nullable) NXMUser *currentUser;
@end

@implementation NXMConversationMembersController

#pragma mark - init

- (instancetype)initWithConversationDetails:(nonnull NXMConversationDetails *)conversationDetails
                             andCurrentUser:(nonnull NXMUser *)currentUser
                                   delegate:(id <NXMConversationMembersControllerDelegate> _Nullable)deleagte
{
    self = [super init];
    if (self) {
        self.conversationDetails = conversationDetails;
        self.currentUser = currentUser;
        self.membersDictionary = [NSMutableDictionary new];
        self.delegate = deleagte;
        [self initMembersWithConversationDetails:conversationDetails];
    }
    return self;
}

- (void)initMembersWithConversationDetails:(NXMConversationDetails * _Nonnull)conversationDetails {
    NXM_LOG_DEBUG([conversationDetails.description UTF8String]);

    for (NXMMember *member in conversationDetails.members) {
        if([member.user.uuid isEqualToString:self.currentUser.uuid]) {
            self.myMember = member;
        }
        
        self.membersDictionary[member.memberUuid] = member;
    }
}

#pragma mark - unsynthesized properties
-(NSArray<NXMMember *> *)allMembers {
    return self.membersDictionary.allValues;
}

#pragma mark - public
-(NXMMember *)memberForMemberId:(NSString *)memberId {
    return self.membersDictionary[memberId];
}


#pragma mark - Private Updating Methods
- (void)conversationExpired {
    NXM_LOG_DEBUG("");

    for (NXMMember *member in self.membersDictionary.allValues) {
        [member updateExpired];
        
        [self member:member changedWithType:NXMMemberUpdateTypeLeg];
    }
}

- (void)handleEvent:(NXMEvent *)event {
    NXM_LOG_DEBUG([event.description UTF8String]);
    
    if(self.conversationDetails.sequence_number >= event.uuid) {
        NXM_LOG_ERROR("sequenceId is lower %ld %ld memberId %s %s",
                    self.conversationDetails.sequence_number,
                    event.uuid,
                    [event.fromMemberId UTF8String],
                    [event.description UTF8String]);

        return;
    }
    
    NXM_LOG_DEBUG("%s",[event.description UTF8String]);
   
    switch (event.type) {
        case NXMEventTypeMedia:
        case NXMEventTypeMediaAction:
            [self handleMediaEvent:(NXMMediaEvent *)event];
            break;
        case NXMEventTypeMember: {
            NXMMemberEvent *memberEvent = (NXMMemberEvent *)event;
            [self handleMemberEvent:memberEvent];
            [memberEvent updateMember:self.membersDictionary[memberEvent.memberId]];
            break;
        }
        case NXMEventTypeLegStatus:
            [self handleLegEvent:(NXMLegStatusEvent *)event];
            break;
            
        default:
            break;
    }
    
    NXMMember *member = self.membersDictionary[event.fromMemberId];
    if (member) {
        [event updateFromMember:member];
    }
}

-(void)handleLegEvent:(NXMLegStatusEvent *)legEvent {
    NXM_LOG_DEBUG([legEvent.description UTF8String]);
    
    NXMMember *member = self.membersDictionary[legEvent.current.memberUUid];
    if (!member) {
        NXM_LOG_ERROR("NXMConversationMembersController legEvent member not found %s", [legEvent.description UTF8String]);
        return;
    }
    
    NXM_LOG_DEBUG("member before leg updates %s", [member.description UTF8String]);
    [member updateChannelWithLeg:(NXMLeg *)legEvent.current];
    NXM_LOG_DEBUG("member after leg updates %s", [member.description UTF8String]);

    [self member:member changedWithType:NXMMemberUpdateTypeLeg];
}

-(void)handleMediaEvent:(NXMEvent *)event {
    NXM_LOG_DEBUG([event.description UTF8String]);
    NXMMember *member = self.membersDictionary[event.fromMemberId];
    if (!member) {
        NXM_LOG_ERROR("member not found %s", [event.description UTF8String]);
        return;
    }
    
    if (event.type == NXMEventTypeMedia) {
        NXM_LOG_DEBUG("member before media updates %s", [member.description UTF8String]);

        [member updateMedia:((NXMMediaEvent *)event).mediaSettings];
        NXM_LOG_DEBUG("member after media updates %s", [member.description UTF8String]);

    } else if (event.type == NXMEventTypeMediaAction) {
        NXMMediaSettings *settings = [[NXMMediaSettings alloc] initWithEnabled:member.media.isEnabled
                                                                       suspend:((NXMMediaSuspendEvent *)event).isSuspended];
        [member updateMedia:settings];
    }
    
    [self member:member changedWithType:NXMMemberUpdateTypeMedia];
}

- (void)handleMemberEvent:(NXMMemberEvent *)memberEvent {
    NXM_LOG_DEBUG([memberEvent.description UTF8String]);
    
    NXMMember *member = self.membersDictionary[memberEvent.memberId];
    if(member) {
        NXM_LOG_DEBUG("member before updates %s", [member.description UTF8String]);
        [member updateState:memberEvent];
        NXM_LOG_DEBUG("member after updates %s", [member.description UTF8String]);

        [self member:member changedWithType:NXMMemberUpdateTypeState];
        return;
    }
    
    member = [[NXMMember alloc] initWithMemberEvent:memberEvent];
    NXM_LOG_DEBUG("member created %s", [member.description UTF8String]);
    [self addMember:member];
    [self member:member changedWithType:NXMMemberUpdateTypeState];
}

- (void)addMember:(nonnull NXMMember *)member {
    NXM_LOG_DEBUG([member.description UTF8String]);
    self.membersDictionary[member.memberUuid] = member;
    if([member.user.uuid isEqualToString:self.currentUser.uuid]) {
        self.myMember = member;
    }
}

#pragma mark - delegate

-(void)member:(nonnull NXMMember *)member changedWithType:(NXMMemberUpdateType)type {
    if(![NSThread isMainThread]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self member:member changedWithType:type];
        });
        return;
    }
    if([self.delegate respondsToSelector:@selector(nxmConversationMembersController:didChangeMember:forChangeType:)]) {
        [self.delegate nxmConversationMembersController:self didChangeMember:member forChangeType:type];
    }
}

@end
