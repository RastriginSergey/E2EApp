//
//  NXMGetEventsPageRequest.h
//  NexmoClient
//
//  Created by Nicola Di Pol on 24/12/2019.
//  Copyright © 2019 Vonage. All rights reserved.
//

#import "NXMBaseRequest.h"
#import "NXMEnums.h"

@interface NXMGetEventsPageRequest : NXMBaseRequest

@property (nonatomic, assign) NSUInteger size;
@property (nonatomic, assign) NXMPageOrder order;
@property (nonatomic, nonnull) NSString *conversationId;
@property (nonatomic, nullable) NSString *cursor;
@property (nonatomic, nullable) NSString *eventType;

- (nonnull instancetype)initWithSize:(NSUInteger)size
                               order:(NXMPageOrder)order
                      conversationId:(nonnull NSString *)conversationId
                              cursor:(nullable NSString *)cursor
                           eventType:(nullable NSString *)eventType;

@end
