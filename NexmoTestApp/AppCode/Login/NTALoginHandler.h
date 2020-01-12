//
//  NTALoginHandler.h
//  NexmoTestApp
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTALoginHandlerDefine.h"
#import "NTAUserInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface NTALoginHandler : NSObject

+ (NTAUserInfo *)currentUser;

+ (void)loginCurrentUserWithCompletion:(void(^_Nullable)(NSError * _Nullable error, NTAUserInfo *userInfo))completion;

+ (void)loginWithUserName:(NSString *)userName andPassword:(NSString *)password completion:(void(^_Nullable)(NSError * _Nullable error, NTAUserInfo *userInfo))completion;

+ (void)logoutWithCompletion:(void(^_Nullable)(NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END

