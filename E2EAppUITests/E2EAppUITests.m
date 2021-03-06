//
//  E2EAppUITests.m
//  E2EAppUITests
//
//  Created by Sergei Rastrigin on 31/01/2020.
//  Copyright © 2020 Sergei Rastrigin. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <NexmoClient/NexmoClient.h>

@interface E2EAppUITests : XCTestCase

@end

@implementation E2EAppUITests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.

    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;

    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // UI tests must launch the application that they test.
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    NXMClient *client = [NXMClient new];
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    XCTAssertTrue(YES);

}

- (void)testFails {
    XCTAssertFalse(YES);
}

@end
