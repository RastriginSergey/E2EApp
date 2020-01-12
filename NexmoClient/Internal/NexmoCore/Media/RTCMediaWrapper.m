//
//  RTCMediaWrapper.m
//  NexmoConversationObjC
//
//  Created by Chen Lev on 4/23/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "RTCMediaWrapper.h"
#import "NXMLoggerInternal.h"

@interface RTCMediaWrapper()
@property MRTCMedia *mrtcMedia;
@property (nonatomic, weak) id<RTCMediaWrapperDelegate> delegate;
@property NSString* lastMemberId; // TODO: remove temporary for test
@end


@implementation RTCMediaWrapper

//- (void)setNetworkDelegate:(id<MRTCMediaNetwork>)networkDelegate {
//    self.network = networkDelegate;
//}

- (instancetype)initWithIceServerUrls:(NSArray<NSString*>*) iceServerUrls{
    if (self = [super init]) {
        self.mrtcMedia = [[MRTCMedia alloc] initWithIceServerUrls:iceServerUrls];
        [self.mrtcMedia setDelegate:self];
    }
    
    return self;
}

- (void)setDelegate:(id<RTCMediaWrapperDelegate>)delegate {
    _delegate = delegate;
}


- (void)disableMedia:(NSString *)mediaId {
    [self.mrtcMedia disableMediaWithMediaId:mediaId andUuid:[[NSUUID UUID] UUIDString]];
}

- (void)enableMediaWithMediaID:(NSString *)conversationId
                      memberId:(NSString *)memberId
                  andWithAudio:(NXMMediaStreamType)audiostream
                  andWithVideo:(NXMMediaStreamType)videoStream {
    
    self.lastMemberId = memberId;

    MRTCMediaInfo *mediaInfo = [[MRTCMediaInfo alloc]initWithMediaId:conversationId conversationId:conversationId member:memberId];
    [self.mrtcMedia enableMediaWithMediaInfo:mediaInfo andWithAudio:MRTCMediaRTPStreamTypeSendReceive andWithVideo:MRTCMediaRTPStreamTypeNone andUuid:[[NSUUID UUID] UUIDString]];
}

- (void)answerWithMediaId:(NSString *)mediaId convId:(NSString *)convId andSDP:(NSString *)sdp {
    [self.mrtcMedia answerWithMediaId:convId andSDP:sdp andRtcId:mediaId andUuid:[[NSUUID UUID] UUIDString]];
}

- (NXMErrorCode)suspendMediaWithMediaId:(nonnull NSString *)conversationId andMediaType:(NXMMediaType)type {
    MRTCMediaType mrtcMediaType = [self mrtcMediaTypeWithNXMMediaType:type];
    if(mrtcMediaType == MRTCMediaTypeNone) {
        NXM_LOG_ERROR("NXMMediaType [%li] is not supported",(long)type);
        return NXMErrorCodeMediaNotSupported;
    }
    
    [self.mrtcMedia suspendMediaWithMediaId:conversationId andMediaType:mrtcMediaType andUuid:[[NSUUID UUID] UUIDString]];
    return NXMErrorCodeNone;
}

- (NXMErrorCode)resumeMediaWithMediaId:(nonnull NSString *)conversationId andMediaType:(NXMMediaType)type {
    MRTCMediaType mrtcMediaType = [self mrtcMediaTypeWithNXMMediaType:type];
    if(mrtcMediaType == MRTCMediaTypeNone) {
        NXM_LOG_ERROR("NXMMediaType [%li] is not supported", (long)type);
        return NXMErrorCodeMediaNotSupported;
    }
    
    [self.mrtcMedia resumeMediaWithMediaId:conversationId andMediaType:mrtcMediaType andUuid:[[NSUUID UUID] UUIDString]];
    return NXMErrorCodeNone;
}


- (NXMErrorCode)sendDTMFWithDigits:(nonnull NSString*)digits
                      andConversationId:(nonnull NSString*)conversationId
                            andMemberId:(nonnull NSString*)memberId
                            andDuration:(int) duration
                                 andGap:(int) gap {
    [self.mrtcMedia sendDTMFDigitsWithMediaId:conversationId andDigits:digits andDuration:duration andGap:gap andUuid:[[NSUUID UUID] UUIDString]];
    
    return NXMErrorCodeNone;
}

#pragma mark: - private

- (MRTCMediaRTPStreamType)nxmStreamTypeToMRTCStreamType:(NXMMediaStreamType)streamType {
    switch (streamType) {
        case NXMMediaStreamTypeNone:
            return MRTCMediaRTPStreamTypeNone;
        case NXMMediaStreamTypeSend:
            return MRTCMediaRTPStreamTypeSend;
        case NXMMediaStreamTypeReceive:
            return MRTCMediaRTPStreamTypeReceive;
        case NXMMediaStreamTypeSendReceive:
            return MRTCMediaRTPStreamTypeSendReceive;
        default:
            return MRTCMediaRTPStreamTypeNone;
            break;
    }
}

-(NXMMediaType)nxmMediaTypeWithMRTCMediaType:(MRTCMediaType)mediaType {
    switch (mediaType) {
        case MRTCMediaTypeAudio:
            return NXMMediaTypeAudio;
            break;
        case MRTCMediaTypeVideo:
            return NXMMediaTypeVideo;
            break;
        default:
            return NXMMediaTypeNone;
            break;
    }
}

-(MRTCMediaType)mrtcMediaTypeWithNXMMediaType:(NXMMediaType)mediaType {
    switch (mediaType) {
        case NXMMediaTypeAudio:
            return MRTCMediaTypeAudio;
            break;
        case NXMMediaTypeVideo:
            return MRTCMediaTypeVideo;
            break;
        default:
            return MRTCMediaTypeNone;
            break;
    }
}

-(NXMMediaInfo *)nxmMediaInfoWithMRTCMediaInfo:(MRTCMediaInfo *)mrtcMediaInfo andRtcId:(NSString *)rtcId {
    return [[NXMMediaInfo alloc] initWithMediaId:mrtcMediaInfo._mediaId conversationId:mrtcMediaInfo._conversationId rtcId:rtcId memberId:mrtcMediaInfo._memberId];
}


//- (void)addMemberWithMediaId:(NSString *)mediaId andSdp:(NSString *)sdp {
//
//}
//
//- (void)updateMediaMediaId:(NSString *)mediaId andWithAudio:(RTPStreamType)audioStream andWithVideo:(RTPStreamType)videoStream {
//
//}
//
//- (void)holdWithMediaId:(NSString *)mediaId {
//
//}


#pragma mark: - MRTCMediaManagerDelegate


- (void)onMediaStatusChange:(NSString *)status andMediaInfo:(MRTCMediaInfo*)mediaInfo {
    
}


- (void)sendSDP:(NSString*)sdp andMediaInfo:(MRTCMediaInfo *)mediaInfo andType:(MRTCMediaNetworkSdpType)type andUuid:(NSString *)uuid completionHandler:(void (^)(NSString *, NSError *, const NSString *))completionHandler {
    if(!self.delegate) {
        completionHandler(nil, [NXMErrors nxmErrorWithErrorCode:NXMErrorCodeMissingDelegate], uuid);
        return;
    }
    
    [self.delegate sendSDP:sdp andMediaInfo:mediaInfo onSuccess:^(NSString * _Nullable value) {
        completionHandler(value, nil,uuid);
    } onError:^(NSError * _Nullable error) {
        completionHandler(nil, error,uuid);
    }];
}

- (void)terminateRtcIdWithMediaInfo:(MRTCMediaInfo *)mediaInfo rtcId:(NSString *)rtcId uuid:(NSString *)uuid completionHandler:(void (^)(NSError *, NSString *))completionHandler {
    
    if(!self.delegate) {
        completionHandler([NXMErrors nxmErrorWithErrorCode:NXMErrorCodeMissingDelegate], uuid);
        return;
    }
    
    [self.delegate terminateRtc:mediaInfo rtcId:rtcId completionHandler:^(NSError * error) {
        completionHandler(error, uuid);
    }];
}

- (void)onMuteStateChanged: (NSString *)rtcId andMediaInfo:(MRTCMediaInfo *)mediaInfo andIsMute:(bool)isMute andMediaType:(MRTCMediaType)mediaType andUuid:(NSString *)uuid {
    if(!self.delegate) {
        return;
    }
    
    [self.delegate didMuteStateChangeWithMediaInfo:[self nxmMediaInfoWithMRTCMediaInfo:mediaInfo andRtcId:rtcId]
                                     andIsMute:isMute
                                  andMediaType:[self nxmMediaTypeWithMRTCMediaType:(MRTCMediaType)mediaType]];
}

- (void)sendMuteState:(const NSString *)rtcId andMediaInfo:(MRTCMediaInfo *)mediaInfo andIsMute:(bool)isMute andMediaType:(MRTCMediaType)mediaType andUuid:(NSString *)uuid completionHandler:(void (^)(bool, const NSString *))completionHandler {
    if(!self.delegate) {
        completionHandler(false, uuid);
        return;
    }
    
    NXMMediaType nxmMediaType = [self nxmMediaTypeWithMRTCMediaType:(MRTCMediaType)mediaType];
    if(nxmMediaType == NXMMediaTypeNone) {
        NXM_LOG_ERROR("MRTCMediaType [%li] is not supported", (long)(MRTCMediaType)mediaType);
        completionHandler(false, uuid);
        return;
    }
    
    [self.delegate sendMuteStateWithMediaInfo:[self nxmMediaInfoWithMRTCMediaInfo:mediaInfo
                                                                         andRtcId:(NSString *)rtcId]
                                                                        andIsMute:isMute
                                                                     andMediaType:nxmMediaType
                                                                        onSuccess:^(void) {
                                                                            completionHandler(true, uuid);
                                                                        } onError:^(NSError * _Nullable error) {
                                                                            NXM_LOG_ERROR("Error sending mute with error:  %@",error.description);
                                                                            completionHandler(false,uuid);
                                                                        }];
}

- (void)sendDTMFCallback:(NSString*)streamId andDigits:(NSString*)digits andUuid:(NSString*)uuid {
    //TODOs 
}

- (void)onEarmuffStateChanged: (NSString *)rtcId andMediaInfo:(MRTCMediaInfo *)mediaInfo andIsEarmuff:(bool)isEarmuff andCallMediaType:(MRTCMediaType)callMediaType andUuid:(NSString *)uuid {
    
}


- (void)onHoldStateChanged: (NSString *)rtcId andMediaInfo:(MRTCMediaInfo *)mediaInfo andIsHold:(bool)isHold  andCallMediaType:(MRTCMediaType)callMediaType andUuid:(NSString *)uuid {
    
}


- (void)sendHoldState:(const NSString *)rtcId andSdp:(const NSString *)sdp andMediaInfo:(MRTCMediaInfo *)mediaInfo andIsHold:(bool)isHold andCallMediaType:(MRTCMediaType)callMediaType andUuid:(NSString *)uuid andCompletionHandler:(void (^)(bool, const NSString *))completionHandler {
    
}

- (void)playDTMF:(NSString*)streamId andDigit:(NSString*)digit {
    
}

- (void)onErrorWithType:(NSString *)type andUuid:(NSString *)uuid andErrorDescription:(NSString *)description andData:(NSDictionary *)data {
    NXM_LOG_DEBUG("%s", description);
}

@end
