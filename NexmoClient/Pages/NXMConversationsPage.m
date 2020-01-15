//
//  NXMConversationsPage.m
//  NexmoClient
//
//  Created by Chen Lev on 9/18/19.
//  Copyright © 2019 Vonage. All rights reserved.
//

#import "NXMConversationsPage.h"
#import "NXMPagePrivate.h"

@implementation NXMConversationsPage

- (NSArray<NXMConversation *> *)conversations {
    return (NSArray<NXMConversation *> *)self.elements;
}

- (void)nextPage:(void (^)(NSError * _Nullable, NXMConversationsPage * _Nullable))completionHandler {
    [super nextPage:^(NSError * _Nullable error, NXMPage * _Nullable page) {
        completionHandler(error, (NXMConversationsPage *)page);
    }];
}

- (void)previousPage:(void (^)(NSError * _Nullable, NXMConversationsPage * _Nullable))completionHandler {
    [super previousPage:^(NSError * _Nullable error, NXMPage * _Nullable page) {
        completionHandler(error, (NXMConversationsPage *)page);
    }];
}

@end
