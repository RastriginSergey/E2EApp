//
//  NXMConverationsPageTests.m
//  NexmoClientTests
//
//  Created by Tamir Tuch on 25/11/2019.
//  Copyright © 2019 Vonage. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "NXMTestingUtilities.h"
#import "NXMPagePrivate.h"

@interface NXMPageResponse (Test)
- (nullable instancetype)initWithPageSize:(unsigned int)pageSize
                            andWithCursor:(nonnull NSString *)cursor
                              andWithData:(nonnull NSArray *)data
                         andWithPageLinks:(nonnull NXMPageLinks *)pageLink;
@end

@interface NXMPageTests : XCTestCase
@property (nonatomic, nonnull) id pagingProxyMock;
@end

@implementation NXMPageTests

- (void)setUp {
    [super setUp];

    self.pagingProxyMock = OCMProtocolMock(@protocol(NXMPageProxy));
}

- (void)tearDown {
    [self.pagingProxyMock verify];
    [self.pagingProxyMock stopMocking];

    [super tearDown];
}

- (void) testHasNextPageReturnsTrue_whenNextPageLinkIsNotNil {
    unsigned int size = 4;
    NXMPageResponse *response = [NXMPageTests pageResponseWithSize:size
                                                           nextURL:[NSURL URLWithString:@"next"]
                                                           prevURL:[NSURL URLWithString:@"prev"]];
    NXMPage *page = [[NXMPage alloc] initWithOrder:NXMPageOrderAsc
                                      pageResponse:response
                                       pagingProxy:self.pagingProxyMock
                                          elements:@[]];
    XCTAssertTrue([page hasNextPage]);
}

- (void) testHasNextPageReturnsFalse_whenNextPageLinkIsNil {
    unsigned int size = 4;
    NXMPageResponse *response = [NXMPageTests pageResponseWithSize:size
                                                           nextURL:nil
                                                           prevURL:[NSURL URLWithString:@"prev"]];
    NXMPage *page = [[NXMPage alloc] initWithOrder:NXMPageOrderAsc
                                      pageResponse:response
                                       pagingProxy:self.pagingProxyMock
                                          elements:@[]];
    XCTAssertFalse([page hasNextPage]);
}

- (void) testHasPreviousPageReturnsTrue_whenPreviousPageLinkIsNotNil {
    unsigned int size = 4;
    NXMPageResponse *response = [NXMPageTests pageResponseWithSize:size
                                                           nextURL:[NSURL URLWithString:@"next"]
                                                           prevURL:[NSURL URLWithString:@"prev"]];
    NXMPage *page = [[NXMPage alloc] initWithOrder:NXMPageOrderAsc
                                      pageResponse:response
                                       pagingProxy:self.pagingProxyMock
                                          elements:@[]];
    XCTAssertTrue([page hasPreviousPage]);
}

- (void) testHasPreviousPageReturnsFalse_whenPreviousPageLinkIsNil {
    unsigned int size = 4;
    NXMPageResponse *response = [NXMPageTests pageResponseWithSize:size
                                                           nextURL:[NSURL URLWithString:@"next"]
                                                           prevURL:nil];
    NXMPage *page = [[NXMPage alloc] initWithOrder:NXMPageOrderAsc
                                      pageResponse:response
                                       pagingProxy:self.pagingProxyMock
                                          elements:@[]];
    XCTAssertFalse([page hasPreviousPage]);
}

- (void) testNextPageCallsCompletionWithError_whenNextPageLinkIsNil {
    unsigned int size = 4;
    NXMPageResponse *response = [NXMPageTests pageResponseWithSize:size
                                                           nextURL:nil
                                                           prevURL:[NSURL URLWithString:@"prev"]];
    NXMPage *page = [[NXMPage alloc] initWithOrder:NXMPageOrderAsc
                                      pageResponse:response
                                       pagingProxy:self.pagingProxyMock
                                          elements:@[]];
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [page nextPage:^(NSError * _Nullable error, NXMPage * _Nullable page) {
        XCTAssertNotNil(error);
        XCTAssertNil(page);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
}

- (void) testNextPageCallsProxyWithPageAndCompletion_whenNextPageLinkIsNotNil {
    unsigned int size = 4;
    NSURL *nextURL = [NSURL URLWithString:@"next"];
    NXMPageResponse *response = [NXMPageTests pageResponseWithSize:size
                                                           nextURL:nextURL
                                                           prevURL:[NSURL URLWithString:@"prev"]];
    NXMPage *page = [[NXMPage alloc] initWithOrder:NXMPageOrderAsc
                                      pageResponse:response
                                       pagingProxy:self.pagingProxyMock
                                          elements:@[]];
    id completionHandler = ^(NSError * _Nullable error, NXMPage * _Nullable page) { };
    OCMExpect([self.pagingProxyMock getPageForURL:nextURL completionHandler:completionHandler]);
    [page nextPage:completionHandler];
}

- (void) testPreviousPageCallsCompletionWithError_whenPreviousPageLinkIsNil {
    unsigned int size = 4;
    NXMPageResponse *response = [NXMPageTests pageResponseWithSize:size
                                                           nextURL:[NSURL URLWithString:@"next"]
                                                           prevURL:nil];
    NXMPage *page = [[NXMPage alloc] initWithOrder:NXMPageOrderAsc
                                      pageResponse:response
                                       pagingProxy:self.pagingProxyMock
                                          elements:@[]];
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [page previousPage:^(NSError * _Nullable error, NXMPage * _Nullable page) {
        XCTAssertNotNil(error);
        XCTAssertNil(page);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
}

- (void) testPreviousPageCallsProxyWithPageAndCompletion_whenPreviousPageLinkIsNotNil {
    unsigned int size = 4;
    NSURL *prevURL = [NSURL URLWithString:@"prev"];
    NXMPageResponse *response = [NXMPageTests pageResponseWithSize:size
                                                           nextURL:[NSURL URLWithString:@"next"]
                                                           prevURL:prevURL];
    NXMPage *page = [[NXMPage alloc] initWithOrder:NXMPageOrderAsc
                                      pageResponse:response
                                       pagingProxy:self.pagingProxyMock
                                          elements:@[]];
    id completionHandler = ^(NSError * _Nullable error, NXMPage * _Nullable page) { };
    OCMExpect([self.pagingProxyMock getPageForURL:prevURL completionHandler:completionHandler]);
    [page previousPage:completionHandler];
}

+ (nonnull NXMPageResponse *)pageResponseWithSize:(unsigned int)size
                                          nextURL:(nullable NSURL *)nextURL
                                          prevURL:(nullable NSURL *)prevURL {
    NXMPageLinks *pageLinks = [[NXMPageLinks alloc] initWithFirst:[NSURL URLWithString:@"first"]
                                                        andWithMe:[NSURL URLWithString:@"me"]
                                                      andWithNext:nextURL
                                                      andWithPrev:prevURL];
    return [[NXMPageResponse alloc] initWithPageSize:size
                                       andWithCursor:@"cursor"
                                         andWithData:@[]
                                    andWithPageLinks:pageLinks];
}

@end
