//
//  NXMLeg.m
//  NexmoClient
//
//  Created by Assaf Passal on 5/30/19.
//  Copyright © 2019 Vonage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NXMLegPrivate.h"
#import "NXMUtils.h"

@implementation NXMLeg

- (nullable instancetype) initWithConversationId:(nullable NSString *)conversationId
                                     andMemberId:(nullable NSString *)memberId
                                        andLegId:(nullable NSString *)legId
                                     andlegTypeE:(NXMLegType)legType
                                   andLegStatusE:(NXMLegStatus)legStatus
                                         andDate:(nullable NSString *)date {
    if (self = [super init]){
        self.uuid = legId;
        self.type = legType;
        self.status = legStatus;
        self.conversationUuid = conversationId;
        self.memberUUid = memberId;
        self.date = [date length] > 0 ? [NXMUtils dateFromISOString:date] : nil;
    }
    
    return self;
}

- (nullable instancetype) initWithConversationId:(nullable NSString *)conversationId
                                     andMemberId:(nullable NSString *)memberId
                                        andLegId:(nullable NSString *)legId
                                      andlegType:(nullable NSString *)legType
                                    andLegStatus:(nullable NSString *)legStatus
                                         andDate:(nullable NSString *)date {
    return [self initWithConversationId:conversationId
                            andMemberId:memberId
                               andLegId:legId
                            andlegTypeE:[NXMLeg getLegTypeFromString:legType]
                          andLegStatusE:[NXMLeg getLegStatusFromString:legStatus]
                                andDate:date];

}

- (nullable instancetype) initWithConversationId:(nullable NSString *) conversationId
                                     andMemberId:(nullable NSString *) memberId
                                      andLegData:(nullable NSDictionary *)legData
                                         andData:(nullable NSDictionary *)data {
    
    return [self initWithConversationId:conversationId
                            andMemberId:memberId
                               andLegId:legData[@"leg_id"]
                            andlegTypeE:[NXMLeg getLegTypeFromString:data[@"type"]]
                          andLegStatusE:[NXMLeg getLegStatusFromString:legData[@"status"]]
                                andDate:nil];
    
}

- (nullable instancetype)initWithData:(nullable NSDictionary *)data
                            andLegData:(nullable NSDictionary *)legData {
    
    return [self initWithConversationId:legData[@"conversation_id"]
                            andMemberId:legData[@"member_id"]
                               andLegId:data[@"leg_id"]
                            andlegTypeE:[NXMLeg getLegTypeFromString:data[@"type"]]
                          andLegStatusE:[NXMLeg getLegStatusFromString:legData[@"status"]]
                                andDate:legData[@"date"]];
}


+ (NXMLegStatus)getLegStatusFromString:(nullable NSString*)statusString {
    return [statusString isEqualToString:@"ringing"] ? NXMLegStatusRinging :
            [statusString isEqualToString:@"answered"] ? NXMLegStatusAnswered :
            [statusString isEqualToString:@"started"] ? NXMLegStatusStarted :
            [statusString isEqualToString:@"canceled"] ? NXMLegStatusCanceled :
            [statusString isEqualToString:@"failed"] ? NXMLegStatusFailed :
            [statusString isEqualToString:@"busy"] ? NXMLegStatusBusy :
            [statusString isEqualToString:@"timeout"] ? NXMLegStatusTimeout :
            [statusString isEqualToString:@"rejected"] ? NXMLegStatusRejected :
            [statusString isEqualToString:@"completed"] ? NXMLegStatusCompleted :
            NXMLegStatusStarted;
}

+ (NXMLegType)getLegTypeFromString:(nullable NSString*)typeString {
    return [typeString isEqualToString:@"app"] ? NXMLegTypeApp :
           [typeString isEqualToString:@"phone"] ? NXMLegTypePhone :
           NXMLegTypeUnknown;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> legId=%@ legType=%ld legStatus=%ld convId=%@ memberId=%@ date=%@",
            NSStringFromClass([self class]),
            self,
            self.uuid,
            (long)self.type,
            (long)self.status,
            self.conversationUuid,
            self.memberUUid,
            self.date];
}

@end
