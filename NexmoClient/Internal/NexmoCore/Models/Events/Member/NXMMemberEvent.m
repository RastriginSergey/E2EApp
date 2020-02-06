//
//  NXMMemberEvent.m
//  NexmoConversationObjC
//
//  Created by user on 21/03/2018.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMMemberEvent.h"
#import "NXMCoreEventsPrivate.h"
#import "NXMUserPrivate.h"
#import "NXMChannelPrivate.h"
#import "NXMMediaSettingsInternal.h"

@interface NXMMemberEvent()
@property (nonatomic, readwrite, nonnull) NXMUser *user;
@property (nonatomic, readwrite, nullable) NXMChannel *channel;
@property (nonatomic, readwrite, nullable) NXMMediaSettings *media;
@property NSString *memberId;
@property NSString *clientRef;
@property (nonatomic, readwrite) NXMMember *member;

@end

@implementation NXMMemberEvent

- (instancetype)initWithData:(NSDictionary *)data
                       state:(NXMMemberState)state {
    return [self initWithData:data state:state conversationUuid:data[@"cid"]];
}

- (instancetype)initWithData:(NSDictionary *)data state:(NXMMemberState)state conversationUuid:(NSString *)conversationUuid {
    NSString *memberId = data[@"body"][@"user"][@"member_id"] ?: data[@"from"];
    
    return [self initWithData:data state:state conversationUuid:conversationUuid memberId:memberId];
}

- (instancetype)initWithData:(NSDictionary *)data
                       state:(NXMMemberState)state
            conversationUuid:(NSString *)conversationUuid
                    memberId:(NSString *)memberId {
    
    NSString *fromKey = state == NXMMemberStateInvited ? @"invited" :
                        state == NXMMemberStateJoined ? @"joined" :
                        @"left";
    NSDictionary *body = data[@"body"];
    
    if (self = [super initWithData:data
                              type:NXMEventTypeMember
                  conversationUuid:conversationUuid
                      fromMemberId:body[@"initiator"][fromKey][@"member_id"]]) {

        
        self.user = [[NXMUser alloc] initWithData:body[@"user"]];
        self.channel = [[NXMChannel alloc] initWithData:body[@"channel"] andConversationId:conversationUuid andMemberId:memberId];
        self.media = [[NXMMediaSettings alloc] initWithEnabled:[[[body[@"media"] objectForKey:@"audio_settings"] objectForKey:@"enabled"] boolValue]
                                                       suspend:[[[body[@"media"] objectForKey:@"audio_settings"] objectForKey:@"muted"] boolValue]];
        self.state = state;
        self.memberId = memberId;
        self.clientRef = data[@"client_ref"];
        self.knockingId = body[@"channel"][@"knocking_id"];
    }

    return self;
}

- (void)updateMember:(NXMMember *)member {
    self.member = member;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> %@ memberId=%@ state=%ld user=%@ media=%@ channel=%@ knockingId=%@",
            NSStringFromClass([self class]),
            self,
            super.description,
            self.memberId,
            (long)self.state,
            self.user,
            self.media,
            self.channel,
            self.knockingId];
}


@end
