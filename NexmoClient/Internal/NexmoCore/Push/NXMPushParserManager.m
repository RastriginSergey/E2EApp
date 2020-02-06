//
//  NXMPushParser.m
//  StitchObjC
//
//  Created by Doron Biaz on 11/1/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMPushParserManager.h"
#import "NXMEventCreator.h"


static const NSString *stitchPushIdentifier = @"nexmo";

@implementation NXMPushParserManager

+ (BOOL)isNexmoPushWithUserInfo:(nonnull NSDictionary *)userInfo {
    return userInfo[stitchPushIdentifier] ? true : false;
}

+ (nullable NSDictionary *)nexmoPushInfoWithUserInfo:(nonnull NSDictionary *)userInfo {
    return userInfo[stitchPushIdentifier];
}

+ (nullable NXMEvent *)parseEventWithUserInfo:(nonnull NSDictionary *)userInfo {
    if(![self isNexmoPushWithUserInfo:userInfo]) {
        return nil;
    }

    NSDictionary *pushPayload = [self nexmoPushInfoWithUserInfo:userInfo];
    return [NXMEventCreator createEvent:pushPayload[@"event_type"]
                                   data:pushPayload
                       conversationUuid:pushPayload[@"conversation_id"]];

}
@end
