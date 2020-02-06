//
//  NXMDeleteEvent.m
//  NexmoConversationObjC
//
//  Created by user on 08/04/2018.
//  Copyright © 2018 Vonage. All rights reserved.
//
#import "NXMMessageStatusEvent.h"
#import "NXMEventInternal.h"


@interface NXMMessageStatusEvent()
@property (nonatomic, readwrite) NSInteger referenceEventUuid;
@property (nonatomic, readwrite) NXMMessageStatusType status;
@end
@implementation NXMMessageStatusEvent

- (instancetype)initWithData:(NSDictionary *)data status:(NXMMessageStatusType)status {
    return [self initWithData:data status:status conversationUuid:data[@"cid"]];
}

- (instancetype)initWithData:(NSDictionary *)data
                      status:(NXMMessageStatusType)status
            conversationUuid:(NSString *)conversationUuid {
    if (self = [super initWithData:data type:NXMEventTypeMessageStatus conversationUuid:data[@"cid"]]) {
        self.status = status;
        self.referenceEventUuid = [data[@"id"] integerValue];
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> %@ referenceEventUuid=%ld status=%@",
            NSStringFromClass([self class]),
            self,
            super.description,
            (long)self.referenceEventUuid,
            self.status == NXMMessageStatusTypeSeen ? @"seen" : self.status == NXMMessageStatusTypeDelivered ? @"delivered" : @"deleted"];
}

@end
