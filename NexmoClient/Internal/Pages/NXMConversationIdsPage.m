//
//  NXMConversationIdsPage.m
//  NexmoClient
//
//  Created by Nicola Di Pol on 12/11/2019.
//  Copyright © 2019 Vonage. All rights reserved.
//

#import "NXMConversationIdsPage.h"
#import "NXMPageResponse.h"

@implementation NXMConversationIdsPage

- (instancetype)initWithPageResponse:(NXMPageResponse *)pageResponse
                               order:(NXMPageOrder)order {
    self = [super init];
    if (self) {
        self.size = pageResponse.pageSize;
        self.order = order;
        self.pageResponse = pageResponse;
        self.conversationIds = [NXMConversationIdsPage conversationIdsFromPageResponse:pageResponse];
    }
    return self;
}

+ (NSArray<NSString *> *)conversationIdsFromPageResponse:(NXMPageResponse *)pageResponse {
    NSMutableArray<NSString *> *result = [NSMutableArray new];
    for (NSDictionary *conversationJson in pageResponse.data) {
        NSString *conversationId = conversationJson[@"id"];
        if (conversationId) {
            [result addObject:conversationId];
        }
    }
    return result;
}

@end
