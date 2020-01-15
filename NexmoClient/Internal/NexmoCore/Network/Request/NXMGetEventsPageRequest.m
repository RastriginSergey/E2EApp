//
//  NXMGetEventsPageRequest.m
//  NexmoClient
//
//  Created by Nicola Di Pol on 24/12/2019.
//  Copyright © 2019 Vonage. All rights reserved.
//

#import "NXMGetEventsPageRequest.h"

@implementation NXMGetEventsPageRequest

- (instancetype)initWithSize:(NSUInteger)size
                       order:(NXMPageOrder)order
              conversationId:(NSString *)conversationId
                      cursor:(NSString *)cursor
                   eventType:(nullable NSString *)eventType {
    self = [super init];
    if (self) {
        self.size = size;
        self.order = order;
        self.conversationId = conversationId;
        self.cursor = cursor;
        self.eventType = eventType;
    }
    return self;
}

@end
