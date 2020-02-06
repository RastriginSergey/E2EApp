//
//  NXMClientDefine.h
//  NexmoClient
//
//  Copyright © 2018 Vonage. All rights reserved.
//


#pragma mark - emitted events
static NSString *const kNXMSocketEventConversationGet = @"conversation:get";
static NSString *const kNXMSocketEventLogin = @"session:login";
static NSString *const kNXMSocketEventLogout = @"session:logout";
static NSString *const kNXMSocketEventRefreshToken = @"session:update-token";

#pragma mark - received events
#pragma mark session
static NSString *const kNXMSocketEventLoginSuccess = @"session:success"; //success login
static NSString *const kNXMSocketEventSessionInvalid = @"session:invalid"; //fail login
static NSString *const kNXMSocketEventSessionErrorInvalid = @"session:error:invalid"; //fail login
static NSString *const kNXMSocketEventSessionLogoutSuccess = @"session:logged-out"; // success logout
static NSString *const kNXMSocketEventSessionTerminated = @"session:terminated"; // logout -> already logged out
static NSString *const kNXMSocketEventMaxOpenedSessions = @"session:error:max-open-sessions"; // fail login

#pragma mark token
static NSString *const kNXMSocketEventRefreshTokenDone = @"session:update-token:success"; // token refreshed
static NSString *const kNXMSocketEventInvalidToken = @"system:error:invalid-token"; //TODO: is this logout or not?
static NSString *const kNXMSocketEventExpiredToken = @"system:error:expired-token"; //TODO: is this logout or not?

#pragma mark system
static NSString *const kNXMSocketEventBadPermission = @"system:error:permission"; //failed ACL
static NSString *const kNXMSocketEventInvalidEvent = @"system:error:invalid-event"; //unrecognized event

#pragma mark user
static NSString *const kNXMSocketEventUserNotFound = @"user:error:not-found";

#pragma mark custom event
static NSString *const kNXMEventCustom = @"custom";

#pragma mark member
static NSString *const kNXMSocketEventMemebrMedia = @"member:media";
static NSString *const kNXMSocketEventMemberJoined = @"member:joined";
static NSString *const kNXMSocketEventMemberLeft = @"member:left";
static NSString *const kNXMSocketEventMemberInvited = @"member:invited";

#pragma mark rtc
static NSString *const kNXMSocketEventRtcAnswer = @"rtc:answer";
static NSString *const kNXMSocketEventRtcIce = @"rtc:ice";
static NSString *const kNXMSocketEventRtcOffer = @"rtc:offer";
static NSString *const kNXMSocketEventRtcNew = @"rtc:new";
static NSString *const kNXMSocketEventRtcTerminate = @"rtc:terminate";

#pragma mark text
static NSString *const kNXMSocketEventTextDelivered = @"text:delivered";
static NSString *const kNXMSocketEventTextSeen = @"text:seen";
static NSString *const kNXMSocketEventText = @"text";
static NSString *const kNXMSocketEventTextSuccess = @"text:success";
static NSString *const kNXMSocketEventTypingOn = @"text:typing:on";
static NSString *const kNXMSocketEventTypingOff = @"text:typing:off";

#pragma mark image
static NSString *const kNXMSocketEventImage = @"image";
static NSString *const kNXMSocketEventImageDelivered = @"image:delivered";
static NSString *const kNXMSocketEventImageSeen = @"image:seen";

#pragma mark delete
static NSString *const kNXMSocketEventMessageDelete = @"event:delete";

#pragma mark audio
static NSString *const kNXMSocketEventAudioMuteOn = @"audio:mute:on";
static NSString *const kNXMSocketEventAudioMuteOff = @"audio:mute:off";
static NSString *const kNXMSocketEventAudioPlay = @"audio:play";
static NSString *const kNXMSocketEventAudioPlayDone = @"audio:play:done";
static NSString *const kNXMSocketEventAudioSay = @"audio:say";
static NSString *const kNXMSocketEventAudioSayDone = @"audio:say:done";
static NSString *const kNXMSocketEventAudioRecord = @"audio:record";
static NSString *const kNXMSocketEventAudioSayRecordDone = @"audio:record:done";
static NSString *const kNXMSocketEventAudioDtmf = @"audio:dtmf";
static NSString *const kNXMSocketEventAudioEarmuffOn = @"audio:earmuff:on";
static NSString *const kNXMSocketEventAudioEarmuffOff = @"audio:earmuff:off";
static NSString *const kNXMSocketEventAudioSpeakingOn = @"audio:speaking:on";
static NSString *const kNXMSocketEventAudioSpeakingOff = @"audio:speaking:off";

#pragma mark sip
static NSString *const kNXMSocketEventSipRinging = @"sip:ringing";
static NSString *const kNXMSocketEventSipAnswered = @"sip:answered";
static NSString *const kNXMSocketEventSipHangup = @"sip:hangup";
static NSString *const kNXMSocketEventSipStatus = @"sip:status";

#pragma mark leg status
static NSString *const kNXMSocketEventLegStatus = @"leg:status:update";
