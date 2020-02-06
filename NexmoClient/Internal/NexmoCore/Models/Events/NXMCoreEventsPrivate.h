//
//  NXMCoreEventsPrivate.h
//  NexmoClient
//
//  Copyright © 2019 Vonage. All rights reserved.
//

#import "NXMCoreEvents.h"
#import "NXMMemberEventPrivate.h"
#import "NXMLegStatusEventPrivate.h"
#import "NXMCustomEventInternal.h"
#import "NXMEventInternal.h"
#import "NXMSipEvent.h"

@interface NXMDTMFEvent (NXMDTMFEventPrivate)

- (instancetype)initWithData:(NSDictionary *)data
            conversationUuid:(NSString *)conversationUuid;
@end


@interface NXMTextEvent (NXMTextEventPrivate)


- (instancetype)initWithData:(NSDictionary *)data
            conversationUuid:(NSString *)conversationUuid;

- (instancetype)initWithConversationId:( NSString *)conversationId
                                     sequenceId:(NSInteger)sequenceId
                                   fromMemberId:( NSString *)fromMemberId
                                   creationDate:( NSDate *)creationDate
                                           type:(NXMEventType)type
                                           text:( NSString *)text;

@end


@interface NXMMessageStatusEvent (NXMMessageStatusEventPrivate)


- (instancetype)initWithData:(NSDictionary *)data
                      status:(NXMMessageStatusType)status
            conversationUuid:(NSString *)conversationUuid;

@end


@interface NXMTextTypingEvent (NXMTextTypingEventPrivate)

- (instancetype)initWithData:(NSDictionary *)data
                      status:(NXMTextTypingEventStatus)status
            conversationUuid:(NSString *)conversationUuid;


@end


@interface NXMSipEvent (NXMSipEventPrivate)

- (instancetype)initWithData:(NSDictionary *)data
                   sipStatus:(NXMSipStatus)sipStatus
            conversationUuid:(NSString *)conversationUuid;

@end

@interface NXMMediaEvent (NXMMediaEventPrivate)
- (instancetype)initWithData:(NSDictionary *)data
            conversationUuid:(NSString *)conversationUuid;

- (instancetype)initWithData:(NSDictionary *)data
                 isSuspended:(BOOL)isSuspended
                   isEnabled:(BOOL)isEnabled
            conversationUuid:(NSString *)conversationUuid;

@end

@interface NXMMessageEvent(NXMImageEventPrivate)
- (instancetype)initWithData:(NSDictionary *)data
                        type:(NXMEventType)type
            conversationUuid:(NSString *)conversationUuid;

@end

@interface NXMImageEvent(NXMImageEventPrivate)
- (instancetype)initWithData:(NSDictionary *)data
            conversationUuid:(NSString *)conversationUuid;

@end

@interface NXMImageInfo(NXMImageInfoPrivate)
- (instancetype)initWithData:(NSDictionary *)data size:(NXMImageSize)size;
@end
