//
//  NXMTextEvent.m
//  NexmoClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//


#import "NXMTextEvent.h"
#import "NXMCoreEventsPrivate.h"

@interface NXMTextEvent()
@property (nonatomic, readwrite, nullable) NSString *text;
@end

@implementation NXMTextEvent

- (instancetype)initWithData:(NSDictionary *)data {
    return  [self initWithData:data conversationUuid:data[@"cid"]];
}

- (instancetype)initWithData:(NSDictionary *)data
            conversationUuid:(NSString *)conversationUuid {
    if (self = [super initWithData:data type:NXMEventTypeText conversationUuid:conversationUuid]) {
        self.text = data[@"body"][@"text"];
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> %@ text=%@",
            NSStringFromClass([self class]),
            self,
            super.description,
            self.text];
}

@end
