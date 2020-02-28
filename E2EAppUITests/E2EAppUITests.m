@import XCTest;
#import "LoginViewController.h"

static NSString * const VARS_JSON_FILE_NAME = @"vars";
static NSString * const ENV_NAME_JSON_KEY = @"envName";
static NSString * const USER_TOKEN_JSON_KEY = @"userToken";

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
    NSDictionary *varsDictionary = [self varsDictionary];
    NSString *envName = varsDictionary[ENV_NAME_JSON_KEY];
    NSString *userToken = varsDictionary[USER_TOKEN_JSON_KEY];
    return @[[self argumentNameFor:[LoginViewController npeNameLaunchArgument]], envName,
             [self argumentNameFor:[LoginViewController userTokenLaunchArgument]], userToken];
}

- (nonnull NSDictionary *)varsDictionary {
    NSString *path = [[NSBundle bundleForClass:self.class] pathForResource:VARS_JSON_FILE_NAME ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    return [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
}

- (nonnull NSString *)argumentNameFor:(nonnull NSString *)name {
    return [NSString stringWithFormat:@"-%@", name];
}

- (void)testLoginSuccessful {
    XCUIElement *loginStatusLabel = self.app.staticTexts[[LoginViewController connectedStatusText]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"exists == true"];
    [self expectationForPredicate:predicate evaluatedWithObject:loginStatusLabel handler:nil];

    [self.app.buttons[[LoginViewController loginButtonAccessibilityId]] tap];

    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssert(loginStatusLabel.exists);
}

@end
