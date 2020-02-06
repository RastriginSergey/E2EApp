//
//  NXMEvent.m
//  NexmoConversationObjC
//
//  Created by Chen Lev on 3/21/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMEventInternal.h"
#import "NXMUtils.h"

@interface NXMEvent()
@property (nonatomic, readwrite, nullable) NXMMember *fromMember;
@property (nonatomic, readwrite, nonnull) NSString *fromMemberId;
@property (nonatomic, readwrite) NXMEventType type;
@property (nonatomic, readwrite) NSInteger uuid;

@end

@implementation NXMEvent

- (nullable instancetype)initWithData:(nonnull NSDictionary *)data type:(NXMEventType)type {
    return [self initWithData:data
                         type:type
             conversationUuid:data[@"cid"]];
}

- (nullable instancetype)initWithData:(nonnull NSDictionary *)data
                                 type:(NXMEventType)type
                     conversationUuid:(NSString *)conversationUuid {
    return [self initWithData:data
                         type:type
             conversationUuid:conversationUuid
                 fromMemberId:data[@"from"]];
}

- (nullable instancetype)initWithData:(nonnull NSDictionary *)data
                                 type:(NXMEventType)type
                     conversationUuid:(NSString *)conversationUuid
                         fromMemberId:(nullable)memberId {
    return [self initWithConversationId:conversationUuid
                             sequenceId:[data[@"id"] integerValue]
                           fromMemberId:memberId
                           creationDate:[NXMUtils dateFromISOString:data[@"timestamp"]]
                                   type:type];
}

- (nullable instancetype)initWithConversationId:(nonnull NSString *)conversationId
                                           type:(NXMEventType)type
                                   fromMemberId:(nullable)memberId
                                     sequenceId:(NSInteger)sequenceId {
    return [self initWithConversationId:conversationId sequenceId:sequenceId fromMemberId:memberId creationDate:NULL type:type];
}
- (nullable instancetype)initWithConversationId:(nonnull NSString *)conversationId
                                     sequenceId:(NSInteger)sequenceId
                                   fromMemberId:(nullable NSString *)fromMemberId
                                   creationDate:(nullable NSDate *)creationDate
                                           type:(NXMEventType)type {
    if (self = [super init]) {
        self.conversationUuid = conversationId;
        self.uuid = sequenceId;
        self.fromMemberId = fromMemberId;
        self.creationDate = creationDate;
        self.type = type;
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> conversationId=%@ fromMemberId=%@ creationDate=%@ deletionDate=%@ type=%ld eventId=%ld",
            NSStringFromClass([self class]),
            self,
            self.conversationUuid,
            self.fromMemberId,
            self.creationDate,
            self.deletionDate,
            (long)self.type,
            (long)self.uuid];
}


- (void)updateFromMember:(NXMMember *)member {
    self.fromMember = member;
}
@end
