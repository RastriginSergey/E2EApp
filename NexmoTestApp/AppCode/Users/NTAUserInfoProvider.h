//
//  NTATokenProvider.h
//  NexmoTestApp
//
//  Created by Chen Lev on 12/9/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTAUserInfo.h"

NS_ASSUME_NONNULL_BEGIN
@interface NTAUserInfoProvider : NSObject
+ (NTAUserInfo *)getDefaultUser;
+ (NTAUserInfo *)getRandomUserForTestGroup;
+ (NTAUserInfo *)getRandomUserForBabyGroup;
+ (NTAUserInfo *)getRandomUserForDemoGroup;

+ (NSArray<NTAUserInfo *> *)getAllUsersWithRequestingUser:(NTAUserInfo *)requestingUser;
+ (NTAUserInfo *)getUserInfoForCSUserName:(nonnull NSString *)csUserName;

+ (void)getUserInfoForUserName:(nonnull NSString *)userName
               password:(NSString *)password
             completion:(void(^_Nullable)(NSError * _Nullable error, NTAUserInfo *userInfo))completion;

+ (NSString *)getUserNameForCSUserName:(nonnull NSString *)csUserName;
+ (NSString *)getUserDisplayNameForUserName:(NSString *)userName;
NS_ASSUME_NONNULL_END
@end


