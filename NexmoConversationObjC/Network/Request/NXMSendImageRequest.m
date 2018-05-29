//
//  NXMSendImageRequest.m
//  NexmoConversationObjC
//
//  Created by Chen Lev on 5/29/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMSendImageRequest.h"

@implementation NXMSendImageRequest

- (instancetype)initWithImage:(NSData *)image conversationId:(NSString *)conversationId memberId:(NSString *)memberId {
    if (self = [super init]){
        self.image = image;
        self.conversationId = conversationId;
        self.memberId = memberId;
    }
    
    return self;
}
@end
