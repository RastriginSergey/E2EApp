//
//  NXMConversationClient.m
//  NexmoConversationObjC
//
//  Created by Chen Lev on 2/26/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import <NexmoConversationObjC.h>
#import "NXMSocketClient.h"
#import "NXMRouter.h"

@interface NXMConversationClient()

@property id<NXMConversationClientDelegate> delegate;
@property NXMSocketClient *socketClient;
@property NXMRouter *router;
@property NXMUser *user;

@end

@implementation NXMConversationClient

- (instancetype _Nullable)initWithConfig:(nonnull NXMConversationClientConfig *)config {
    if (self = [super init]) {
        NSString *host = [config getWSHost];
        self.socketClient = [[NXMSocketClient alloc] initWitHost:host];
        [self.socketClient setDelegate:self];
        
        self.router = [[NXMRouter alloc] initWitHost:[config getHttpHost]];
    }
    
    return self;
}

- (void)enablePushNotifications:(BOOL)enable responseBlock:(void (^_Nullable)(NSError * _Nullable error))responseBlock {
    
}

- (void)loginWithToken:(nonnull NSString *)token {
    [self.socketClient loginWithToken:token];
    [self.router setToken:token];
}

- (void)logout:(void (^_Nullable)(NSError * _Nullable error))responseBlock {
    
}

- (void)newConversationWithConversationName:(nonnull NSString *)conversationName responseBlock:(void (^_Nullable)(NSError * _Nullable error, NSString * _Nullable conversation))responseBlock {
    [self.router createConversationWithName:conversationName responseBlock:responseBlock];
    
}

- (void)addMemberToConversation:(nonnull NSString *)conversationId userId:(nonnull NSString *)userId completionBlock:(void (^_Nullable)(NSError * _Nullable error))completionBlock {
    [self.router addMemberToConversation:conversationId userId:userId completionBlock:completionBlock];
}

- (void)sendText:(nonnull NSString *)text
  conversationId:(nonnull NSString *)conversationId
    fromMemberId:(nonnull NSString *)fromMemberId
 completionBlock:(void (^_Nullable)(NSError * _Nullable error))completionBlock {
    [self.socketClient sendText:text conversationId:conversationId fromMemberId:fromMemberId completionBlock:^(NSError * _Nullable error, NXMSocketResponse * _Nullable response) {
        // TODO:
    }];
}
- (nullable NXMConversation *)getConversationWithCID:(nonnull NSString *)cid {
    return  nil;
}

- (nullable NSArray<NXMConversation *> *)getConversationList {
    return  nil;
}

- (void)enableAudio {
    
}

- (void)disableAudio {
    
}

- (nonnull NXMConnectionStatus *)getConnectionStatus {
    return  nil;
}

- (nonnull NXMUser *)getUser {
    return  self.user;
}

- (nonnull NSString *)getToken {
    //return  self.;
    return nil;
}

- (BOOL)isLoggedIn {
    return NO;
} // TODO: the use already login but the network is down?

- (void)registerEventsWithDelegate:(nonnull id<NXMConversationClientDelegate>)delegate {
    self.delegate = delegate;
}

- (void)unregisterEvents {
    
}

#pragma mark - NXMSocketCllientDelegate

- (void)connectionStatusChanged:(BOOL)isOpen {
    
}

- (void)userStatusChanged:(NXMUser *)user {
    self.user = user;
    
    [self.delegate connectedWithUser:user];
}

- (void)memberJoined:(nonnull NXMMember *)member {
    [self.delegate memberJoined:member];
}

@end

