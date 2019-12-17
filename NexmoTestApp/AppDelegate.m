//
//  AppDelegate.m
//  NexmoTestApp
//
//  Created by Chen Lev on 12/9/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "AppDelegate.h"
#import "NTALogger.h"
#import "CommunicationsManager.h"
#import "MainFlow.h"

#import <AVFoundation/AVAudioSession.h>
#import <PushKit/PushKit.h>

@interface AppDelegate () <PKPushRegistryDelegate>
@property (nonatomic) UNUserNotificationCenter *notificationCenter;
@property (nonatomic) PKPushRegistry *pushKitRegister;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return true;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [[MainFlow sharedInstance] startMainFlowWithAppWindow:self.window];
    [NTALogger debug:@"#### Test APP - launch done ####"];
    [CommunicationsManager setLogger];
    
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)])
    {
        [[AVAudioSession sharedInstance] requestRecordPermission: ^ (BOOL response)
         {
             NSLog(@"iOS 7+: Allow microphone use response: %d", response);
         }];
    }
    
    //Regular Push Notification - (Local)
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    self.notificationCenter = center;
    self.notificationCenter.delegate = self;
    [self.notificationCenter requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                [[UIApplication sharedApplication] registerForRemoteNotifications];
                [NTALogger info:@"Push Authorization success"];
            } else {
                NSString *errorString = [NSString stringWithFormat:@"Push Authorization failed.\n"];
                errorString = [errorString stringByAppendingString:[NSString stringWithFormat:@"ERROR: %@ - %@\n", error.localizedFailureReason, error.localizedDescription]];
                errorString = [errorString stringByAppendingString:[NSString stringWithFormat:@"SUGGESTIONS: %@ - %@", error.localizedRecoveryOptions, error.localizedRecoverySuggestion]];

                [NTALogger error:errorString];
            }});
    }];
    
    //Push Kit
    self.pushKitRegister = [[PKPushRegistry alloc] initWithQueue:nil];
    self.pushKitRegister.delegate = self;
    self.pushKitRegister.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [NTALogger debug:@"#### Test APP - Background ####"];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    [NTALogger debug:@"#### Test APP - enter Foreground ####"];

    [UIApplication.sharedApplication setApplicationIconBadgeNumber:0];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [NTALogger debug:@"#### Test APP - became Active ####"];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [NTALogger debug:@"#### Test APP - will Terminate ####"];
}

#pragma mark - Push Notifications
- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    self.deviceToken = deviceToken;
    [NTALogger info:@"Push registration didRegisterForRemoteNotificationsWithDeviceToken"];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [NTALogger errorWithFormat:@"Push registration failed didFailToRegisterForRemoteNotificationsWithError with error %@", error];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler
{
    NSDictionary *userInfo = notification.request.content.userInfo;
    [NTALogger infoWithFormat:@"NTA Handle Push from foreground with userInfo: %@",userInfo];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler
{
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    [NTALogger infoWithFormat:@"NTA Handle Push from background or closed with userInfo: %@",userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler {
    [NTALogger infoWithFormat:@"NTA Handle Push Silent with userInfo: %@",userInfo];
}


- (void)fireLocalNotificationWithUserInfo:(NSDictionary *)userInfo {
    UNMutableNotificationContent *notificationContent = [[UNMutableNotificationContent alloc] init];

    notificationContent.title = @"incoming call";
    //  notificationContent.body = message;
    //  notificationContent.sound = [UNNotificationSound defaultSound];
    notificationContent.userInfo = userInfo;
    notificationContent.badge = @(1);

    UNNotificationTrigger *notificationTrigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];

    NSString *notificationIdentifier = [[NSUUID UUID] UUIDString];
    UNNotificationRequest *notificationRequest = [UNNotificationRequest requestWithIdentifier:notificationIdentifier content:notificationContent trigger:notificationTrigger];

    [ [UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:notificationRequest withCompletionHandler:^(NSError * _Nullable error) {
        if(error) {
            [NTALogger errorWithFormat:@"Failed firing local notification with error: %@", error];
        }
    }];
}

- (void)fireProcessingNexmoPushWithUserInfo:(NSDictionary *)userInfo {
    UNMutableNotificationContent *notificationContent = [[UNMutableNotificationContent alloc] init];
    
    notificationContent.title = @"Processing Nexmo Push";
    //  notificationContent.body = message;
    //  notificationContent.sound = [UNNotificationSound defaultSound];
    notificationContent.userInfo = userInfo;
    notificationContent.badge = @(1);
    
    UNNotificationTrigger *notificationTrigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
    
    NSString *notificationIdentifier = [[NSUUID UUID] UUIDString];
    UNNotificationRequest *notificationRequest = [UNNotificationRequest requestWithIdentifier:notificationIdentifier content:notificationContent trigger:notificationTrigger];
    
    [ [UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:notificationRequest withCompletionHandler:^(NSError * _Nullable error) {
        if(error) {
            [NTALogger errorWithFormat:@"Failed firing local notification with error: %@", error];
        }
    }];
}

#pragma mark - Push Kit Notifications Delegate


- (void)pushRegistry:(nonnull PKPushRegistry *)registry didUpdatePushCredentials:(nonnull PKPushCredentials *)pushCredentials forType:(nonnull PKPushType)type {
    [NTALogger info:@"PushKit token updated"];
    self.pushKitToken = pushCredentials.token;
}

- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(PKPushType)type {
    self.pushKitToken = nil;
    [NTALogger info:@"PushKit token invalidated"];
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type withCompletionHandler:(void (^)(void))completion {
    [NTALogger infoWithFormat:@"PushKit push with payload: %@", payload.dictionaryPayload];
    if([CommunicationsManager.sharedInstance isClientPushWithUserInfo: payload.dictionaryPayload]) {
        [self fireProcessingNexmoPushWithUserInfo:payload.dictionaryPayload];
        if (CommunicationsManager.sharedInstance.client.connectionStatus != NXMConnectionStatusConnected) {
            NSString *token = [CommunicationsManager.sharedInstance.client getToken];
            [CommunicationsManager.sharedInstance.unprocessedPushPayloads addObject:payload];
            [CommunicationsManager.sharedInstance.client loginWithAuthToken:token];
            return;
        }

        [self handlePushNotificationWithUserInfo:payload.dictionaryPayload];
    }
}

- (void)handlePushNotificationWithUserInfo:(NSDictionary *)userInfo {
    [NTALogger info:@"Handeling nexmo voip push"];
    [CommunicationsManager.sharedInstance processClientPushWithUserInfo:userInfo completion:^(NSError * _Nullable error) {
        if(error) {
            [NTALogger errorWithFormat:@"Error processing nexmo push: %@", error];
        }
    }];
}

@end
