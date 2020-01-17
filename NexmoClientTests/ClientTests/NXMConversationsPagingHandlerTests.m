//
//  NXMConversationsPagingHandlerTests.m
//  NexmoClientTests
//
//  Created by Nicola Di Pol on 21/11/2019.
//  Copyright © 2019 Vonage. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "NXMConversationsPagingHandler.h"
#import "NXMTestingUtilities.h"
#import "NXMConversationPrivate.h"
#import "NXMErrorsPrivate.h"

@interface NXMConversationsPagingHandler (Test)
- (instancetype)initWithStitchContext:(NXMStitchContext *)stitchContext
              getConversationWithUuid:(GetConversationWithUuidBlock)getConversationWithUuid;

- (void)getConversationsFromIds:(nonnull NSArray<NSString *> *)conversationIds
              completionHandler:(void (^ _Nonnull)(NSArray<NXMConversation *> *_Nonnull))completionHandler;

- (void)getConversationsPageFromConversationIdsPage:(NXMConversationIdsPage *)page
                                  completionHandler:(void (^)(NSError * _Nullable, NXMConversationsPage * _Nullable))completionHandler;
@end

@interface NXMConversationsPagingHandlerTests : XCTestCase
@property (nonatomic) id stitchContextMock;
@property (nonatomic) id stitchCoreMock;
@end

@implementation NXMConversationsPagingHandlerTests

- (void)setUp {
    [super setUp];

    self.stitchContextMock = OCMClassMock([NXMStitchContext class]);
    self.stitchCoreMock = OCMClassMock([NXMCore class]);

    OCMStub([self.stitchContextMock alloc]).andReturn(self.stitchContextMock);
    OCMStub([self.stitchContextMock initWithCoreClient:OCMOCK_ANY]).andReturn(self.stitchContextMock);

    OCMStub([self.stitchContextMock coreClient]).andReturn(self.stitchCoreMock);
}

- (void)tearDown {
    [self.stitchCoreMock verify];
    [self.stitchContextMock verify];

    [self.stitchCoreMock stopMocking];
    [self.stitchContextMock stopMocking];

    [super tearDown];
}

#pragma mark - getConversationsPageWithSize:order:userId:completionHandler:

- (void)testGetConversationsPageWithSizeOrderUserId_happyPath {
    NSUInteger size = 4;
    NSString *userId = @"USR-01";
    NXMPageOrder order = NXMPageOrderAsc;
    NXMConversationIdsPage *conversationIdsPage = [NXMConversationIdsPage new];
    NXMConversationsPage *conversationsPage = [NXMConversationsPage new];

    GetConversationWithUuidBlock getConversationWithUuid = ^(NSString * _Nonnull uuid, void (^ _Nullable completionHandler)(NSError * _Nullable, NXMConversation * _Nullable)) {
        NXMConversationDetails *details = [NXMTestingUtils conversationDetailsWithConversationId:uuid];
        NXMConversation *conversation = [[NXMConversation alloc] initWithConversationDetails:details andStitchContext:self.stitchContextMock];
        completionHandler(nil, conversation);
    };

    OCMStub([self.stitchCoreMock getConversationIdsPageWithSize:size
                                                         cursor:nil
                                                         userId:userId
                                                          order:order
                                                      onSuccess:([OCMArg invokeBlockWithArgs:conversationIdsPage, nil])
                                                        onError:[OCMArg any]]);
    NXMConversationsPagingHandler *conversationsPagingHandler = [[NXMConversationsPagingHandler alloc] initWithStitchContext:self.stitchContextMock getConversationWithUuid:getConversationWithUuid];

    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    id handlerPartialMock = OCMPartialMock(conversationsPagingHandler);
    OCMStub([handlerPartialMock getConversationsPageFromConversationIdsPage:conversationIdsPage
                                                          completionHandler:([OCMArg invokeBlockWithArgs:[NSNull null], conversationsPage, nil])]);
    [handlerPartialMock getConversationsPageWithSize:size
                                               order:order
                                              userId:userId
                                   completionHandler:^(NSError * _Nullable error, NXMConversationsPage * _Nullable page) {
                                       XCTAssertNil(error);
                                       XCTAssertEqual(conversationsPage, page);
                                       [expectation fulfill];
                                   }];

    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];

    [handlerPartialMock stopMocking];
}

- (void)testGetConversationsPageWithSizeOrderUserId_coreClientCallsCompletionWithNilPage_callsCompletionWithError {
    NSUInteger size = 4;
    NSString *userId = @"USR-01";
    NXMPageOrder order = NXMPageOrderAsc;
    NXMConversationIdsPage *conversationIdsPage = [NXMConversationIdsPage new];
    NXMConversationsPage *conversationsPage = [NXMConversationsPage new];

    GetConversationWithUuidBlock getConversationWithUuid = ^(NSString * _Nonnull uuid, void (^ _Nullable completionHandler)(NSError * _Nullable, NXMConversation * _Nullable)) {
        NXMConversationDetails *details = [NXMTestingUtils conversationDetailsWithConversationId:uuid];
        NXMConversation *conversation = [[NXMConversation alloc] initWithConversationDetails:details andStitchContext:self.stitchContextMock];
        completionHandler(nil, conversation);
    };

    OCMStub([self.stitchCoreMock getConversationIdsPageWithSize:size
                                                         cursor:nil
                                                         userId:userId
                                                          order:order
                                                      onSuccess:([OCMArg invokeBlockWithArgs:[NSNull null], nil])
                                                        onError:[OCMArg any]]);

    NXMConversationsPagingHandler *conversationsPagingHandler = [[NXMConversationsPagingHandler alloc] initWithStitchContext:self.stitchContextMock
                                                                                                     getConversationWithUuid:getConversationWithUuid];

    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    id handlerPartialMock = OCMPartialMock(conversationsPagingHandler);
    OCMStub([handlerPartialMock getConversationsPageFromConversationIdsPage:conversationIdsPage
                                                          completionHandler:([OCMArg invokeBlockWithArgs:[NSNull null], conversationsPage, nil])]);

    [handlerPartialMock getConversationsPageWithSize:size
                                               order:order
                                              userId:userId
                                 completionHandler:^(NSError * _Nullable error, NXMConversationsPage * _Nullable page) {
                                     XCTAssertNotNil(error);
                                     XCTAssertNil(page);
                                     [expectation fulfill];
                                 }];

    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];

    [handlerPartialMock stopMocking];
}


#pragma mark - getConversationIdsPageForURL:onSuccess:onError:

- (void)testGetConversationsForURL_happyPath {
    NSURL *url = [NSURL URLWithString:@"https://domain.com"];
    NXMConversationIdsPage *conversationIdsPage = [NXMConversationIdsPage new];
    NXMConversationsPage *conversationsPage = [NXMConversationsPage new];

    GetConversationWithUuidBlock getConversationWithUuid = ^(NSString * _Nonnull uuid, void (^ _Nullable completionHandler)(NSError * _Nullable, NXMConversation * _Nullable)) {
        NXMConversationDetails *details = [NXMTestingUtils conversationDetailsWithConversationId:uuid];
        NXMConversation *conversation = [[NXMConversation alloc] initWithConversationDetails:details andStitchContext:self.stitchContextMock];
        completionHandler(nil, conversation);
    };
    OCMStub([self.stitchCoreMock getConversationIdsPageForURL:url
                                                    onSuccess:([OCMArg invokeBlockWithArgs:conversationIdsPage, nil])
                                                      onError:[OCMArg any]]);
    NXMConversationsPagingHandler *conversationsPagingHandler = [[NXMConversationsPagingHandler alloc] initWithStitchContext:self.stitchContextMock
                                                                                                     getConversationWithUuid:getConversationWithUuid];

    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    id handlerPartialMock = OCMPartialMock(conversationsPagingHandler);
    OCMStub([handlerPartialMock getConversationsPageFromConversationIdsPage:conversationIdsPage
                                                          completionHandler:([OCMArg invokeBlockWithArgs:[NSNull null], conversationsPage, nil])]);

    [handlerPartialMock getConversationsPageForURL:url
                                 completionHandler:^(NSError * _Nullable error, NXMConversationsPage * _Nullable page) {
                                     XCTAssertNil(error);
                                     XCTAssertEqual(conversationsPage, page);
                                     [expectation fulfill];
                                 }];

    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];

    [handlerPartialMock stopMocking];
}

- (void)testGetConversationsForURL_coreClientSucceedsWithNilPage_callsCompletionWithError {
    NSURL *url = [NSURL URLWithString:@"https://domain.com"];
    NXMConversationIdsPage *conversationIdsPage = [NXMConversationIdsPage new];
    NXMConversationsPage *conversationsPage = [NXMConversationsPage new];

    GetConversationWithUuidBlock getConversationWithUuid = ^(NSString * _Nonnull uuid, void (^ _Nullable completionHandler)(NSError * _Nullable, NXMConversation * _Nullable)) {
        NXMConversationDetails *details = [NXMTestingUtils conversationDetailsWithConversationId:uuid];
        NXMConversation *conversation = [[NXMConversation alloc] initWithConversationDetails:details andStitchContext:self.stitchContextMock];
        completionHandler(nil, conversation);
    };

    OCMStub([self.stitchCoreMock getConversationIdsPageForURL:url
                                                    onSuccess:([OCMArg invokeBlockWithArgs:[NSNull null], nil])
                                                      onError:[OCMArg any]]);

    NXMConversationsPagingHandler *conversationsPagingHandler = [[NXMConversationsPagingHandler alloc] initWithStitchContext:self.stitchContextMock
                                                                                                     getConversationWithUuid:getConversationWithUuid];

    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    id handlerPartialMock = OCMPartialMock(conversationsPagingHandler);
    OCMStub([handlerPartialMock getConversationsPageFromConversationIdsPage:conversationIdsPage
                                                          completionHandler:([OCMArg invokeBlockWithArgs:[NSNull null], conversationsPage, nil])]);

    [handlerPartialMock getConversationsPageForURL:url
                                 completionHandler:^(NSError * _Nullable error, NXMConversationsPage * _Nullable page) {
                                     XCTAssertNotNil(error);
                                     XCTAssertNil(page);
                                     [expectation fulfill];
                                 }];

    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];

    [handlerPartialMock stopMocking];
}

- (void)testGetConversationsForURL_coreClientFails_callsCompletionWithError {
    NSURL *url = [NSURL URLWithString:@"https://domain.com"];
    NXMConversationIdsPage *conversationIdsPage = [NXMConversationIdsPage new];
    NXMConversationsPage *conversationsPage = [NXMConversationsPage new];

    GetConversationWithUuidBlock getConversationWithUuid = ^(NSString * _Nonnull uuid, void (^ _Nullable completionHandler)(NSError * _Nullable, NXMConversation * _Nullable)) {
        NXMConversationDetails *details = [NXMTestingUtils conversationDetailsWithConversationId:uuid];
        NXMConversation *conversation = [[NXMConversation alloc] initWithConversationDetails:details andStitchContext:self.stitchContextMock];
        completionHandler(nil, conversation);
    };

    NSError *error = [NXMErrors nxmErrorWithErrorCode:NXMErrorCodeNone andUserInfo:nil];
    OCMStub([self.stitchCoreMock getConversationIdsPageForURL:url
                                                    onSuccess:[OCMArg any]
                                                      onError:([OCMArg invokeBlockWithArgs:error, nil])]);

    NXMConversationsPagingHandler *conversationsPagingHandler = [[NXMConversationsPagingHandler alloc] initWithStitchContext:self.stitchContextMock
                                                                                                     getConversationWithUuid:getConversationWithUuid];

    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    id handlerPartialMock = OCMPartialMock(conversationsPagingHandler);
    OCMStub([handlerPartialMock getConversationsPageFromConversationIdsPage:conversationIdsPage
                                                          completionHandler:([OCMArg invokeBlockWithArgs:[NSNull null], conversationsPage, nil])]);

    [handlerPartialMock getConversationsPageForURL:url
                                 completionHandler:^(NSError * _Nullable error, NXMConversationsPage * _Nullable page) {
                                     XCTAssertNotNil(error);
                                     XCTAssertNil(page);
                                     [expectation fulfill];
                                 }];

    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];

    [handlerPartialMock stopMocking];
}


#pragma mark - getConversationsFromIds:completionHandler:

- (void)testGetConversationsFromIds_happyPath {
    NSArray<NSString *> *conversationIds = @[@"CON-01", @"CON-02", @"CON-03"];
    NXMConversation *conversationA = [[NXMConversation alloc] initWithConversationDetails:[NXMTestingUtils conversationDetailsWithConversationId:conversationIds[0]] andStitchContext:self.stitchContextMock];
    NXMConversation *conversationB = [[NXMConversation alloc] initWithConversationDetails:[NXMTestingUtils conversationDetailsWithConversationId:conversationIds[1]] andStitchContext:self.stitchContextMock];
    NXMConversation *conversationC = [[NXMConversation alloc] initWithConversationDetails:[NXMTestingUtils conversationDetailsWithConversationId:conversationIds[2]] andStitchContext:self.stitchContextMock];
    NSDictionary<NSString *, NXMConversation *> *conversationById = @{conversationIds[0]: conversationA, conversationIds[1]: conversationB, conversationIds[2]: conversationC};
    GetConversationWithUuidBlock getConversationWithUuid = ^(NSString * _Nonnull uuid, void (^ _Nullable completionHandler)(NSError * _Nullable, NXMConversation * _Nullable)) {
        completionHandler(nil, conversationById[uuid]);
    };
    NXMConversationsPagingHandler *conversationsPagingHandler = [[NXMConversationsPagingHandler alloc] initWithStitchContext:self.stitchContextMock
                                                                                                     getConversationWithUuid:getConversationWithUuid];
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [conversationsPagingHandler getConversationsFromIds:conversationIds
                                      completionHandler:^(NSArray<NXMConversation *> *_Nonnull conversations) {
                                          XCTAssertEqual(conversations.count, 3);
                                          XCTAssertTrue([conversationA isEqual:conversations[0]]);
                                          XCTAssertTrue([conversationB isEqual:conversations[1]]);
                                          XCTAssertTrue([conversationC isEqual:conversations[2]]);

                                          [expectation fulfill];
                                      }];
    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
}

- (void)testGetConversationsFromIds_whenConversationFromIdFails {
    NSArray<NSString *> *conversationIds = @[@"CON-01", @"CON-02", @"CON-03"];
    NXMConversation *conversationA = [[NXMConversation alloc] initWithConversationDetails:[NXMTestingUtils conversationDetailsWithConversationId:conversationIds[0]] andStitchContext:self.stitchContextMock];
    NXMConversation *conversationB = [[NXMConversation alloc] initWithConversationDetails:[NXMTestingUtils conversationDetailsWithConversationId:conversationIds[2]] andStitchContext:self.stitchContextMock];

    NSDictionary<NSString *, NXMConversation *> *conversationById = @{conversationIds[0]: conversationA, conversationIds[2]: conversationB};

    GetConversationWithUuidBlock getConversationWithUuid = ^(NSString *_Nonnull uuid, void (^_Nullable completionHandler)(NSError *_Nullable, NXMConversation *_Nullable)) {
        if ([uuid isEqualToString:@"CON-02"]) {
            completionHandler([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeNone andUserInfo:nil], nil);
            return;
        }

        completionHandler(nil, conversationById[uuid]);
    };
    NXMConversationsPagingHandler *conversationsPagingHandler = [[NXMConversationsPagingHandler alloc] initWithStitchContext:self.stitchContextMock
                                                                                                     getConversationWithUuid:getConversationWithUuid];
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [conversationsPagingHandler getConversationsFromIds:conversationIds
                                      completionHandler:^(NSArray<NXMConversation *> *_Nonnull conversations) {
                                          XCTAssertEqual(conversations.count, 2);
                                          XCTAssertTrue([conversationA isEqual:conversations[0]]);
                                          XCTAssertTrue([conversationB isEqual:conversations[1]]);
                                          [expectation fulfill];
                                      }];
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
        XCTAssertNil(error);
    }];
}

-(void)testGetConversationsFromIds_whenAllConversationsFromIdFail {
    NSArray<NSString *> *conversationIds = @[@"CON-01", @"CON-02", @"CON-03"];

    GetConversationWithUuidBlock getConversationWithUuid = ^(NSString *_Nonnull uuid, void (^_Nullable completionHandler)(NSError *_Nullable, NXMConversation *_Nullable)) {
        completionHandler([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeNone andUserInfo:nil], nil);
    };

    NXMConversationsPagingHandler *conversationsPagingHandler = [[NXMConversationsPagingHandler alloc] initWithStitchContext:self.stitchContextMock
                                                                                                     getConversationWithUuid:getConversationWithUuid];
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [conversationsPagingHandler getConversationsFromIds:conversationIds
                                      completionHandler:^(NSArray<NXMConversation *> *_Nonnull conversations) {
                                          XCTAssertEqual(conversations.count, 0);
                                          [expectation fulfill];
                                      }];
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
        XCTAssertNil(error);
    }];
}

@end
