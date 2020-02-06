//
//  ChatEventTableViewCell.m
//  NexmoTestApp
//
//  Copyright © 2020 Vonage. All rights reserved.
//

#import "ChatEventTableViewCell.h"

#import <NexmoClient/NexmoClient.h>


@interface ChatEventTableViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *eventText;
@property (weak, nonatomic) IBOutlet UIImageView *audioImage;
@property NXMEvent *event;
@end

@implementation ChatEventTableViewCell

- (void)updateWithEvent:(NXMEvent *)event {
    self.event = event;
    
    if (event.type == NXMEventTypeMember) {
        NSString *text = [NSString stringWithFormat:@"%@ %@",
                          [self memberStateDescription],
                          ((NXMMemberEvent *)event).member.user.name];
        self.eventText.text = text;
        self.eventText.textAlignment = NSTextAlignmentCenter;
        self.audioImage.image = [[UIImage alloc] init];
        return;
    }
    
    if (event.type == NXMEventTypeMedia) {
        NXMMediaEvent *mediaEvent = ((NXMMediaEvent *)event);
        NSString *text = [NSString stringWithFormat:@"Audio %@ by %@",
                          mediaEvent.isEnabled ? @"Enabled" : @"Disabled",
                          mediaEvent.fromMember.user.name];
        self.eventText.text = text;
        self.eventText.textAlignment = NSTextAlignmentLeft;
        NSString *imageName = mediaEvent.isEnabled ? @"eventAudioEnabled" : @"eventAudioDisabled";
        self.audioImage.image = [UIImage imageNamed:imageName];
    }
}

- (NSString *)memberStateDescription {
    switch (((NXMMemberEvent *)self.event).state) {
        case NXMMemberStateInvited:
            return @"invited";
        case NXMMemberStateJoined:
            return @"joined";
        case NXMMemberStateLeft:
            return @"left";
        default:
            return @"unknown";
    }
}

@end

