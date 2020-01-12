//
//  VPSocketLogger.m
//  VPSocketIO
//
//  Created by Vasily Popov on 9/26/17.
//  Copyright © 2017 Vasily Popov. All rights reserved.
//

#import "VPSocketLogger.h"
#import "NXMLoggerInternal.h"

@implementation VPSocketLogger

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.log = NO;
    }
    return self;
}

-(void) log:(NSString*)message type:(NSString*)type
{
    if(_log) {
      NXM_LOG_VERBOSE([message UTF8String]);
    }
}

-(void) error:(NSString*)message type:(NSString*)type
{
    if(_log) {
        NXM_LOG_VERBOSE([message UTF8String]);
    }
}

-(void)dealloc {
    
}

@end
