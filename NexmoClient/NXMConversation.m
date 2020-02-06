//
//  NXMConversation.m
//  NexmoClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMConversationPrivate.h"
#import "NXMStitchContext.h"
#import "NXMConversationMembersController.h"
#import "NXMConversationEventsQueue.h"
#import "NXMBlocksHelper.h"
#import "NXMErrorsPrivate.h"
#import "NXMConversationMembersController.h"
#import "NXMLoggerInternal.h"
#import "NXMEventInternal.h"
#import "NXMMemberEventPrivate.h"


static NSUInteger EVENTS_PAGE_DEFAULT_SIZE = 10;
static NXMPageOrder EVENTS_PAGE_DEFAULT_ORDER = NXMPageOrderAsc;

@interface NXMConversation () <NXMConversationEventsQueueDelegate,NXMConversationMembersControllerDelegate>
@property (readwrite, nonatomic) NXMStitchContext *stitchContext;

@property (readwrite, nonatomic, nonnull) NXMConversationDetails *conversationDetails;
@property (readonly, nonatomic, nullable) NXMUser *currentUser;
@property (readwrite, nonatomic, nonnull) NXMConversationEventsQueue *eventsQueue;
@property (readwrite, nonatomic, nullable) NXMConversationMembersController *conversationMembersController;

- (instancetype)initWithConversationDetails:(nonnull NXMConversationDetails *)conversationDetails andStitchContext:(nonnull NXMStitchContext *)stitchContext;
@end

@implementation NXMConversation
- (instancetype)initWithConversationDetails:(NXMConversationDetails *)conversationDetails andStitchContext:(NXMStitchContext *)stitchContext
{
    self = [super init];
    if (self) {
        self.stitchContext = stitchContext;
        self.conversationDetails = conversationDetails;
        self.eventsQueue = [[NXMConversationEventsQueue alloc] initWithConversationDetails:self.conversationDetails stitchContext:self.stitchContext delegate:self];
        self.conversationMembersController = [[NXMConversationMembersController alloc]
                                              initWithConversationDetails:self.conversationDetails
                                              andCurrentUser:self.currentUser
                                              delegate:self];
        
    }
    return self;
}

#pragma mark - Properties

- (NSString *)name {
    return self.conversationDetails.name;
}
- (NSString *)displayName {
    return self.conversationDetails.displayName;
}
- (NSString *)uuid {
    return self.conversationDetails.conversationId;
}
- (NSInteger)lastEventId {
    return self.conversationDetails.sequence_number;
}
- (NSDate *)creationDate {
    return self.conversationDetails.created;
}

- (NXMMember *)myMember {
    return self.conversationMembersController.myMember;
}

- (NSArray<NXMMember *> *)allMembers {
    return self.conversationMembersController.allMembers;
}

#pragma mark Private Properties
- (NXMUser *)currentUser {
    return self.stitchContext.currentUser;
}

#pragma mark EventQueueDelegate

- (void)handleEvent:(NXMEvent*_Nonnull)event {
    
    if(![NSThread isMainThread]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleEvent:event];
        });
        return;
    }
    
    NXM_LOG_DEBUG("%s %s", self.uuid.UTF8String, event.description.UTF8String);

    [self.conversationMembersController handleEvent:event];
    
    switch (event.type) {
        case NXMEventTypeGeneral:
            break;
        case NXMEventTypeCustom:
            if([self.delegate respondsToSelector:@selector(conversation:didReceiveCustomEvent:)]) {
                [self.delegate conversation:self didReceiveCustomEvent:(NXMCustomEvent *)event];
            }
            break;
        case NXMEventTypeText:
            if([self.delegate respondsToSelector:@selector(conversation:didReceiveTextEvent:)]) {
                [self.delegate conversation:self didReceiveTextEvent:(NXMTextEvent *)event];
            }
            break;
        case NXMEventTypeImage:
            if([self.delegate respondsToSelector:@selector(conversation:didReceiveImageEvent:)]) {
                [self.delegate conversation:self didReceiveImageEvent:(NXMImageEvent *)event];
            }
            break;
        case NXMEventTypeMessageStatus:
            if([self.delegate respondsToSelector:@selector(conversation:didReceiveMessageStatusEvent:)]) {
                [self.delegate conversation:self didReceiveMessageStatusEvent:(NXMMessageStatusEvent *)event];
            }
            break;
        case NXMEventTypeTextTyping:
            if([self.delegate respondsToSelector:@selector(conversation:didReceiveTypingEvent:)]) {
                [self.delegate conversation:self didReceiveTypingEvent:(NXMTextTypingEvent *)event];
            }
            break;
        case NXMEventTypeMedia:
            if([self.delegate respondsToSelector:@selector(conversation:didReceiveMediaEvent:)]) {
                [self.delegate conversation:self didReceiveMediaEvent:(NXMMediaEvent *)event];
            }
            break;
        case NXMEventTypeDTMF:
            if([self.delegate respondsToSelector:@selector(conversation:didReceiveDTMFEvent:)]) {
                [self.delegate conversation:self didReceiveDTMFEvent:(NXMDTMFEvent *)event];
            }
            break;
        case NXMEventTypeMember:
            if([self.delegate respondsToSelector:@selector(conversation:didReceiveMemberEvent:)]) {
                [self.delegate conversation:self didReceiveMemberEvent:(NXMMemberEvent *)event];
            }
            break;
        case NXMEventTypeLegStatus:
            if([self.delegate respondsToSelector:@selector(conversation:didReceiveLegStatusEvent:)]) {
                [self.delegate conversation:self didReceiveLegStatusEvent:(NXMLegStatusEvent *)event];
            }
        case NXMEventTypeSip:
            break;
        default:
            break;
    }
}

- (void)conversationExpired {
    NXM_LOG_DEBUG(self.uuid.UTF8String);
    [self.conversationMembersController conversationExpired];
    if([self.delegate respondsToSelector:@selector(conversationExpired)]) {
        [self.delegate conversation:self didReceive:[[NSError alloc] initWithDomain:NXMErrorDomain code:NXMErrorCodeConversationExpired userInfo:nil]];
    }
}

#pragma mark - Public Methods

#pragma mark members
- (void)join:(void (^_Nullable)(NSError * _Nullable error, NXMMember * _Nullable member))completion {
    NXM_LOG_DEBUG(self.uuid.UTF8String);
    
    [self joinMemberWithUsername:self.currentUser.name completion:^(NSError * _Nullable error, NXMMember * _Nullable member) {
        [NXMBlocksHelper runWithError:error value:member completion:completion];
    }];
}

- (void)joinMemberWithUsername:(nonnull NSString *)username
                  completion:(void (^_Nullable)(NSError * _Nullable error, NXMMember * _Nullable member))completion {
    NXM_LOG_DEBUG("%s username: %s", self.uuid.UTF8String, username.UTF8String);
    [self.stitchContext.coreClient joinToConversation:self.uuid
                                           withUsername:username
                                            onSuccess:^(NSObject * _Nullable object) {
                                                [NXMBlocksHelper runWithError:nil value:object completion:completion];
                                            }
                                              onError:^(NSError * _Nullable error) {
                                                  [NXMBlocksHelper runWithError:error value:nil completion:completion];

                                              }];
}

- (void)leave:(void (^_Nullable)(NSError * _Nullable error))completion {
    NXM_LOG_DEBUG(self.uuid.UTF8String);

    [self kickMemberWithMemberId:self.myMember.memberUuid completion:completion];
}


- (void)kickMemberWithMemberId:(nonnull NSString *)memberId completion:(void (^_Nullable)(NSError * _Nullable error))completion {
    NXM_LOG_DEBUG("%s memberId: %s", self.uuid.UTF8String, memberId.UTF8String);
    
    [self.stitchContext.coreClient deleteMember:memberId
                         fromConversationWithId:self.uuid
                                      onSuccess:^(NSString * _Nullable value) {
                                          [NXMBlocksHelper runWithError:nil completion:completion];

                                      }
                                        onError:^(NSError * _Nullable error) {
                                            [NXMBlocksHelper runWithError:error completion:completion];

                                        }];
}

- (void)sendCustomWithEvent:(nonnull NSString *)customType
                   data:(nonnull NSDictionary *)data
             completionHandler:(void (^_Nullable)(NSError * _Nullable error))completion {
    NXM_LOG_DEBUG("%s customType: %s", self.uuid.UTF8String, customType.UTF8String);
    
    NSError *validityError = [self validateMyMemberJoined];
    if (validityError) {
        [NXMBlocksHelper runWithError:validityError completion:completion];
        
        return;
    }
    
    [self.stitchContext.coreClient sendCustomEvent:customType
                                              body:data
                                    conversationId:self.uuid
                                      fromMemberId:self.myMember.memberUuid
                                         onSuccess:^(NSString * _Nullable value) {
                                             [NXMBlocksHelper runWithError:nil completion:completion];
                                         }
                                           onError:^(NSError * _Nullable error) {
                                               [NXMBlocksHelper runWithError:error completion:completion];
                                           }];
    
}

- (void)sendDTMF:(NSString *)dtmf  completion:(void (^_Nullable)(NSError * _Nullable error))completion {
    NXM_LOG_DEBUG("%s dtmf: %s", self.uuid.UTF8String, dtmf.UTF8String);
    NSError *validityError = [self validateMyMemberJoined];
    if (validityError) {
        [NXMBlocksHelper runWithError:validityError completion:completion];
        
        return;
    }
    validityError = [self validateDTMF:dtmf];
    if (validityError) {
        [NXMBlocksHelper runWithError:validityError completion:completion];
        
        return;
    }
    [self.stitchContext.coreClient sendDTMF:dtmf conversationId:self.uuid fromMemberId:self.myMember.memberUuid onSuccess:^(NSString * _Nullable value) {
        [NXMBlocksHelper runWithError:nil completion:completion];
    } onError:^(NSError * _Nullable error) {
        [NXMBlocksHelper runWithError:error completion:completion];
    }];
}

-(void)sendText:(nonnull NSString *)text completionHandler:(void (^_Nullable)(NSError * _Nullable error))completion {
    NXM_LOG_DEBUG("%s dtmf: %s", self.uuid.UTF8String, text.UTF8String);
    NSError *validityError = [self validateMyMemberJoined];
    if (validityError) {
        [NXMBlocksHelper runWithError:validityError completion:completion];

        return;
    }
    
    [self.stitchContext.coreClient sendText:text
                             conversationId:self.uuid
                               fromMemberId:self.myMember.memberUuid
                                  onSuccess:^(NSString * _Nullable value) {
                                      [NXMBlocksHelper runWithError:nil completion:completion];
                                  }
                                    onError:^(NSError * _Nullable error) {
                                        [NXMBlocksHelper runWithError:error completion:completion];
                                    }];
}


-(void)sendAttachmentWithType:(NXMAttachmentType)attachmentType name:(nonnull NSString *)name data:(nonnull NSData *)data
            completionHandler:(void (^_Nullable)(NSError * _Nullable error))completion {
    NXM_LOG_DEBUG("%s name: %s", self.uuid.UTF8String, name.UTF8String);
    NSError *validityError = [self validateMyMemberJoined];
    if (validityError) {
        [NXMBlocksHelper runWithError:validityError completion:completion];

        return;
    }
    
    if(attachmentType != NXMAttachmentTypeImage) {
        [NXMBlocksHelper runWithError:[NXMErrors nxmErrorWithErrorCode:NXMErrorCodeNotImplemented] completion:completion];

        return;
    }
    
    [self.stitchContext.coreClient sendImageWithName:name image:data conversationId:self.uuid fromMemberId:self.myMember.memberUuid onSuccess:^(NSString * _Nullable value) {
        [NXMBlocksHelper runWithError:nil completion:completion];

    } onError:^(NSError * _Nullable error) {
        [NXMBlocksHelper runWithError:error completion:completion];

    }];
}

- (void)sendMarkSeenMessage:(NSInteger)messageId
            completionHandler:(void (^_Nullable)(NSError * _Nullable error))completion{
    NXM_LOG_DEBUG("%s name: %d", self.uuid.UTF8String, messageId);
    NSError *validityError = [self validateMyMemberJoined];
    if (validityError) {
        [NXMBlocksHelper runWithError:validityError completion:completion];
        
        return;
    }
    
    [self.stitchContext.coreClient markAsSeen:messageId
                               conversationId:self.uuid
                             fromMemberWithId:self.myMember.memberUuid
                                    onSuccess:^{
                                        [NXMBlocksHelper runWithError:nil completion:completion];
                                    }
                                      onError:^(NSError * _Nullable error) {
                                          [NXMBlocksHelper runWithError:error completion:completion];
                                      }];
}

- (void)sendStartTyping:(void (^_Nullable)(NSError * _Nullable error))completion {
    NXM_LOG_DEBUG(self.uuid.UTF8String);
    NSError *validityError = [self validateMyMemberJoined];
    if (validityError) {
        [NXMBlocksHelper runWithError:validityError completion:completion];

        return;
    }
    
    [self.stitchContext.coreClient startTypingWithConversationId:self.uuid memberId:self.myMember.memberUuid];
    [NXMBlocksHelper runWithError:nil completion:completion];
}

- (void)sendStopTyping:(void (^_Nullable)(NSError * _Nullable error))completion {
    NXM_LOG_DEBUG(self.uuid.UTF8String);
    NSError *validityError = [self validateMyMemberJoined];
    if (validityError) {
        [NXMBlocksHelper runWithError:validityError completion:completion];

        return;
    }
    
    [self.stitchContext.coreClient stopTypingWithConversationId:self.uuid memberId:self.myMember.memberUuid];
    [NXMBlocksHelper runWithError:nil completion:completion];
}
#pragma mark internal

- (nonnull NSString *)joinClientRef:(void (^_Nullable)(NSError * _Nullable error, NXMMember * _Nullable member))completionHandler {
    NXM_LOG_DEBUG(self.uuid.UTF8String);
    return [self.stitchContext.coreClient joinToConversation:self.uuid
                                                withUsername:self.currentUser.name
                                                   onSuccess:^(NSObject * _Nullable object) {
                                                       [NXMBlocksHelper runWithError:nil value:object completion:completionHandler];
                                                   }
                                                     onError:^(NSError * _Nullable error) {
                                                         [NXMBlocksHelper runWithError:error value:nil completion:completionHandler];
                                                     }];
}

- (void)inviteMemberWithUsername:(nonnull NSString *)username
                      completion:(void (^_Nullable)(NSError * _Nullable error))completion {
    NXM_LOG_DEBUG("%s username: %s", self.uuid.UTF8String, username.UTF8String);

    [self.stitchContext.coreClient inviteToConversation:self.uuid
                                           withUsername:username
                                              withMedia:NO
                                              onSuccess:^(NSObject * _Nullable object) {
                                                  [NXMBlocksHelper runWithError:nil completion:completion];
                                                  
                                              } onError:^(NSError * _Nullable error) {
                                                  [NXMBlocksHelper runWithError:error completion:completion];
                                                  
                                              }];
}

- (void)inviteMemberWithUsername:(nonnull NSString *)username withMedia:(bool)withMedia
                    completion:(void (^_Nullable)(NSError * _Nullable error, NXMMember * _Nullable member))completion {
    NXM_LOG_DEBUG("%s username: %s, media: %d", self.uuid.UTF8String, username.UTF8String, withMedia);


    [self.stitchContext.coreClient inviteToConversation:self.uuid withUsername:username withMedia:withMedia
                                              onSuccess:^(NSObject * _Nullable object) {
                                                    [NXMBlocksHelper runWithError:nil value:object completion:completion];

                                                } onError:^(NSError * _Nullable error) {
                                                    [NXMBlocksHelper runWithError:error value:nil completion:completion];

                                                }];
}

- (void)inviteToConversationWithPhoneNumber:(NSString*)phoneNumber
                                 completion:(void (^_Nullable)(NSError * _Nullable error, NSString * _Nullable knockingId))completion {
    NXM_LOG_DEBUG("%s phoneNumber: %s", self.uuid.UTF8String, phoneNumber.UTF8String);
    [self.stitchContext.coreClient inviteToConversation:self.stitchContext.currentUser.name withPhoneNumber:phoneNumber
                                              onSuccess:^(NSString * _Nullable value) {
                                                  [NXMBlocksHelper runWithError:nil value:value completion:completion];
                                              } onError:^(NSError * _Nullable error) {
                                                    [NXMBlocksHelper runWithError:error value:nil completion:completion];
                                                }];
}

- (void)enableMedia {
    NXM_LOG_DEBUG(self.uuid.UTF8String);
    [self.stitchContext.coreClient enableMedia:self.uuid memberId:self.myMember.memberUuid];
}

- (void)disableMedia {
    NXM_LOG_DEBUG([self.uuid UTF8String]);

    [self.stitchContext.coreClient disableMedia:self.uuid];
}

- (void)hold:(BOOL)isHold {
    
}

- (void)mute:(BOOL)isMuted {
    NXM_LOG_DEBUG("%s muted:%d", self.uuid.UTF8String, isMuted);
    if (isMuted) {
        [self.stitchContext.coreClient suspendMyMedia:NXMMediaTypeAudio inConversation:self.uuid];
        return;
    }
    
    [self.stitchContext.coreClient resumeMyMedia:NXMMediaTypeAudio inConversation:self.uuid];
}

- (void)earmuff:(BOOL)isEarmuff {
    
}

#pragma mark - Get events page

- (void)getEventsPage:(void (^)(NSError * _Nullable, NXMEventsPage * _Nullable))completionHandler {
    [self getEventsPageWithSize:EVENTS_PAGE_DEFAULT_SIZE
                          order:EVENTS_PAGE_DEFAULT_ORDER
                      eventType:nil
              completionHandler:completionHandler];
}

- (void)getEventsPageWithSize:(NSUInteger)size
                        order:(NXMPageOrder)order
            completionHandler:(void (^)(NSError * _Nullable, NXMEventsPage * _Nullable))completionHandler {
    [self getEventsPageWithSize:size order:order eventType:nil completionHandler:completionHandler];
}

- (void)getEventsPageWithSize:(NSUInteger)size
                        order:(NXMPageOrder)order
                    eventType:(NSString *)eventType
            completionHandler:(void (^)(NSError * _Nullable, NXMEventsPage * _Nullable))completionHandler {
    NXM_LOG_DEBUG([NSString stringWithFormat:@"conversationUuid: %@, size = %lu, order = %@, eventType = %@, completionHandler %@",
                   self.uuid,
                   (unsigned long)size,
                   order == NXMPageOrderAsc ? @"ASC" : @"DESC",
                   eventType,
                   completionHandler ? @"not nil" : @"nil"].UTF8String);

    if (!completionHandler) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self.stitchContext.coreClient getEventsPageWithSize:size
                                                   order:order
                                          conversationId:self.conversationDetails.conversationId
                                               eventType:eventType
                                       completionHandler:^(NSError * _Nullable error, NXMEventsPage * _Nullable page) {
                                           if (error) {
                                               NXM_LOG_ERROR([NSString stringWithFormat:@"conversationUuid: %@, NXMEventsPage failed: %@",
                                                              self.uuid, error.description].UTF8String);
                                               completionHandler(error, nil);
                                               return;
                                           }

                                           if (!page) {
                                               NXM_LOG_ERROR([NSString stringWithFormat:@"conversationUuid: %@, Empty NXMEventsPage received", self.uuid].UTF8String);
                                               completionHandler([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeUnknown], nil);
                                               return;
                                           }

                                           [weakSelf updateMembersForPage:page];
                                           completionHandler(nil, page);
                                       }];
}

- (void)updateMembersForPage:(nonnull NXMEventsPage *)page {
    for (NXMEvent *event in page.events) {
        NXMMember *member = [self.conversationMembersController memberForMemberId:event.fromMemberId];
        [event updateFromMember:member];
        if (event.type == NXMEventTypeMember) {
            NXMMemberEvent *memberEvent = (NXMMemberEvent *)event;
            [memberEvent updateMember:[self.conversationMembersController memberForMemberId:memberEvent.memberId]];
        }
    }
}

#pragma mark - Private Methods

- (void)finishHandleEventsSequence {
//    [self.conversationMembersController finishHandleEventsSequence];
}

- (NSError *)validateMyMemberJoined {
    if (self.myMember.state == NXMMemberStateJoined) {
        return nil;
    }
    
    return [NXMErrors nxmErrorWithErrorCode:NXMErrorCodeNotAMemberOfTheConversation];
}

- (NSError *)validateDTMF:dtmf {
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[\\da-dA-D#*pP]{1,45}$$"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:dtmf
                                                        options:0
                                                          range:NSMakeRange(0, [dtmf length])];
    if (numberOfMatches > 0){
        return nil;
    }
    return [NXMErrors nxmErrorWithErrorCode:NXMErrorCodeDTMFIllegal];
}

#pragma member controller delegate

- (void)nxmConversationMembersController:(NXMConversationMembersController * _Nonnull)controller didChangeMember:(nonnull NXMMember *)member forChangeType:(NXMMemberUpdateType)type {
    if([self.updatesDelegate respondsToSelector:@selector(conversation:didUpdateMember:withType:)]) {
        [self.updatesDelegate conversation:self didUpdateMember:member withType:type];
    }
}

#pragma description
- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> convId=%@ name=%@ displayName=%@ lastEventId=%ld creationDate=%@ myMember=%@ otherMembers=%@",
            NSStringFromClass([self class]),
            self,
            self.uuid,
            self.name,
            self.displayName,
            (long)self.lastEventId,
            self.creationDate,
            self.myMember,
            self.allMembers];
}

@end
