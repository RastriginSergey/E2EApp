//
//  NXMEventsDispatcherLoginStatusModel.h
//  NexmoClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NexmoCore/NexmoCore.h>

@interface NXMEventsDispatcherLoginStatusModel : NSObject
@property (nonatomic, nullable) NXMUser *user;
@property (nonatomic) BOOL isLoggedIn;
@property (nonatomic, nullable) NSError *error;
-(instancetype)initWithNXMuser:(NXMUser *)user isLoggedIn:(BOOL)isLoggedIn andError:(NSError *)error;
@end
