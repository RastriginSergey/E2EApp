//
//  ConversationEventTableViewCell.h
//  StitchTestApp
//
//  Created by Chen Lev on 5/28/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NXMEvent;
@interface ConversationEventTableViewCell : UITableViewCell

- (void)updateWithEvent:(NXMEvent *)event;
- (void)updateWithEvent:(NXMEvent *)event memberName:(NSString *)memberName;

@end