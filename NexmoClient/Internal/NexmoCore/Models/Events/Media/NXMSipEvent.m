//
//  NXMSipEvent.m
//  StitchObjC
//
//  Created by user on 19/06/2018.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMSipEvent.h"
#import "NXMEventInternal.h"

@interface NXMSipEvent()
@property (nonatomic, readwrite) NXMSipStatus status;
@end

@implementation NXMSipEvent

- (instancetype)initWithData:(NSDictionary *)data sipStatus:(NXMSipStatus)sipStatus {
    return [self initWithData:data sipStatus:sipStatus conversationUuid:data[@"cid"]];
}

- (instancetype)initWithData:(NSDictionary *)data
                   sipStatus:(NXMSipStatus)sipStatus
            conversationUuid:(NSString *)conversationUuid {
    if ([self initWithData:data type:NXMEventTypeSip conversationUuid:conversationUuid]) {
        self.status = sipStatus;
        self.phoneNumber = data[@"body"][@"channel"][@"to"][@"number"];
        self.applicationId = data[@"application_id"];
    }
    
    return self;
}
@end
