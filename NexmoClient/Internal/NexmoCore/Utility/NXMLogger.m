//
//  NXMLogger.m
//  NexmoClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMLoggerInternal.h"


@interface NXMLogger()

@property NXMLogger *sharedInstance;

@end

@implementation NXMLogger

+ (void)setLogLevel:(NXMLoggerLevel)logLevel {
    nexmoLogLevel_t level = NEXMO_LOG_LEVEL_NONE;
    
    switch (logLevel) {
        case NXMLoggerLevelNone:
            level = NEXMO_LOG_LEVEL_NONE;
            break;
        case NXMLoggerLevelError:
            level = NEXMO_LOG_LEVEL_ERROR;
            break;
        case NXMLoggerLevelDebug:
            level = NEXMO_LOG_LEVEL_DEBUG;
            break;
        case NXMLoggerLevelInfo:
            level = NEXMO_LOG_LEVEL_INFO;
            break;
        case NXMLoggerLevelVerbose:
            level = NEXMO_LOG_LEVEL_VERBOSE;
            break;
        default:
            break;
    }
    
    [NXMLog setLogLevel:level];
}

+ (nonnull NSMutableArray *)getLogFileNames {
    return [NXMLog getLogFilesPathes];
}

@end

