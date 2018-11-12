//
//  StitchWrapper.m
//  StitchTestApp
//
//  Created by Chen Lev on 5/28/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "ConversationManager.h"

@implementation ConversationManager
@synthesize stitchConversationClient = _stitchConversationClient;
@synthesize connectedUser = _connectedUser;

-(void)setStitchCoreClient:(NXMStitchCore *)stitchCoreClient {
    _stitchConversationClient = stitchCoreClient;
    [_stitchConversationClient setDelgate:self];
}

-(instancetype)initWithStitchCoreClient:(NXMStitchCore *)stitchCoreClient {
    if(self = [super init])
    {
        [self setStitchCoreClient:stitchCoreClient];
        self.conversationIdToMemberId = [NSMutableDictionary new];
        self.ongoingCalls =[OngoingMediaCollection new];
        self.memberIdToName = [NSMutableDictionary<NSString *,NSString *> new];
    }
    return self;
}

+(instancetype)sharedInstance {
    static ConversationManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NXMStitchCore *stitchCoreClient = [NXMStitchCore new];
        sharedInstance = [[ConversationManager alloc] initWithStitchCoreClient:stitchCoreClient];
    });
    return sharedInstance;
}


-(void)addLookupMemberId:(NSString *)memberId forUser:(NSString *)userId inConversation:(NSString *)conversationId {
    [self.conversationIdToMemberId setObject:memberId forKey:conversationId];
}

-(bool)isCurrentUserThisMember:(NSString *)memberId {
    return [_connectedUser.name isEqualToString:[self.memberIdToName objectForKey:memberId]];
}



#pragma mark - StitchDelegate

- (void)actionOnMedia:(nonnull NXMMediaActionEvent *)mediaActionEvent {
    OngoingMedia *media = nil;
    switch (mediaActionEvent.actionType) {
        case NXMMediaActionTypeSuspend://TODO: what happens when another member tells you to mute? should you change your local mute????
            if(media = [self.ongoingCalls getMediaForMember:mediaActionEvent.toMemberId inConversation:mediaActionEvent.conversationId]) {
                if(mediaActionEvent.sequenceId > media.lastSeqNum) {
                    media.suspended = ((NXMMediaSuspendEvent *)mediaActionEvent).isSuspended;
                    media.lastSeqNum = mediaActionEvent.sequenceId;
                }
            }
            break;
            
        default:
            break;
    }
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"mediaActionEvent"
     object:nil userInfo:@{@"media":mediaActionEvent}];
}

- (void)loginStatusChanged:(nullable NXMUser *)user loginStatus:(BOOL)isLoggedIn withError:(nullable NSError *)error; {
    if (user && isLoggedIn) {
        _connectedUser = user;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loginSuccess" object:nil userInfo:@{@"user":user}];
    } else if (!isLoggedIn && user) {
        NSLog(@"User logged out: %@", [user description]) ;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"logout" object:nil userInfo:@{@"user":user}];
        _connectedUser = nil;
    } else if (error){
        _connectedUser = nil;
        NSLog(@"Authentication Error Occured: %@", [error description]);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loginFailure" object:nil userInfo:@{@"error":error}];
    }
}

- (void)imageDelivered:(nonnull NXMMessageStatusEvent *)statusEvent {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"statusEvent"
     object:nil userInfo:@{@"statusEvent":statusEvent}];
}

- (void)imageRecieved:(nonnull NXMImageEvent *)textEvent {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"imageEvent"
     object:nil userInfo:@{@"image":textEvent}];
}

- (void)imageSeen:(nonnull NXMMessageStatusEvent *)statusEvent {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"statusEvent"
     object:nil userInfo:@{@"statusEvent":statusEvent}];
}

- (void)informOnMedia:(nonnull NXMMediaEvent *)mediaEvent { //assuming disabled does not come before enabled - not always true
    if(mediaEvent.mediaSettings.isEnabled) {
        OngoingMedia *media = [[OngoingMedia alloc] initWithMemberId:mediaEvent.fromMemberId andConversationId:mediaEvent.conversationId andSeqNum:mediaEvent.sequenceId];
        media.enabled = mediaEvent.mediaSettings.isEnabled;
        media.suspended = mediaEvent.mediaSettings.isSuspended;
        
        [self.ongoingCalls addMedia:media ForMember:mediaEvent.fromMemberId inConversation:mediaEvent.conversationId];
    } else {
        [self.ongoingCalls removeMediaForMember:mediaEvent.fromMemberId inConversation:mediaEvent.conversationId];
    }
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"mediaEvent"
     object:nil userInfo:@{@"media":mediaEvent}];
}

- (void)memberInvited:(nonnull NXMMemberEvent *)memberEvent {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"memberEvent"
     object:nil userInfo:@{@"member":memberEvent}];
    if (memberEvent.user.name){
        [self.memberIdToName setObject:memberEvent.user.name forKey:memberEvent.memberId];
    }
}

- (void)memberJoined:(nonnull NXMMemberEvent *)memberEvent {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"memberEvent"
     object:nil userInfo:@{@"member":memberEvent}];
    if (memberEvent.user.name){
        [self.memberIdToName setObject:memberEvent.user.name forKey:memberEvent.memberId];
    }
}

- (void)memberRemoved:(nonnull NXMMemberEvent *)memberEvent {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"memberEvent"
     object:nil userInfo:@{@"member":memberEvent}];
}

- (void)connectionStatusChanged:(BOOL)isConnected {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"connectionStatusChanged" object:nil];
}

- (void)sipAnswered:(nonnull NXMSipEvent *)sipEvent {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"sipEvent"
     object:nil userInfo:@{@"sipEvent":sipEvent}];
}

- (void)sipHangup:(nonnull NXMSipEvent *)sipEvent {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"sipEvent"
     object:nil userInfo:@{@"sipEvent":sipEvent}];
}

- (void)sipRinging:(nonnull NXMSipEvent *)sipEvent {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"sipEvent"
     object:nil userInfo:@{@"sipEvent":sipEvent}];
}

- (void)sipStatus:(nonnull NXMSipEvent *)sipEvent {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"sipEvent"
     object:nil userInfo:@{@"sipEvent":sipEvent}];
}

- (void)messageDeleted:(nonnull NXMMessageStatusEvent *)statusEvent {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"statusEvent"
     object:nil userInfo:@{@"statusEvent":statusEvent}];
}

- (void)textDelivered:(nonnull NXMMessageStatusEvent *)statusEvent {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"statusEvent"
     object:nil userInfo:@{@"statusEvent":statusEvent}];
}

- (void)textRecieved:(nonnull NXMTextEvent *)textEvent {
    NSString *memberId = self.conversationIdToMemberId[textEvent.conversationId];
    if (memberId) {
        [self.stitchConversationClient markAsDelivered:textEvent.sequenceId conversationId:textEvent.conversationId fromMemberWithId:memberId onSuccess:^{
            
        } onError:^(NSError * _Nullable error) {
            NSLog(@"error markAsDelivered");
        }];
    } else {
        [self.stitchConversationClient getConversationDetails:textEvent.conversationId onSuccess:^(NXMConversationDetails * _Nullable conversationDetails) {
            NSString *currMember;
            for (NXMMember *member in conversationDetails.members) {
                if ([member.userId isEqualToString:self.stitchConversationClient.getUser.uuid]){
                    currMember = member.memberId;
                    [self.conversationIdToMemberId setObject:member.memberId forKey:member.conversationId];
                    break;
                }
            }
            
            [self.stitchConversationClient markAsDelivered:textEvent.sequenceId conversationId:textEvent.conversationId fromMemberWithId:currMember onSuccess:^{
                
            } onError:^(NSError * _Nullable error) {
                NSLog(@"error markAsDelivered");
            }];
        } onError:^(NSError * _Nullable error) {
            
        }];
    }
    
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"textEvent"
     object:nil userInfo:@{@"text":textEvent}];
}

- (void)textSeen:(nonnull NXMMessageStatusEvent *)statusEvent {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"statusEvent"
     object:nil userInfo:@{@"statusEvent":statusEvent}];
}

- (void)textTypingOff:(nonnull NXMTextTypingEvent *)textTypingEvent {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"typingEvent"
     object:nil userInfo:@{@"typingEvent":textTypingEvent}];
}

- (void)textTypingOn:(nonnull NXMTextTypingEvent *)textTypingEvent {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"typingEvent"
     object:nil userInfo:@{@"typingEvent":textTypingEvent}];
}

- (void)tokenExpired:(nullable NSString *)token withReason:(NXMStitchErrorCode)reason {
    
}

- (void)localActionOnMedia:(nonnull NXMMediaActionEvent *)mediaActionEvent {
    
}


- (void)localInformOnMedia:(nonnull NXMMediaEvent *)mediaEvent {
    
}


@end

