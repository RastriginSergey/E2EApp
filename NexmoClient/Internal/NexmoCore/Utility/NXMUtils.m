//
//  NXMUtils.m
//  NexmoClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMUtils.h"
#import <sys/utsname.h>


//@interface NXMUtils ()

//@property NSISO8601DateFormatter* dateFormatter;

//@end

@implementation NXMUtils : NSObject
static NSMutableDictionary<NSString*, NSNumber*>* statusMap = nil;
static NSMutableDictionary<NSString*, NSNumber*>* typeMap = nil;

static NSString * const NexmoDeviceUuidKey = @"NexmoClientDeviceUuid";

+ (NSDate *)dateFromISOString:(NSString *)isoString {
    NSDateFormatter *isoDateFomatter = [[NSDateFormatter alloc] init];
    isoDateFomatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
    return [isoDateFomatter dateFromString:isoString];
}

+ (NSString *)nexmoDeviceId {
    NSString *deviceUuid = @"";
    @synchronized([self class]) {
        deviceUuid = [[NSUserDefaults standardUserDefaults] stringForKey:NexmoDeviceUuidKey];
        if ([deviceUuid length] > 0) {
            return deviceUuid;
        }
        
        deviceUuid = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:deviceUuid forKey:NexmoDeviceUuidKey];
    }
    
    return deviceUuid;
}

+ (NSString *)deviceMachineName {
    struct utsname systemInfo;
    uname(&systemInfo);
        
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}


@end
