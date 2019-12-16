//
//  NXMErrors.m
//  NexmoCore
//
//  Created by Chen Lev on 3/22/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMErrorsPrivate.h"

NSString *const NXMErrorDomain = @"com.nexmo.errorDomain";

@implementation NXMErrors
+(NSError *)nxmErrorWithErrorCode:(NXMErrorCode)errorCode andUserInfo:(nullable NSDictionary<NSErrorUserInfoKey,id> *)userInfo {
    return [NSError errorWithDomain:NXMErrorDomain code:errorCode userInfo:userInfo];
}

+(NSError *)nxmErrorWithErrorCode:(NXMErrorCode)errorCode {
    NSString *errorDescription = [NXMErrors nxmErrorCodeToString:errorCode];
    NSDictionary *userInfo = [errorDescription length] > 0 ? @{ NSLocalizedDescriptionKey : errorDescription } : nil;
    
    return [NSError errorWithDomain:NXMErrorDomain code:errorCode userInfo:userInfo];
}

+ (NSString *)nxmErrorCodeToString:(NXMErrorCode)code {
    switch (code) {
        case NXMErrorCodeNone:
            return @"No error";
        case NXMErrorCodeUnknown:
            return @"Unknown error";
        case NXMErrorCodeSessionUnknown:
            return @"Session unknown";
        case NXMErrorCodeSessionInvalid:
            return @"Session invalid";
        case NXMErrorCodeSessionDisconnected:
            return @"Session disconnected";
        case NXMErrorCodeMaxOpenedSessions:
            return @"Max opened sessions";
        case NXMErrorCodeTokenUnknown:
            return @"Token unknown";
        case NXMErrorCodeTokenInvalid:
            return @"Token invalid";
        case NXMErrorCodeTokenExpired:
            return @"Token expired";
        case NXMErrorCodeMemberUnknown:
            return @"Member unknown";
        case NXMErrorCodeMemberNotFound:
            return @"Member not found";
        case NXMErrorCodeMemberAlreadyRemoved:
            return @"Member already removed";
        case NXMErrorCodeNotAMemberOfTheConversation:
            return @"Member not part of the conversation";
        case NXMErrorCodeEventUnknown:
            return @"Event unknown";
        case NXMErrorCodeEventUserNotFound:
            return @"User not found";
        case NXMErrorCodeEventUserAlreadyJoined:
            return @"User already joind";
        case NXMErrorCodeEventNotFound:
            return @"Event invalid";
        case NXMErrorCodeEventBadPermission:
            return @"Bad permission";
        case NXMErrorCodeEventInvalid:
            return @"Event not found";
        case NXMErrorCodeConversationRetrievalFailed:
            return @"Conversation retrieval failed";
        case NXMErrorCodeConversationInvalidMember:
            return @"Conversation invalid member";
        case NXMErrorCodeConversationNotFound:
            return @"Conversation not found";
        case NXMErrorCodeConversationExpired:
            return @"Conversation expired";
        case NXMErrorCodeConversationsPageNotFound:
            return @"Conversation page not found";
            
        case NXMErrorCodeMediaNotSupported:
            return @"Media not Supported";
        case NXMErrorCodeMediaNotFound:
            return @"Media not foound";
        case NXMErrorCodeInvalidMediaRequest:
            return @"Invalid media request";
            
        case NXMErrorCodeMediaTooManyRequests:
            return @"Media too many requests";
        case NXMErrorCodeMediaBadRequest:
            return @"Media bad request";
        case NXMErrorCodeMediaInternalError:
            return @"Media internal error";
            
        case NXMErrorCodePushNotANexmoPush:
            return @"Push not a nexmo push";
        case NXMErrorCodePushParsingFailed:
            return @"Puash parsing failed";
        case NXMErrorCodeNotImplemented:
            return @"Code not implemented";
        case NXMErrorCodeMissingDelegate:
            return @"Missing delegate";
        case NXMErrorCodePayloadTooBig:
            return @"Payload too big";
        case NXMErrorCodeSDKDisconnected:
            return @"NXMClient disconnected";
        case NXMErrorCodeUserNotFound:
            return @"User not found";
        case NXMErrorCodeDTMFIllegal:
            return @"DTMF illegal";
        default:
            return @"";
    }
}
@end

