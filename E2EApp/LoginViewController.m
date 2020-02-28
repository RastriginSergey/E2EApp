#import "LoginViewController.h"

static NSString * const API_URL_FORMAT = @"https://%@-api.npe.nexmo.io";
static NSString * const WEBSOCKET_URL_FORMAT = @"https://%@-ws.npe.nexmo.io";
static NSString * const IPS_URL = @"https://api.dev.nexmoinc.net/play4/v1/image";

static NSString * const NOT_DEFINED_TEXT = @"-";

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UILabel *loginStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *npeNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *userTokenLabel;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.loginButton.accessibilityIdentifier = LOGIN_BUTTON_ACCESSIBILITY_ID;
    self.loginStatusLabel.accessibilityIdentifier = LOGIN_STATUS_LABEL_ACCESSIBILITY_ID;

    self.loginStatusLabel.text = NOT_DEFINED_TEXT;
    self.npeNameLabel.text = [self npeName];
    self.userTokenLabel.text = [self userToken];
}

- (IBAction)onLoginButtonTouchUpInside:(UIButton *)sender {
    [NXMClient setConfiguration: [self clientConfig]];
    [NXMClient.shared setDelegate:self];

    [NXMClient.shared loginWithAuthToken:[self userToken]];
}

- (nonnull NXMClientConfig *)clientConfig {
    NSString *npeName = [self npeName];
    NSString *apiUrl = [NSString stringWithFormat:API_URL_FORMAT, npeName];
    NSString *websocketUrl = [NSString stringWithFormat:WEBSOCKET_URL_FORMAT, npeName];
    return [[NXMClientConfig alloc] initWithApiUrl:apiUrl websocketUrl:websocketUrl ipsUrl:IPS_URL];
}

- (nonnull NSString *)npeName {
    NSString *npeName = [NSUserDefaults.standardUserDefaults stringForKey:NPE_NAME_LAUNCH_ARG];
    return npeName.length == 0 ? NOT_DEFINED_TEXT : npeName;
}

- (nonnull NSString *)userToken {
    NSString *userToken = [NSUserDefaults.standardUserDefaults stringForKey:USER_TOKEN_LAUNCH_ARG];
    return userToken.length == 0 ? NOT_DEFINED_TEXT : userToken;
}

#pragma mark - NXMClientDelegate

- (void)client:(nonnull NXMClient *)client didChangeConnectionStatus:(NXMConnectionStatus)status reason:(NXMConnectionStatusReason)reason {
    switch (status) {
        case NXMConnectionStatusDisconnected:
            [self updateLoginStatusLabel:DISCONNECTED_STATUS_TEXT];
            break;
        case NXMConnectionStatusConnecting:
            [self updateLoginStatusLabel:CONNECTING_STATUS_TEXT];
            break;
        case NXMConnectionStatusConnected:
            [self updateLoginStatusLabel:CONNECTED_STATUS_TEXT];
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
