//
//  ChatTextTableViewCell.m
//  NexmoTestApp
//
//  Copyright © 2020 Vonage. All rights reserved.
//

#import "ChatTextTableViewCell.h"
#include <math.h>

const int kBubbleWidthOffset = 10.0f;

@interface ChatTextTableViewCell()

@property (strong, nonatomic) IBOutlet UILabel *fromLabel;
@property (strong, nonatomic) IBOutlet UILabel *messageText;
@property (strong, nonatomic) IBOutlet UIImageView *bubbleImage;
@property (strong, nonatomic) IBOutlet UIImageView *messageStatusImage;
@property (weak, nonatomic) IBOutlet UILabel *messageStatusLabel;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property NSData *imageData;
@property (nonatomic, assign) BOOL isMe;

@end
@implementation ChatTextTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self.imageView setHidden:YES];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.fromLabel.backgroundColor = [UIColor clearColor];
        self.fromLabel.numberOfLines = 0;
        self.fromLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.fromLabel.textColor = [UIColor blackColor];
        self.fromLabel.font = [self nameFont];
        
        self.messageText.backgroundColor = [UIColor clearColor];
        self.messageText.numberOfLines = 0;
        self.messageText.lineBreakMode = NSLineBreakByWordWrapping;
        self.messageText.textColor = [UIColor blackColor];
        self.messageText.font = [self textFont];
    }
    
    return self;
}

- (void)layoutSubviews {
    [self updateFrames];
}

- (void)updateFrames {
    [self setImageForSenderType:self.isMe];
    
    CGSize nameSize = CGSizeZero;
    CGSize boundSize = CGSizeMake(self.frame.size.width / 2.0f, CGFLOAT_MAX);
    if (self.fromLabel.text.length) {
        nameSize = [self.fromLabel.text boundingRectWithSize:boundSize
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:@{NSFontAttributeName:[self nameFont]}
                                                     context:nil].size;
    }
    
    CGSize textSize = [self.messageText.text boundingRectWithSize:boundSize
                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                       attributes:@{NSFontAttributeName:[self textFont]}
                                                          context:nil].size;
    CGSize imageSize = self.imageView.bounds.size;
    
    CGFloat labelsWidth = MAX(MAX(nameSize.width, textSize.width), imageSize.width);
    
    CGSize totalSize = CGSizeMake(labelsWidth + 10.0f, nameSize.height + textSize.height + (self.imageView.isHidden ? 0 : imageSize.height));
    if (!self.isMe) {
        self.bubbleImage.frame = CGRectMake(self.frame.size.width - (totalSize.width + kBubbleWidthOffset), 0.0f, totalSize.width +
                                            kBubbleWidthOffset, totalSize.height + 40.0f);
        self.fromLabel.frame = CGRectMake(self.frame.size.width - (totalSize.width + kBubbleWidthOffset - 10.0f), 6.0f,
                                          totalSize.width, nameSize.height);
        self.messageText.frame = CGRectMake(self.frame.size.width - (totalSize.width + kBubbleWidthOffset - 10.0f),
                                            self.fromLabel.frame.size.height + 5.0f, totalSize.width, textSize.height);
        self.imageView.frame = CGRectMake(self.frame.size.width - (totalSize.width + kBubbleWidthOffset - 10.0f),
                                          self.fromLabel.frame.size.height + 5.0f, totalSize.width, imageSize.width);
        
        self.fromLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        self.messageText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        self.bubbleImage.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        self.bubbleImage.transform = CGAffineTransformIdentity;
        return;
    }
    
    
    self.bubbleImage.frame = CGRectMake(0.0f, 0.0f, totalSize.width + kBubbleWidthOffset, totalSize.height + 40.0f);
    self.fromLabel.frame = CGRectZero;
    self.messageText.frame = CGRectMake(10.0f, 6.0f, totalSize.width, totalSize.height + 5.0f);
    self.imageView.frame = CGRectMake(10.0f, 6.0f, totalSize.width, totalSize.height + 5.0f);
    
    self.fromLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    self.messageText.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    self.bubbleImage.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    self.bubbleImage.transform = CGAffineTransformIdentity;
    self.bubbleImage.transform = CGAffineTransformMakeScale(-1.0f, 1.0f);
}


- (void)updateWithEvent:(NXMEvent *)event
                   isMe:(BOOL)isMe
          messageStatus:(NXMMessageStatusType)status {
    if (event.type == NXMEventTypeText) {
        [self.imageView setHidden:YES];
        NXMTextEvent *eventText = ((NXMTextEvent *)event);
        self.messageText.text = eventText.text;
    }
    
    if (event.type == NXMEventTypeImage) {
        [self.imageView setHidden:NO];
        self.imageView.image = [UIImage imageNamed:@"messageStatusSeen"];
        if (self.imageData) {
            self.imageView.image = [UIImage imageWithData:self.imageData];
        } else {
            [self downloadImage:((NXMImageEvent *)event).thumbnailImage.url];
        }
    }

    self.isMe = isMe;
    self.fromLabel.text = isMe ? @"" : event.fromMember.user.name;
    self.messageStatusImage.image = [[UIImage alloc] init];
    self.messageStatusLabel.text = @"";
    
    [self layoutIfNeeded];

    if (status == NXMMessageStatusTypeSeen) {
        self.messageStatusImage.image = [UIImage imageNamed:@"messageStatusSeen"];
        self.messageStatusLabel.text = @"Seen";
        return;
    }
    
    if (status == NXMMessageStatusTypeDelivered) {
        self.messageStatusImage.image = [UIImage imageNamed:@"messageStatusDelivered"];
        self.messageStatusLabel.text = @"Delivered";
        return;
    }
    
    if (status == NXMMessageStatusTypeDeleted) {
        self.messageText.text = @"Deleted";
    }
}

#pragma mark - Helper Methods

- (void)setImageForSenderType:(BOOL)isMe {
    NSString *imageName = isMe ? @"bubbleDefault" : @"bubbleBlue";
    UIEdgeInsets insets = UIEdgeInsetsMake(12.0f, 20.0f, 12.0f, 20.0f);
    self.bubbleImage.image = [[UIImage imageNamed:imageName] resizableImageWithCapInsets:insets];
}

- (UIFont *)textFont {
    return [UIFont systemFontOfSize:14.0];
}

- (UIFont *)nameFont {
    return [UIFont boldSystemFontOfSize:14.0];
}


- (void)downloadImage:(NSURL*)url {
     NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
     config.HTTPAdditionalHeaders = @{@"Authorization": [NSString stringWithFormat:@"bearer %@", NXMClient.shared.authToken]};
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    
    NSURLSessionDataTask *task = [[NSURLSession sessionWithConfiguration:config] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            NSLog(@"%@", error);
            return;
        }
        
        if (data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageData = data;
                self.imageView.image = [UIImage imageWithData:data];
                [self layoutIfNeeded];
            });
        }
    }];
    
    [task resume];
}

@end
