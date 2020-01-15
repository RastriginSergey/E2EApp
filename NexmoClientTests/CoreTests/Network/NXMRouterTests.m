//
//  NXMRouterTests.m
//  NexmoClientTests
//
//  Created by Chen Lev on 10/23/19.
//  Copyright © 2019 Vonage. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "NXMPagePrivate.h"
#import "NXMRouter.h"
#import "NXMEventInternal.h"
#import "NXMErrorsPrivate.h"
#import "NXMGetEventsPageRequest.h"

@interface NXMRouter(NXMRouterTests)
- (void)executeRequest:(NSURLRequest *)request
         responseBlock:(void (^_Nullable)(NSError * _Nullable error, NSDictionary * _Nullable data))responseBlock;
@end

@interface NXMRouterTests : XCTestCase

@end

@implementation NXMRouterTests

#pragma mark - create conversation tests

- (void)testCreateConversation {
    NSString *host = @"vv";
    NSString *ips = @"vv";
    NSString *token = @"myToken";
    NSString *displayName = @"myConvName";
    NSString *expectedConvId = @"q2";
    NXMRouter *router = [[NXMRouter alloc] initWithHost:host ipsURL:[NSURL URLWithString:ips]];
    
    [router setToken:token];
    __block NSString *convID = nil;
    
    id routerPartialMock = OCMPartialMock(router);
    OCMStub([routerPartialMock executeRequest:OCMOCK_ANY
                                responseBlock:([OCMArg invokeBlockWithArgs:[NSNull null], @{@"id":expectedConvId}, nil])]);
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"testCreateConversation"];
    
    NXMCreateConversationRequest *convRequest = [[NXMCreateConversationRequest alloc] initWithDisplayName:displayName];
    [router createConversation:convRequest onSuccess:^(NSString * _Nullable value) {
        convID = value;
        [expectation fulfill];
    } onError:^(NSError * _Nullable error) {
        XCTFail(@"create conversation failed");
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:1];
    XCTAssertEqual(result, XCTWaiterResultCompleted);
    XCTAssertEqual(convID, expectedConvId);
    
    [routerPartialMock verify];
    [routerPartialMock stopMocking];
}

- (void)testCreateConversationFailed {
    NSString *host = @"vv";
    NSString *ips = @"vv";
    NSString *token = @"myToken";
    NSString *displayName = @"myConvName";

    NXMRouter *router = [[NXMRouter alloc] initWithHost:host ipsURL:[NSURL URLWithString:ips]];
    [router setToken:token];
    
    id routerPartialMock = OCMPartialMock(router);
    OCMStub([routerPartialMock executeRequest:[OCMArg checkWithBlock:^BOOL(id param){
            NSURLRequest *request = param;
            return [request.URL.baseURL.absoluteString isEqualToString:host] &&
                [request.URL.relativeString isEqualToString:@"beta/conversations"];
            }]
                                responseBlock:([OCMArg invokeBlockWithArgs:[NSNull null], [NSNull null], nil])]);
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"testCreateConversation"];
    
    NXMCreateConversationRequest *convRequest = [[NXMCreateConversationRequest alloc] initWithDisplayName:displayName];
    [router createConversation:convRequest onSuccess:^(NSString * _Nullable value) {
        XCTFail(@"create conversation should fail");
    } onError:^(NSError * _Nullable error) {
        [expectation fulfill];
        XCTAssertNotNil(error);
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:1];
    XCTAssertEqual(result, XCTWaiterResultCompleted);
    
    [routerPartialMock verify];
    [routerPartialMock stopMocking];
}


#pragma mark - join conversation tests


#pragma mark - get events page tests

- (void)testGetEventsPageWithRequest_succeeds_withSucceedingHttpResponse {
    NSString *host = @"https://hostname.com/";
    NSString *ips = @"https://hostname.com/image/";
    NXMRouter *router = [[NXMRouter alloc] initWithHost:host ipsURL:[NSURL URLWithString:ips]];

    NSString *conversationId = @"CON-ID-01";
    NSUInteger pageSize = 20;
    NXMPageOrder order = NXMPageOrderDesc;
    NSInteger firstEventId = 1234;
    id<NXMPageProxy> proxyMock = OCMProtocolMock(@protocol(NXMPageProxy));
    NSDictionary *responseDict = @{
        @"page_size": @(pageSize),
        @"cursor": @"string",
        @"_embedded": @{
                @"data": @{
                        @"events": @[
                                @{
                                    @"to": @"string",
                                    @"id": @(firstEventId),
                                    @"timestamp": @"2019-12-19T11:24:06.766Z",
                                    @"_links": @{@"self": @{@"href": @"string"}},
                                    @"from": @"string",
                                    @"type": @"audio:mute:on"
                                }
                        ]
                }
        },
        @"_links": @{
                @"first": @{@"href": @"string"},
                @"self": @{@"href": @"string"},
                @"next": @{@"href": @"string"},
                @"prev": @{@"href": @"string"}
        }
    };
    id requestMatcher = [OCMArg checkWithBlock:^BOOL(id param) {
        NSString *urlString = [NSString stringWithFormat:@"%@beta2/conversations/%@/events?page_size=%lu&order=DESC",
                               host, conversationId, (unsigned long)pageSize];
        return [((NSURLRequest *)param).URL.absoluteString isEqualToString:urlString];
    }];
    id responseBlockMatcher = [OCMArg invokeBlockWithArgs:[NSNull null], responseDict, nil];
    id routerPartialMock = OCMPartialMock(router);
    OCMStub([routerPartialMock executeRequest:requestMatcher responseBlock:responseBlockMatcher]);

    NXMEvent *expectedFirstEvent = [[NXMEvent alloc] initWithConversationId:conversationId
                                                                 sequenceId:firstEventId
                                                               fromMemberId:nil
                                                               creationDate:nil
                                                                       type:NXMEventTypeMediaAction];
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    NXMGetEventsPageRequest *request = [[NXMGetEventsPageRequest alloc] initWithSize:pageSize
                                                                               order:order
                                                                      conversationId:conversationId
                                                                              cursor:nil
                                                                           eventType:nil];
    [router getEventsPageWithRequest:request
                   eventsPagingProxy:proxyMock
                           onSuccess:^(NXMEventsPage * _Nullable page) {
                               XCTAssertEqual(page.size, pageSize);
                               XCTAssertEqual(page.order, order);
                               XCTAssertEqual(page.events.count, 1);
                               [self doesEvent:page.events.firstObject matchWith:expectedFirstEvent];
                               [expectation fulfill];
                           }
                             onError:^(NSError * _Nullable error) {
                                 XCTFail(@"Get events page must not fail");
                             }];

    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];

    [routerPartialMock verify];
    [routerPartialMock stopMocking];
}

- (void)testGetEventsPageWithRequest_fails_withFailingHttpResponse {
    NSString *host = @"https://hostname.com/";
    NSString *ips = @"https://hostname.com/image/";
    NXMRouter *router = [[NXMRouter alloc] initWithHost:host ipsURL:[NSURL URLWithString:ips]];

    NSString *conversationId = @"CON-ID-01";
    NSUInteger pageSize = 20;
    NXMPageOrder order = NXMPageOrderDesc;
    id<NXMPageProxy> proxyMock = OCMProtocolMock(@protocol(NXMPageProxy));
    NSError *error = [NXMErrors nxmErrorWithErrorCode:NXMErrorCodeUnknown];

    id requestMatcher = [OCMArg checkWithBlock:^BOOL(id param) {
        NSString *urlString = [NSString stringWithFormat:@"%@beta2/conversations/%@/events?page_size=%lu&order=DESC",
                               host, conversationId, (unsigned long)pageSize];
        return [((NSURLRequest *)param).URL.absoluteString isEqualToString:urlString];
    }];
    id responseBlockMatcher = [OCMArg invokeBlockWithArgs:error, [NSNull null], nil];
    id routerPartialMock = OCMPartialMock(router);
    OCMStub([routerPartialMock executeRequest:requestMatcher responseBlock:responseBlockMatcher]);

    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    NXMGetEventsPageRequest *request = [[NXMGetEventsPageRequest alloc] initWithSize:pageSize
                                                                               order:order
                                                                      conversationId:conversationId
                                                                              cursor:nil
                                                                           eventType:nil];
    [router getEventsPageWithRequest:request
                   eventsPagingProxy:proxyMock
                           onSuccess:^(NXMEventsPage * _Nullable page) {
                               XCTFail(@"Get events page must fail");
                           }
                             onError:^(NSError * _Nullable error) {
                                 [expectation fulfill];
                             }];

    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];

    [routerPartialMock verify];
    [routerPartialMock stopMocking];
}

- (void)testGetEventsPageForURL_succeeds_withSucceedingHttpResponse_andNoOrderInURL {
    NSString *host = @"https://hostname.com/";
    NSString *ips = @"https://hostname.com/image/";
    NXMRouter *router = [[NXMRouter alloc] initWithHost:host ipsURL:[NSURL URLWithString:ips]];

    NSString *conversationId = @"CON-ID-01";
    NSUInteger pageSize = 20;
    NSString *cursor = @"SOME_CURSOR";
    NSString *urlFormat = @"%@beta2/conversations/%@/events?page_size=%lu&cursor=%@";
    NSString *url = [NSString stringWithFormat:urlFormat, host, conversationId, (unsigned long)pageSize, cursor];
    NSInteger firstEventId = 1234;
    id<NXMPageProxy> proxyMock = OCMProtocolMock(@protocol(NXMPageProxy));
    NSDictionary *responseDict = @{
        @"page_size": @(pageSize),
        @"cursor": @"string",
        @"_embedded": @{
                @"data": @{
                        @"events": @[
                                @{
                                    @"to": @"string",
                                    @"id": @(firstEventId),
                                    @"timestamp": @"2019-12-19T11:24:06.766Z",
                                    @"_links": @{@"self": @{@"href": @"string"}},
                                    @"from": @"string",
                                    @"type": @"audio:mute:on"
                                }
                        ]
                }
        },
        @"_links": @{
                @"first": @{@"href": @"string"},
                @"self": @{@"href": @"string"},
                @"next": @{@"href": @"string"},
                @"prev": @{@"href": @"string"}
        }
    };
    id requestMatcher = [OCMArg checkWithBlock:^BOOL(id param) {
        NSString *urlString = [NSString stringWithFormat:urlFormat, host, conversationId, (unsigned long)pageSize, cursor];
        return [((NSURLRequest *)param).URL.absoluteString isEqualToString:urlString];
    }];
    id responseBlockMatcher = [OCMArg invokeBlockWithArgs:[NSNull null], responseDict, nil];
    id routerPartialMock = OCMPartialMock(router);
    OCMStub([routerPartialMock executeRequest:requestMatcher responseBlock:responseBlockMatcher]);

    NXMEvent *expectedFirstEvent = [[NXMEvent alloc] initWithConversationId:conversationId
                                                                 sequenceId:firstEventId
                                                               fromMemberId:nil
                                                               creationDate:nil
                                                                       type:NXMEventTypeMediaAction];
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    [router getEventsPageForURL:[NSURL URLWithString:url]
              eventsPagingProxy:proxyMock
                      onSuccess:^(NXMEventsPage * _Nullable page) {
                          XCTAssertEqual(page.size, pageSize);
                          XCTAssertEqual(page.order, NXMPageOrderAsc);
                          XCTAssertEqual(page.events.count, 1);
                          [self doesEvent:page.events.firstObject matchWith:expectedFirstEvent];
                          [expectation fulfill];
                      }
                        onError:^(NSError * _Nullable error) {
                            XCTFail(@"Get events page must not fail");
                        }];

    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];

    [routerPartialMock verify];
    [routerPartialMock stopMocking];
}

- (void)testGetEventsPageForURL_succeeds_withSucceedingHttpResponse_andDescOrderInURL {
    NSString *host = @"https://hostname.com/";
    NSString *ips = @"https://hostname.com/image/";
    NXMRouter *router = [[NXMRouter alloc] initWithHost:host ipsURL:[NSURL URLWithString:ips]];

    NSString *conversationId = @"CON-ID-01";
    NSUInteger pageSize = 20;
    NSString *cursor = @"SOME_CURSOR";
    NSString *order = @"desc";
    NSString *urlFormat = @"%@beta2/conversations/%@/events?page_size=%lu&cursor=%@&order=%@";
    NSString *url = [NSString stringWithFormat:urlFormat, host, conversationId, (unsigned long)pageSize, cursor, order];
    NSInteger firstEventId = 1234;
    id<NXMPageProxy> proxyMock = OCMProtocolMock(@protocol(NXMPageProxy));
    NSDictionary *responseDict = @{
        @"page_size": @(pageSize),
        @"cursor": @"string",
        @"_embedded": @{
                @"data": @{
                        @"events": @[
                                @{
                                    @"to": @"string",
                                    @"id": @(firstEventId),
                                    @"timestamp": @"2019-12-19T11:24:06.766Z",
                                    @"_links": @{@"self": @{@"href": @"string"}},
                                    @"from": @"string",
                                    @"type": @"audio:mute:on"
                                }
                        ]
                }
        },
        @"_links": @{
                @"first": @{@"href": @"string"},
                @"self": @{@"href": @"string"},
                @"next": @{@"href": @"string"},
                @"prev": @{@"href": @"string"}
        }
    };
    id requestMatcher = [OCMArg checkWithBlock:^BOOL(id param) {
        NSString *urlString = [NSString stringWithFormat:urlFormat, host, conversationId, (unsigned long)pageSize, cursor, order];
        return [((NSURLRequest *)param).URL.absoluteString isEqualToString:urlString];
    }];
    id responseBlockMatcher = [OCMArg invokeBlockWithArgs:[NSNull null], responseDict, nil];
    id routerPartialMock = OCMPartialMock(router);
    OCMStub([routerPartialMock executeRequest:requestMatcher responseBlock:responseBlockMatcher]);

    NXMEvent *expectedFirstEvent = [[NXMEvent alloc] initWithConversationId:conversationId
                                                                 sequenceId:firstEventId
                                                               fromMemberId:nil
                                                               creationDate:nil
                                                                       type:NXMEventTypeMediaAction];
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    [router getEventsPageForURL:[NSURL URLWithString:url]
              eventsPagingProxy:proxyMock
                      onSuccess:^(NXMEventsPage * _Nullable page) {
                          XCTAssertEqual(page.size, pageSize);
                          XCTAssertEqual(page.order, NXMPageOrderDesc);
                          XCTAssertEqual(page.events.count, 1);
                          [self doesEvent:page.events.firstObject matchWith:expectedFirstEvent];
                          [expectation fulfill];
                      }
                        onError:^(NSError * _Nullable error) {
                            XCTFail(@"Get events page must not fail");
                        }];

    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];

    [routerPartialMock verify];
    [routerPartialMock stopMocking];
}

- (void)testGetEventsPageForURL_fails_withFailingHttpResponse {
    NSString *host = @"https://hostname.com/";
    NSString *ips = @"https://hostname.com/image/";
    NXMRouter *router = [[NXMRouter alloc] initWithHost:host ipsURL:[NSURL URLWithString:ips]];

    NSString *conversationId = @"CON-ID-01";
    NSUInteger pageSize = 20;
    NSString *cursor = @"SOME_CURSOR";
    NSString *urlFormat = @"%@beta2/conversations/%@/events?page_size=%lu&cursor=%@";
    NSString *url = [NSString stringWithFormat:urlFormat, host, conversationId, (unsigned long)pageSize, cursor];
    id<NXMPageProxy> proxyMock = OCMProtocolMock(@protocol(NXMPageProxy));
    NSError *error = [NXMErrors nxmErrorWithErrorCode:NXMErrorCodeUnknown];
    id requestMatcher = [OCMArg checkWithBlock:^BOOL(id param) {
        NSString *urlString = [NSString stringWithFormat:urlFormat, host, conversationId, (unsigned long)pageSize, cursor];
        return [((NSURLRequest *)param).URL.absoluteString isEqualToString:urlString];
    }];
    id responseBlockMatcher = [OCMArg invokeBlockWithArgs:error, [NSNull null], nil];
    id routerPartialMock = OCMPartialMock(router);
    OCMStub([routerPartialMock executeRequest:requestMatcher responseBlock:responseBlockMatcher]);

    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    [router getEventsPageForURL:[NSURL URLWithString:url]
              eventsPagingProxy:proxyMock
                      onSuccess:^(NXMEventsPage * _Nullable page) {
                          XCTFail(@"Get events page must fail");
                      }
                        onError:^(NSError * _Nullable error) {
                            [expectation fulfill];
                        }];

    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];

    [routerPartialMock verify];
    [routerPartialMock stopMocking];
}

- (void)testGetEventsPageWithRequestWithEventTypeFilter_succeeds_withSucceedingHttpResponse {
    NSString *host = @"https://hostname.com/";
    NSString *ips = @"https://hostname.com/image/";
    NXMRouter *router = [[NXMRouter alloc] initWithHost:host ipsURL:[NSURL URLWithString:ips]];

    NSString *conversationId = @"CON-ID-01";
    NSUInteger pageSize = 20;
    NXMPageOrder order = NXMPageOrderAsc;
    NSString *eventType = @"member:*";
    NSInteger firstEventId = 1234;
    id<NXMPageProxy> proxyMock = OCMProtocolMock(@protocol(NXMPageProxy));
    NSDictionary *responseDict = @{
        @"page_size": @(pageSize),
        @"cursor": @"string",
        @"_embedded": @{
                @"data": @{
                        @"events": @[
                                @{
                                    @"to": @"string",
                                    @"id": @(firstEventId),
                                    @"timestamp": @"2019-12-19T11:24:06.766Z",
                                    @"_links": @{@"self": @{@"href": @"string"}},
                                    @"from": @"string",
                                    @"type": @"audio:mute:on"
                                }
                        ]
                }
        },
        @"_links": @{
                @"first": @{@"href": @"string"},
                @"self": @{@"href": @"string"},
                @"next": @{@"href": @"string"},
                @"prev": @{@"href": @"string"}
        }
    };
    id requestMatcher = [OCMArg checkWithBlock:^BOOL(id param) {
        NSString *urlString = [NSString stringWithFormat:@"%@beta2/conversations/%@/events?page_size=%lu&order=ASC&event_type=%@",
                               host, conversationId, (unsigned long)pageSize, eventType];
        return [((NSURLRequest *)param).URL.absoluteString isEqualToString:urlString];
    }];
    id responseBlockMatcher = [OCMArg invokeBlockWithArgs:[NSNull null], responseDict, nil];
    id routerPartialMock = OCMPartialMock(router);
    OCMStub([routerPartialMock executeRequest:requestMatcher responseBlock:responseBlockMatcher]);

    NXMEvent *expectedFirstEvent = [[NXMEvent alloc] initWithConversationId:conversationId
                                                                 sequenceId:firstEventId
                                                               fromMemberId:nil
                                                               creationDate:nil
                                                                       type:NXMEventTypeMediaAction];
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    NXMGetEventsPageRequest *request = [[NXMGetEventsPageRequest alloc] initWithSize:pageSize
                                                                               order:order
                                                                      conversationId:conversationId
                                                                              cursor:nil
                                                                           eventType:eventType];
    [router getEventsPageWithRequest:request
                   eventsPagingProxy:proxyMock
                           onSuccess:^(NXMEventsPage * _Nullable page) {
                               XCTAssertEqual(page.size, pageSize);
                               XCTAssertEqual(page.order, order);
                               XCTAssertEqual(page.events.count, 1);
                               [self doesEvent:page.events.firstObject matchWith:expectedFirstEvent];
                               [expectation fulfill];
                           }
                             onError:^(NSError * _Nullable error) {
                                 XCTFail(@"Get events page must not fail");
                             }];

    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];

    [routerPartialMock verify];
    [routerPartialMock stopMocking];
}

- (void)doesEvent:(nonnull NXMEvent *)lhs matchWith:(nonnull NXMEvent *)rhs {
    XCTAssertEqual(lhs.uuid, rhs.uuid);
    XCTAssertEqual(lhs.type, rhs.type);
    XCTAssertTrue([lhs.conversationUuid isEqualToString: rhs.conversationUuid]);
}

@end
