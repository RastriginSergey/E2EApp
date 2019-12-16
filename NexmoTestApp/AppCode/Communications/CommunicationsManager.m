//
//  NexmoClientWrapper.m
//  NexmoTestApp
//
//  Copyright © 2018 Vonage. All rights reserved.
//


#import "CommunicationsManager.h"
#import "NTAUserInfo.h"
#import "NTALoginHandler.h"
#import "NTALogger.h"

@interface CommunicationsManager()
@property (nonatomic, nonnull, readwrite) NXMClient *client;
@end

@implementation CommunicationsManager

+ (nonnull CommunicationsManager *)sharedInstance {
    
    static CommunicationsManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [CommunicationsManager new];
    });
    
    return sharedInstance;
}

+ (void)setLogger {
    [NXMLogger setLogLevel:NXMLoggerLevelVerbose];
}

#pragma mark - init
- (instancetype)init {
    if(self = [super init]) {        
        //notifications
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(NTADidLoginWithNSNotification:) name:kNTALoginHandlerNotificationNameUserDidLogin object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(NTADidLogoutWithNSNotification:) name:kNTALoginHandlerNotificationNameUserDidLogout object:nil];
        
        if (NTALoginHandler.currentUser) {
            [self setupClientWithUser:NTALoginHandler.currentUser];
            [self login];
        }
    }
    return self;
}


#pragma public

+ (NSString *)statusReasonToString:(NXMConnectionStatusReason)status {
    switch (status) {
        case NXMConnectionStatusReasonUnknown:
            return @"ReasonUnknown";
        case NXMConnectionStatusReasonLogin:
            return @"ReasonLogin";
        case NXMConnectionStatusReasonLogout:
            return @"ReasonLogout";
        case NXMConnectionStatusReasonTokenRefreshed:
            return @"ReasonTokenRefreshed";
        case NXMConnectionStatusReasonTokenInvalid:
            return @"ReasonTokenInvalid";
        case NXMConnectionStatusReasonTokenExpired:
            return @"ReasonTokenExpired";
        case NXMConnectionStatusReasonTerminated:
            return @"ReasonSessionTerminated";
        case NXMConnectionStatusReasonUserNotFound:
            return @"ReasonUserNotFound";
        default:
            break;
    }
    
    return @"invalid reason";
}

- (void)enablePushNotificationsWithDeviceToken:(nonnull NSData *)deviceToken
                                     pushKit:(nonnull NSData *)pushKit
                                     isSandbox:(BOOL)isSandbox
                                    completion:(void(^_Nullable)(NSError * _Nullable error))completion {
    [self.client enablePushNotificationsWithPushKitToken:pushKit
                                   userNotificationToken:deviceToken
                                               isSandbox:isSandbox
                                      completionHandler:completion];
}

- (void)disablePushNotificationsWithCompletion:(void(^_Nullable)(NSError * _Nullable error))completion {
    [self.client disablePushNotifications:completion];
}

- (BOOL)isClientPushWithUserInfo:(nonnull NSDictionary *)userInfo {
    return [self.client isNexmoPushWithUserInfo:userInfo];
}

- (void)processClientPushWithUserInfo:(nonnull NSDictionary *)userInfo
                           completion:(void(^_Nullable)(NSError * _Nullable error))completion {
    [self.client processNexmoPushWithUserInfo:userInfo
                            completionHandler:completion];
}

#pragma mark - post notifications

- (void)didChangeConnectionStatus:(NXMConnectionStatus)connectionStatus WithReason:(NXMConnectionStatusReason)reason {
    NSDictionary *userInfo = @{
                               kNTACommunicationsManagerNotificationKeyConnectionStatus:@(connectionStatus),
                               kNTACommunicationsManagerNotificationKeyConnectionStatusReason: @(reason)
                               };
    [NSNotificationCenter.defaultCenter postNotificationName:kNTACommunicationsManagerNotificationNameConnectionStatus object:nil userInfo:userInfo];
}

- (void)didgetIncomingCall:(NXMCall *)call {
    NSDictionary *userInfo = @{
                               kNTACommunicationsManagerNotificationKeyIncomingCall:call
                               };
    [NSNotificationCenter.defaultCenter postNotificationName:kNTACommunicationsManagerNotificationNameIncomingCall object:nil userInfo:userInfo];
}

#pragma mark - stitchClientDelegate

- (void)client:(nonnull NXMClient *)client didChangeConnectionStatus:(NXMConnectionStatus)status reason:(NXMConnectionStatusReason)reason {
    [self didChangeConnectionStatus:status WithReason:reason];
}

- (void)tokenRefreshed {
    //TODO: add to observer
}

- (void)client:(nonnull NXMClient *)client didReceiveCall:(nonnull NXMCall *)call {
    [NTALogger info:@"Communications Manager - Nexmo Client incoming call"];
    [self didgetIncomingCall:call];
}

- (void)client:(nonnull NXMClient *)client didReceiveConversation:(nonnull NXMConversation *)conversation {
    
}

- (void)client:(nonnull NXMClient *)client didReceiveError:(nonnull NSError *)error {
    [NTALogger info:[NSString stringWithFormat:@"Communications Manager - Nexmo Client Error %@", error.description]];

}




#pragma mark - LoginHandler notifications
- (void)NTADidLoginWithNSNotification:(NSNotification *)note {
    NTAUserInfo *user = note.userInfo[kNTALoginHandlerNotificationKeyUser];
    [self setupClientWithUser:user];
}

- (void)NTADidLogoutWithNSNotification:(NSNotification *)note {
    [self logout];
}

- (void)login {
    //[self.client loginWithAuthToken:(NSString *)authToken];
}

- (void)logout {
    [self.client logout];
}

- (void)setupClientWithUser:(NTAUserInfo *)userInfo {
    if(self.client) { //TODO: this is because creating two clients without holding reference to both creates crashes in miniRTC. change after it is fixed
        return;
    }
    
    NXMClientConfig* config = [[NXMClientConfig alloc] init];
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString* npeName = infoDict[@"NpeName"];
    if ([npeName caseInsensitiveCompare:@"prod"] != NSOrderedSame){
        NSString* restUrl = [NSString stringWithFormat:@"https://%@-api.npe.nexmo.io/",npeName];
        NSString* wsUrl = [NSString stringWithFormat:@"https://%@-ws.npe.nexmo.io/",npeName];
        NSString* ipsUrl = [restUrl stringByAppendingString:@"v1/image/"];
        config = [[NXMClientConfig alloc] initWithApiUrl:restUrl websocketUrl:wsUrl ipsUrl:ipsUrl];
    }
    [NXMClient setConfiguration:config];
    
    self.client = NXMClient.shared;

    [self.client setDelegate:self];
    [self.client loginWithAuthToken:@"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBsaWNhdGlvbl9pZCI6ImYxYTVmNmZhLTdkNzQtNGI5Ny1iZGY0LTRlY2FhZThlODUxZSIsInN1YiI6InRlc3R1c2VyMTIiLCJpc3MiOiJLb3N0YXMiLCJhY2wiOnsicGF0aHMiOnt9fSwianRpIjoiMTU3NjUwNzA4NzE2NSIsImV4cCI6MTg5MTg2NzA4NywiaWF0IjoxNTc2NTA3MDg3LjAsIm5iZiI6MTU3NjUwNzA4Ny4wfQ.ie5TegO6u94bLpUomk4zG_MQhz99KQH3WL-gT0-sTmHwjuhoKcGNbE_AQd135DQMm3soUy4U-OaGSemGoBtqzsCkZrt-soUV3Yw53FS3Fo7FkYlwNQy1c9xT1MVFudSKNbbPWSzRT89IMZMg0WS01S5-1M0XISWvNlY7Xbv-jwZXfsueRV-ObBE3zCKcBTIvNO_aOBkeRhrFTCAtIFxKzLlYs7ukJofHegUfOZ0YE7R01Z_LTMzWo9A3VTLT_ZSVbrvZeX2Uyy-Ej4WlpsOViTOqhDpOsh-Edce8cWPKVfZNtp-mFxajlGcr_jCr7JvK_P108o0gXUjt5EfFgsAsBQ"];
}

@end

