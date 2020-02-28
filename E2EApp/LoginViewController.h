@import UIKit;
@import NexmoClient;

static NSString * const NPE_NAME_LAUNCH_ARG = @"npeName";
static NSString * const USER_TOKEN_LAUNCH_ARG = @"userToken";

static NSString * const DISCONNECTED_STATUS_TEXT = @"Disconnected";
static NSString * const CONNECTING_STATUS_TEXT = @"Connecting";
static NSString * const CONNECTED_STATUS_TEXT = @"Connected";

@interface LoginViewController : UIViewController <NXMClientDelegate>

@end
