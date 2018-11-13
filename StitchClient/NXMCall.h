//
//  NXMCall.h
//  StitcClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StitchCore/StitchCore.h>

#import "NXMCallParticipant.h"

@protocol NXMCallDelegate

- (void)statusChanged;
- (void)holdChanged:(NXMCallParticipant *)participant isHold:(BOOL)isHold member:(NSString *)member;
- (void)muteChanged:(NXMCallParticipant *)participant isMuted:(BOOL)isMuted member:(NSString *)member;

@end

typedef NS_ENUM(NSInteger, NXMCallStatus) {
    NXMCallStatusConnected,
    NXMCallStatusDisconnected
};


@interface NXMCall : NSObject

@property (nonatomic, readonly) NSString *conversationId;
@property (readonly, nonatomic) NSMutableArray<NXMCallParticipant *> *otherParticipants;
@property (nonatomic, readonly) NXMCallParticipant *myParticipant;
@property (nonatomic, readonly) NXMCallStatus status;

- (void)setDelegate:(id<NXMCallDelegate>)delegate;

- (void)addParticipantWithUserId:(NSString *)userId completionHandler:(NXMErrorCallback _Nullable)completionHandler;
- (void)addParticipantWithNumber:(NSString *)number completionHandler:(NXMErrorCallback _Nullable)completionHandler;

- (void)turnOff;

@end

