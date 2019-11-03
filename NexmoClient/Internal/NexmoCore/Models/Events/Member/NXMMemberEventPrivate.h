//
//  NXMMemberEventPrivate.h
//  NexmoClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//


#import "NXMMemberEvent.h"

@interface NXMMemberEvent (private)

- (instancetype)initWithConversationId:(NSString *)conversationId
                        sequenceId:(NSUInteger)sequenceId
                        andState:(NXMMemberState)state
                        clientRef:(NSString *)clientRef
                        andData:(NSDictionary *)data
                        creationDate:(NSDate *)creationDate
                        memberId:(NSString *)memberId;

@property (nonatomic, readonly) NXMUser *user;

@property NSString *memberId;
@property NSString *clientRef;

- (void)updateMember:(NXMMember *)member;
@end

