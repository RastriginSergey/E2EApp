//
//  NXMCallTests.m
//  NexmoClientTests
//
//  Created by Chen Lev on 10/16/19.
//  Copyright © 2019 Vonage. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "NXMCallPrivate.h"
#import "NXMConversationPrivate.h"
#import "NXMCoreEventsPrivate.h"
#import "NXMConversationDelegate.h"

@interface NXMCall(NXMCallTests)
- (void)hangup:(NXMCallMember *)callMember;
@end

@interface NXMCallTests : XCTestCase

@end

@implementation NXMCallTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

#pragma Answer tests

- (void)testAnswer {
    id conversationMock = OCMClassMock([NXMConversation class]);
    OCMExpect([conversationMock joinClientRef:([OCMArg invokeBlockWithArgs:[NSNull null], [NXMMember new], nil])]);
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"testAnswer"];

    NXMCall *call = [[NXMCall alloc] initWithConversation:conversationMock];
    [call answer:^(NSError * _Nullable error) {
        if (error) {
            XCTFail(@"answer failed");
        }
        
        [expectation fulfill];
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:1];
    
    [conversationMock verify];
    [conversationMock stopMocking];
    
    XCTAssertEqual(result, XCTWaiterResultCompleted);
}

- (void)testAnswerFailedError {
    id conversationMock = OCMClassMock([NXMConversation class]);
    OCMExpect([conversationMock joinClientRef:([OCMArg invokeBlockWithArgs:[[NSError alloc] initWithDomain:NXMErrorDomain code:NXMErrorCodeUnknown userInfo:nil], [NSNull null], nil])]);
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"testAnswerFailedError"];
    
    NXMCall *call = [[NXMCall alloc] initWithConversation:conversationMock];
    [call answer:^(NSError * _Nullable error) {
        if (error) {
            XCTAssertEqual(error.code, NXMErrorCodeUnknown);
            [expectation fulfill];
            return;
        }
        
        XCTFail(@"answer should failed");
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:1];
    
    [conversationMock verify];
    [conversationMock stopMocking];
    
    XCTAssertEqual(result, XCTWaiterResultCompleted);
    
}

#pragma Reject tests

- (void)testReject {
    id conversationMock = OCMClassMock([NXMConversation class]);
    id callMemberMock = OCMClassMock([NXMCallMember class]);
    OCMStub([callMemberMock status]).andReturn(NXMCallMemberStatusRinging);
    OCMExpect([conversationMock leave:([OCMArg invokeBlockWithArgs:[NSNull null], nil])]);
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"testReject"];
    
    NXMCall *call = [[NXMCall alloc] initWithConversation:conversationMock];
    id callPartialMock = OCMPartialMock(call);
    OCMStub([callPartialMock myCallMember]).andReturn(callMemberMock);
    
    [call reject:^(NSError * _Nullable error) {
        if (error) {
            XCTFail(@"reject failed");
            return;
        }
        
        [expectation fulfill];
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:1];
    XCTAssertEqual(result, XCTWaiterResultCompleted);

    [conversationMock verify];
    [conversationMock stopMocking];
    [callPartialMock stopMocking];
}

- (void)testRejectFailed_alreadyAnswered {
    id conversationMock = OCMClassMock([NXMConversation class]);
    id callMemberMock = OCMClassMock([NXMCallMember class]);
    OCMStub([callMemberMock status]).andReturn(NXMCallMemberStatusAnswered);
    OCMReject([conversationMock leave:([OCMArg invokeBlockWithArgs:[NSNull null], nil])]);
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"testRejectFailed_alreadyAnswered"];
    
    NXMCall *call = [[NXMCall alloc] initWithConversation:conversationMock];
    id callPartialMock = OCMPartialMock(call);
    OCMStub([callPartialMock myCallMember]).andReturn(callMemberMock);
    
    [call reject:^(NSError * _Nullable error) {
        if (error) {
            [expectation fulfill];
            XCTAssertEqual(error.code, NXMErrorCodeUnknown);
            return;
        }
        
        XCTFail(@"reject should failed");
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:1];
    XCTAssertEqual(result, XCTWaiterResultCompleted);
    
    [conversationMock verify];
    [conversationMock stopMocking];
    [callMemberMock stopMocking];
    [callPartialMock stopMocking];
}

- (void)testRejectFailed {
    id conversationMock = OCMClassMock([NXMConversation class]);
    id callMemberMock = OCMClassMock([NXMCallMember class]);
    OCMStub([callMemberMock status]).andReturn(NXMCallMemberStatusRinging);
    OCMExpect([conversationMock leave:([OCMArg invokeBlockWithArgs:[[NSError alloc] initWithDomain:NXMErrorDomain code:NXMErrorCodeUnknown userInfo:nil], nil])]);
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"testRejectFailed"];
    
    NXMCall *call = [[NXMCall alloc] initWithConversation:conversationMock];
    id callPartialMock = OCMPartialMock(call);
    OCMStub([callPartialMock myCallMember]).andReturn(callMemberMock);
    
    [call reject:^(NSError * _Nullable error) {
        if (error) {
            [expectation fulfill];
            XCTAssertEqual(error.code, NXMErrorCodeUnknown);
            return;
        }
        
        XCTFail(@"reject should failed");
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:1];
    XCTAssertEqual(result, XCTWaiterResultCompleted);
    
    [conversationMock verify];
    [conversationMock stopMocking];
    [callMemberMock stopMocking];
    [callPartialMock stopMocking];
}

#pragma Hangup tests

- (void)testHangup_CallMyMemberHangup {
    id conversationMock = OCMClassMock([NXMConversation class]);
    
    id callMemberMock = OCMClassMock([NXMCallMember class]);
    OCMStub([callMemberMock status]).andReturn(NXMCallMemberStatusAnswered);
    OCMExpect([callMemberMock hangup]);
    
    NXMCall *call = [[NXMCall alloc] initWithConversation:conversationMock];
    id callPartialMock = OCMPartialMock(call);
    OCMStub([callPartialMock myCallMember]).andReturn(callMemberMock);
    
    [call hangup];
    
    [conversationMock verify];
    [conversationMock stopMocking];
    [callMemberMock stopMocking];
    [callPartialMock stopMocking];
}

- (void)testHangup_CallCompleted {
    id conversationMock = OCMClassMock([NXMConversation class]);
    
    id callMemberMock = OCMClassMock([NXMCallMember class]);
    OCMStub([callMemberMock status]).andReturn(NXMCallMemberStatusCompleted);
    OCMReject([callMemberMock hangup]);
    
    NXMCall *call = [[NXMCall alloc] initWithConversation:conversationMock];
    id callPartialMock = OCMPartialMock(call);
    OCMStub([callPartialMock myCallMember]).andReturn(callMemberMock);
    
    [call hangup];
    
    [conversationMock verify];
    [conversationMock stopMocking];
    [callMemberMock stopMocking];
    [callPartialMock stopMocking];
}

- (void)testCallMemberHangup {
    id conversationMock = OCMClassMock([NXMConversation class]);
    id callMemberMock = OCMClassMock([NXMCallMember class]);
    OCMStub([callMemberMock status]).andReturn(NXMCallMemberStatusAnswered);
    
    NSString *myMemberId = @"1";
    OCMStub([callMemberMock memberId]).andReturn(myMemberId);
    
    OCMExpect([conversationMock disableMedia]);
    OCMExpect([conversationMock kickMemberWithMemberId:myMemberId completion:([OCMArg invokeBlockWithArgs:[NSNull null], nil])]);
    
    NXMCall *call = [[NXMCall alloc] initWithConversation:conversationMock];
    id callPartialMock = OCMPartialMock(call);
    OCMStub([callPartialMock myCallMember]).andReturn(callMemberMock);
    
    [call hangup:call.myCallMember];
    
    [conversationMock verify];
    [conversationMock stopMocking];
    [callMemberMock stopMocking];
    [callPartialMock stopMocking];
}

#pragma DTMF tests

- (void)testSendDTMF {
    id conversationMock = OCMClassMock([NXMConversation class]);
    id callMemberMock = OCMClassMock([NXMCallMember class]);
    OCMStub([callMemberMock status]).andReturn(NXMCallMemberStatusAnswered);
    
    NSString *digit = @"4";
    OCMExpect([conversationMock sendDTMF:digit completion:OCMOCK_ANY]);

    NXMCall *call = [[NXMCall alloc] initWithConversation:conversationMock];
    
    id callPartialMock = OCMPartialMock(call);
    OCMStub([callPartialMock myCallMember]).andReturn(callMemberMock);

    [call sendDTMF:digit];

    [conversationMock verify];
    [conversationMock stopMocking];
    [callMemberMock stopMocking];
    [callPartialMock stopMocking];
}

- (void)testSendDTMFCallEnded {
    id conversationMock = OCMClassMock([NXMConversation class]);
    id callMemberMock = OCMClassMock([NXMCallMember class]);
    OCMStub([callMemberMock status]).andReturn(NXMCallMemberStatusCompleted);
    
    NSString *digit = @"4";
    OCMReject([conversationMock sendDTMF:digit completion:OCMOCK_ANY]);
    
    NXMCall *call = [[NXMCall alloc] initWithConversation:conversationMock];
    
    id callPartialMock = OCMPartialMock(call);
    OCMStub([callPartialMock myCallMember]).andReturn(callMemberMock);
    
    [call sendDTMF:digit];
    
    [conversationMock verify];
    [conversationMock stopMocking];
    [callMemberMock stopMocking];
    [callPartialMock stopMocking];
}

- (void)testReceiveDTMF {
    id conversationMock = OCMClassMock([NXMConversation class]);
    id callDelegateMock = OCMProtocolMock(@protocol(NXMCallDelegate));
    
    NSString *digit = @"4";
    NXMDTMFEvent *dtmfEvent = [[NXMDTMFEvent alloc] initWithDigit:digit andDuration:@(10)];
    
    NXMCall *call = [[NXMCall alloc] initWithConversation:conversationMock];
    [call setDelegate:callDelegateMock];
    
    OCMExpect([callDelegateMock call:call didReceive:digit fromCallMember:OCMOCK_ANY]);
    [call conversation:conversationMock didReceiveDTMFEvent:dtmfEvent];

    [callDelegateMock verify];
    [conversationMock stopMocking];
    [callDelegateMock stopMocking];
}

@end
