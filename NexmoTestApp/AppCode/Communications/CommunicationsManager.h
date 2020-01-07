//
//  NexmoClientWrapper.h
//  NexmoTestApp
//
//  Created by Chen Lev on 12/9/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NexmoClient/NexmoClient.h>
#import <PushKit/PushKit.h>

#import "NTAUserInfo.h"
#import "CommunicationsManagerDefine.h"

@interface CommunicationsManager : NSObject <NXMClientDelegate>

@property (nonatomic, nonnull, readonly) NXMClient *client;
@property (nonatomic, nonnull) NSMutableArray<PKPushPayload *> *unprocessedPushPayloads;

+ (nonnull CommunicationsManager *)sharedInstance;

+ (nonnull NSString *)statusReasonToString:(NXMConnectionStatusReason)status;

- (void)loginWithUserToken:(nonnull NSString *)userToken;

- (void)logout;

+ (void)setLogger;

- (void)enablePushNotificationsWithDeviceToken:(nonnull NSData *)deviceToken
                                     pushKit:(nonnull NSData *)pushKit
                                     isSandbox:(BOOL)isSandbox
                                    completion:(void(^_Nullable)(NSError * _Nullable error))completion;

- (void)disablePushNotificationsWithCompletion:(void(^_Nullable)(NSError * _Nullable error))completion;

- (BOOL)isClientPushWithUserInfo:(nonnull NSDictionary *)userInfo;

- (void)processClientPushWithUserInfo:(nonnull NSDictionary *)userInfo
                          completion:(void(^_Nullable)(NSError * _Nullable error))completion;
@end

