@import XCTest;
#import "LoginViewController.h"

//static NSString * const ENV_NAME_ENV_VAR = @"ENV_NAME";
//static NSString * const USER_TOKEN_ENV_VAR = @"USER_TOKEN";

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
//    NSString *envName = NSProcessInfo.processInfo.environment[ENV_NAME_ENV_VAR];
//    NSString *userToken = NSProcessInfo.processInfo.environment[USER_TOKEN_ENV_VAR];
    NSDictionary *varsDictionary = [self varsDictionaryFromJsonFile];
    NSString *envName = varsDictionary[@"envName"];
    NSString *userToken = varsDictionary[@"userToken"];
    return @[[self argumentNameFor:[LoginViewController npeNameLaunchArgument]], envName,
             [self argumentNameFor:[LoginViewController userTokenLaunchArgument]], userToken];
}

- (nonnull NSDictionary *)varsDictionaryFromJsonFile {
    NSString *path = [[NSBundle bundleForClass:self.class] pathForResource:@"vars" ofType:@"json"];
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
