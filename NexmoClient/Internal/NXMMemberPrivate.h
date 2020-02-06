//
//  NXMMemberParser.h
//  NexmoClient
//
//  Copyright © 2019 Vonage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NXMMember.h"
#import "NXMMemberEvent.h"
#import "NXMEnums.h"

@interface NXMMember (PrivateParser)

@property (nonatomic, readonly) NSDictionary<NSValue *, NXMInitiator *> *initiators;
@property NSString *clientRef;

- (instancetype)initWithData:(NSDictionary *)data
                 andMemberIdFieldName:(NSString *)memberIdFieldName;

- (instancetype)initWithData:(NSDictionary *)data
                 andMemberIdFieldName:(NSString *)memberIdFieldName
                    andConversationId:(NSString *)convertaionId;

- (instancetype)initWithMemberEvent:(NXMMemberEvent *)memberEvent;

- (void)updateChannelWithLeg:(NXMLeg *)leg;
- (void)updateMedia:(BOOL)isEnabled isSuspended:(BOOL)isSuspended;
- (void)updateState:(NXMMemberEvent *)memberEvent;
- (void)updateExpired;

- (void)setMember:(NXMMember *)member;
@end

