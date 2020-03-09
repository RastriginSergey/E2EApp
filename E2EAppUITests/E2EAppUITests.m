@import XCTest;
#import "LoginViewController.h"
#import "E2EAppUITests-Swift.h"

static NSString * const VARS_JSON_FILE_NAME = @"vars";
static NSString * const ENV_NAME_JSON_KEY = @"envName";
static NSString * const RS256_PRIVATE_KEY = @"rs256PrivateKey";
static NSString * const APPLICATION_ID = @"applicationId";
static NSString * const USERNAME = @"username";

@interface E2EAppUITests : XCTestCase
@property XCUIApplication *app;
@end

@implementation E2EAppUITests

- (void)setUp {
    self.continueAfterFailure = NO;

    self.app = [XCUIApplication new];
    NSDictionary *varsDictionary = [self getVarsDictionary];
    self.app.launchArguments = [self.class launchArgumentsFrom:varsDictionary];
    [self.app launch];
}

- (void)testLoginSuccessful {
    XCUIElement *loginStatusLabel = self.app.staticTexts[LoginViewController.connectedStatusText];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"exists == true"];
    [self expectationForPredicate:predicate evaluatedWithObject:loginStatusLabel handler:nil];

    [self.app.buttons[LoginViewController.loginButtonAccessibilityId] tap];

    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssert(loginStatusLabel.exists);
}

- (nonnull NSDictionary *)getVarsDictionary {
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    NSString *varsJsonPath = [bundle pathForResource:VARS_JSON_FILE_NAME ofType:@"json"];
    NSData *varsData = [NSData dataWithContentsOfFile:varsJsonPath];
    return [self.class varsDictionaryFrom:varsData];
}

+ (nonnull NSDictionary *)varsDictionaryFrom:(nonnull NSData *)data {
    return [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)kNilOptions error:nil];
}

+ (nonnull NSArray<NSString *> *)launchArgumentsFrom:(nonnull NSDictionary *)varsDictionary {
    NSString *envName = varsDictionary[ENV_NAME_JSON_KEY];
    NSString *privateKey = varsDictionary[RS256_PRIVATE_KEY];
    NSString *applicationId = varsDictionary[APPLICATION_ID];
    NSString *username = varsDictionary[USERNAME];
    NSString *userToken = [JWTGenerator generateTokenWithPrivateKey:privateKey
                                                      applicationId:applicationId
                                                           username:username];
    return @[[self.class argumentNameFor:LoginViewController.npeNameLaunchArgument], envName,
             [self.class argumentNameFor:LoginViewController.userTokenLaunchArgument], userToken];
}

+ (nonnull NSString *)argumentNameFor:(nonnull NSString *)name {
    return [NSString stringWithFormat:@"-%@", name];
}

@end
