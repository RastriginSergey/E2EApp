//
//  ChatTextTableViewCell.h
//  NexmoTestApp
//
//  Created by Chen Lev on 1/12/20.
//  Copyright © 2020 Vonage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <NexmoClient/NexmoClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChatTextTableViewCell : UITableViewCell

- (void)updateWithEvent:(NXMEvent *)event
                   isMe:(BOOL)isMe
          messageStatus:(NXMMessageStatusType)status;
@end

NS_ASSUME_NONNULL_END
