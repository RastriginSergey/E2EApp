//
//  NXMErrorsPrivate.h
//  NexmoClient
//
//  Copyright © 2019 Vonage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NXMErrors.h"

@interface NXMErrors : NSObject
+ (NSError *)nxmErrorWithErrorCode:(NXMErrorCode)errorCode andUserInfo:(NSDictionary<NSErrorUserInfoKey,id> *)userInfo;
+ (NSError *)nxmErrorWithErrorCode:(NXMErrorCode)errorCode;
@end

