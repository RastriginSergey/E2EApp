//
//  NXMHelper.m
//  NexmoClient
//
//  Created by Nicola Di Pol on 02/01/2020.
//  Copyright © 2020 Vonage. All rights reserved.
//

#import "NXMHelper.h"

@implementation NXMHelper

+ (NSString *)descriptionForEventType:(NXMEventType)eventType {
    NSString *result = @(eventType).stringValue;
    switch (eventType) {
        case NXMEventTypeGeneral:
            result = @"General";
            break;
        case NXMEventTypeCustom:
            result = @"Custom";
            break;
        case NXMEventTypeText:
            result = @"Text";
            break;
        case NXMEventTypeImage:
            result = @"Image";
            break;
        case NXMEventTypeMessageStatus:
            result = @"Message status";
            break;
        case NXMEventTypeTextTyping:
            result = @"Text typing";
            break;
        case NXMEventTypeMedia:
            result = @"Media";
            break;
        case NXMEventTypeMember:
            result = @"Member";
            break;
        case NXMEventTypeSip:
            result = @"SIP";
            break;
        case NXMEventTypeDTMF:
            result = @"DTMF";
            break;
        case NXMEventTypeLegStatus:
            result = @"Leg status";
            break;
        case NXMEventTypeUnknown:
            result = @"Unknown";
            break;
    }
    return result;
}

@end
