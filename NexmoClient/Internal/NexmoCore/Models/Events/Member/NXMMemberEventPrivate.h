//
//  NXMMemberEventPrivate.h
//  NexmoClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//


#import "NXMMemberEvent.h"

@interface NXMMemberEvent (private)

- (instancetype)initWithData:(NSDictionary *)data
state:(NXMMemberState)state;

- (instancetype)initWithData:(NSDictionary *)data
                        state:(NXMMemberState)state
    conversationUuid:(NSString *)conversationUuid;

- (instancetype)initWithData:(NSDictionary *)data
state:(NXMMemberState)state
conversationUuid:(NSString *)conversationUuid
memberId:(NSString *)memberId;

@property (nonatomic, readonly) NXMUser *user;

@property NSString *memberId;
@property NSString *clientRef;

- (void)updateMember:(NXMMember *)member;
@end

