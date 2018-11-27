//
//  OngoingCallsViewController.m
//  StitchTestApp
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "SCLOngoingCallsViewController.h"
#import "SCLOnGoingCallsCollectionViewCell.h"
#import "SCLConversationManager.h"


@interface SCLOngoingCallsViewController ()
@property SCLConversationManager *conversationManager;
@property NXMConversationDetails *conversationContext;
@property (weak, nonatomic) IBOutlet UICollectionView *onGoinCallsCollectionView;
@end

@implementation SCLOngoingCallsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.conversationManager = SCLConversationManager.sharedInstance;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedMediaEvent:)
                                                 name:@"mediaEvent"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedMediaActionEvent:)
                                                 name:@"mediaActionEvent"
                                               object:nil];
    [self.onGoinCallsCollectionView setDataSource:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


-(void)updateWithConversation:(NXMConversationDetails *)conversation {
    self.conversationManager = SCLConversationManager.sharedInstance;
    self.conversationContext = conversation;
}

- (void)receivedMediaEvent:(NSNotification *) notification {
    NSDictionary *userInfo = notification.userInfo;
    NXMMediaEvent *media = userInfo[@"media"];
    if (![media.conversationId isEqualToString:self.conversationContext.conversationId]) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.onGoinCallsCollectionView reloadData];
    });
}

- (void)receivedMediaActionEvent:(NSNotification *) notification {
    NSDictionary *userInfo = notification.userInfo;
    NXMMediaActionEvent *media = userInfo[@"media"];
    if (![media.conversationId isEqualToString:self.conversationContext.conversationId]) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.onGoinCallsCollectionView reloadData];
    });
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    SCLOnGoingCallsCollectionViewCell *cell = (SCLOnGoingCallsCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"onGoingCallsCell" forIndexPath:indexPath];
    SCLOngoingMedia *media = [self.conversationManager.ongoingCalls getMediaForIndex:[NSNumber numberWithUnsignedInteger:[indexPath indexAtPosition:1]]];
    [cell updateWithConversationManager:self.conversationManager andOngoingMedia:media];
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.conversationManager.ongoingCalls.count;
}

@end
