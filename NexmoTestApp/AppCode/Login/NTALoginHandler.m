//
//  NTALoginHandler.m
//  NexmoTestApp
//
//  Created by Doron Biaz on 12/13/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NTALoginHandler.h"
#import "NTAUserInfo.h"
#import "NTAUserInfoProvider.h"
#import "NTALogger.h"
#import "NTAErrors.h"
#import "CommunicationsManager.h"
#import "AppDelegate.h"

static NTAUserInfo *_currentUser;
static BOOL _registeredForNexmoPushNotifications;

@implementation NTALoginHandler
#pragma mark - initialize
+(void)initialize {
    if(self != [NTALoginHandler self]) {
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self loadStateFromUserDefaults:defaults];
    
    //notifications
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(connectionStatusChangedWithNSNotification:) name:kNTACommunicationsManagerNotificationNameConnectionStatus object:nil];
}

+ (void)loadStateFromUserDefaults:(NSUserDefaults *)userDefaults {
    [self loadCurrentUserWithUserDefaults:userDefaults];
    [self loadPushRegistrationWithUserDefaults:userDefaults];
}

+ (void)loadCurrentUserWithUserDefaults:(NSUserDefaults *)defaults {
    if([defaults objectForKey:kNTALoginHandlerCurrentUserNamePreferencesKey] && [defaults objectForKey:kNTALoginHandlerCurrentUserPasswordPreferencesKey]) {
        NSString *userName = [defaults stringForKey:kNTALoginHandlerCurrentUserNamePreferencesKey];
        NSString *password = [defaults stringForKey:kNTALoginHandlerCurrentUserPasswordPreferencesKey];
        [NTAUserInfoProvider getUserInfoForUserName:userName password:password completion:^(NSError * _Nullable error, NTAUserInfo *userInfo) {
            if(error) {
                [NTALogger errorWithFormat:@"User %@ with password %@ saved in preferences is invalid", userName, password];
                _currentUser = nil;
            }
            
            _currentUser = userInfo;
        }];
    }
}

+ (void)loadPushRegistrationWithUserDefaults:(NSUserDefaults *)defaults {
    _registeredForNexmoPushNotifications = [defaults objectForKey:kNTALoginHandlerDidRegisterForNexmoPushPreferencesKey] ? YES : NO;
}


+ (NTAUserInfo *)currentUser {
    return _currentUser;
}

+ (void)loginCurrentUserWithCompletion:(void(^_Nullable)(NSError * _Nullable error, NTAUserInfo *userInfo))completion {
    NTAUserInfo *user = [self currentUser];
    if(!user) {
        [NTALogger error:@"NTALoginHandler failed login. loginCurrentUser called with no current user available"];
        NSError *error = [NTAErrors errorWithErrorCode:NXMTestAppErrorCodeTestAppCurrentUserNotFound andUserInfo:nil];
        if(completion) {
            completion(error, nil);
        }
    }
    
    [self loginWithUserName:user.name andPassword:user.password completion:^(NSError * _Nullable error, NTAUserInfo *userInfo) {
        completion(error, userInfo);
    
        if (!error && userInfo.csUserToken) {
            [CommunicationsManager.sharedInstance loginWithUserToken:userInfo.csUserToken];
        }
    }];
}

+ (void)loginWithUserName:(NSString *)userName andPassword:(NSString *)password completion:(void(^_Nullable)(NSError * _Nullable error, NTAUserInfo *userInfo))completion {
    [NTAUserInfoProvider getUserInfoForUserName:userName password:password completion:^(NSError * _Nullable error, NTAUserInfo *userInfo) {
        
        if(error) {
            [NTALogger errorWithFormat:@"NTALoginHandler failed login. User or password is incorrect. Error: %@", error];
            if(completion) {
                completion(error, nil);
            }
            return;
        }
        
        [self setCurrentUserWithUserName:userName password:password andUserInfo:userInfo];
        if(completion) {
            completion(nil, _currentUser);
        }
        
        NSDictionary *notificationUserInfo = @{kNTALoginHandlerNotificationKeyUser : [[self currentUser] copy]};
        [NSNotificationCenter.defaultCenter postNotificationName:kNTALoginHandlerNotificationNameUserDidLogin object:nil userInfo:notificationUserInfo];
    }];
}

+ (void)logoutWithCompletion:(void(^_Nullable)(NSError * _Nullable error))completion {
    NTAUserInfo *currentUser = [[self currentUser] copy];
    [self removeCurrentUser];
    [NSNotificationCenter.defaultCenter postNotificationName:kNTALoginHandlerNotificationNameUserDidLogout object:nil userInfo:@{kNTALoginHandlerNotificationKeyUser : currentUser}];
    
    if(_registeredForNexmoPushNotifications) {
        [self setNexmoPushRegistrationState:FALSE];
    }
    
    if(completion) {
        completion(nil);
    }
}

#pragma mark - Private
+ (void)removeCurrentUser {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences removeObjectForKey:kNTALoginHandlerCurrentUserNamePreferencesKey];
    [preferences removeObjectForKey:kNTALoginHandlerCurrentUserPasswordPreferencesKey];
    _currentUser = nil;
}

+ (void)setCurrentUserWithUserName:(NSString *)userName password:(NSString *)password andUserInfo:(NTAUserInfo *)userInfo {
    _currentUser = userInfo;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults  setObject:userName forKey:kNTALoginHandlerCurrentUserNamePreferencesKey];
    [userDefaults setObject:password forKey:kNTALoginHandlerCurrentUserPasswordPreferencesKey];
    const BOOL didSave = [userDefaults synchronize];
    if(!didSave) {
        [NTALogger errorWithFormat:@"Failed saving User %@ with password %@ in userDefaults", userName, password];
    }
}

#pragma mark nexmo push
+ (void)setNexmoPushRegistrationState:(BOOL)state {
    _registeredForNexmoPushNotifications = state;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if(state) {
        [userDefaults setObject:@(_registeredForNexmoPushNotifications) forKey:kNTALoginHandlerDidRegisterForNexmoPushPreferencesKey];
    } else {
        [userDefaults removeObjectForKey:kNTALoginHandlerDidRegisterForNexmoPushPreferencesKey];
    }
    
    const BOOL didSave = [userDefaults synchronize];
    if(!didSave) {
        [NTALogger errorWithFormat:@"Failed saving nexmo push state %@ in userDefaults", state];
    }
}

+ (void)disableNexmoPushWithCompletion:(void(^_Nullable)(NSError * _Nullable error))completion {
    [CommunicationsManager.sharedInstance disablePushNotificationsWithCompletion:^(NSError * _Nullable error) {
        if(error) {
            NSString *errorString  = [NSString stringWithFormat:@"Failed disabling Nexmo push with error: %@", error];
            [NTALogger error:errorString];
            
            if(completion) {
                completion([NTAErrors errorWithErrorCode:NXMTestAppErrorCodeFailedDisablingPush andUserInfo:nil]);
            }
            
            return;
        }
        
        [self setNexmoPushRegistrationState:FALSE];
        
        if(completion) {
            completion(nil);
        }
    }];
}

+ (void)connectionStatusChangedWithNSNotification:(NSNotification *)note {
    // TODO...
}

@end
