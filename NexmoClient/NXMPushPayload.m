//
//  NXMPushEvent.m
//  NexmoClient
//
//  Created by Chen Lev on 1/23/20.
//  Copyright © 2020 Vonage. All rights reserved.
//

#import "NXMPushPayload.h"

@interface NXMPushPayload()
@property (nonatomic, readwrite) NSDictionary *customData;
@property (nonatomic, readwrite) NSDictionary *eventData;
@property (nonatomic, readwrite) NXMPushTemplate template;
@end

@implementation NXMPushPayload

- (nullable instancetype)initWithData:(nonnull NSDictionary *)data {
    if (self = [super init]) {
        self.eventData = data;
        self.customData = data[@"custom_data"];
        self.template = self.customData ? NXMPushTemplateCustom : NXMPushTemplateDefault;
    }
    
    return self;
}
@end
