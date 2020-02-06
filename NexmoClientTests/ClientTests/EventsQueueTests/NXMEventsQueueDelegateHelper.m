//
//  NXMEventsQueueDelegateHelper.m
//  NexmoClientTests
//
//  Copyright © 2019 Vonage. All rights reserved.
//

#import "NXMEventsQueueDelegateHelper.h"

@implementation NXMEventsQueueDelegateHelper
+ (instancetype)SingleEventHelperWithExpectationDescription:(NSString *)expectationDescription {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:expectationDescription];
    return [[NXMEventsQueueDelegateHelper alloc] initWithFinishHandleExpectation:expectation];
}

+ (instancetype)multiEventHelperWithExpectedNumberOfHandledEvents:(NSUInteger)expectedNumberOfHandledEvents andExpectationDescription:(NSString *)expectationDescription {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:expectationDescription];
    expectation.expectedFulfillmentCount = expectedNumberOfHandledEvents;
    expectation.assertForOverFulfill = YES;
    return [[NXMEventsQueueDelegateHelper alloc] initWithEventHandleExpectation:expectation];
}

- (instancetype)initWithEventHandleExpectation:(XCTestExpectation *)eventHandleExpectation {
    return [self initWithEventHandleExpectation:eventHandleExpectation andFinishHandleExpectation:nil];
}

- (instancetype)initWithFinishHandleExpectation:(XCTestExpectation *)finishHandleExpectation {
    return [self initWithEventHandleExpectation:nil andFinishHandleExpectation:finishHandleExpectation];
}

- (instancetype)initWithEventHandleExpectation:(XCTestExpectation *)eventHandleExpectation andFinishHandleExpectation:(XCTestExpectation *)finishHandleExpectation {
    if(self = [super init]) {
        self.eventHandleExpectation = eventHandleExpectation;
        self.finishHandleExpectation = finishHandleExpectation;
        self.handledEvents = [NSMutableArray new];
    }
    return self;
}

- (NSArray<NSNumber *> *)handledEventsIds {
    return [self.handledEvents valueForKey:NSStringFromSelector(@selector(uuid))];
}

- (NSArray<XCTestExpectation *> *)expectations {
    NSMutableArray *expecs = [NSMutableArray new];
    if(self.eventHandleExpectation) {
        [expecs addObject:self.eventHandleExpectation];
    }
    if(self.finishHandleExpectation) {
        [expecs addObject:self.finishHandleExpectation];
    }
    return expecs;
}

- (void)handleEvent:(NXMEvent*_Nonnull)event {
    [self.handledEvents addObject:event];
    if(self.eventHandleExpectation) {
        [self.eventHandleExpectation fulfill];
    }
}

- (void)finishHandleEventsSequence {
    if(self.finishHandleExpectation) {
        [self.finishHandleExpectation fulfill];
    }
}

- (void)conversationExpired {
    
}

@end
