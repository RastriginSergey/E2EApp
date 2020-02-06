//
//  NXMClient.m
//  NexmoClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMClient.h"
#import "NXMStitchContext.h"
#import "NXMConversationPrivate.h"
#import "NXMConversationIdsPage.h"
#import "NXMCallPrivate.h"
#import "NXMCallMemberPrivate.h"
#import "NXMBlocksHelper.h"
#import "NXMLoggerInternal.h"
#import "NXMErrorsPrivate.h"
#import "NXMEventInternal.h"
#import "NXMPushPayloadInternal.h"
#import "NXMMemberEventPrivate.h"
#import "NXMConversationsPagingHandler.h"

typedef void (^knockingComplition)(NSError * _Nullable error, NXMCall * _Nullable call);
NSString *const NXMCallPrefix = @"CALL_";

static NSString *const NXMCLIENT_CONFIG_CHANGED_AFTER_SHARED_EXCEPTION_REASON = @"NXMClientConfig can't be changed after shared's been called.";

@interface NXMClientRefCallObj : NSObject
@property knockingComplition complition;
@end
@implementation NXMClientRefCallObj
@end

@interface NXMClient() <NXMStitchContextDelegate>

@property (nonatomic, nonnull) NXMStitchContext *stitchContext;
@property (nonatomic, nullable, weak) id <NXMClientDelegate> delegate;
@property (nonatomic, nonnull) NSMutableDictionary<NSString*, NXMClientRefCallObj*> * clientRefToCallCallback;
@property (nonatomic, nonnull) NXMConversationsPagingHandler *conversationsPagingHandler;
@property (nonatomic, nonnull) NSMutableDictionary<NSString*, NSNumber*> * conversationToLastEvent;
@property (nonatomic, nonnull) NSObject * syncConversationToLastEvent;
@end

@implementation NXMClient

static NXMClientConfig *_configuration = nil;
static NXMClient * _sharedInstance = nil;
static dispatch_once_t _onceToken = 0;

- (nonnull instancetype)initWithConfiguration:(nonnull NXMClientConfig *)configuration {
    NXM_LOG_DEBUG("--------------------- Nexmo Client-----------------------");
    NXM_LOG_DEBUG("::::    :::  ::::::::::  :::    :::  ::::    ::::    ::::::::");
    NXM_LOG_DEBUG(":+:+:   :+:  :+:         :+:    :+:  +:+:+: :+:+:+  :+:    :+:");
    NXM_LOG_DEBUG(":+:+:+  +:+  +:+          +:+  +:+   +:+ +:+:+ +:+  +:+    +:+");
    NXM_LOG_DEBUG("+#+ +:+ +#+  +#++:++#      +#++:+    +#+  +:+  +#+  +#+    +:+");
    NXM_LOG_DEBUG("+#+  +#+#+#  +#+          +#+  +#+   +#+       +#+  +#+    +#+");
    NXM_LOG_DEBUG("#+#   #+#+#  #+#         #+#    #+#  #+#       #+#  #+#    #+#");
    NXM_LOG_DEBUG("###    ####  ##########  ###    ###  ###       ###   ########");
    NXM_LOG_DEBUG("--------------------- Nexmo Client-----------------------");
    
    if(self = [super init]) {
        self.stitchContext = [[NXMStitchContext alloc] initWithCoreClient:[[NXMCore alloc] initWithToken:@""
                                                                                           configuration:configuration]];
        [self.stitchContext setDelegate:self];
         
        [self.stitchContext.eventsDispatcher.notificationCenter addObserver:self selector:@selector(onMemberEvent:) name:kNXMEventsDispatcherNotificationMember object:nil];
        
        self.clientRefToCallCallback = [NSMutableDictionary new];
        self.conversationToLastEvent = [NSMutableDictionary new];
        self.syncConversationToLastEvent = [NSObject new];

        __weak typeof(self) weakSelf = self;
        self.conversationsPagingHandler = [[NXMConversationsPagingHandler alloc] initWithStitchContext:self.stitchContext
                                                                               getConversationWithUuid:^(NSString * _Nonnull uuid, void (^ _Nullable completionHandler)(NSError * _Nullable, NXMConversation * _Nullable)) {
                                                                                   [weakSelf getConversationWithUuid:uuid completionHandler:completionHandler];
                                                                               }];
    }
    
    return self;
}

- (void)dealloc {
    [self.stitchContext.eventsDispatcher.notificationCenter removeObserver:self];
}

#pragma shared

+ (NXMClient *)shared {
    dispatch_once(&_onceToken, ^{
        _configuration = _configuration ?: [NXMClientConfig new];
        _sharedInstance = [[NXMClient alloc] initWithConfiguration:_configuration];
    });
    return _sharedInstance;
}

// DO NOT USE THIS METHOD!! ONLY FOR TESTING - RESET SINGLETON
+ (void)destory {
    _sharedInstance = nil;
    _onceToken = 0;
    _configuration = nil;
}

#pragma configuration

+ (void)setConfiguration:(NXMClientConfig *)configuration {
    if (_sharedInstance) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:NXMCLIENT_CONFIG_CHANGED_AFTER_SHARED_EXCEPTION_REASON
                                     userInfo:nil];
    }
    
    _configuration = configuration;
}


#pragma mark - login and connectivity

-(bool) isConnected {
    return [self getConnectionStatus] == NXMConnectionStatusConnected;
}

-(NXMConnectionStatus)getConnectionStatus {
    return self.stitchContext.coreClient.connectionStatus;
}

// TODO: move to user defaults
-(NXMUser *)getUser {
    return [self.stitchContext currentUser];
}

// TODO: move to user defaults
-(NSString *)getToken {
    return self.stitchContext.coreClient.token;
}

// TODO: move to user defaults
-(NXMClientConfig *)getConfiguration {
    return _configuration;
}

-(void)loginWithAuthToken:(NSString *)authToken {
    NXM_LOG_DEBUG("" );
    if(!self.delegate) {
        NXM_LOG_ERROR("login called without setting delegate");
    }
    self.stitchContext.coreClient.token = authToken;
    [self.stitchContext.coreClient login];

}

-(void)updateAuthToken:(nonnull NSString *)authToken {
    NXM_LOG_DEBUG([authToken UTF8String]);

    [self.stitchContext.coreClient refreshAuthToken:authToken];
}

-(void)logout {
    NXM_LOG_DEBUG("" );

    if (self.connectionStatus == NXMConnectionStatusDisconnected) {
        return;
    }
    
    //TODO: disableAudio
    
    //TODO: decide if disable should be required before logout, or maybe it should be
    [self disablePushNotifications:^(NSError * _Nullable error) {
        if(error) {
            NXM_LOG_ERROR("failed disabling push during logout with error: %s", [error.description UTF8String]);
            return;
        }
    }];
    
    [self.stitchContext.coreClient logout];
}

#pragma StitchContext delegate
- (void)onError:(NXMErrorCode)errorCode {
    [self.delegate client:self didReceiveError:[NXMErrors nxmErrorWithErrorCode:errorCode]];
}


- (void)connectionStatusChanged:(NXMConnectionStatus)status reason:(NXMConnectionStatusReason)reason {
    NXM_LOG_DEBUG("status %ld reason %ld", status, reason);
    NSError *setUpCleanUpError = nil;
    switch (self.connectionStatus) {
        case NXMConnectionStatusDisconnected:
            if(![self cleanUpWithErrorPtr:&setUpCleanUpError]) {
                //TODO: report/fail cleanup error
            }
            break;
        case NXMConnectionStatusConnected:
            if(![self setUpWithErrorPtr:&setUpCleanUpError]) {
                //TODO: report/fail setup error
            }
            break;
        case NXMConnectionStatusConnecting:
        default:
            break;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate client:self didChangeConnectionStatus:status reason:reason];
    });
}

#pragma mark - conversation

-(void)getConversationWithUuid:(nonnull NSString *)converesationId
                  completionHandler:(void(^_Nullable)(NSError * _Nullable error, NXMConversation * _Nullable conversation))completion {
    NXM_LOG_DEBUG([converesationId UTF8String]);
    if (![self isConnected]){
        NXM_LOG_DEBUG("SDK disconnected" );
        completion([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeSDKDisconnected], nil);
        return;
    }
    
    [self.stitchContext.coreClient getConversationDetails:converesationId
                                                onSuccess:^(NXMConversationDetails * _Nullable conversationDetails) {
                                                    if(completion) {
                                                        NXMConversation *conversation = [[NXMConversation alloc] initWithConversationDetails:conversationDetails andStitchContext:self.stitchContext];
                                                        completion(nil, conversation);
                                                    }
                                                }
                                                  onError:^(NSError * _Nullable error) {
                                                      [NXMBlocksHelper runWithError:error value:nil completion:completion];
                                                  }];
    }

-(void)createConversationWithName:(nonnull NSString *)name completionHandler:(void(^_Nullable)(NSError * _Nullable error, NXMConversation * _Nullable conversation))completion {
    NXM_LOG_DEBUG("" );

    if (![self isConnected]){
        NXM_LOG_DEBUG("SDK disconnected" );
        completion([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeSDKDisconnected], nil);
        return;
    }
    __weak NXMClient *weakSelf = self;
    [self.stitchContext.coreClient createConversationWithName:name
                                                    onSuccess:^(NSString * _Nullable value) {
                                                        if(completion) {
                                                            [weakSelf getConversationWithUuid:value completionHandler:^(NSError * _Nullable error, NXMConversation * _Nullable conversation){
                                                                if(!conversation) {
                                                                    NSError *wrappingError = [NXMErrors nxmErrorWithErrorCode:NXMErrorCodeConversationRetrievalFailed andUserInfo:@{NSLocalizedDescriptionKey:[NXMErrors nxmErrorCodeToString:NXMErrorCodeConversationRetrievalFailed],
                                                                                                                                                                    NSUnderlyingErrorKey: error}];
                                                                    
                                                                    [NXMBlocksHelper runWithError:wrappingError value:nil completion:completion];
                                                                    return;
                                                                }
                                                                
                                                                [NXMBlocksHelper runWithError:nil value:conversation completion:completion];
                                                            }];
                                                        }
                                                    }
                                                    onError:^(NSError * _Nullable error) {
                                                        [NXMBlocksHelper runWithError:error value:nil completion:completion];

                                                    }];
}

- (void)getConversationsPageWithSize:(NSInteger)size
                               order:(NXMPageOrder)order
                   completionHandler:(void (^)(NSError * _Nullable, NXMConversationsPage * _Nullable))completionHandler {
    NSString *userId = self.user.uuid;
    NXM_LOG_DEBUG([NSString stringWithFormat: @"UserID: %@; Page size: %@", userId, @(size).stringValue].UTF8String);
    [self.conversationsPagingHandler getConversationsPageWithSize:size
                                                            order:order
                                                           userId:userId
                                                completionHandler:completionHandler];
}

- (void)addPendingClientReference:(nonnull NSString*)clientRef
                     delegate:(id<NXMCallDelegate>)delegate
                   completion:(void(^_Nullable)(NSError * _Nullable error, NXMCall * _Nullable call))completion{
    NXM_LOG_DEBUG([clientRef UTF8String]);

    NXMClientRefCallObj *clientRefObj = [NXMClientRefCallObj new];
    clientRefObj.complition = completion;
    self.clientRefToCallCallback[clientRef] = clientRefObj;
}

- (void)startIpCall:(nonnull NSString *)callee
            delegate:(id<NXMCallDelegate>)delegate
          completion:(void(^_Nullable)(NSError * _Nullable error, NXMCall * _Nullable call))completion {
    NXM_LOG_DEBUG([callee UTF8String]);
    __weak NXMClient *weakSelf = self;
    __weak NXMCore *weakCore = self.stitchContext.coreClient;
    [weakCore createConversationWithName:[NSString stringWithFormat:@"%@%@", NXMCallPrefix, [[NSUUID UUID] UUIDString]]
                               onSuccess:^(NSString * _Nullable convId) {
                                   [weakSelf getConversationWithUuid:convId completionHandler:^(NSError * _Nullable error, NXMConversation * _Nullable conversation) {
                                       NXMCall * call = [[NXMCall alloc] initWithConversation:conversation];

                                       if (conversation){
                                           call.clientRef = [conversation joinClientRef:^(NSError * _Nullable error, NXMMember * _Nullable member) {
                                               if (member) {
                                                   [conversation inviteMemberWithUsername:callee withMedia:YES completion:^(NSError *error, NXMMember *member) {
                                                       
                                                       if (error) {
                                                           [NXMBlocksHelper runWithError:error
                                                                                   value:nil
                                                                              completion:completion];
                                                           return;
                                                       }
                                                       

                                                       [NXMBlocksHelper runWithError:nil value:call completion:completion];
                                                   }];
                                               }
                                           }];
                                       } else {
                                           [NXMBlocksHelper runWithError:[NXMErrors nxmErrorWithErrorCode:NXMErrorCodeUnknown]
                                                        value:nil
                                                   completion:completion];

                                       }
                                   }];
                               }
                                 onError:^(NSError * _Nullable error) {
                                     [NXMBlocksHelper runWithError:error value:nil completion:completion];
                                 }
     ];
}

- (void)startServerCall:(nonnull NSString *)callee
            delegate:(id<NXMCallDelegate>)delegate
          completion:(void(^_Nullable)(NSError * _Nullable error, NXMCall * _Nullable call))completion {
    NXM_LOG_DEBUG([callee UTF8String]);

    
    NSString *clientRef = [self.stitchContext.coreClient inviteToConversation:self.user.name withPhoneNumber:callee onSuccess:^(NSString * _Nullable value) {
            //if (value)
    } onError:^(NSError * _Nullable error) {
        NXM_LOG_ERROR("startServerCall falied %s", [error.description UTF8String]);
    }];
    
    [self addPendingClientReference:clientRef delegate:delegate completion:completion];
}

- (void)call:(nonnull NSString *)callees
           callHandler:(NXMCallHandler)callHandler
         completionHandler:(void (^ _Nullable)(NSError * _Nullable, NXMCall * _Nullable))completionHandler {
    NXM_LOG_DEBUG([[callees description] UTF8String]);
    if (![self isConnected]){
        NXM_LOG_DEBUG("SDK disconnected" );
        completionHandler([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeSDKDisconnected], nil);
        return;
    }
    switch (callHandler) {
        case NXMCallHandlerInApp:
            [self startIpCall:callees delegate:nil completion:completionHandler];
            break;
        case NXMCallHandlerServer:
            [self startServerCall:callees delegate:nil completion:completionHandler];
            break;
        default:
            break;
    }
}

#pragma mark - push

- (void)enablePushNotificationsWithPushKitToken:(nullable NSData *)pushKitToken
                          userNotificationToken:(nullable NSData *)userNotificationToken
                                      isSandbox:(BOOL)isSandbox
                              completionHandler:(void(^_Nullable)(NSError * _Nullable error))completionHandler {
    NXM_LOG_DEBUG("%s %s %d", [[NSString alloc] initWithData:pushKitToken encoding:NSUTF8StringEncoding],  [[NSString alloc] initWithData:userNotificationToken encoding:NSUTF8StringEncoding], isSandbox);
    if (![self isConnected]){
        NXM_LOG_DEBUG("SDK disconnected" );
        completionHandler([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeSDKDisconnected]);
        return;
    }
    
    [self.stitchContext.coreClient enablePushNotificationsWithPushKitToken:pushKitToken
                                                     userNotificationToken:userNotificationToken
                                                                 isSandbox:isSandbox
                                                                 onSuccess:^{
        NXM_LOG_DEBUG("Nexmo push notifications enabled" );
        [NXMBlocksHelper runWithError:nil completion:completionHandler];
    } onError:^(NSError * _Nullable error) {
        NXM_LOG_ERROR("Nexmo push notifications enabling failed with error: %s", [error.description UTF8String]);
        [NXMBlocksHelper runWithError:error completion:completionHandler];
    }];
}

- (void)disablePushNotifications:(void(^_Nullable)(NSError * _Nullable error))completionHandler {
    NXM_LOG_DEBUG("" );

    if (![self isConnected]){
        NXM_LOG_DEBUG("SDK disconnected");
        completionHandler([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeSDKDisconnected]);
        return;
    }
    [self.stitchContext.coreClient disablePushNotificationsWithOnSuccess:^{
        NXM_LOG_DEBUG("Nexmo push notifications disabled" );
        [NXMBlocksHelper runWithError:nil completion:completionHandler];
    } onError:^(NSError * _Nullable error) {
        NXM_LOG_ERROR("Nexmo push notifications disabling failed with error: %s", [error.description UTF8String]);
        [NXMBlocksHelper runWithError:error completion:completionHandler];
    }];

}

- (BOOL)isNexmoPushWithUserInfo:(nonnull NSDictionary *)userInfo {
    NXM_LOG_DEBUG([[userInfo description] UTF8String]);
    
    return [self.stitchContext.coreClient isNexmoPushWithUserInfo:userInfo];
    
}

- (void)processNexmoPushWithUserInfo:(nonnull NSDictionary *)userInfo completionHandler:(void (^ _Nullable)(NSError * _Nullable))completionHandler {
    NXM_LOG_DEBUG([[userInfo description] UTF8String]);
    
    if (![self isConnected]){
        NXM_LOG_DEBUG("SDK disconnected");
        completionHandler([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeSDKDisconnected]);
        return;
    }
    
    [self.stitchContext.coreClient processNexmoPushWithUserInfo:userInfo onSuccess:^(NXMEvent * _Nullable event) {
        [NXMBlocksHelper runWithError:nil completion:completionHandler];
    } onError:^(NSError * _Nullable error) {
        NXM_LOG_ERROR("Error processing nexmo push with error:%s", [error.description UTF8String]);
        [NXMBlocksHelper runWithError:error completion:completionHandler];
    }];
}

- (nullable NXMPushPayload *)processNexmoPushPayload:(nonnull NSDictionary *)pushInfo {
    NXM_LOG_DEBUG([[pushInfo description] UTF8String]);
    
    NSDictionary *nexmoPayload = pushInfo[@"nexmo"];
    if (!nexmoPayload) {
        [self.delegate client:self didReceiveError:[NXMErrors nxmErrorWithErrorCode:NXMErrorCodePushNotANexmoPush]];
        return nil;
    }
    
    [self processNexmoPushWithUserInfo:pushInfo completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NXM_LOG_ERROR(error.description.UTF8String);
        }
    }];
    
    NXMPushPayload *payload = [[NXMPushPayload alloc] initWithData:nexmoPayload];
    
    return payload;
}

#pragma mark - notification center

- (void)onMemberEvent:(NSNotification* )notification {
    NXM_LOG_DEBUG([notification.name UTF8String]);
    NXMMemberEvent* event = [NXMEventsDispatcherNotificationHelper<NXMMemberEvent *> nxmNotificationModelWithNotification:notification];
    
    NXM_LOG_DEBUG([[event description] UTF8String]);
    
    if (![event.user.uuid isEqualToString:self.user.uuid]) { return; }
    
    if ([self tryUpdateConversationSequenceId:[NSNumber numberWithInteger:event.uuid] conversationId:event.conversationUuid]) { return;}
                                
    /*
     Three types of events
     1. incoming conversation (Joined + Someone else invite you + no knocking id)
     2. incoming IP call (Invited + media enabled)
     3. out going server call (Joined + knocking Id exist)
    */
    //Incoming conversation
    if (![event.fromMemberId isEqualToString:event.memberId] &&
        event.state != NXMMemberStateLeft  &&
        !event.knockingId &&
        !event.media.isEnabled) {
        if ([self.delegate respondsToSelector:@selector(client:didReceiveConversation:)]) {
            NXM_LOG_DEBUG("got newConversation event" );
            
            [self getConversationWithUuid:event.conversationUuid completionHandler:^(NSError * _Nullable error, NXMConversation * _Nullable conversation) {
                if (error) {
                    NXM_LOG_ERROR("get conversation failed %s", [error.description UTF8String]);
                    return;
                }
                
                if (!conversation) {
                    NXM_LOG_ERROR("got empty conversation without error conversation id %s:", [event.conversationUuid UTF8String]);
                }
                
                
                [self.delegate client:self didReceiveConversation:conversation];
            }];
        }
        
        return;
    }
    
    //Incoming IP call
    if (event.state == NXMMemberStateInvited && event.media.isEnabled) {
        if ([self.delegate respondsToSelector:@selector(client:didReceiveCall:)]) { // optimization
            
            NXM_LOG_DEBUG("got member invited event with enable media" );
            
            [self getConversationWithUuid:event.conversationUuid completionHandler:^(NSError * _Nullable error, NXMConversation * _Nullable conversation) {
                if (error) {
                    NXM_LOG_ERROR("get conversation failed %s", [error.description UTF8String]);
                    return;
                }

                if (!conversation){
                    NXM_LOG_ERROR("got empty conversation without error conversation id %s:", [event.conversationUuid UTF8String]);
                }

                if (![conversation.displayName hasPrefix:NXMCallPrefix] && // IP-IP CS
                        event.fromMemberId) { // IP-IP VAPI
                    NXM_LOG_ERROR("member invited event with media enabled without call perfix" );
                    return;
                }

                NXMCall * call = [[NXMCall alloc] initWithConversation:conversation];
                [self.delegate client:self didReceiveCall:call];

            }];

        }
    }
    //Out going server call
    if (event.state == NXMMemberStateJoined && event.clientRef.length > 0){
        NXM_LOG_DEBUG("got member JOINED event with clientRef" );
        
        [self getConversationWithUuid:event.conversationUuid completionHandler:^(NSError * _Nullable error, NXMConversation * _Nullable conversation) {
            if (error) {
                 NXM_LOG_ERROR("got empty conversation without error conversation id %s:", [event.conversationUuid UTF8String]);
                return;
            }
            
            if (!conversation){
                NXM_LOG_ERROR("got empty conversation without error conversation id %s:", [event.conversationUuid UTF8String]);
            }
            
            if (event.clientRef && self.clientRefToCallCallback[event.clientRef]){
                NXM_LOG_DEBUG("processing clientRef");
                NXMClientRefCallObj *obj = self.clientRefToCallCallback[event.clientRef];
                [conversation enableMedia];
                [self.clientRefToCallCallback removeObjectForKey:event.clientRef];
                
                NXMCall * call = [[NXMCall alloc] initWithConversation:conversation];
                obj.complition(nil, call);
            } else {
                NXM_LOG_ERROR("got member event with clientRef that client doesn't have");
                //TODO: check if this is a valid state for a call
                //this could happened if we get the member events before cs return the knocking id
                //to prevent drop calls we use the Incoming IP call
              //  [self.delegate didReceiveCall:call];
            }
        }];
    }
}

#pragma mark - private

- (BOOL)setUpWithErrorPtr:(NSError **)errorPtr {
    NXM_LOG_DEBUG("" );
    //TODO: set up, set error and return false if problematic
    return YES;
}

- (BOOL)cleanUpWithErrorPtr:(NSError **)errorPtr {
    NXM_LOG_DEBUG("" );
    //TODO: clean up, set error and return false if problematic
    return YES;
}

- (BOOL)tryUpdateConversationSequenceId:(NSNumber*) sequenceId conversationId:(NSString*)conversationId{
    @synchronized (self.syncConversationToLastEvent) {
        if ([sequenceId longValue]<= [self.conversationToLastEvent[conversationId] longValue])  {
            return YES;
        }
        self.conversationToLastEvent[conversationId] = sequenceId;
    }
    return NO;
}

@end
