//
//  NXMCallMemberPrivate.h
//  StitcClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMCallMember.h"

@protocol NXMCallProxy;

@interface NXMCallMember (NXMCallMemberPrivate)

- (nullable instancetype)initWithMemberId:(NSString *)memberId user:(NXMUser *)user andCallProxy:(id<NXMCallProxy>)callProxy;
- (nullable instancetype)initWithMember:(NXMMember *)member andCallProxy:(id<NXMCallProxy>)callProxy;
- (nullable instancetype)initWithMemberEvent:(NXMMemberEvent *)memberEvent andCallProxy:(id<NXMCallProxy>)callProxy;

- (void)updateWithMember:(NXMMember *)member;
- (void)updateWithMediaEvent:(NXMEvent *)mediaEvent;
- (void)updateWithMemberEvent:(NXMMemberEvent *)memberEvent;

- (void)callEnded;

@end
