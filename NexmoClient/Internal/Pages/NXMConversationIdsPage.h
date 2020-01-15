//
//  NXMConversationIdsPage.h
//  NexmoClient
//
//  Created by Nicola Di Pol on 12/11/2019.
//  Copyright © 2019 Vonage. All rights reserved.
//

#import "NXMConversation.h"
@class NXMPageResponse;

@interface NXMConversationIdsPage : NSObject

@property (nonatomic, assign) NSUInteger size;
@property (nonatomic, assign) NXMPageOrder order;
@property (nonatomic) NXMPageResponse *pageResponse;
@property (nonatomic) NSArray<NSString *> *conversationIds;

- (instancetype)initWithPageResponse:(NXMPageResponse *)pageResponse
                               order:(NXMPageOrder)order;

@end
