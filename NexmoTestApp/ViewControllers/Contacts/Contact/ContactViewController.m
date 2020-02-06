//
//  ContactViewController.m
//  NexmoTestApp
//
//  Created by Doron Biaz on 12/18/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "ContactViewController.h"
#import "CommunicationsManager.h"

#import "NTAUserInfo.h"
#import "InAppcallCreator.h"
#import "ServerCallCreator.h"
#import "CallViewController.h"
#import "ChatViewController.h"

@interface ContactViewController ()
@property (weak, nonatomic) IBOutlet UILabel *avatarInitialisLabel;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UIButton *callButton;
@property (weak, nonatomic) IBOutlet UIButton *messageButton;

@property (nonatomic) NTAUserInfo *contactUserInfo;
@end

@implementation ContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - init
- (void)updateWithContactUserInfo:(NTAUserInfo *)contactUserInfo {
    self.contactUserInfo = contactUserInfo;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.avatarInitialisLabel.text = contactUserInfo.initials;
        self.userNameLabel.text = contactUserInfo.displayName;
    });
}

#pragma mark - calls

- (IBAction)callInAppButtonPressed:(UIButton *)sender {
    //create an NTA Call Object and initialize with inApp parameters it so that when we move to the next screen the next screen just calls start.
    InAppCallCreator *callCreator = [[InAppCallCreator alloc] initWithUsers:@[self.contactUserInfo]];
    [self showInCallViewControllerWithCallCreator:callCreator];
}


- (IBAction)callServerButtonPressed:(UIButton *)sender {
    //create an NTA Call Object and initialize with inApp parameters it so that when we move to the next screen the next screen just calls start.
    ServerCallCreator *callCreator = [[ServerCallCreator alloc] initWithUsers:@[self.contactUserInfo]];
    [self showInCallViewControllerWithCallCreator:callCreator];
}

- (void)showInCallViewControllerWithCallCreator:(id<CallCreator>)callCreator {
    CallViewController *inCallVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"Call"];
    [inCallVC updateWithContactUserInfo:self.contactUserInfo callCreator:callCreator andIsIncomingCall:NO];
    [self presentViewController:inCallVC animated:YES completion:nil];
}


#pragma mark - messages

- (IBAction)messageButtonPrerssed:(UIButton *)sender {
    // TODO activity indicatore
    NSString *convUuid = [self conversationIdForUser];
    
    if (convUuid.length > 0) {
        [CommunicationsManager.sharedInstance.client getConversationWithUuid:convUuid completionHandler:^(NSError * _Nullable error, NXMConversation * _Nullable conversation) {
            if (error) {
                // TODO: show error
                return;
            }
            
            [self showConversation:conversation];
        }];
        
        return;
    }
    
    [CommunicationsManager.sharedInstance.client createConversationWithName:[[NSUUID UUID] UUIDString]
                                                          completionHandler:^(NSError * _Nullable error, NXMConversation * _Nullable conversation) {
        if (error) {
            // TODO: show error
            return;
        }
                                                              
        [conversation join:^(NSError * _Nullable error, NXMMember * _Nullable member) {
          [conversation joinMemberWithUsername:self.contactUserInfo.displayName completion:^(NSError * _Nullable error, NXMMember * _Nullable member) {
              [self updateConversationIdForUser:conversation.uuid];
              [self showConversation:conversation];
          }];
        }];
    }];

}

- (void)showConversation:(NXMConversation *)conversation {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showConversation:conversation];
        });
        
        return;
    }
    
    ChatViewController *chatVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"Chat"];
    [chatVC updateConversation:conversation];
    [chatVC setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:chatVC animated:YES];
}

- (NSString *)conversationIdForUser {
    NSString *myUser = CommunicationsManager.sharedInstance.client.user.displayName;
    NSString *secondUser = self.contactUserInfo.displayName;
    NSString *keyFormat = [NSString stringWithFormat:@"%@-%@", myUser > secondUser ? myUser : secondUser, myUser > secondUser ? secondUser : myUser];
    return [[NSUserDefaults standardUserDefaults] stringForKey:keyFormat];
}

- (void)updateConversationIdForUser:(NSString *)convUUid {
    NSString *myUser = CommunicationsManager.sharedInstance.client.user.displayName;
    NSString *secondUser = self.contactUserInfo.displayName;
    NSString *keyFormat = [NSString stringWithFormat:@"%@-%@", myUser > secondUser ? myUser : secondUser, myUser > secondUser ? secondUser : myUser];
    [[NSUserDefaults standardUserDefaults] setObject:convUUid forKey:keyFormat];
}

@end
