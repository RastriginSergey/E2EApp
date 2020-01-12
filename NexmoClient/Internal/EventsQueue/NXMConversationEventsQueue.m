//
//  ConversationEventsQueue.m
//  StitchClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMConversationEventsQueue.h"
#import "NXMStitchContext.h"
#import "NXMEventsDispatcherNotificationHelper.h"
#import "NXMLoggerInternal.h"


@interface NXMConversationEventsQueue()

@property (strong,nonatomic)NSString *conversationId;
@property (strong,nonatomic)NSMutableArray<NXMEvent*>*eventsQueue;
@property (strong,nonatomic)NSOperationQueue *operationQueue;
@property (nonatomic, readwrite) NSInteger currentHandledSequenceId;
@property (nonatomic, readwrite) NSInteger sequenceIdSyncingFrom;
@property (nonatomic, readwrite) NSInteger highestQueriedSequenceId;
@property (nonatomic) NSUInteger numOfProcessingRequests;
@property (nonatomic, readonly, getter=getIsProcessingRequests) BOOL isProcessingRequests;

@property (strong,nonatomic)NSMutableArray <id <NSObject>>*observers;
@property (strong,nonatomic)NXMStitchContext *stitchContext;
@property int sucsessNumber;
@property int failNumber;

@end

@implementation NXMConversationEventsQueue

const unsigned int MAX_PAGE_EVENTS=60;

#pragma mark - Init
- (nullable instancetype)initWithConversationDetails:(nonnull NXMConversationDetails*)ConversationDetails
                                       stitchContext:(nonnull NXMStitchContext*)stitchContext {
    return [self initWithConversationDetails:ConversationDetails stitchContext:stitchContext delegate:nil];
}

- (nullable instancetype)initWithConversationDetails:(nonnull NXMConversationDetails*)ConversationDetails
                                    stitchContext:(nonnull NXMStitchContext*)stitchContext
                                            delegate:(_Nullable id <NXMConversationEventsQueueDelegate>)delegate{
    self = [super init];
    if(self){
        self.conversationId = ConversationDetails.conversationId;
        self.eventsQueue = [[NSMutableArray alloc] init];
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        self.currentHandledSequenceId = ConversationDetails.sequence_number;
        self.sequenceIdSyncingFrom = ConversationDetails.sequence_number;
        self.highestQueriedSequenceId = ConversationDetails.sequence_number;
        self.stitchContext = stitchContext;
        self.delegate = delegate;
        [self registerSocketEventsNotifications];
    }
    return self;
}

- (void)dealloc{
    [self unregisterFromDispatchedEvents];
}

- (BOOL)getIsProcessingRequests {
    return self.numOfProcessingRequests != 0;
}

#pragma mark - Dispatcher Registration
- (void)unregisterFromDispatchedEvents {
    [self.stitchContext.eventsDispatcher.notificationCenter removeObserver:self];
}

- (void)registerToDispatchedEvent:(NSString *)eventName {
    [self.stitchContext.eventsDispatcher.notificationCenter addObserver:self selector:@selector(handleDispatchedEventWithNotification:) name:eventName object:nil];
}

- (void)registerToDispatchedConnectionStatus:(NSString *)eventName {
    [self.stitchContext.eventsDispatcher.notificationCenter addObserver:self selector:@selector(handleDispatchedConnectionStatusWithNotification:) name:eventName object:nil];
}

- (void)registerSocketEventsNotifications{
    [self registerToDispatchedEvent:kNXMEventsDispatcherNotificationMember];
    [self registerToDispatchedEvent:kNXMEventsDispatcherNotificationMedia];
    [self registerToDispatchedEvent:kNXMEventsDispatcherNotificationCustom];
    [self registerToDispatchedEvent:kNXMEventsDispatcherNotificationMessage];
    [self registerToDispatchedEvent:kNXMEventsDispatcherNotificationMessageStatus];
    
    [self registerToDispatchedConnectionStatus:kNXMEventsDispatcherNotificationConnectionStatus];
}

#pragma mark - Dispatch Handlers
- (void)handleDispatchedConnectionStatusWithNotification:(NSNotification *)notification {
    NXM_LOG_DEBUG([[NSString stringWithFormat:@"%@ %@", notification.name, notification.userInfo] UTF8String]);
    
    NXMEventsDispatcherConnectionStatusModel *connectionStatusModel = [NXMEventsDispatcherNotificationHelper<NXMEventsDispatcherConnectionStatusModel *> nxmNotificationModelWithNotification:notification];
    
    __weak NXMConversationEventsQueue *weakSelf = self;
    [self.operationQueue addOperationWithBlock:^{
        [weakSelf handleDispatchedConnectionStatus:connectionStatusModel.status];
    }];
}

- (void)handleDispatchedEventWithNotification:(NSNotification *)notification {
    NXMEvent *event = [NXMEventsDispatcherNotificationHelper<NXMEvent *> nxmNotificationModelWithNotification:notification];
    NXM_LOG_DEBUG("<%p> %s", self, [event.description UTF8String]);
    __weak NXMConversationEventsQueue *weakSelf = self;
    [self.operationQueue addOperationWithBlock:^{
        [weakSelf handleDispatchedEvent: event];
    }];
}

- (void)handleDispatchedConnectionStatus:(NXMConnectionStatus)connectionStatus {
    NXM_LOG_DEBUG("<%p> %i", self, connectionStatus);
    if(connectionStatus != NXMConnectionStatusConnected) {
        return;
    }
    
    [self queryEventsFromServerUpToLastEvent];
}

- (void)handleDispatchedEvent:(NXMEvent*)event{
    NXM_LOG_DEBUG("<%p> %s", self, [event.description UTF8String]);
    if(![event.conversationUuid isEqualToString:self.conversationId]){
        return;
    }
    [self startProcessingRequest];
    [self.eventsQueue addObject:event];
    [self endProcessingRequest];
}

#pragma mark - Process Queued Events

- (void)processNextEvent{
    NXM_LOG_DEBUG("<%p>", self);
    NXMEvent *event = self.eventsQueue.firstObject;
    if(event == nil){
        [self finishHandleEventsSequence];
        return;
    }
    
    NXM_LOG_DEBUG("<%p> Processing #%li of type %li, syncingFrom: %li, currentHandled: %li, maxQueried: %li", self, event.uuid, event.type, self.sequenceIdSyncingFrom, self.currentHandledSequenceId, self.highestQueriedSequenceId);
    
    if(event.uuid < self.sequenceIdSyncingFrom) {
        [self doneProcessingEvent:event];
        return;
    }
    
    if([self isMissingEventsWithNextEvent:event]) {
        [self queryEventsFromServerUpToEndId:@(event.uuid - 1)];
        return;
    }
    
    [self handleEvent:event];
}

- (BOOL)isMissingEventsWithNextEvent:(NXMEvent *)event {
    NXM_LOG_DEBUG("<%p> %i", self, event.uuid);
    return event.uuid > self.currentHandledSequenceId + 1 && event.uuid > self.highestQueriedSequenceId + 1;
}

- (void)handleEvent:(NXMEvent*)event {
    NXM_LOG_DEBUG([event.description UTF8String]);
    BOOL shouldHandleEvent = event.uuid > self.currentHandledSequenceId ||
                             event.type == NXMEventTypeMessageStatus;
    
    if(shouldHandleEvent &&
       [self.delegate respondsToSelector:@selector(handleEvent:)]) {
        NXM_LOG_DEBUG("<%p> Handeling #%li of type %li", self, event.uuid, event.type);
        [self.delegate handleEvent:event];
    }
    
    if(event.uuid > self.currentHandledSequenceId) {
        self.currentHandledSequenceId = event.uuid;
    }
    
    [self doneProcessingEvent:event];
}

-(void)doneProcessingEvent:(NXMEvent*)event{
    NXM_LOG_DEBUG("<%p> %s", self,[event.description UTF8String]);
    [self.eventsQueue removeObject:event];
    [self processNextEvent];
}

- (void)finishHandleEventsSequence{
    if([self.delegate respondsToSelector:@selector(finishHandleEventsSequence)]){
        [self.delegate finishHandleEventsSequence];
    }
}

#pragma mark - Query Event Sequence

- (void)queryEventsFromServerUpToLastEvent {
    NXM_LOG_DEBUG("<%p> %s", self, "Querying events up to last event" );
    __weak NXMConversationEventsQueue *weakSelf = self;
    [self.stitchContext.coreClient getLatestEventInConversation:self.conversationId onSuccess:^(NXMEvent * _Nullable event) {
        [self.operationQueue addOperationWithBlock:^{
            [weakSelf handleDispatchedEvent: event];
        }];
    } onError:^(NSError * _Nullable error) {
        // PATCH!! FIX on conversation deleted. this code stops the events queue FOREVER.
        // when we will add retry mechanism this code will be moved.
        if (error.code == NXMErrorCodeConversationNotFound) {
            NXM_LOG_DEBUG("ConversationEventsQueue NXMErrorCodeConversationNotFound %s", [error.description UTF8String]);
            [self.delegate conversationExpired];
            
            return;
        }
        
        [weakSelf.operationQueue addOperationWithBlock:^{
             NXM_LOG_ERROR("ConversationEventsQueue failed querying events from server with error: %s" , [error.description UTF8String]);
            [self endProcessingRequest];
            return;
            //TODO: handle specific errors in case that we want handle next events
            //right now we stop handeling events until another event arrives or connection status changes to connected
        }];
    }];
}

- (void)queryEventsFromServerUpToEndId:(NSNumber *)endId {
    NXM_LOG_DEBUG("<%p> %i", self, endId);
    [self startProcessingRequest];
    __weak NXMConversationEventsQueue *weakSelf = self;
    //Check that the request dosn't ask for more then MAX_PAGE_EVENTS
    NSNumber *maxAllowedEndId = @(self.currentHandledSequenceId + MAX_PAGE_EVENTS);
    endId = endId ? @(MIN([endId integerValue], [maxAllowedEndId integerValue])) : maxAllowedEndId;
    [self.stitchContext.coreClient getEventsInConversation:self.conversationId
                                                   startId:@(self.currentHandledSequenceId + 1)
                                                     endId:endId onSuccess:^(NSMutableArray<NXMEvent *> * _Nullable events) {
        [weakSelf.operationQueue addOperationWithBlock:^{
            NSNumber * highestQueriedWithResponse = [weakSelf handleGetEventResponse:events];
            
            NSNumber *highestQueriedUpdate = endId ?: highestQueriedWithResponse;
            if(highestQueriedUpdate) {
                [self updateHighestQueriedWithSequenceId:[highestQueriedUpdate integerValue]];
            }
            
            [self endProcessingRequest];
        }];
    } onError:^(NSError * _Nullable error) {
        // PATCH!! FIX on conversation deleted. this code stops the events queue FOREVER.
        // when we will add retry mechanism this code will be moved.
        if (error.code == NXMErrorCodeConversationNotFound) {
            NXM_LOG_DEBUG("ConversationEventsQueue NXMErrorCodeConversationNotFound %s" , [error.description UTF8String]);
            [self conversationExpired];

            return;
        }
        
        [weakSelf.operationQueue addOperationWithBlock:^{
             NXM_LOG_ERROR("ConversationEventsQueue failed querying events from server with error: %s" , [error.description UTF8String]);
            [self endProcessingRequest];
            return;
            //TODO: handle specific errors in case that we want handle next events
            //right now we stop handeling events until another event arrives or connection status changes to connected
        }];
    }];
}

- (void)conversationExpired {
    NXM_LOG_DEBUG("<%p>", self);
    NSArray *sortedEvents = [self.eventsQueue sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return ((NXMEvent *)obj1).uuid < ((NXMEvent *)obj2).uuid ?
                (NSComparisonResult)NSOrderedAscending :
                (NSComparisonResult)NSOrderedDescending;
    }];
    
    NXM_LOG_DEBUG("NXMConversationEventsQueue flush events %lu", (unsigned long)sortedEvents.count);
    
    for (NXMEvent *event in sortedEvents) {
        [self.delegate handleEvent:event];
    }
    
    [self.delegate conversationExpired];

}

- (void)startProcessingRequest {
    NXM_LOG_DEBUG("");
    self.numOfProcessingRequests++;
}

- (void)endProcessingRequest {
    NXM_LOG_DEBUG("");
    self.numOfProcessingRequests--;
    if(self.numOfProcessingRequests == 0) {
        [self processNextEvent];
    }
}

- (void)updateHighestQueriedWithSequenceId:(NSInteger)sequenceId {
    NXM_LOG_DEBUG("%i", sequenceId);
    if(sequenceId > self.highestQueriedSequenceId) {
        self.highestQueriedSequenceId = sequenceId;
    }
}

- (NSNumber *)handleGetEventResponse:(NSArray<NXMEvent*>*)events {
    NXM_LOG_DEBUG([events.description UTF8String]);
    NSArray<NXMEvent*> *sortedEventsArray = [self sortWithEvents:events];
    [self insertToEventsQueueWithEvents:sortedEventsArray];
    return [self highestEventIdWithSortedEvents:sortedEventsArray];
}

- (NSArray<NXMEvent*> *)sortWithEvents:(NSArray<NXMEvent*>*)events {
    NXM_LOG_DEBUG([events.description UTF8String]);
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"uuid" ascending:YES];
    return [events sortedArrayUsingDescriptors:@[sort]];
}

- (void)insertToEventsQueueWithEvents:(NSArray<NXMEvent*> *)events {
    NXM_LOG_DEBUG([events.description UTF8String]);
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, events.count)];
    [self.eventsQueue insertObjects:events atIndexes:indexes];
}

- (nullable NSNumber *)highestEventIdWithSortedEvents:(NSArray<NXMEvent*> *)sortedEvents {
    NXM_LOG_DEBUG([sortedEvents.description UTF8String]);
    NSNumber *highestEventId = nil;
    NXMEvent *highestEvent = sortedEvents.lastObject;
    
    if(highestEvent) {
        highestEventId = [NSNumber numberWithInteger:highestEvent.uuid];
    }
    
    return highestEventId;
}

@end
