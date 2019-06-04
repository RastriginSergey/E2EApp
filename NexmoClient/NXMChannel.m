//
//  NXMChannel.m
//  NexmoClient
//
//  Copyright © 2019 Vonage. All rights reserved.
//

#import "NXMChannelPrivate.h"

@interface NXMDirection()
@end

@implementation NXMDirection
- (nullable instancetype)initWithType:(NXMDirectionType)type andData:(NSString *)data {
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
@end

@implementation NXMChannel

- (nullable instancetype)initWithData:(NSDictionary *)data {
    if (self = [super init]) {
        self.from = [NXMChannel createDirectionWithData:data[@"from"]];
        self.to = [NXMChannel createDirectionWithData:data[@"to"]];
    }
    return self;
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
@end