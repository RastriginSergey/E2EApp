//
//  NXMClient.m
//  NexmoClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMClient.h"
#import "NXMStitchContext.h"
#import "NXMConversationPrivate.h"
#import "NXMCallPrivate.h"
#import "NXMCallParticipantPrivate.h"

@interface NXMClient() <NXMStitchContextDelegate>
@property (nonatomic, nonnull) NXMStitchContext *stitchContext;
@property (nonatomic, nullable, weak) id <NXMClientDelegate> delegate;

@end

@implementation NXMClient

- (instancetype)init {
    if(self = [super init]) {
        self.stitchContext = [[NXMStitchContext alloc] initWithCoreClient:[NXMCore new]];
        [self.stitchContext setDelegate:self];
         
        [self.stitchContext.eventsDispatcher.notificationCenter addObserver:self selector:@selector(onMemberEvent:) name:kNXMEventsDispatcherNotificationMember object:nil];
    }
    return self;
}

- (void)dealloc {
    [self.stitchContext.eventsDispatcher.notificationCenter removeObserver:self];
}

#pragma mark - login and connectivity

-(BOOL)isLoggedIn {
    return self.stitchContext.coreClient.isLoggedIn;
}

-(BOOL)isConnected {
    return self.stitchContext.coreClient.isConnected;
}

// TODO: move to user defaults
-(NXMUser *)getUser {
    return self.stitchContext.coreClient.user;
}

// TODO: move to user defaults
-(NSString *)getToken {
    return self.stitchContext.coreClient.token;
}

-(void)loginWithAuthToken:(nonnull NSString *)authToken {
    if(!self.delegate) {
        [NXMLogger warning:@"NXMClient: login called without setting delegate"];
    }
    [self.stitchContext.coreClient loginWithAuthToken:authToken];
}

-(void)refreshAuthToken:(nonnull NSString *)authToken {
    [self.stitchContext.coreClient refreshAuthToken:authToken];
}

-(void)logout {
    
    if(!self.isLoggedIn) {
        return;
    }
    
    //TODO: disableAudio
    
    //TODO: decide if disable should be required before logout, or maybe it should be 
    [self disablePushNotificationsWithCompletion:^(NSError * _Nullable error) {
        if(error) {
            [NXMLogger errorWithFormat:@"NXMClient: failed disabling push during logout with error: %@", error];
            return;
        }
    }];
    
    [self.stitchContext.coreClient logout];
}



- (void)connectionStatusChanged:(BOOL)isOnline {
    [self.delegate connectionStatusChanged:isOnline];
}

- (void)loginStatusChanged:(nullable NXMUser *)user loginStatus:(BOOL)isLoggedIn withError:(nullable NSError *)error {
    
    //TODO: when deciding how to handle setup/cleanup maybe change this instead of setting up an error, to have a delegate method for setup/cleanup error
    NSError *setUpCleanUpError = nil;
    if(isLoggedIn) {
        if(![self setUpWithErrorPtr:&setUpCleanUpError]) {
            //TODO: report/fail setup error
        }
    } else {
        if(![self cleanUpWithErrorPtr:&setUpCleanUpError]) {
            //TODO: report/fail cleanup error
        }
    }
    
    [self.delegate loginStatusChanged:user loginStatus:isLoggedIn withError:error];
}

- (void)tokenRefreshed {
    [self.delegate tokenRefreshed];
}

#pragma mark - conversation

-(void)getConversationWithId:(nonnull NSString *)converesationId completion:(void(^_Nullable)(NSError * _Nullable error, NXMConversation * _Nullable conversation))completion {
    [self.stitchContext.coreClient getConversationDetails:converesationId
                                                onSuccess:^(NXMConversationDetails * _Nullable conversationDetails) {
                                                    if(completion) {
                                                        NXMConversation *conversation = [[NXMConversation alloc] initWithConversationDetails:conversationDetails andStitchContext:self.stitchContext];
                                                        completion(nil, conversation);
                                                    }
                                                }
                                                  onError:^(NSError * _Nullable error) {
                                                      if(completion) {
                                                          completion(error, nil);
                                                      }
                                                  }];
}

-(void)createConversationWithName:(nonnull NSString *)name completion:(void(^_Nullable)(NSError * _Nullable error, NXMConversation * _Nullable conversation))completion {
    __weak NXMClient *weakSelf = self;
    [self.stitchContext.coreClient createConversationWithName:name
                                                    onSuccess:^(NSString * _Nullable value) {
                                                        if(completion) {
                                                            [weakSelf getConversationWithId:value completion:^(NSError * _Nullable error, NXMConversation * _Nullable conversation){
                                                                if(error) {
                                                                    NSError *wrappingError = [NXMErrors nxmErrorWithErrorCode:NXMErrorCodeConversationRetrievalFailed andUserInfo:@{NSUnderlyingErrorKey: error}];
                                                                    completion(wrappingError, nil);
                                                                } else {
                                                                    completion(nil, conversation);
                                                                }
                                                            }];
                                                        }
                                                    }
                                                    onError:^(NSError * _Nullable error) {
                                                        if(completion) {
                                                            completion(error, nil);
                                                        }
                                                    }];
}

- (void)callToUsers:(nonnull NSArray<NSString *>*)users
           delegate:(id<NXMCallDelegate>)delegate
         completion:(void(^_Nullable)(NSError * _Nullable error, NXMCall * _Nullable call))completion {
    __weak NXMClient *weakSelf = self;
    __weak NXMCore *weakCore = self.stitchContext.coreClient;
    
    [weakCore createConversationWithName:[[NSUUID UUID] UUIDString]
                               onSuccess:^(NSString * _Nullable convId) {
                                   [weakSelf getConversationWithId:convId completion:^(NSError * _Nullable error, NXMConversation * _Nullable conversation) {
                                       if (conversation){
                                           [conversation joinWithCompletion:^(NSError * _Nullable error, NXMMember * _Nullable member) {
                                               if (member){
                                                   NXMCall * call = [[NXMCall alloc] initWithConversation:conversation];
                                                   NXMCallParticipant *participant = [[NXMCallParticipant alloc] initWithMemberId:member.memberId
                                                                                                                     andCallProxy:(id<NXMCallProxy>)call];
                                                   [call setMyParticipant:participant];
                                                   
                                                   [conversation enableMedia:member.memberId];
                                                   
                                                   for (NSString *userId in users) {
                                                       [call addParticipantWithUserId:userId completionHandler:nil];
                                                   }
                                                   
                                                   [call setDelegate:delegate];
                                                   
                                                   completion(nil, call);
                                               }
                                           }];
                                       }else{
                                           completion(error, nil);
                                       }
                                   }];
                               }
                                 onError:^(NSError * _Nullable error) {
                                     completion(error, nil); // TODO: Error handling
                                 }
     ];
}

- (void)callToNumber:(nonnull NSString *)number
           delegate:(id<NXMCallDelegate>)delegate
         completion:(void(^_Nullable)(NSError * _Nullable error, NXMCall * _Nullable call))completion {
    //TODO: the flow for PSTN is diffrent:
    //1. create a knocking request [conversation.inviteToConversationWithPhoneNumber]
    //2. wait for knocking event and get the conversation
    //3. add the current user to the conversation
    //4. return the call object
//    __weak NXMStitchClient *weakSelf = self;
//    __weak NXMStitchCore *weakCore = self.stitchContext.coreClient;
//    
//    [weakCore createConversationWithName:[[NSUUID UUID] UUIDString]
//                               onSuccess:^(NSString * _Nullable convId) {
//                                   [weakSelf getConversationWithId:convId completion:^(NSError * _Nullable error, NXMConversation * _Nullable conversation) {
//                                       if (conversation){
//                                           [conversation joinWithCompletion:^(NSError * _Nullable error, NXMMember * _Nullable member) {
//                                               if (member){
//                                                   NXMCall * call = [[NXMCall alloc] initWithConversation:conversation];
//                                                   NXMCallParticipant *participant = [[NXMCallParticipant alloc] initWithMemberId:member.memberId
//                                                                                                                     andCallProxy:(id<NXMCallProxy>)call];
//                                                   [call setMyParticipant:participant];
//                                                   
//                                                   [conversation enableMedia];
//                                                   [call addParticipantWithNumber:number completionHandler:nil];
//                                                   
//                                                   [call setDelegate:delegate];
//                                                   
//                                                   completion(nil, call);
//                                               }
//                                           }];
//                                       }else{
//                                           completion(error, nil);
//                                       }
//                                   }];
//                               }
//                                 onError:^(NSError * _Nullable error) {
//                                     completion(error, nil); // TODO: Error handling
//                                 }
//     ];
}


#pragma mark - push

- (void)enablePushNotificationsWithDeviceToken:(nonnull NSData *)deviceToken
                                     isPushKit:(BOOL)isPushKit
                                     isSandbox:(BOOL)isSandbox
                                    completion:(void(^_Nullable)(NSError * _Nullable error))completion {
        [self.stitchContext.coreClient enablePushNotificationsWithDeviceToken:deviceToken isSandbox:isSandbox onSuccess:^{
        [self executeBlockWithError:nil completion:completion];
    } onError:^(NSError * _Nullable error) {
        [self executeBlockWithError:error completion:completion];
    }];
}

- (void)disablePushNotificationsWithCompletion:(void(^_Nullable)(NSError * _Nullable error))completion {
    
    [self.stitchContext.coreClient disablePushNotificationsWithOnSuccess:^{
        [self executeBlockWithError:nil completion:completion];
    } onError:^(NSError * _Nullable error) {
        [self executeBlockWithError:error completion:completion];
    }];
}

- (BOOL)isNexmoPushWithUserInfo:(nonnull NSDictionary *)userInfo {
    return [self.stitchContext.coreClient isNexmoPushWithUserInfo:userInfo];
}

- (void)processNexmoPushWithUserInfo:(nonnull NSDictionary *)userInfo completion:(void(^_Nullable)(NSError * _Nullable error))completion {
    [self.stitchContext.coreClient processNexmoPushWithUserInfo:userInfo onSuccess:^(NXMEvent * _Nullable event) {
        [self executeBlockWithError:nil completion:completion];
    } onError:^(NSError * _Nullable error) {
        [self executeBlockWithError:error completion:completion];
    }];
}


#pragma mark - notification center

- (void)onMemberEvent:(NSNotification* )notification {
    NXMMemberEvent* event = [NXMEventsDispatcherNotificationHelper<NXMMemberEvent *> nxmNotificationModelWithNotification:notification];
    
    if (![event.user.userId isEqualToString:self.user.userId]) { return; }
    
    if (event.state == NXMMemberStateJoined && ![event.fromMemberId isEqualToString:event.memberId]) { 
        if ([self.delegate respondsToSelector:@selector(addedToConversation:)]) {            
            [NXMLogger info:@"got member joined event"];
            
            [self getConversationWithId:event.conversationId completion:^(NSError * _Nullable error, NXMConversation * _Nullable conversation) {
                if (error) {
                    [NXMLogger error:[NSString stringWithFormat:@"get conversation failed %@", error]];
                    return;
                }
                
                if (!conversation) {
                    [NXMLogger error:[NSString stringWithFormat:@"got empty conversation without error conversation id %@:", event.conversationId]];
                }
                
                [self.delegate addedToConversation:conversation];
            }];
            
        }
        
        return;
    }
    
    if (event.state == NXMMemberStateInvited && event.media.isEnabled) {
        if ([self.delegate respondsToSelector:@selector(incomingCall:)]) { // optimization
            
            [NXMLogger info:@"got member invited event with enable media"];
            
            [self getConversationWithId:event.conversationId completion:^(NSError * _Nullable error, NXMConversation * _Nullable conversation) {
                if (error) {
                    [NXMLogger error:[NSString stringWithFormat:@"get conversation failed %@", error]];
                    return;
                }

                if (!conversation){
                    [NXMLogger error:[NSString stringWithFormat:@"got empty conversation without error conversation id %@:", event.conversationId]];
                }
                
                NXMCall * call = [[NXMCall alloc] initWithConversation:conversation];
                [self.delegate incomingCall:call];
            }];
            
        }
    }
}

#pragma mark - private

- (void)executeBlockWithError:(nullable NSError *)error completion:(void(^_Nullable)(NSError * _Nullable error))completion {
    if (completion) {
        completion(error);
    }
}

- (BOOL)setUpWithErrorPtr:(NSError **)errorPtr {
    //TODO: set up, set error and return false if problematic
    return YES;
}

- (BOOL)cleanUpWithErrorPtr:(NSError **)errorPtr {
    //TODO: clean up, set error and return false if problematic
    return YES;
}

@end