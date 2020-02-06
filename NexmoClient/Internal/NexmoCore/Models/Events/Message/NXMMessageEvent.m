//
//  NXMMessageEvent.m
//  NexmoClient
//
//  Created by Iliya Barenboim on 29/08/2018.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMMessageEvent.h"
#import "NXMUtils.h"
#import "NXMEventInternal.h"

@interface NXMMessageEvent()
@property (nonatomic, readwrite, nonnull) NSMutableDictionary<NSNumber *, NSMutableDictionary<NSString *, NSDate *> *> *state;
@end

@implementation NXMMessageEvent

- (instancetype)initWithData:(NSDictionary *)data
                        type:(NXMEventType)type
            conversationUuid:(NSString *)conversationUuid {
    if (self = [super initWithData:data type:type conversationUuid:conversationUuid]) {
        self.state = [self parseStateFromDictionary:data[@"state"]];
    }
    return self;
}

- (NSMutableDictionary<NSNumber *, NSMutableDictionary<NSString *, NSDate *> *> *)parseStateFromDictionary:(NSDictionary *)dictionary {
    if(![dictionary isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dict = [NSMutableDictionary new];
        dict[@(NXMMessageStatusTypeSeen)] = @{};
        dict[@(NXMMessageStatusTypeDelivered)] = @{};
        
        return dict;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@(NXMMessageStatusTypeSeen)] = [self parseFromSpecificStateDictionary:dictionary[@"seen_by"]];
    dict[@(NXMMessageStatusTypeDelivered)] = [self parseFromSpecificStateDictionary:dictionary[@"delivered_to"]];
    
    return dict;
}

- (NSMutableDictionary<NSString *, NSDate *> *)parseFromSpecificStateDictionary:(NSDictionary *)specificStateDictionary {
    NSMutableDictionary<NSString *, NSDate *> *outputDictionary = [NSMutableDictionary new];
    for (NSString *key in specificStateDictionary) {
        outputDictionary[key] = [NXMUtils dateFromISOString:specificStateDictionary[key]];
    }
    return outputDictionary;
}

@end
