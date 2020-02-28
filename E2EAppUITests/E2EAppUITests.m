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
    NSString *envName = NSProcessInfo.processInfo.environment[ENV_NAME_ENV_VAR];
    NSString *userToken = NSProcessInfo.processInfo.environment[USER_TOKEN_ENV_VAR];
    self.app.launchArguments = @[[self argumentNameFor:NPE_NAME_LAUNCH_ARG], envName,
                                 [self argumentNameFor:USER_TOKEN_LAUNCH_ARG], userToken];
    [self.app launch];

    self.continueAfterFailure = NO;
}

- (nonnull NSString *)argumentNameFor:(nonnull NSString *)name {
    return [NSString stringWithFormat:@"-%@", name];
}

- (void)testLoginSuccessful {
    XCUIElement *connectedLabel = self.app.staticTexts[CONNECTED_STATUS_TEXT];
    NSPredicate *existsPredicate = [NSPredicate predicateWithFormat:@"exists == true"];
    [self expectationForPredicate:existsPredicate evaluatedWithObject:connectedLabel handler:nil];

    [self.app.buttons[@"Login"] tap];

    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssert(connectedLabel.exists);
}

@end
