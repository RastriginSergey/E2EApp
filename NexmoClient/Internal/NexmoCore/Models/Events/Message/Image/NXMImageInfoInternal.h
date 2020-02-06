//
//  NXMImageInfoInternal.h
//  NXMiOSSDK
//
//  Created by Chen Lev on 9/5/19.
//  Copyright © 2019 Vonage. All rights reserved.
//

#import "NXMImageInfo.h"

@interface NXMImageInfo(internal)

- (nullable instancetype)initWithData:(nonnull NSDictionary *)data;

- (nullable instancetype)initWithId:(nonnull NSString *)imageId
                               size:(NSInteger)size
                                url:(nonnull NSURL *)url
                               type:(NXMImageSize)type;

@end
