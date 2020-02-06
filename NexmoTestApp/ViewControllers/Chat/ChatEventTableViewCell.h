//
//  ChatEventTableViewCell.h
//  NexmoTestApp
//
//  Created by Chen Lev on 1/12/20.
//  Copyright © 2020 Vonage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <NexmoClient/NexmoClient.h>


NS_ASSUME_NONNULL_BEGIN

@interface ChatEventTableViewCell : UITableViewCell

- (void)updateWithEvent:(NXMEvent *)event;
@end

NS_ASSUME_NONNULL_END
