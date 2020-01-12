//
//  NXMErrorParser.m
//  NexmoConversationObjC
//
//  Created by user on 22/03/2018.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMErrorParser.h"

static NSDictionary<NSString *,NSNumber *> *csErrorToNXMCode;

@interface NXMErrorParser()
@end
@implementation NXMErrorParser

+(void)initialize {
    csErrorToNXMCode = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                        [NSNumber numberWithInteger:NXMErrorCodeMemberNotFound],@"member:error:not-found",
                        [NSNumber numberWithInteger:NXMErrorCodeMemberAlreadyRemoved],@"conversation:error:invalid-member-state",
                        [NSNumber numberWithInteger:NXMErrorCodeEventUserNotFound],@"user:error:not-found",
                        [NSNumber numberWithInteger:NXMErrorCodeEventUserAlreadyJoined],@"conversation:error:member-already-joined",
                        [NSNumber numberWithInteger:NXMErrorCodeTokenInvalid],@"system:error:invalid-token",
                        [NSNumber numberWithInteger:NXMErrorCodeTokenExpired],@"system:error:expired-token",
                        [NSNumber numberWithInteger:NXMErrorCodeEventNotFound],@"event:error:not-found",
                        [NSNumber numberWithInteger:NXMErrorCodeConversationNotFound],@"conversation:error:not-found",
                        [NSNumber numberWithInteger:NXMErrorCodeInvalidMediaRequest],@"audio:error:invalid-event",
                        [NSNumber numberWithInteger:NXMErrorCodeMediaNotFound],@"media:error:not-found",
                        [NSNumber numberWithInteger:NXMErrorCodeMediaTooManyRequests],@"media:error:too-many-request",
                        [NSNumber numberWithInteger:NXMErrorCodeMediaBadRequest],@"media:error:bad-request",
                        [NSNumber numberWithInteger:NXMErrorCodeMediaInternalError],@"media:error:internal",
                        [NSNumber numberWithInteger:NXMErrorCodeConversationInvalidMember],@"conversation:error:invalid-member",
                        nil];
}

+ (int) parseErrorWithData:(nonnull NSData*) data{
    NSDictionary* dataDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return [self parseError:dataDict];
}

+ (int) parseError:(nonnull NSDictionary*) data{
    
    NSString* errorCodeMsg = data[@"code"];
    return csErrorToNXMCode[errorCodeMsg] ? (int)csErrorToNXMCode[errorCodeMsg].integerValue : (int)NXMErrorCodeUnknown;
}

@end
