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
    self.continueAfterFailure = NO;

    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    NSString *varsJsonPath = [bundle pathForResource:VARS_JSON_FILE_NAME ofType:@"json"];
    NSData *varsData = [NSData dataWithContentsOfFile:varsJsonPath];
    NSDictionary *varsDictionary = [self.class varsDictionaryFrom:varsData];

    self.app = [XCUIApplication new];
    self.app.launchArguments = [self.class launchArgumentsFrom:varsDictionary];
    [self.app launch];
}

+ (nonnull NSDictionary *)varsDictionaryFrom:(nonnull NSData *)data {
    return [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)kNilOptions error:nil];
}

+ (nonnull NSArray<NSString *> *)launchArgumentsFrom:(nonnull NSDictionary *)varsDictionary {
    NSString *envName = varsDictionary[ENV_NAME_JSON_KEY];
    NSString *userToken = varsDictionary[USER_TOKEN_JSON_KEY];
    return @[[self.class argumentNameFor:LoginViewController.npeNameLaunchArgument], envName,
             [self.class argumentNameFor:LoginViewController.userTokenLaunchArgument], userToken];
}

+ (nonnull NSString *)argumentNameFor:(nonnull NSString *)name {
    return [NSString stringWithFormat:@"-%@", name];
}

- (void)testLoginSuccessful {
    XCUIElement *loginStatusLabel = self.app.staticTexts[LoginViewController.connectedStatusText];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"exists == true"];
    [self expectationForPredicate:predicate evaluatedWithObject:loginStatusLabel handler:nil];

    [self.app.buttons[LoginViewController.loginButtonAccessibilityId] tap];

    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssert(loginStatusLabel.exists);
}

@end
