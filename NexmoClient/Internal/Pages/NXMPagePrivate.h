//
//  NXMPagePrivate.h
//  NexmoClient
//
//  Created by Nicola Di Pol on 23/12/2019.
//  Copyright © 2019 Vonage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NXMPage.h"
#import "NXMPageResponse.h"

@protocol NXMPageProxy <NSObject>

- (void)getPageForURL:(nonnull NSURL *)url
    completionHandler:(void(^_Nullable)(NSError * _Nullable error, NXMPage * _Nullable page))completionHandler;

@end

@interface NXMPage (Private)

@property (nonatomic, nonnull, readwrite) NSArray *elements;
@property (nonatomic, nonnull, readonly) NXMPageResponse *pageResponse;
@property (nonatomic, nonnull, readonly) id<NXMPageProxy> proxy;

- (nonnull instancetype)initWithOrder:(NXMPageOrder)order
                         pageResponse:(nonnull NXMPageResponse *)pageResponse
                          pagingProxy:(nonnull id<NXMPageProxy>)proxy
                             elements:(nonnull NSArray *)elements;

- (void)nextPage:(void (^_Nonnull)(NSError * _Nullable, NXMPage * _Nullable))completionHandler;
- (void)previousPage:(void (^_Nonnull)(NSError * _Nullable, NXMPage * _Nullable))completionHandler;

@end
