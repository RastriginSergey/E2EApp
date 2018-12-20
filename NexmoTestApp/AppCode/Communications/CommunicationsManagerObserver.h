//
//  NexmoClientStatusObserver.h
//  NexmoTestApp
//
//  Created by Doron Biaz on 12/10/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommunicationsManagerDefine.h"

NS_ASSUME_NONNULL_BEGIN
@protocol CommunicationsManagerObserver
@optional
- (void)connectionStatusChanged:(CommunicationsManagerConnectionStatus)connectionStatus withReason:(CommunicationsManagerConnectionStatusReason)reason;
- (void)incomingCall:(NXMCall *)call;
@end

NS_ASSUME_NONNULL_END
