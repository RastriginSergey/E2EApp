//
//  NXMCall.h
//  StitcClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StitchCore/StitchCore.h>

#import "NXMCallParticipant.h"
#import "NXMConversation.h"

@protocol NXMCallDelegate
- (void)statusChanged;
- (void)holdChanged:(NXMCallParticipant *)participant isHold:(BOOL)isHold member:(NSString *)member;
- (void)muteChanged:(NXMCallParticipant *)participant isMuted:(BOOL)isMuted member:(NSString *)member;
- (void)mediaEvent:(NXMEvent *)mediaEvent;
- (void)memberEvent:(NXMMemberEvent *)memberEvent;
@end

typedef NS_ENUM(NSInteger, NXMCallStatus) {
    NXMCallStatusConnected,
    NXMCallStatusDisconnected
};


@interface NXMCall : NSObject

@property (readonly, nonatomic) NSMutableArray<NXMCallParticipant *> *otherParticipants;
@property (nonatomic, readonly) NXMCallParticipant *myParticipant;
@property (nonatomic, readonly) NXMCallStatus status;
@property (nonatomic, readonly) NXMConversation* conversation;

- (void)setDelegate:(id<NXMCallDelegate>)delegate;

- (void)answer:(id<NXMCallDelegate>)delegate completionHandler:(NXMErrorCallback _Nullable)completionHandler;
- (void)hangup:(NXMErrorCallback _Nullable)completionHandler;

- (void)addParticipantWithUserId:(NSString *)userId completionHandler:(NXMErrorCallback _Nullable)completionHandler;
- (void)addParticipantWithNumber:(NSString *)number completionHandler:(NXMErrorCallback _Nullable)completionHandler;

@end

