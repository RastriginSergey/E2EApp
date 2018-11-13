//
//  RTCMediaWrapperDelegate.h
//  StitchCore
//
//  Copyright © 2018 Vonage. All rights reserved.
//

#import <iOSFramework/iOSFramework.h>
#import "NXMMediaInfo.h"
#import "NXMBlocks.h"

@protocol RTCMediaWrapperDelegate

- (void)onMediaStatusChangedWithConversationId:(NSString *)conversationId andStatus:(NSString *)status;

- (void)sendSDP:(NSString *)sdp
   andMediaInfo:(MRTCMediaInfo *)mediaInfo
      onSuccess:(NXMSuccessCallbackWithId)onSuccess
        onError:(NXMErrorCallback)onError;

- (void)terminateRtc:(MRTCMediaInfo *)mediaInfo rtcId:(NSString *)rtcId  completionHandler:(void (^)(NSError *))completionHandler;

- (void)didMuteStateChangeWithMediaInfo:(NXMMediaInfo *)mediaInfo andIsMute:(bool)isMute andMediaType:(NXMMediaType)mediaType;

- (void)sendMuteStateWithMediaInfo:(NXMMediaInfo *)mediaInfo andIsMute:(bool)isMute andMediaType:(NXMMediaType)mediaType onSuccess:(void (^) (void))onSuccess onError:(void (^_Nullable) (NSError * _Nullable error))onError;
//TODO: make some preset callback blocks (maybe move the NXMNetwork callbacks outside to some extent)
@end
