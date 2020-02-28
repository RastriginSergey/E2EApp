@import XCTest;
#import "LoginViewController.h"

static NSString * const ENV_NAME_ENV_VAR = @"ENV_NAME";
static NSString * const USER_TOKEN_ENV_VAR = @"USER_TOKEN";

@interface E2EAppUITests : XCTestCase
@property XCUIApplication *app;
@end

@implementation E2EAppUITests

- (void)setUp {
    self.app = [XCUIApplication new];
    self.app.launchArguments = [self launchArguments];
    [self.app launch];

    self.continueAfterFailure = NO;
}

- (nonnull NSArray<NSString *> *)launchArguments {
    NSString *envName = NSProcessInfo.processInfo.environment[ENV_NAME_ENV_VAR];
    NSString *userToken = NSProcessInfo.processInfo.environment[USER_TOKEN_ENV_VAR];
    return @[[self argumentNameFor:NPE_NAME_LAUNCH_ARG], envName,
             [self argumentNameFor:USER_TOKEN_LAUNCH_ARG], userToken];
}

- (nonnull NSString *)argumentNameFor:(nonnull NSString *)name {
    return [NSString stringWithFormat:@"-%@", name];
}

- (void)testLoginSuccessful {
    XCUIElement *loginStatusLabel = self.app.staticTexts[CONNECTED_STATUS_TEXT];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"exists == true"];
    [self expectationForPredicate:predicate evaluatedWithObject:loginStatusLabel handler:nil];

    [self.app.buttons[LOGIN_BUTTON_ACCESSIBILITY_ID] tap];

    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssert(loginStatusLabel.exists);
}

@end
