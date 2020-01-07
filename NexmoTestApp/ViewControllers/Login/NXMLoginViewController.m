//
//  NXMLoginVC.m
//  NexmoTestApp
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMLoginViewController.h"
#import "ContactsListViewController.h"
#import "UserSettingsViewController.h"
#import "MainTabViewController.h"
#import "DialerViewController.h"
#import "ConversationsTableViewController.h"
#import "CommunicationsManager.h"

#import "NTAUserInfoProvider.h"
#import "NTALoginHandler.h"

#import "NTAAlertUtils.h"
#import "NTALogger.h"

@interface NXMLoginViewController ()

@property (nonatomic) UITapGestureRecognizer *tapRecognizer;
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIView *inprogressView;

@end

@implementation NXMLoginViewController
- (IBAction)loadDefaultTestUserToTextFields:(UIButton *)sender {
    NTAUserInfo *randomUser = [NTAUserInfoProvider getRandomUserForTestGroup];
    self.username.text = randomUser.name;
    self.password.text = randomUser.password;
}

- (IBAction)loadDefaultBabyUserToTextFields:(UIButton *)sender {
    NTAUserInfo *randomUser = [NTAUserInfoProvider getRandomUserForBabyGroup];
    self.username.text = randomUser.name;
    self.password.text = randomUser.password;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.inprogressView.hidden = true;
    
    //Keyboard stuff
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    self.tapRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:self.tapRecognizer];
    
    //notifications
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(NTADidLogoutWithNotification:) name:kNTALoginHandlerNotificationNameUserDidLogout object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    //check if alreadyLoggedIn
    if([NTALoginHandler currentUser]) {
        [NTALoginHandler loginCurrentUserWithCompletion:^(NSError * _Nullable error, NTAUserInfo * _Nonnull userInfo) {
            [self didLogin];
        }];
    }
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark - Login
- (void)NTADidLogoutWithNotification:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.username.text = @"";
        self.password.text = @"";
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (IBAction)onLoginPressed:(UIButton *)sender {
    [self showInProgressView];
    
    __weak NXMLoginViewController *weakSelf = self;
    
    [NTALoginHandler loginWithUserName:self.username.text andPassword:self.password.text completion:^(NSError * _Nullable error, NTAUserInfo * _Nonnull userInfo) {
        
        [self hideInProgressView];
        
        if(error) {
            [self hideInProgressView];
            [NTAAlertUtils displayAlertForController:weakSelf withTitle:@"Authentcation failed" andMessage:@"User name or password is incorrect"];
            return;
        }
        
        if (userInfo.csUserToken) {
            [CommunicationsManager.sharedInstance loginWithUserToken:userInfo.csUserToken];
        }
        
        [self didLogin];
    }];
}


- (void)didLogin {
    [self showMainScreen];
}

#pragma mark - private



- (void)showMainScreen {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    UINavigationController *contactsNavigationController = [storyboard instantiateViewControllerWithIdentifier:@"ContactsListNavigation"];
    UserSettingsViewController *userSettingsVC = [storyboard instantiateViewControllerWithIdentifier:@"UserSettings"];
    
    DialerViewController *dialerVC = [storyboard instantiateViewControllerWithIdentifier:@"dialer"];

    UINavigationController *conversationsNavigationController = [storyboard instantiateViewControllerWithIdentifier:@"conversationsNavigationController"];

    MainTabViewController *tabBarController = [storyboard instantiateViewControllerWithIdentifier:@"mainTabBar"];
    tabBarController.viewControllers = @[contactsNavigationController,
                                         dialerVC,
                                         conversationsNavigationController,
                                         userSettingsVC];
    
    [self presentViewController:tabBarController animated:NO completion:nil];
}

- (void)showInProgressView {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.inprogressView.hidden = false;
        [self.activityIndicator startAnimating];
    });
}

- (void)hideInProgressView {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator stopAnimating];
        self.inprogressView.hidden = true;
    });
}

#pragma mark - UITextFieldDelegate

- (void)handleSingleTap:(UITapGestureRecognizer *) sender {
    [self.view endEditing:YES];
}

@end
