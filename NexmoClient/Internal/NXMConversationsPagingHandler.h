//
//  NXMConversationsPagingHandler.h
//  NXMiOSSDK
//
//  Created by Chen Lev on 11/19/19.
//  Copyright © 2019 Vonage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NXMPagePrivate.h"
#import "NXMStitchContext.h"

typedef void (^GetConversationWithUuidBlock)(NSString * _Nonnull uuid,
                                             void (^ _Nullable completionHandler)(NSError * _Nullable error,
                                                                                  NXMConversation * _Nullable conversation));

@interface NXMConversationsPagingHandler : NSObject<NXMPageProxy>

@property (nonatomic, nullable, weak) NXMStitchContext *stitchContext;
@property (nonatomic, nonnull) GetConversationWithUuidBlock getConversationWithUuid;

- (nonnull instancetype)initWithStitchContext:(nonnull NXMStitchContext *)stitchContext
                      getConversationWithUuid:(nonnull GetConversationWithUuidBlock)getConversationWithUuid;

- (void)getConversationsPageWithSize:(NSInteger)size
                               order:(NXMPageOrder)order
                              userId:(nonnull NSString *)userId
                   completionHandler:(void(^_Nullable)(NSError * _Nullable error, NXMConversationsPage * _Nullable page))completionHandler;
- (void)getConversationsPageForURL:(nonnull NSURL *)url
                 completionHandler:(void (^ _Nullable)(NSError * _Nullable, NXMConversationsPage * _Nullable))completionHandler;

@end
