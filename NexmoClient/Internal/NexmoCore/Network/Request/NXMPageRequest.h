//
//  NXMPageRequest.h
//  NexmoClient
//
//  Created by Assaf Passal on 7/2/19.
//  Copyright © 2019 Vonage. All rights reserved.
//

#ifndef NXMPageRequest_h
#define NXMPageRequest_h
#import "NXMBaseRequest.h"

@interface NXMPageRequest : NXMBaseRequest

@property (nonatomic ) unsigned int pageSize;
@property (nonatomic, strong, nonnull) NSURL *url;
@property (nonatomic, strong, nonnull) NSString *cursor;
@property (nonatomic, strong, nonnull) NSString *order;
 
- (nullable instancetype)initWithPageSize:(unsigned int) pageSize withUrl:(nonnull NSURL *)url withCursor:(nullable NSString*)cursor withOrder:(nullable NSString *)order;
- (nullable instancetype)initWithUrl:(nonnull NSURL *)url withCursor:(nullable NSString*)cursor withOrder:(nullable NSString *)order;

@end

#endif /* NXMPageRequest_h */
