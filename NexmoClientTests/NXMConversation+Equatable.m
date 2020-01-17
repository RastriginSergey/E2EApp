//
// Created by Sergei Rastrigin on 15/01/2020.
// Copyright (c) 2020 Vonage. All rights reserved.
//

#import "NXMConversation+Equatable.h"


@implementation NXMConversation (Equatable)

- (BOOL)isMyMemberEqual:(NXMMember *)otherMember {
    return (!self.myMember && !otherMember)
            || [NXMConversation isMember:self.myMember equalTo:otherMember];
}

+ (BOOL)isMember:(NXMMember *)lhMember equalTo:(NXMMember *)rhMember {
    return [lhMember.memberUuid isEqualToString:rhMember.memberUuid];
}

- (BOOL)areAllMembersEqualTo:(NSArray<NXMMember *> *)otherMembers {
    if (self.allMembers.count != otherMembers.count) {
        return NO;
    }

    for (int index = 0; index < self.allMembers.count; ++index) {
        if (![NXMConversation isMember:self.allMembers[index] equalTo:otherMembers[index]]) {
            return NO;
        }
    }

    return YES;
}

- (BOOL)isEqual:(id)other {

    if (!other || ![other isKindOfClass:[self class]]) {
        return NO;
    }

    NXMConversation *otherConversation = (NXMConversation *)other;

    if (other == self) {
        return YES;
    }

    if ([self.uuid isEqualToString:otherConversation.uuid]
            && [self.name isEqualToString:otherConversation.name]
            && [self.displayName isEqualToString:otherConversation.displayName]
            && self.lastEventId == otherConversation.lastEventId
            && [self.creationDate compare:otherConversation.creationDate] == NSOrderedSame
            && [self isMyMemberEqual:otherConversation.myMember]
            && [self areAllMembersEqualTo:self.allMembers]
            ) {
        return YES;
    }

    return NO;
}

@end