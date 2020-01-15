//
//  NXMEventsPage.m
//  NexmoClient
//
//  Created by Nicola Di Pol on 16/12/2019.
//  Copyright © 2019 Vonage. All rights reserved.
//

#import "NXMEventsPage.h"
#import "NXMPagePrivate.h"

@implementation NXMEventsPage

- (NSArray<NXMEvent *> *)events {
    return (NSArray<NXMEvent *> *)self.elements;
}

- (void)nextPage:(void (^)(NSError * _Nullable, NXMEventsPage * _Nullable))completionHandler {
    [super nextPage:^(NSError * _Nullable error, NXMPage * _Nullable page) {
        completionHandler(error, (NXMEventsPage *)page);
    }];
}

- (void)previousPage:(void (^)(NSError * _Nullable, NXMEventsPage * _Nullable))completionHandler {
    [super previousPage:^(NSError * _Nullable error, NXMPage * _Nullable page) {
        completionHandler(error, (NXMEventsPage *)page);
    }];
}

@end
