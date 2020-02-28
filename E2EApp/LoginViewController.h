@import UIKit;
@import NexmoClient;

@interface LoginViewController : UIViewController <NXMClientDelegate>

+ (nonnull NSString *)npeNameLaunchArgument;
+ (nonnull NSString *)userTokenLaunchArgument;

+ (nonnull NSString *)connectedStatusText;

+ (nonnull NSString *)loginButtonAccessibilityId;
+ (nonnull NSString *)loginStatusLabelAccessibilityId;

@end
