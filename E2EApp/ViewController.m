//
//  ViewController.m
//  E2EApp
//
//  Created by Sergei Rastrigin on 31/01/2020.
//  Copyright © 2020 Sergei Rastrigin. All rights reserved.
//

#import "ViewController.h"

static NSString * const API_URL_FORMAT = @"https://%@-api.npe.nexmo.io";
static NSString * const WEBSOCKET_URL_FORMAT = @"https://%@-ws.npe.nexmo.io";
static NSString * const IPS_URL = @"https://api.dev.nexmoinc.net/play4/v1/image";

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *loginStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *npeNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *userTokenLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.loginStatusLabel.text = @"-";

    self.npeNameLabel.text = [self npeName];
    self.userTokenLabel.text = [self userToken];
}

- (IBAction)onLoginButtonTouchUpInside:(UIButton *)sender {
    /* TODO:
     Jenkins build params (NPE name, user token) -> XCUITest (-> App)
     */

    NSString *npeName = [self npeName];

    NXMClientConfig *clientConfig = [[NXMClientConfig alloc] initWithApiUrl:[NSString stringWithFormat:API_URL_FORMAT, npeName]
                                                               websocketUrl:[NSString stringWithFormat:WEBSOCKET_URL_FORMAT, npeName]
                                                                     ipsUrl:IPS_URL];

    [NXMClient setConfiguration: clientConfig];
    [NXMClient.shared setDelegate:self];

    [NXMClient.shared loginWithAuthToken:[self userToken]];
}

- (nonnull NSString *)npeName {
    return NSProcessInfo.processInfo.environment[@"ENV_NAME"];
}

- (nonnull NSString *)userToken {
    return NSProcessInfo.processInfo.environment[@"USER_TOKEN"];
}

#pragma mark - NXMClientDelegate

- (void)client:(nonnull NXMClient *)client didChangeConnectionStatus:(NXMConnectionStatus)status reason:(NXMConnectionStatusReason)reason {
    switch (status) {
        case NXMConnectionStatusDisconnected:
            [self updateLoginStatusLabel:@"Disconnected"];
            break;
        case NXMConnectionStatusConnecting:
            [self updateLoginStatusLabel:@"Connecting"];
            break;
        case NXMConnectionStatusConnected:
            [self updateLoginStatusLabel:@"Connected"];
            break;
    }
}

- (void)client:(nonnull NXMClient *)client didReceiveError:(nonnull NSError *)error { }

- (void)updateLoginStatusLabel:(nonnull NSString *)text {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.loginStatusLabel.text = text;
    });
}

@end
