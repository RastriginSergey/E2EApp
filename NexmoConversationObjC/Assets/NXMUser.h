//
//  User.h
//  NexmoConversationObjC
//
//  Created by Chen Lev on 2/26/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NXMUser : NSObject

@property NSString * _Nonnull uuid;
@property NSString * _Nonnull name;

- (instancetype _Nullable)initWithId:(NSString * _Nonnull)uuid name:(NSString * _Nonnull)name;

@end
//@interface NXMUser : NSObject
//
//@property NSString *uuid;
//@property NSString *name;
//
//- (instancetype)initWithId:(NSString *)uuid name:(NSString *)name;
//
//@end

