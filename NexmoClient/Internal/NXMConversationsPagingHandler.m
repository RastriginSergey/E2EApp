//
//  NXMConversationsPagingHandler.m
//  NexmoClient
//
//  Created by Nicola Di Pol on 19/11/2019.
//  Copyright © 2019 Vonage. All rights reserved.
//

#import "NXMConversationsPagingHandler.h"
#import "NXMErrorsPrivate.h"
#import "NXMLoggerInternal.h"
#import "NXMConversationPrivate.h"

NSString * const EMPTY_CONVERSATION_UUID = @"emptyConversationUUID";

@implementation NXMConversationsPagingHandler

- (instancetype)initWithStitchContext:(NXMStitchContext *)stitchContext
              getConversationWithUuid:(GetConversationWithUuidBlock)getConversationWithUuid {
    self = [super init];
    if (self) {
        _stitchContext = stitchContext;
        _getConversationWithUuid = getConversationWithUuid;
    }
    return self;
}

- (void)getConversationsPageWithSize:(NSInteger)size
                               order:(NXMPageOrder)order
                              userId:(NSString *)userId
                   completionHandler:(void (^)(NSError * _Nullable, NXMConversationsPage * _Nullable))completionHandler {
    NXMCore *coreClient = self.stitchContext.coreClient;
    __weak typeof(self) weakSelf = self;
    [coreClient getConversationIdsPageWithSize:size
                                        cursor:nil
                                        userId:userId
                                         order:order
                                     onSuccess:^(NXMConversationIdsPage * _Nullable page) {
                                         if (!page) {
                                             completionHandler([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeUnknown], nil);
                                             return;
                                         }

                                         [weakSelf getConversationsPageFromConversationIdsPage:page
                                                                             completionHandler:completionHandler];
                                     }
                                       onError:^(NSError * _Nullable error) {
                                           completionHandler(error, nil);
                                       }];
}

- (void)getConversationsPageForURL:(NSURL *)url
                 completionHandler:(void (^)(NSError * _Nullable, NXMConversationsPage * _Nullable))completionHandler {
    NXM_LOG_DEBUG([NSString stringWithFormat: @"URL: %@", url.absoluteString].UTF8String);
    NXMCore *coreClient = self.stitchContext.coreClient;
    __weak typeof(self) weakSelf = self;
    [coreClient getConversationIdsPageForURL:url
                                   onSuccess:^(NXMConversationIdsPage * _Nullable page) {
                                       if (!page) {
                                           completionHandler([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeUnknown], nil);
                                           return;
                                       }
                                       [weakSelf getConversationsPageFromConversationIdsPage:page
                                                                           completionHandler:completionHandler];
                                   }
                                     onError:^(NSError * _Nullable error) {
                                         completionHandler(error, nil);
                                     }];
}

- (void)getConversationsPageFromConversationIdsPage:(NXMConversationIdsPage *)page
                                  completionHandler:(void (^)(NSError * _Nullable, NXMConversationsPage * _Nullable))completionHandler {
    [self getConversationsFromIds:page.conversationIds
                completionHandler:^(NSArray<NXMConversation *> *_Nonnull conversations) {
                    NXMConversationsPage *resultPage = [[NXMConversationsPage alloc] initWithOrder:page.order
                                                                                      pageResponse:page.pageResponse
                                                                                       pagingProxy:self
                                                                                          elements:conversations];
                    if (!resultPage) {
                        completionHandler([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeUnknown], nil);
                        return;
                    }

                    completionHandler(nil, resultPage);
                }];
}

+ (NSArray<NXMConversation *> *)getFilteredConversations:(NSArray<NXMConversation *> *)conversations {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NXMConversation *conversation, NSDictionary *bindings) {
        return ![conversation.uuid isEqualToString:EMPTY_CONVERSATION_UUID];
    }];
    return [conversations filteredArrayUsingPredicate:predicate];
}

+ (NXMConversation *)createPlaceholderConversation {
    NXMConversationDetails *conversationDetails = [[NXMConversationDetails alloc] initWithConversationId:EMPTY_CONVERSATION_UUID];
    NXMConversation *conversationPlaceholder = [NXMConversation new];
    conversationPlaceholder.conversationDetails = conversationDetails;

    return conversationPlaceholder;
}

+ (NSMutableArray<NXMConversation *> *)resultPlaceholderArray:(NSUInteger)count {
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:count];

    for (NSUInteger index = 0; index < count; ++index) {
        results[index] = [NXMConversationsPagingHandler createPlaceholderConversation];
    }

    return results;
}

- (void)getConversationsFromIds:(nonnull NSArray<NSString *> *)conversationIds
              completionHandler:(void (^ _Nonnull)(NSArray<NXMConversation *> * _Nonnull))completionHandler {
    NXM_LOG_DEBUG([NSString stringWithFormat:@"conversationIds: %@", conversationIds].UTF8String);

    NSMutableArray<NXMConversation *> *results = [NXMConversationsPagingHandler resultPlaceholderArray:conversationIds.count];

    dispatch_group_t group = dispatch_group_create();
    __weak typeof(self) weakSelf = self;

    for (NSUInteger i = 0; i < conversationIds.count; ++i) {
        NSString *conversationId = conversationIds[i];

        NXM_LOG_DEBUG([NSString stringWithFormat:@"Started a request for the conversation:%@", conversationId].UTF8String);

        dispatch_group_enter(group);

        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {

            weakSelf.getConversationWithUuid(conversationId, ^(NSError * _Nullable error, NXMConversation * _Nullable conversation) {
                if (error) {
                    NXM_LOG_ERROR(error.description.UTF8String);

                    dispatch_group_leave(group);
                    return;
                }

                if (conversation) {
                    NXM_LOG_DEBUG([NSString stringWithFormat:@"Successfully requested the conversation:%@", conversationId].UTF8String);
                    results[i] = conversation;

                    dispatch_group_leave(group);
                }
            });
        });
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^ {
        completionHandler([NXMConversationsPagingHandler getFilteredConversations:results]);
    });
}

- (void)getPageForURL:(NSURL *)url completionHandler:(void (^)(NSError * _Nullable, NXMPage * _Nullable))completionHandler {
    [self getConversationsPageForURL:url completionHandler:completionHandler];
}

@end
