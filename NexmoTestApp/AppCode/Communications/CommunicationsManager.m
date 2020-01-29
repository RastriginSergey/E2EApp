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
        self.unprocessedPushPayloads = [NSMutableArray new];

        //notifications
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(NTADidLoginWithNSNotification:) name:kNTALoginHandlerNotificationNameUserDidLogin object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(NTADidLogoutWithNSNotification:) name:kNTALoginHandlerNotificationNameUserDidLogout object:nil];
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
    [self.client processNexmoPushPayload:userInfo];
}

#pragma mark - post notifications

- (void)didChangeConnectionStatus:(NXMConnectionStatus)connectionStatus WithReason:(NXMConnectionStatusReason)reason {
    if (connectionStatus == NXMConnectionStatusConnected) {
        [self handleUnprocessedPushNotifications];
    }
    NSDictionary *userInfo = @{
                               kNTACommunicationsManagerNotificationKeyConnectionStatus:@(connectionStatus),
                               kNTACommunicationsManagerNotificationKeyConnectionStatusReason: @(reason)
                               };
    [NSNotificationCenter.defaultCenter postNotificationName:kNTACommunicationsManagerNotificationNameConnectionStatus object:nil userInfo:userInfo];
}

- (void)handleUnprocessedPushNotifications {
    for (PKPushPayload *payload in self.unprocessedPushPayloads) {
        [self handlePushNotificationWithUserInfo:payload.dictionaryPayload];
    }
    [self.unprocessedPushPayloads removeAllObjects];
}

- (void)handlePushNotificationWithUserInfo:(NSDictionary *)userInfo {
    [NTALogger info:@"Handeling nexmo voip push"];
    [CommunicationsManager.sharedInstance processClientPushWithUserInfo:userInfo completion:^(NSError * _Nullable error) {
        if(error) {
            [NTALogger errorWithFormat:@"Error processing nexmo push: %@", error];
        }
    }];
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
    [self setupClientWithUserToken:user.csUserToken];
}

- (void)NTADidLogoutWithNSNotification:(NSNotification *)note {
    [self logout];
}

- (void)loginWithUserToken:(NSString *)userToken {
    [self setupClientWithUserToken:userToken];
}

- (void)logout {
    [self.client logout];
}

- (void)setupClientWithUserToken:(NSString *)userToken {
    if(self.client) { //TODO: this is because creating two clients without holding reference to both creates crashes in miniRTC. change after it is fixed
        
        [self.client loginWithAuthToken:userToken];
        
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
    [self.client loginWithAuthToken:userToken];
}

@end

