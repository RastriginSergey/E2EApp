//
//  NXMMediaEvent.m
//  NexmoConversationObjC
//
//  Created by Chen Lev on 4/30/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMMediaEvent.h"
#import "NXMEventInternal.h"
#import "NXMMediaSettingsInternal.h"

@interface NXMMediaEvent()
@property (nonatomic, readwrite) bool isEnabled;
@property (nonatomic, readwrite) bool isSuspended;

@end
@implementation NXMMediaEvent

- (instancetype)initWithData:(NSDictionary *)data
                 isSuspended:(BOOL)isSuspended
                 isEnabled:(BOOL)isEnabled
            conversationUuid:(NSString *)conversationUuid {
    if (self = [super initWithData:data type:NXMEventTypeMedia conversationUuid:conversationUuid]) {
        self.isEnabled = isEnabled;
        self.isSuspended = isSuspended;
    }
    
    return self;
}
- (instancetype)initWithData:(NSDictionary *)data
            conversationUuid:(NSString *)conversationUuid {
    return [self initWithData:data
                  isSuspended:[data[@"body"][@"media"][@"audio_settings"][@"muted"] boolValue]
                    isEnabled:[data[@"body"][@"media"][@"audio_settings"][@"enabled"] boolValue]
             conversationUuid:conversationUuid];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> %@ isEnabled=%i isSuspended=%i",
            NSStringFromClass([self class]),
            self,
            super.description,
            self.isEnabled,
            self.isSuspended];
}
@end
