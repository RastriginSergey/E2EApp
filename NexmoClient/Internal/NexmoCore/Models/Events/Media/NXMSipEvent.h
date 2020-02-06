//
//  NXMSipEvent.h
//  NexmoClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMEvent.h"

@interface NXMSipEvent : NXMEvent
@property (nonatomic, copy, nonnull) NSString *phoneNumber;
@property (nonatomic, copy, nonnull) NSString *applicationId;
@property (nonatomic, readonly) NXMSipStatus status;
@end
