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

static NSString *const ON_MAIN_THREAD_EXCEPTION_REASON = @"This method can't be called on the main thread.";

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

- (void)getConversationsPageForURL:(nonnull NSURL *)url
                 completionHandler:(void (^ _Nullable)(NSError * _Nullable, NXMConversationsPage * _Nullable))completionHandler {

    LOG_DEBUG([NSString stringWithFormat: @"URL: %@", url.absoluteString].UTF8String);
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
                        onSuccess:^(NSArray<NXMConversation *> * _Nonnull conversations) {
                            NXMConversationsPage *resultPage = [[NXMConversationsPage alloc] initWithSize:page.size
                                                                                                    order:page.order
                                                                                             pageResponse:page.pageResponse
                                                                                 conversationsPagingProxy:self
                                                                                            conversations:conversations];
                            if (!resultPage) {
                                completionHandler([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeUnknown], nil);
                                return;
                            }

                            completionHandler(nil, resultPage);
                        }
                          onError:^(NSError * _Nullable error) {
                              completionHandler(error, nil);
                          }];
}

- (void)getConversationsFromIds:(nonnull NSArray<NSString *> *)conversationIds
                      onSuccess:(void (^ _Nonnull)(NSArray<NXMConversation *> * _Nonnull))onSuccess
                        onError:(void (^ _Nonnull)(NSError * _Nullable))onError {

    if (NSThread.isMainThread) {
        LOG_DEBUG(ON_MAIN_THREAD_EXCEPTION_REASON.UTF8String);
    }

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{

        // TODO: this solution gets each NXMConversation sequentially. It'd be done concurrently to increase performance
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        __block NSMutableArray<NXMConversation *> *results = [NSMutableArray new];

        for (NSUInteger i = 0; i < conversationIds.count; i += 1) {
            NSString *conversationId = conversationIds[i];
            weakSelf.getConversationWithUuid(conversationId, ^(NSError * _Nullable error, NXMConversation * _Nullable conversation) {
                if (!error && conversation) { [results addObject:conversation]; }
                dispatch_semaphore_signal(semaphore);
            });
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }

        onSuccess(results);
    });
}

@end
