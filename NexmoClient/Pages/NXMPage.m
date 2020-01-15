//
//  NXMPage.m
//  NexmoClient
//
//  Created by Nicola Di Pol on 23/12/2019.
//  Copyright © 2019 Vonage. All rights reserved.
//

#import "NXMPagePrivate.h"
#import "NXMPageResponse.h"
#import "NXMErrorsPrivate.h"

@interface NXMPage()

@property (nonatomic, assign, readwrite) NXMPageOrder order;
@property (nonatomic, nonnull, readwrite) NXMPageResponse *pageResponse;
@property (nonatomic, nonnull, readwrite) id<NXMPageProxy> proxy;
@property (nonatomic, nonnull, readwrite) NSArray *elements;

@end

@implementation NXMPage

- (instancetype)initWithOrder:(NXMPageOrder)order
                 pageResponse:(NXMPageResponse *)pageResponse
                  pagingProxy:(id<NXMPageProxy>)proxy
                     elements:(NSArray *)elements {
    self = [super init];
    if (self) {
        self.order = order;
        self.pageResponse = pageResponse;
        self.proxy = proxy;
        self.elements = elements;
    }
    return self;
}

- (NSUInteger)size {
    return self.pageResponse.pageSize;
}

- (BOOL)hasNextPage {
    return self.pageResponse.links.next ? true : false;
}

- (BOOL)hasPreviousPage {
    return self.pageResponse.links.prev ? true : false;
}

- (void)nextPage:(void (^)(NSError * _Nullable, NXMPage * _Nullable))completionHandler {
    [self moveToPageURL:self.pageResponse.links.next completionHandler:completionHandler];
}

- (void)previousPage:(void (^)(NSError * _Nullable, NXMPage * _Nullable))completionHandler {
    [self moveToPageURL:self.pageResponse.links.prev completionHandler:completionHandler];
}

- (void)moveToPageURL:(nullable NSURL *)newPageURL
    completionHandler:(void (^_Nonnull)(NSError * _Nullable, NXMPage * _Nullable))completionHandler {
    if (!newPageURL) {
        completionHandler([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeEventsPageNotFound andUserInfo:nil], nil);
        return;
    }

    [self.proxy getPageForURL:newPageURL completionHandler:completionHandler];
}

@end
