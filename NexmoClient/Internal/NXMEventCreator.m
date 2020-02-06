//
//  NXMEventCreator.m
//  NexmoClient
//
//  Created by Chen Lev on 1/27/20.
//  Copyright © 2020 Vonage. All rights reserved.
//

#import "NXMEventCreator.h"
#import "NXMCoreEventsPrivate.h"
#import "NXMClientDefine.h"


@implementation NXMEventCreator


+ (NXMEvent *)createEvent:(NSString *)eventname data:(NSDictionary *)data {
    return [NXMEventCreator createEvent:eventname data:data conversationUuid:data[@"cid"]];
}

+ (NXMEvent *)createEvent:(NSString *)eventname data:(NSDictionary *)data conversationUuid:(NSString *)conversationUuid {
    if ([eventname isEqualToString: kNXMSocketEventMemberJoined]) {
        return [NXMEventCreator parseMemberEvent:NXMMemberStateJoined dict:data conversationId:conversationUuid];
    }
                
    if ([eventname isEqualToString: kNXMSocketEventMemberInvited]) {
        return [NXMEventCreator parseMemberEvent:NXMMemberStateInvited dict:data conversationId:conversationUuid];
    }
         
    if ([eventname isEqualToString: kNXMSocketEventMemberLeft]) {
        return [NXMEventCreator parseMemberEvent:NXMMemberStateLeft dict:data conversationId:conversationUuid];
    }
         
    if ([eventname isEqualToString: kNXMSocketEventMemebrMedia]) {
        return [NXMEventCreator parseMediaEvent:data conversationId:conversationUuid];
    }
         
    if ([eventname isEqualToString: kNXMEventCustom]) {
        NSString *customType = [eventname substringFromIndex:[kNXMEventCustom length] + 1];
        return [NXMEventCreator parseCustomEvent:customType
                                            dict:data
                                  conversationId:conversationUuid];
    }
         
    if ([eventname isEqualToString: kNXMSocketEventAudioMuteOn]) {
                return [NXMEventCreator parseAudioMuteOnEvent:data conversationId:conversationUuid];
    }
         
    if ([eventname isEqualToString: kNXMSocketEventAudioMuteOff]) {
                return [NXMEventCreator parseAudioMuteOffEvent:data conversationId:conversationUuid];
    }
         
    if ([eventname isEqualToString: kNXMSocketEventTextSeen]) {
        return [NXMEventCreator parseMessageStatusEvent:data conversationId:conversationUuid state:NXMMessageStatusTypeSeen];
    }
         
    if ([eventname isEqualToString: kNXMSocketEventTextDelivered]) {
        return [NXMEventCreator parseMessageStatusEvent:data conversationId:conversationUuid
                                       state:NXMMessageStatusTypeDelivered];
    }
         
    if ([eventname isEqualToString: kNXMSocketEventText]) {
        return [NXMEventCreator parseTextEvent:data conversationId:conversationUuid];
    }
         
    if ([eventname isEqualToString: kNXMSocketEventImage]) {
        return [NXMEventCreator parseImageEvent:data conversationId:conversationUuid];
    }
         
    if ([eventname isEqualToString: kNXMSocketEventImageSeen]) {
        return [NXMEventCreator parseMessageStatusEvent:data conversationId:conversationUuid state:NXMMessageStatusTypeSeen];
    }
         
    if ([eventname isEqualToString: kNXMSocketEventImageDelivered]) {
        return [NXMEventCreator parseMessageStatusEvent:data conversationId:conversationUuid state:NXMMessageStatusTypeDelivered];
    }
         
    if ([eventname isEqualToString: kNXMSocketEventMessageDelete]) {
        return [NXMEventCreator parseMessageStatusEvent:data conversationId:conversationUuid state:NXMMessageStatusTypeDeleted];
    }
         
    if ([eventname isEqualToString: kNXMSocketEventSipRinging]) {
        return [NXMEventCreator parseSipEvent:data conversationId:conversationUuid state:NXMSipEventRinging];
    }
         
    if ([eventname isEqualToString: kNXMSocketEventSipAnswered]) {
        return [NXMEventCreator parseSipEvent:data conversationId:conversationUuid state:NXMSipEventAnswered];
    }
         
    if ([eventname isEqualToString: kNXMSocketEventSipHangup]) {
        return [NXMEventCreator parseSipEvent:data conversationId:conversationUuid state:NXMSipEventHangup];
    }
         
    if ([eventname isEqualToString: kNXMSocketEventSipStatus]) {
        return [NXMEventCreator parseSipEvent:data conversationId:conversationUuid state:NXMSipEventStatus];
    }
         
    if ([eventname isEqualToString: kNXMSocketEventLegStatus]) {
        return [[NXMLegStatusEvent alloc] initWithConversationId:conversationUuid
                                                         andData:data];
    }
    
    if ([eventname isEqualToString:kNXMSocketEventAudioDtmf]) {
        return [[NXMDTMFEvent alloc] initWithData:data conversationUuid:conversationUuid];
    }
    
    if ([eventname isEqualToString:kNXMSocketEventTypingOn]) {
        return [[NXMTextTypingEvent alloc] initWithData:data status:NXMTextTypingEventStatusOn conversationUuid:conversationUuid];

    }
    
    if ([eventname isEqualToString:kNXMSocketEventTypingOff]) {
        return [[NXMTextTypingEvent alloc] initWithData:data status:NXMTextTypingEventStatusOff conversationUuid:conversationUuid];
        
    }


    return nil;
}


+ (NXMMemberEvent* )parseMemberEvent:(NXMMemberState)state dict:(nonnull NSDictionary*)dict conversationId:(nonnull NSString*)conversationId{
    NXMMemberEvent *memberEvent = [[NXMMemberEvent alloc] initWithData:dict state:state conversationUuid:conversationId];
    
    return memberEvent;
}

+ (NXMMediaEvent* )parseMediaEvent:(nonnull NSDictionary*)dict conversationId:(nonnull NSString*)conversationId{
    NXMMediaEvent* event = [[NXMMediaEvent alloc] initWithData:dict conversationUuid:conversationId];
    
    return event;
}
+ (NXMCustomEvent *)parseCustomEvent:(NSString *)customType
                                dict:(nonnull NSDictionary*)dict
                      conversationId:(nonnull NSString*)conversationId {
    
    return [[NXMCustomEvent alloc] initWithCustomType:customType conversationId:conversationId andData:dict];
}
+ (NXMMediaEvent *)parseAudioMuteOnEvent:(nonnull NSDictionary*)dict conversationId:(nonnull NSString*)conversationId{
    NXMMediaEvent *event = [[NXMMediaEvent alloc] initWithData:dict isSuspended:YES isEnabled:YES conversationUuid:conversationId];
    return event;
}

+ (NXMMediaEvent *)parseAudioMuteOffEvent:(nonnull NSDictionary*)dict conversationId:(nonnull NSString*)conversationId{
    NXMMediaEvent *event = [[NXMMediaEvent alloc] initWithData:dict isSuspended:NO isEnabled:YES conversationUuid:conversationId];
    return event;
}

+ (NXMSipEvent* )parseSipEvent:(nonnull NSDictionary*)dict conversationId:(nonnull NSString*)conversationId state:(NXMSipStatus )state{
    NXMSipEvent * event = [[NXMSipEvent alloc] initWithData:dict sipStatus:state conversationUuid:conversationId];
    return event;
}

+ (NXMMessageStatusEvent* )parseMessageStatusEvent:(nonnull NSDictionary*)dict conversationId:(nonnull NSString*)conversationId state:(NXMMessageStatusType )state{
    NXMMessageStatusEvent * event = [[NXMMessageStatusEvent alloc] initWithData:dict status:state conversationUuid:conversationId];
    return event;
}

+ (NXMTextEvent *)parseTextEvent:(nonnull NSDictionary*)dict conversationId:(nonnull NSString*)conversationId {
    NXMTextEvent* event = [[NXMTextEvent alloc] initWithData:dict conversationUuid:conversationId];
    return event;
}

+ (NXMImageEvent *)parseImageEvent:(nonnull NSDictionary*)json conversationId:(nonnull NSString*)conversationId {
    NXMImageEvent *imageEvent = [[NXMImageEvent alloc] initWithData:json conversationUuid:conversationId];
    return imageEvent;
}

+ (nonnull NXMEvent *)parseUnknownEvent:(nonnull NSDictionary *)json conversationId:(nonnull NSString *)conversationId {
    return [[NXMEvent alloc] initWithData:json type:NXMEventTypeUnknown];
}

@end
