#import "LoginViewController.h"

static NSString * const API_URL_FORMAT = @"https://%@-api.npe.nexmo.io";
static NSString * const WEBSOCKET_URL_FORMAT = @"https://%@-ws.npe.nexmo.io";
static NSString * const IPS_URL = @"https://api.dev.nexmoinc.net/play4/v1/image";

static NSString * const NPE_NAME_LAUNCH_ARG = @"npeName";
static NSString * const USER_TOKEN_LAUNCH_ARG = @"userToken";

static NSString * const DISCONNECTED_STATUS_TEXT = @"Disconnected";
static NSString * const CONNECTING_STATUS_TEXT = @"Connecting";
static NSString * const CONNECTED_STATUS_TEXT = @"Connected";
static NSString * const NOT_DEFINED_TEXT = @"-";

static NSString * const LOGIN_BUTTON_ACCESSIBILITY_ID = @"loginButtonId";
static NSString * const LOGIN_STATUS_LABEL_ACCESSIBILITY_ID = @"loginStatusLabelId";

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
    self.npeNameLabel.text = [self getNpeName];
    self.userTokenLabel.text = [self.class shortUserTokenFrom:[self getUserToken]];
}

- (IBAction)onLoginButtonTouchUpInside:(UIButton *)sender {
    [NXMClient setConfiguration:[self getClientConfig]];
    [NXMClient.shared setDelegate:self];

    [NXMClient.shared loginWithAuthToken:[self getUserToken]];
}

- (nonnull NXMClientConfig *)getClientConfig {
    NSString *npeName = [self getNpeName];
    NSString *apiUrl = [NSString stringWithFormat:API_URL_FORMAT, npeName];
    NSString *websocketUrl = [NSString stringWithFormat:WEBSOCKET_URL_FORMAT, npeName];
    return [[NXMClientConfig alloc] initWithApiUrl:apiUrl websocketUrl:websocketUrl ipsUrl:IPS_URL];
}

- (nonnull NSString *)getNpeName {
    NSString *npeName = [NSUserDefaults.standardUserDefaults stringForKey:NPE_NAME_LAUNCH_ARG];
    return npeName.length == 0 ? NOT_DEFINED_TEXT : npeName;
}

- (nonnull NSString *)getUserToken {
    NSString *userToken = [NSUserDefaults.standardUserDefaults stringForKey:USER_TOKEN_LAUNCH_ARG];
    return userToken.length == 0 ? NOT_DEFINED_TEXT : userToken;
}

+ (nonnull NSString *)shortUserTokenFrom:(nonnull NSString *)userToken {
    NSUInteger prefixLength = 6;
    NSUInteger suffixLength = 10;
    NSUInteger minUserTokenLength = 1 + prefixLength + suffixLength;
    NSString *shortUserToken = NOT_DEFINED_TEXT;
    if (userToken.length > 0 && userToken.length < minUserTokenLength) {
        shortUserToken = userToken;
    } else if (userToken.length >= minUserTokenLength) {
        NSString *prefix = [userToken substringToIndex:prefixLength];
        NSString *suffix = [userToken substringFromIndex:userToken.length - suffixLength];
        shortUserToken = [NSString stringWithFormat:@"%@ ... %@", prefix, suffix];
    }
    return shortUserToken;
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

#pragma mark - Static 'properties'

+ (NSString *)npeNameLaunchArgument {
    return NPE_NAME_LAUNCH_ARG;
}

+ (NSString *)userTokenLaunchArgument {
    return USER_TOKEN_LAUNCH_ARG;
}

+ (NSString *)connectedStatusText {
    return CONNECTED_STATUS_TEXT;
}

+ (NSString *)loginButtonAccessibilityId {
    return LOGIN_BUTTON_ACCESSIBILITY_ID;
}

+ (NSString *)loginStatusLabelAccessibilityId {
    return LOGIN_STATUS_LABEL_ACCESSIBILITY_ID;
}

@end
