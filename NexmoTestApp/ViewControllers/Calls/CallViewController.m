//
//  InCallViewController.m
//  NexmoTestApp
//
//  Created by Doron Biaz on 12/19/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "CallViewController.h"
#import "NTAUserInfo.h"
#import "NTALogger.h"
#import "NTAAlertUtils.h"
#import "CallsDefine.h"

@interface CallViewController () <NXMCallDelegate>
@property (weak, nonatomic) IBOutlet UIView *InCallView;
@property (weak, nonatomic) IBOutlet UIImageView *InCallAvatarImage;
@property (weak, nonatomic) IBOutlet UILabel *InCallAvatarInitialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *InCallUserNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *InCallUserStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *InCallUserSecondName;
@property (weak, nonatomic) IBOutlet UILabel *InCallUserStatusName;
@property (weak, nonatomic) IBOutlet UIButton *InCallMuteButton;
@property (weak, nonatomic) IBOutlet UIButton *InCallSpeakerButton;
@property (weak, nonatomic) IBOutlet UIButton *InCallEarmuffButton;
@property (weak, nonatomic) IBOutlet UIButton *InCallHoldButton;
@property (weak, nonatomic) IBOutlet UIButton *InCallKeyPadButton;
@property (weak, nonatomic) IBOutlet UIButton *InCallEndCallButton;
@property (weak, nonatomic) IBOutlet UILabel *InCallStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;

@property (weak, nonatomic) IBOutlet UIView *InCallKeyboard;
@property (weak, nonatomic) IBOutlet UIView *IncomingCallView;
@property (weak, nonatomic) IBOutlet UIImageView *IncomingCallAvatarImage;
@property (weak, nonatomic) IBOutlet UILabel *IncomingCallInitialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *IncomingCalluserNameLabel;


@property (nonatomic) NTAUserInfo *contactUserInfo;
@property (nonatomic) NSString *number;
@property (nonatomic) id<CallCreator> callCreator;
@property (nonatomic) NXMCall *call;
@property (nonatomic) BOOL isControllerInIncomingCallState;
@property NSDate * startTime;
@property NSTimer* timer;
@property BOOL isSpeaker;
@property BOOL isIncoming;
@end

@implementation CallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    // Do any additional setup after loading the view.
    [self.callCreator callWithDelegate:self completion:^(NSError * _Nullable error, NXMCall * _Nullable call) {
        if(error) {
            [self didFailCreatingCallWithError:error];
            return;
        }
        
        [self didCreateCall:(NXMCall *)call];
    }];
    
    if(self.isControllerInIncomingCallState) {
        [self activateIncomingCallView];
    } else {
        [self activateInCallView];
        self.isIncoming = NO;

    }
    
    [self updateContactUI];
    [self updateInCallStatusLabels];
}


- (void)viewWillDisappear:(BOOL)animated {
    [self.timer invalidate];

}
#pragma mark - init
- (void)updateWithContactUserInfo:(NTAUserInfo *)contactUserInfo callCreator:(id<CallCreator>)callCreator andIsIncomingCall:(BOOL)isIncomingCall {
    self.contactUserInfo = contactUserInfo;
    self.callCreator = callCreator;
    self.isControllerInIncomingCallState = isIncomingCall;
}

- (void)updateWithNumber:(NSString *)number callCreator:(id<CallCreator>)callCreator andIsIncomingCall:(BOOL)isIncomingCall {
    self.number = number;
    self.callCreator = callCreator;
    self.isControllerInIncomingCallState = isIncomingCall;
}

- (void)updateContactUI {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateContactUI];
        });
        return;
    }

    BOOL isPSTN = [self.number length] > 0;
    self.IncomingCallInitialsLabel.text =  isPSTN ? @"PSTN" : self.contactUserInfo.initials;
    self.IncomingCalluserNameLabel.text = isPSTN > 0 ? self.number : self.contactUserInfo.displayName;
    self.InCallAvatarInitialsLabel.text = isPSTN > 0 ? @"PSTN" : self.contactUserInfo.initials;
    self.InCallUserNameLabel.text = isPSTN > 0 ? self.number : self.contactUserInfo.displayName;
}

- (void)activateInCallView {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self activateInCallView];
        });
        return;
    }
    
    self.isControllerInIncomingCallState = NO;
    [self.InCallView setHidden:NO];
    [self.IncomingCallView setHidden:YES];
    [self startTimer];

}

- (void)activateIncomingCallView {
    self.isIncoming = YES;
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self activateIncomingCallView];
        });
        return;
    }
    
    self.isControllerInIncomingCallState = YES;
    [self.IncomingCallView setHidden:NO];
    [self.InCallView setHidden:YES];
    
}

- (void)didFailCreatingCallWithError:(NSError *)error {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self didFailCreatingCallWithError:error];
        });
        return;
    }
    
    [self.InCallStatusLabel setText:@"Error"];

    [NTAAlertUtils displayAlertForController:self withTitle:@"Call Failed" andMessage:[NSString stringWithFormat:@"Call failed with error: %@", error] andActionBlock:^(UIAlertAction * _Nonnull action) {
            [self dismiss];
    }];
}

- (void)didCreateCall:(NXMCall *)call {
    self.call = call;
    [self.call setDelegate:self];
    [self updateInCallStatusLabels];
}

- (void)updateInCallStatusLabels {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateInCallStatusLabels];
        });
        
        return;
    }
    
    [self.InCallStatusLabel setText:self.call.myCallMember.statusDescription];
    if (self.call.otherCallMembers.count > 0) {
        [NTALogger debug:[NSString stringWithFormat:@"status %@", self.call.otherCallMembers[0].statusDescription]];

        [self.InCallUserNameLabel setText:[self memberName:self.call.otherCallMembers[0]]];
        [self.InCallUserStatusLabel setText:self.call.otherCallMembers[0].statusDescription];
    }
    
    if (self.call.otherCallMembers.count > 1) {
        [NTALogger debug:[NSString stringWithFormat:@"status %@", self.call.otherCallMembers[1].statusDescription]];
        
        [self.InCallUserStatusName setText:[self memberName:self.call.otherCallMembers[1]]];
        [self.InCallUserSecondName setText:self.call.otherCallMembers[1].statusDescription];
    } else {
        [self.InCallUserStatusName setText:@""];
        [self.InCallUserSecondName setText:@""];
    }
}

#pragma Mark IncomingCall

#pragma mark AnswerCall

- (IBAction)answerCallButtonPressed:(id)sender {
    [self.call answer:^(NSError * _Nullable error) {
        if(error) {
            [NTALogger errorWithFormat:@"Failed answering incoming call with error: %@", error];
            [self endCall];
        }
    }];
    
    [self activateInCallView];
}

#pragma mark Decline Call

- (IBAction)declineCallButtonPressed:(UIButton *)sender {
    [self.call reject:^(NSError * _Nullable error) {
        if(error) {
            [NTALogger errorWithFormat:@"Error declining call: %@",error];
            return;
        }
        //TODO: refactor when fixing the [endCall - should only be dismissed after hangup succeeds]
        [self dismiss];
    }];
}

#pragma mark - InCall Controls
- (IBAction)endCallButtonPressed:(UIButton *)sender {
    [self endCall];
}

- (IBAction)mutePressed:(id)sender {
    [self.call.myCallMember mute:!self.call.myCallMember.isMuted];
}

- (IBAction)speakerPressed:(id)sender {
    if (!self.isSpeaker) {
        if ([[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil]) {
            self.isSpeaker = YES;
        }
    } else if ([[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil]){
        self.isSpeaker = NO;
    }
    
    [self.InCallSpeakerButton setSelected:self.isSpeaker];
}
- (IBAction)dailerPressed:(id)sender {
    self.InCallKeyboard.hidden = NO;
}

- (IBAction)addPreseed:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add User" message:@"Add user to call" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"User name";
        textField.secureTextEntry = YES;
    }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        __weak id weakSelf = self;
        [self.call addCallMemberWithUsername:@"testuser3" completionHandler:^(NSError * _Nullable error) {
            if (error) {
                UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Failed"
                                                                                    message:error.description
                                                                             preferredStyle:UIAlertControllerStyleAlert];
                
                [errorAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                
                [weakSelf presentViewController:errorAlert animated:YES completion:nil];
            }
        }];
    }];
    [alert addAction:confirmAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"Canelled");
    }];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - InCall Keyboard

- (IBAction)hideKeyboardPressed:(id)sender {
    [self.InCallKeyboard setHidden:YES];
    
}

- (IBAction)dailerDigitPressed:(id)sender {
    NSInteger digit = (long)((UIButton *)sender).tag;
    if (digit <= 9) {
        [self.call sendDTMF: [NSString stringWithFormat:@"%ld", (long)((UIButton *)sender).tag]];
    } else if (digit == 10) {
        [self.call sendDTMF:@"*"];
    } else {
        [self.call sendDTMF:@"#"];
    }
}


#pragma mark - NXMCallDelegate


- (void)call:(nonnull NXMCall *)call didReceive:(nonnull NSError *)error {
    
}

- (void)call:(nonnull NXMCall *)call didUpdate:(nonnull NXMCallMember *)callMember isMuted:(BOOL)muted {
    [NTALogger debug:[NSString stringWithFormat:@"CallViewController statusChanged %@ %@ %ld", callMember.memberId, callMember.user.name, callMember.status]];
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self call:call didUpdate:callMember isMuted:muted];
        });
        
        return;
    }
    if ([callMember.user.uuid isEqualToString:self.call.myCallMember.user.uuid]) {
        [self.InCallMuteButton setSelected:callMember.isMuted];
    }
    
    [self updateInCallStatusLabels];
}

- (void)call:(nonnull NXMCall *)call didUpdate:(nonnull NXMCallMember *)callMember withStatus:(NXMCallMemberStatus)status {
    [NTALogger debug:[NSString stringWithFormat:@"CallViewController statusChanged %@ %@ %ld", callMember.memberId, callMember.user.name, callMember.status]];
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self call:call didUpdate:callMember withStatus:status];
        });
        
        return;
    }
    
    if (self.isControllerInIncomingCallState &&
        (self.call.myCallMember.status != NXMCallMemberStatusRinging ||
         self.call.otherCallMembers[0].status == NXMCallMemberStatusCompleted ||
         self.call.otherCallMembers[0].status == NXMCallMemberStatusRinging)) {
        [self dismiss];
    }
    
    if (self.call.myCallMember.status == NXMCallMemberStatusCompleted) {
        [self didDisconnectCall];
        return;
    }
    
    [self updateInCallStatusLabels];
}

- (void)call:(nonnull NXMCall *)call didReceive:(nonnull NSString *)dtmf fromCallMember:(nullable NXMCallMember *)callMember {
    
}

#pragma mark - Private
- (void)didDisconnectCall {
    [self endCall];
}

- (void)refreshTimeLabel
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSInteger   connectedTime = [[NSDate date] timeIntervalSinceDate:self.startTime];
        NSString    *timeString;
        
        if ( connectedTime >= 3600 ) { // more than an hour
            NSInteger   inHourTime = connectedTime%3600;
            
            timeString = [NSString stringWithFormat:@"%02d:%02d:%02d", (int)(connectedTime/3600), (int)(inHourTime/60), (int)(inHourTime%60)];
        }
        else {
            timeString = [NSString stringWithFormat:@"%02d:%02d", (int)(connectedTime / 60), (int)(connectedTime % 60)];
        }
        
        self.timerLabel.text = timeString;
    });
}

- (void)startTimer
{
    self.startTime = [NSDate date]; //start dateTime for your timer, ensure that date format is correct
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(refreshTimeLabel)
                                                userInfo:nil
                                                 repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)endCall {
    if (self.call.myCallMember.status != NXMLegStatusCompleted) {
        [self.call hangup];
    }
    
    if (self.isSpeaker) {
        if ([[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil]){
            self.isSpeaker = NO;
        }
    }
    
    [self dismiss];
}

- (void)dismiss {
    if(![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dismiss];
        });
        return;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [NSNotificationCenter.defaultCenter postNotificationName:kNTACallsDefineNotificationNameEndCall object:self];
}

- (NSString *)memberName:(NXMCallMember *)member {
    if (self.isIncoming) {
        if (member.channel.from.data) {
            return member.channel.from.data;
        }
    } else {
        if (member.channel.to.data) {
            return member.channel.to.data;
        }
    }
    
    return member.user.name;
}

@end
