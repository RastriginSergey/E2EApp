//
//  NXMTextTypingEvent.m
//  NexmoClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMTextTypingEvent.h"
#import "NXMEventInternal.h"

@interface NXMTextTypingEvent()
@property (nonatomic, readwrite) NXMTextTypingEventStatus status;
@end
@implementation NXMTextTypingEvent


- (instancetype)initWithData:(NSDictionary *)data status:(NXMTextTypingEventStatus)status conversationUuid:(NSString *)conversationUuid {
    if (self = [super initWithData:data type:NXMEventTypeTextTyping conversationUuid:conversationUuid]) {
        self.status = status;
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> %@ status=%@",
            NSStringFromClass([self class]),
            self,
            super.description,
            self.status == NXMTextTypingEventStatusOn ? @"on" : @"off"];
}
@end
