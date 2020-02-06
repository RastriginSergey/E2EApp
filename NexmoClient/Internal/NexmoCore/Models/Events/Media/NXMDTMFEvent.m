//
//  NXMDTMFEvent.m
//  NexmoClient
//
//  Copyright © 2019 Vonage. All rights reserved.
//

#import "NXMDTMFEvent.h"
#import "NXMEventInternal.h"

@interface NXMDTMFEvent()

@property (readwrite, nonatomic) NSString *digit;
@property (readwrite, nonatomic) NSNumber *duration;

@end

@implementation NXMDTMFEvent

- (instancetype)initWithData:(NSDictionary *)data {
    return [self initWithData:data conversationUuid:data[@"cid"]];
}

- (instancetype)initWithData:(NSDictionary *)data
            conversationUuid:(NSString *)conversationUuid {
    if (self = [super initWithData:data type:NXMEventTypeDTMF conversationUuid:data[@"cid"]]) {
        self.digit = data[@"body"][@"digit"];
        self.duration = @([data[@"body"][@"duration"] integerValue]);
    }
    
    return self;
}

- (instancetype)initWithDigit:(NSString *)digit andDuration:(NSNumber *)duration {
    if (self = [super init]) {
        self.digit = digit;
        self.duration = duration;
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> %@ digit=%@ duration=%@",
            NSStringFromClass([self class]),
            self,
            super.description,
            self.digit,
            self.duration];
}

@end
