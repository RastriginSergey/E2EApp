//
//  NXMChannel.m
//  NexmoClient
//
//  Copyright © 2019 Vonage. All rights reserved.
//

#import "NXMChannelPrivate.h"
#import "NXMLegPrivate.h"
#import "NXMLoggerInternal.h"

@interface NXMDirection()
@end

@implementation NXMDirection
- (nullable instancetype)initWithType:(NXMDirectionType)type andData:(NSString *)data{
    if (self = [super init]) {
        self.type = type;
        self.data = data;
    }
    
    return self;
}
@end

@interface NXMChannel()
@property (nonatomic, readwrite) NXMDirection *from;
@property (nonatomic, readwrite) NXMDirection *to;
@property NSMutableArray<NXMLeg *> *legs;
@end

@implementation NXMChannel

- (nullable instancetype)initWithData:(NSDictionary *)data andConversationId:(NSString*)conversationId andMemberId:(NSString*)memberId{
    if (self = [super init]) {
        self.from = [NXMChannel createDirectionWithData:data[@"from"]];
        self.to = [NXMChannel createDirectionWithData:data[@"to"]];
        self.legs = [NXMChannel createLegsWithData:data andConversationId:conversationId andMemberId:memberId];
    }
    return self;
}

- (NXMLeg *)leg {
    return [self.legs lastObject];
}

- (void)addLeg:(NXMLeg *)leg{
    NXM_LOG_DEBUG([leg.description UTF8String]);
    [self.legs addObject:leg];
}

#pragma Private methods

+ (NSMutableArray<NXMLeg*> *)createLegsWithData:(NSDictionary *)data
                              andConversationId:(NSString *)conversationId
                                    andMemberId:(NSString *)memberId {
    
    NSMutableArray<NXMLeg*> *legs = [[NSMutableArray<NXMLeg *> alloc] init];
    
    for (NSDictionary* currLeg in [data objectForKey:@"legs"]){
        NXMLeg* leg = [[NXMLeg alloc] initWithConversationId:conversationId
                                                 andMemberId:memberId
                                                  andLegData:currLeg
                                                     andData:data];
        [legs addObject:leg];
    }
    
    return legs;
}

+ (NXMDirection *)createDirectionWithData:(NSDictionary *)data {
    NXMDirectionType fromType = [NXMChannel typeFromString:data[@"type"]];

    return [[NXMDirection alloc] initWithType:fromType
                                      andData:data[[NXMChannel channelDataFieldName:fromType]]];
}

+ (NXMDirectionType)typeFromString:(nullable NSString *)typeString{
    
    return [typeString isEqualToString:@"app"] ? NXMDirectionTypeApp :
            [typeString isEqualToString:@"phone"] ? NXMDirectionTypePhone :
            [typeString isEqualToString:@"sip"] ? NXMDirectionTypeSIP :
            [typeString isEqualToString:@"websocket"] ? NXMDirectionTypeWebsocket :
            [typeString isEqualToString:@"vbc"] ? NXMDirectionTypeVBC :
    
    NXMDirectionTypeUnknown;
}

+ (NSString *)channelDataFieldName:(NXMDirectionType)channelType {
    
    switch (channelType) {
        case NXMDirectionTypeApp:
            return @"user";
        case NXMDirectionTypePhone:
            return @"number";
        case NXMDirectionTypeSIP:
        case NXMDirectionTypeWebsocket:
            return @"uri";
        case NXMDirectionTypeVBC:
            return @"extension";
        default:
            return @"";
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> from: %@ to: %@ legs: %@",
            NSStringFromClass([self class]),
            self,
            self.from,
            self.to,
            self.legs.description];
}
@end
