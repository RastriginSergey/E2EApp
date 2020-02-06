//
//  NXMImageInfo.m
//  NexmoClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMImageInfo.h"

@interface NXMImageInfo()
@property (nonatomic, readwrite, nonnull) NSString *imageUuid;
@property (nonatomic, readwrite, nonnull) NSURL *url;
@property (readwrite) NSInteger sizeInBytes;
@property (readwrite) NXMImageSize size;

@end

@implementation NXMImageInfo

- (instancetype)initWithData:(NSDictionary *)data size:(NXMImageSize)size {
    
    if (self = [super init]) {
        self.imageUuid = data[@"id"];
        self.sizeInBytes = [data[@"size"] integerValue];
        self.url = [[NSURL alloc] initWithString:data[@"url"]];
        self.size = size;
    }
    
    return self;
}
@end
