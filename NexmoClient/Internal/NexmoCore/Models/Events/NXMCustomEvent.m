//
//  NXMCustomEvent.m
//  NexmoClient
//
//  Copyright © 2019 Vonage. All rights reserved.
//

#import "NXMCoreEventsPrivate.h"
#import "NXMCustomEvent.h"
#import "NXMUtils.h"

@interface NXMCustomEvent()
@property (nonatomic, readwrite, nullable) NSString *data;
@end
@implementation NXMCustomEvent

- (instancetype)initWithCustomType:(NSString *)customType andData:(NSDictionary *)data {
    return [self initWithCustomType:customType conversationId:data[@"cid"] andData:data];
    
}

- (instancetype)initWithCustomType:(NSString *)customType
                    conversationId:(NSString *)conversationId
                           andData:(NSDictionary *)data  {
    return [self initWithConversationId:conversationId
                             sequenceId:[data[@"id"] integerValue]
                               memberId:data[@"from"]
                           creationDate:[NXMUtils dateFromISOString:data[@"timestamp"]]
                             customType:customType
                                andData:data[@"body"]];
}


- (instancetype)initWithConversationId:(NSString *)conversationId
                            sequenceId:(NSUInteger)sequenceId
                              memberId:(NSString *)memberId
                          creationDate:(NSDate *)creationDate
                            customType:(NSString *)customType
                               andData:(NSString *)data {
    if (self = [super initWithConversationId:conversationId sequenceId:sequenceId fromMemberId:memberId creationDate:creationDate type:NXMEventTypeCustom]) {
        self.customType = customType;
        self.data = data;
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> %@ customType=%@ data=%@",
            NSStringFromClass([self class]),
            self,
            super.description,
            self.customType,
            self.data];
}

@end
