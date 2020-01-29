//
//  NXMPushPayloadInternal.h
//  NexmoClient
//
//  Copyright © 2020 Vonage. All rights reserved.
//


#import "NXMPushPayload.h"

@interface NXMPushPayload (NXMPushPayloadInternal)

- (nullable instancetype)initWithData:(nonnull NSDictionary *)data;

@end

