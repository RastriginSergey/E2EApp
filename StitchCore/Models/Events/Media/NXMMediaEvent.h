//
//  NXMMediaEvent.h
//  NexmoConversationObjC
//
//  Created by Chen Lev on 4/30/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NXMEvent.h"
#import "NXMMediaSettings.h"

@interface NXMMediaEvent : NXMEvent
@property (nonatomic) NXMMediaSettings *mediaSettings; //TODO: add support to multiple media types
@end
