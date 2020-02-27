//
//  E2EAppUITests.m
//  E2EAppUITests
//
//  Created by Sergei Rastrigin on 31/01/2020.
//  Copyright © 2020 Sergei Rastrigin. All rights reserved.
//

@import XCTest;

@interface E2EAppUITests : XCTestCase

@property XCUIApplication *app;

@end

@implementation E2EAppUITests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.

    // UI tests must launch the application that they test.
    self.app = [XCUIApplication new];
    [self.app launch];

    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;

    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

//- (void)testExample {
//    // Use recording to get started writing UI tests.
//    // Use XCTAssert and related functions to verify your tests produce the correct results.
//    XCTAssertTrue(YES);
//}

/*
xcodebuild test-without-building -project NXMiOSSDK.xcodeproj \
    -scheme NexmoE2EApp \
    -destination 'platform=iOS Simulator,name=iPhone 8,OS=13.3' \
    NPE_ENV_NAME='Correct value'
 */
//- (void)testNpeEnvNameEnvironmentVariable {
//    NSString *envName = NSProcessInfo.processInfo.environment[@"ENV_NAME"];
//    XCTAssertTrue([envName isEqualToString:@"Correct value"]);
//}

- (void)testLoginSuccessful {
    [self.app.buttons[@"Login"] tap];

    // TODO: watch loginStatusLabel...
}

@end
