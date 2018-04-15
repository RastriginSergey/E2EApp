//
//  NXMLoggerDelegate.h
//  NexmoConversationObjC
//
//  Created by Chen Lev on 4/15/18.
//  Copyright © 2018 Vonage. All rights reserved.
//


@protocol NXMLoggerDelegate

- (void)error:(nullable NSString *)message;
- (void)warning:(nullable NSString *)message;
- (void)info:(nullable NSString *)message;
- (void)debug:(nullable NSString *)message;

@end
