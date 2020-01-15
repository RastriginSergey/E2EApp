//
//  EventsTableViewController.h
//  NexmoTestApp
//
//  Created by Nicola Di Pol on 20/12/2019.
//  Copyright © 2019 Vonage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <NexmoClient/NXMClient.h>

@interface EventsTableViewController : UITableViewController

@property (nonatomic, nullable) NXMConversation *conversation;

@end
