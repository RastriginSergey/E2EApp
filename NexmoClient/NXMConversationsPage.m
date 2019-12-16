//
//  NXMConversationsPage.m
//  NexmoClient
//
//  Created by Chen Lev on 9/18/19.
//  Copyright © 2019 Vonage. All rights reserved.
//

#import "NXMConversationsPagePrivate.h"
#import "NXMConversation.h"
#import "NXMConversationDetails.h"
#import "NXMPageResponse.h"
#import "NXMErrorsPrivate.h"

@interface NXMConversationsPage()

@property (nonatomic, assign, readwrite) NSUInteger size;
@property (nonatomic, assign, readwrite) NXMPageOrder order;
@property (nonatomic, nonnull, readwrite) NXMPageResponse *pageResponse;
@property (nonatomic, nonnull, readwrite) id<NXMConversationsPageProxy> proxy;
@property (nonatomic, nonnull, readwrite) NSArray<NXMConversation *> *conversations;

@end

@implementation NXMConversationsPage

- (instancetype)initWithSize:(NSUInteger)size
                       order:(NXMPageOrder)order
                pageResponse:(NXMPageResponse *)pageResponse
    conversationsPagingProxy:(id<NXMConversationsPageProxy>)proxy
               conversations:(NSArray<NXMConversation *> *)conversations {
    self = [super init];
    if (self) {
        self.size = size;
        self.order = order;
        self.pageResponse = pageResponse;
        self.proxy = proxy;
        self.conversations = conversations;
    }
    return self;
}

- (BOOL)hasNextPage {
    return self.pageResponse.links.next ? true : false;
}

- (BOOL)hasPreviousPage {
    return self.pageResponse.links.prev ? true : false;
}

- (void)nextPage:(void (^)(NSError * _Nullable, NXMConversationsPage * _Nullable))completionHandler {
    [self moveToPageURL:self.pageResponse.links.next completionHandler:completionHandler];
}

- (void)previousPage:(void (^)(NSError * _Nullable, NXMConversationsPage * _Nullable))completionHandler {
    [self moveToPageURL:self.pageResponse.links.prev completionHandler:completionHandler];
}

- (void)moveToPageURL:(nullable NSURL *)newPageURL
    completionHandler:(void (^)(NSError * _Nullable, NXMConversationsPage * _Nullable))completionHandler {

    if (!newPageURL) {
        completionHandler([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeConversationsPageNotFound], nil);
        return;
    }

    [self.proxy getConversationsPageForURL:newPageURL completionHandler:completionHandler];
}

@end
