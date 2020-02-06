//
//  NXMEventCreator.h
//  NexmoClient
//
//  Created by Chen Lev on 1/27/20.
//  Copyright © 2020 Vonage. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NXMEvent;

@interface NXMEventCreator : NSObject

+ (NXMEvent *)createEvent:(NSString *)eventname data:(NSDictionary *)data;
+ (NXMEvent *)createEvent:(NSString *)eventname data:(NSDictionary *)data conversationUuid:(NSString *)conversationUuid;

@end

