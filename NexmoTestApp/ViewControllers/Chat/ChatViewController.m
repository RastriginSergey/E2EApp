//
//  ChatViewController.m
//  NexmoTestApp
//
//  Created by Chen Lev on 1/12/20.
//  Copyright © 2020 Vonage. All rights reserved.
//

#import "ChatViewController.h"

#import <Foundation/Foundation.h>
#import <NexmoClient/NexmoClient.h>
#import <Photos/Photos.h>

#import "CommunicationsManagerDefine.h"
#import "NTAUserInfo.h"
#import "NTALogger.h"

#import "ChatTextTableViewCell.h"
#import "ChatEventTableViewCell.h"


const NSUInteger events_count = 20;

@interface ChatViewController ()<UIGestureRecognizerDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, NXMConversationDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewContraint;

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextView *textinput;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIImageView *enableAudioImage;
@property (weak, nonatomic) IBOutlet UILabel *typingLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadMoreActivityIndicator;


@property NXMConversation *conversation;
@property (nonatomic, readonly, nullable) NXMMember *myMember;
@property NSMutableArray<NXMEvent *> *events;
@property BOOL isAudioEnabled;
@property BOOL isLoadMoreRequested;
@property BOOL shouldSyncEvents;

@property NSSet *eventsToPresent;



@end

@implementation ChatViewController

- (nullable NXMMember *)myMember {
    return self.conversation.myMember;
}

#pragma mark - view lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.delegate = self;
    [self.tableView addGestureRecognizer:tapGesture];
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPressGesture.minimumPressDuration = 1.0f;
    longPressGesture.delegate = self;
    
    [self.tableView addGestureRecognizer:longPressGesture];
    
    self.textinput.delegate = self;
    self.sendButton.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self subscribeConnectionEvents];

    self.typingLabel.hidden = YES;
    [self loadEvents];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateConversation:(NXMConversation *)conversation {
    [self setup];
    
    self.conversation = conversation;
    conversation.delegate = self;
}

- (void)setup {
    self.shouldSyncEvents = YES;
    self.events = [NSMutableArray new];
    self.eventsToPresent = [[NSSet alloc] initWithObjects:@(NXMEventTypeText),@(NXMEventTypeImage),@(NXMEventTypeMedia),@(NXMEventTypeMember), nil];
    
}

#pragma mark - keyboard

- (void)keyboardWillShow:(NSNotification*)notification {
    NSDictionary* info = [notification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    self.textViewContraint.constant = keyboardSize.height - 40;
    [self.view layoutIfNeeded];
    
}

- (void)keyboardWillHide:(NSNotification*)notification {
    self.textViewContraint.constant = 0;
    [self.view layoutIfNeeded];
}

- (void)updateSendButtonIfNeeded {
    self.sendButton.enabled = self.textinput.text.length > 0;
}

#pragma mark - login (reconnect)
- (void)subscribeConnectionEvents {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSuccessfulLogin:) name:kNTACommunicationsManagerNotificationNameConnectionStatus object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionStatusChanged:) name:@"connectionStatusChanged" object:nil];
}

- (void)didSuccessfulLogin:(NSNotification *)notification {
    // TODO:
}

- (void)connectionStatusChanged:(NSNotification *)notification {
    // TODO:
}

- (void)addEventToSource:(NXMEvent *)event {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self addEventToSource:event];
        });
        
        return;
    }
    
    if (!event || ![self.eventsToPresent containsObject:@(event.type)]) {
        return;
    }
    
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.events.count inSection:0]]
                          withRowAnimation:UITableViewRowAnimationLeft];
    [self.events addObject:event];
    [self.tableView endUpdates];
    
    [self scrollToBottom];
}

#pragma NXMConversationDelegate methods
- (void)conversation:(nonnull NXMConversation *)conversation didReceive:(nonnull NSError *)error {
    
}

- (void)conversation:(nonnull NXMConversation *)conversation didReceiveCustomEvent:(nonnull NXMCustomEvent *)event {
    [self addEventToSource:event];
}

- (void)conversation:(nonnull NXMConversation *)conversation didReceiveTextEvent:(nonnull NXMTextEvent *)event {
    [self addEventToSource:event];
}

- (void)conversation:(nonnull NXMConversation *)conversation didReceiveImageEvent:(nonnull NXMImageEvent *)event {
    [self addEventToSource:event];
}

- (void)conversation:(nonnull NXMConversation *)conversation didReceiveMessageStatusEvent:(nonnull NXMMessageStatusEvent *)event {
    
}

- (void)conversation:(nonnull NXMConversation *)conversation didReceiveTypingEvent:(nonnull NXMTextTypingEvent *)event {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (event.status == NXMTextTypingEventStatusOff) {
            self.typingLabel.hidden = YES;
            return;
        }
        
        self.typingLabel.text = [NSString stringWithFormat:@"%@ is typing...", event.fromMember.user.name];
        self.typingLabel.hidden = NO;
    });
}

- (void)conversation:(nonnull NXMConversation *)conversation didReceiveMemberEvent:(nonnull NXMMemberEvent *)event {
    [self addEventToSource:event];
}

- (void)conversation:(nonnull NXMConversation *)conversation didReceiveLegStatusEvent:(nonnull NXMLegStatusEvent *)event {
    
}

- (void)conversation:(nonnull NXMConversation *)conversation didReceiveMediaEvent:(nonnull NXMMediaEvent *)event {
    [self addEventToSource:event];
}

- (void)conversation:(nonnull NXMConversation *)conversation didReceiveDTMFEvent:(nonnull NXMDTMFEvent *)event {
    [self addEventToSource:event];
}

#pragma mark - IBAction

- (IBAction)addMemberPressed:(id)sender {
    NSMutableString *message = [NSMutableString new];
    if (self.myMember) {
        [message appendFormat:@"%@\n",self.myMember.user.name];
    }
    
    NSArray<NSString *> *membersNames = [[self.conversation.allMembers valueForKey:@"name"] allObjects];
    [message appendFormat:@"%@\n",[membersNames componentsJoinedByString:@"\n"]];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"members" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"add user";
    }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *username =[[alertController textFields][0] text];
        [NTALogger debug:[NSString stringWithFormat:@"username %@", username]];
        
        __weak ChatViewController *weakSelf = self;
        [self.conversation joinMemberWithUsername:username completion:^(NSError * _Nullable error, NXMMember * _Nullable member) {
            if(error) {
                NSLog(@"failed adding user with Error: %@", error);
                [weakSelf showMessageWithTitle:@"error" andMessage:@"failed adding user" andDismissAfterSeconds:2];
                return;
            }
            NSLog(@"success add username %@", username);
        }];
    }];
        
    [alertController addAction:confirmAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"Canelled");
    }];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];;
}

- (IBAction)sendMsgPressed:(id)sender {
    self.sendButton.enabled = NO;
    self.textinput.editable = NO;
    
    [self.conversation sendStopTyping:^(NSError * _Nullable error) {
        if(error) {
            [NTALogger debug:@"error stop typing"];
        }
    }];
    
    [self.conversation sendText:self.textinput.text completionHandler:^(NSError * _Nullable error) {
        if(error) {
            [NTALogger debug:@"sendText failed"];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.textinput.editable = YES;
            });
            return;
        }
        
        [NTALogger debug:@"sendText success"];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.textinput.editable = YES;
            self.textinput.text = @"";
            [self.textinput endEditing:YES];
        });
    }];
}

- (IBAction)attachmentPressed:(id)sender {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    NSData* data = UIImagePNGRepresentation(image);
    
    NSString *filename = [NSString stringWithFormat:@"IMAGE_%@.png", [[NSUUID UUID] UUIDString]];
    
    [self.conversation sendAttachmentWithType:NXMAttachmentTypeImage name:filename data:data completionHandler:^(NSError * _Nullable error) {
        if(error) {
            NSLog(@"failed to upload image with error: %@", error);
            [self showMessageWithTitle:@"image upload" andMessage:@"Failed to upload image" andDismissAfterSeconds:2];
            return;
        }
        [self showMessageWithTitle:@"image upload" andMessage:@"image uploaded" andDismissAfterSeconds:2];
    }];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - initialization

-(void)loadEvents {
    if (!self.shouldSyncEvents) {
        return;
    }
    
    self.navigationItem.title = self.conversation.allMembers[1].user.name;
    self.shouldSyncEvents = NO;
    
    [self.conversation getEventsPageWithSize:events_count order:NXMPageOrderAsc completionHandler:^(NSError * _Nullable error, NXMEventsPage * _Nullable events) {
        [self loadMoreEvents:events];
    }];
}

- (void)loadMoreEvents:(NXMEventsPage *)page {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadMoreEvents:page];
        });
        
        return;
    }
    
    if (!page) {
        return;
    }
    
    [self.tableView beginUpdates];

    
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    int i = (int)self.events.count;
    for (NXMEvent *event in page.events) {
        if ([self.eventsToPresent containsObject:@(event.type)]) {
            [self.events addObject:event];
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            i++;
        }
    }
    
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationLeft];
    [self.tableView endUpdates];
    
    [page nextPage:^(NSError * _Nullable error, NXMEventsPage * _Nullable page) {
        [self loadMoreEvents:page];
    }];
    
    [self loadViewIfNeeded];
}

#pragma mark - tableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.events.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NXMEvent *event = self.events[indexPath.row];
    
    if (event.type == NXMEventTypeMember || event.type == NXMEventTypeMedia) {
        ChatEventTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ChatEventCell"];
        [cell updateWithEvent:event];

        return cell;
    }
    
    if (event.type == NXMEventTypeText || event.type == NXMEventTypeImage) {
        ChatTextTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ChatTextCell"];
        if (cell == nil) {
            cell = [[ChatTextTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ChatTextCell"];
            cell.backgroundColor = self.tableView.backgroundColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }

        NXMMessageEvent *messageEvent = (NXMMessageEvent *)event;
        [cell updateWithEvent:event isMe:[event.fromMember isEqual:self.myMember]
                messageStatus:messageEvent.state[@(NXMMessageStatusTypeDelivered)].count != 0 ? NXMMessageStatusTypeDelivered :
                                messageEvent.state[@(NXMMessageStatusTypeSeen)].count != 0 ? NXMMessageStatusTypeSeen :
                                NXMMessageStatusTypeNone];
        
        
        return cell;
    }

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NXMEvent *event = self.events[indexPath.row];
    if (event.type == NXMEventTypeMember || event.type == NXMEventTypeMedia || event.type == NXMEventTypeSip) {
        return 50.0f;
    }
    
    if (event.type == NXMEventTypeText) {
        NXMTextEvent *textEvent = (NXMTextEvent *)event;
        CGSize boundSize = CGSizeMake(self.tableView.frame.size.width / 2.0f, CGFLOAT_MAX);
        CGSize textSize = [textEvent.text boundingRectWithSize:boundSize
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0f]}
                                                       context:nil].size;
        CGSize nameSize = CGSizeZero;
        if (!([self.myMember.memberUuid isEqualToString:event.fromMember.memberUuid])) {
            nameSize = [event.fromMember.user.name boundingRectWithSize:boundSize
                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                      attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:14.0f]}
                                                                context:nil].size;
        }
        
        return textSize.height + nameSize.height + 40.0f;
    }
    
    if (event.type == NXMEventTypeImage) {
        CGSize boundSize = CGSizeMake(self.tableView.frame.size.width / 2.0f, CGFLOAT_MAX);
        CGSize nameSize = CGSizeZero;
        if (!([self.myMember.memberUuid isEqualToString:event.fromMember.memberUuid])) {
            nameSize = [event.fromMember.user.name boundingRectWithSize:boundSize
                                                                options:NSStringDrawingUsesLineFragmentOrigin
                                                             attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:14.0f]}
                                                                context:nil].size;
        }
        
        return 60.0f + nameSize.height + 40.0f;
    }
    
    return 0.1f;
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if(scrollView.contentOffset.y < 0) {
        self.isLoadMoreRequested = true;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if(!self.isLoadMoreRequested) {
        return;
    }
    
    if(scrollView.contentOffset.y > 0) {
        self.isLoadMoreRequested = NO;
        return;
    }
    
    [self.loadMoreActivityIndicator startAnimating];
    
//    [self loadEvents:^(NSError * _Nullable error) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.loadMoreActivityIndicator stopAnimating];
//            self.isLoadMoreRequested = NO;
//            if (error) {
//                [self showMessageWithTitle:@"error" andMessage:@"failed loading more events" andDismissAfterSeconds:2];
//                return;
//            }
//
//            [self reloadDataSourceWithScrollFlag:NO];
//        });
//    }];
}

#pragma mark - Gestures

- (void)handleTap:(UIGestureRecognizer *)recognizer {
    // [self.textinput endEditing:YES];
}

- (void)handleLongPress:(UIGestureRecognizer *)recognizer {
    CGPoint locationInView = [recognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:locationInView];
    NXMEvent *event = self.events[indexPath.row];
    
    if (![event.fromMember isEqual:self.myMember]) {
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"conversation" message:@"do you want to delete this msg?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        // TODO: delete event
    }];
    [alertController addAction:confirmAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"Cancelled");
    }];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    if (!self.sendButton.enabled) {
        [self.conversation sendStartTyping:nil];
    }

    if(textView.text.length == 0) {
        [self.conversation sendStopTyping:nil];
    }

    [self updateSendButtonIfNeeded];
}



#pragma mark - Helper Methods
- (void)reloadDataSourceWithScrollFlag:(BOOL)scrollFlag {
    NSInteger currentNumberOfRows = [self.tableView numberOfRowsInSection:0];
    [self.tableView reloadData];
    if(scrollFlag) {
        [self scrollToBottom];
        return;
    }
    
    NSUInteger newNumberOfRows = self.events.count;
    NSInteger dif = newNumberOfRows - currentNumberOfRows - (currentNumberOfRows ? 0 : 1);
    if(dif > 0) {
        [self scrollToRow:dif position:UITableViewScrollPositionTop animated:NO];
    }
}

- (void)scrollToBottom {
    if (self.events.count == 0) {
        return;
    }
    
    [self scrollToRow:(self.events.count - 1) position:UITableViewScrollPositionBottom animated:YES];
}

- (void)scrollToRow:(NSInteger)row position:(UITableViewScrollPosition)position animated:(BOOL)animated{
    if (self.events.count == 0) {
        return;
    }
    
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow: row inSection: 0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:position animated:animated];
}

#pragma mark - Media

- (void)startAudioAnimation {
    [UIView animateWithDuration:1.0f
                     animations:^{
                         self.enableAudioImage.transform = CGAffineTransformScale(self.enableAudioImage.transform, 2.0f, 2.0f);
                     }
                     completion:^(BOOL finished) {
                         [self endAudioAnimation];
                     }];
}

- (void)endAudioAnimation {
    [UIView animateWithDuration:1.0f
                     animations:^{
                         self.enableAudioImage.transform = CGAffineTransformIdentity;
                     }
                     completion:^(BOOL finished) {
                         if (self.isAudioEnabled) {
                             [self startAudioAnimation];
                         }
                     }];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

}

-(void)showMessageWithTitle:(NSString *)title andMessage:(NSString *)message andDismissAfterSeconds:(NSUInteger)seconds {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    });
}

@end
