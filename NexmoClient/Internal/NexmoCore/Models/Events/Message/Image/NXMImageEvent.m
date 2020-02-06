//
//  NXMImageEvent.m
//  NexmoClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMImageEvent.h"
#import "NXMCoreEventsPrivate.h"

@interface NXMImageEvent()
@property (nonatomic, readwrite, nonnull) NSString *imageUuid;
@property (nonatomic, readwrite, nonnull) NXMImageInfo *mediumImage;
@property (nonatomic, readwrite, nonnull) NXMImageInfo *originalImage;
@property (nonatomic, readwrite, nonnull) NXMImageInfo *thumbnailImage;
@end

@implementation NXMImageEvent

- (instancetype)initWithData:(NSDictionary *)data {
    return [self initWithData:data conversationUuid:data[@"cid"]];
}

- (instancetype)initWithData:(NSDictionary *)data
            conversationUuid:(NSString *)conversationUuid {
    if (self = [super initWithData:data type:NXMEventTypeImage conversationUuid:conversationUuid]) {
        self.imageUuid = data[@"id"];
        
        NSDictionary * representations = data[@"body"][@"representations"];
        self.originalImage = [[NXMImageInfo alloc] initWithData:representations[@"original"] size:NXMImageSizeOriginal];
        self.mediumImage = [[NXMImageInfo alloc] initWithData:representations[@"medium"] size:NXMImageSizeMedium];
        self.thumbnailImage = [[NXMImageInfo alloc] initWithData:representations[@"thumbnail"] size:NXMImageSizeOriginal];
    }
    
    return self;
}

@end
