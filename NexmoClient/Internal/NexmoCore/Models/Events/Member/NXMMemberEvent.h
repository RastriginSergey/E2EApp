//
//  NXMMemberEvent.h
//  NexmoNClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMEvent.h"
#import "NXMUser.h"
#import "NXMMediaSettings.h"

typedef NS_ENUM(NSInteger, NXMChannelType){
    NXMChannelTypeApp,
    NXMChannelTypePhone,
    NXMChannelTypeUnknown
};

@interface NXMMemberEvent : NXMEvent

@property (nonatomic, strong) NSString *memberId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) NXMMemberState state;
@property (nonatomic, strong) NXMUser *user;
@property (nonatomic, strong) NSString* phoneNumber;
@property (nonatomic, strong) NXMMediaSettings *media;
@property (nonatomic) NXMChannelType channelType;
@property (nonatomic, strong) NSString* channelData;
@property(nonatomic, strong) NSString* knockingId;

@end
