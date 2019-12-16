# NexmoClient mobile SDK for iOS Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.2.3 - 2019-12-13

### Fixed.
- Calling `conversation.getEvents` returned an `NXMEvent` with the field `fromMember` set to `nil`


## 1.2.2 - 2019-12-12

### Fixed
- Support for DTLS in WebRTC.
- 'didReceiveCall' and 'didReceiveConversation' not being called twice for the same call or conversation.
- Option to enable push notification with only one token `pushKit` or `userNotification`.
- NXMClientConfig region URLs fix.
- On login with invalid user, fixed to `NXMConnectionStatusReasonUserNotFound`.
- Added build architectures: `armv7` and `armv7s`.

## 1.2.1 - 2019-12-05
### Added
Configuration for ICE server:
```
NXMClientConfig *config = [[NXMClientConfig alloc] initWithApiUrl:restUrl
                                                     websocketUrl:wsUrl
                                                           ipsUrl:ipsUrl
                                                    iceServerUrls:iceUrls];
[NXMClient setConfiguration:config]
```
This configuration is optional and a default will be set if not specified.

Note: setConfiguration should be used before accessing `NXMClient.shared`.

### Fixed
Corrected nil values for `fromMember` for `NXMConversation` events.

## 1.2.0 - 2019-12-03

### Added
`NXMClient`'s `getConversationsPageWithSize:order:completionHandler:` method to get conversations with paging.

`NXMConversationsPage`, which represents the retrieved page, provides the following instance methods

- `hasNextPage` / `hasPreviousPage` to check if forward/backward page retrieval is possible and
- `nextPage:` / `previousPage:` to asynchronously retrieve the next/previous page.

### Changed
`NXMClient`'s `getConversationWithUUid:completionHandler:` method's name typo (now called `getConversationWithUuid:completionHandler:`).

## 1.1.1 - 2019-11-19

### Added
NXMClientConfig object in order to change DC configuration. How to use:
```
[NXMClient setConfiguration:NXMClientConfig.DC]
```

this configuration is optional, when not using it the configuration will set to default.
Note: you most call `setConfiguration` method before using `NXMClient.shared`.

## 1.1.0 - 2019-11-14
### Fixed
- iOS 13 push notifications support
- Start server call fix stability
- Receiving a DTMF event in call and conversation

### Added
NXMConversationDelegate did receive DTMF event method
```
- (void)conversation:(nonnull NXMConversation *)conversation didReceiveDTMFEvent:(nullable NXMDTMFEvent *)event;
```

### Changed
NXMClient client enable push notifications method changed
param pushKitToken - only for voip push (incoming calls)
param userNotificationToken - all push types
```
- (void)enablePushNotificationsWithPushKitToken:(nullable NSData *)pushKitToken
                          userNotificationToken:(nullable NSData *)userNotificationToken
                                      isSandbox:(BOOL)isSandbox
                              completionHandler:(void(^_Nullable)(NSError * _Nullable error))completionHandler;

```

## 1.0.0 - 2019-09-05
### Fixed
- NexmoClient when disconnected returns error callback for all function.
- CallMember status calculated by the current leg status.
- CallMember supports failed, busy, timeout and canceled statuses.
- Supports member invited.
- Conversation has media methods.
- NexmoClient is now singleton.
- Call method changed to string instead of array.
- NexmoClient delegate methods renamed.

### Added
Added conversation media
```
NXMConversation myConversation;
[myConversation enableMedia];   // my media will be enabled
[myConversation disableMedia];  // my media will be disabled
```

Added invite member
```
NXMConversation myConversation;
[myConversation inviteMemberWithUsername:@"someUsername"
                      completion:myCompletionBlock];
```

Added the member state initiator.
```
NXMMember *member = someMember;
NSDictionary<NSValue *, NXMInitiator *> *initiators = member.initiators; 

NXMInitiator leftStateInitiator = initiators[NXMMemberStateLeft];
leftStateInitiator.isSystem; 
leftStateInitiator.userId; 
leftStateInitiator.memberId;
leftStateInitiator.time;
```

Added NXMConversationUpdateDelegate to notify on member updates like media,leg,state.
Added updatesDelegate property to NXMConversation.
```
@property (nonatomic, weak, nullable) id <NXMConversationUpdateDelegate> updatesDelegate;
```
Example
```
@interface MyClass() <NXMConversationUpdateDelegate>
@implementation MyClass

- (void)setConversation:(NXMConversation *conversation) {
	conversation.updatesDelegate(self); // register to conversation updatesDelegate
}

- (void)conversation:(nonnull NXMConversation *)conversation didUpdateMember:(nonnull NXMMember *)member withType:(NXMMemberUpdateType)type {
	if (type == NXMMemberUpdateTypeState) {
		// the member state changed
	}

	if (type == NXMMemberUpdateTypeMedia) {
		// the member media changed
	}
}
@end
```

### Changed

NXMClient is now singleton
```
NXMClient.shared // the shared instance of NXMClient
```
Renamed:
```
@property (nonatomic, readonly, nullable, getter=getToken) NSString *authToken; // was token

// was - (void)login;
- (void)loginWithAuthToken:(NSString *)authToken;

// was - (void)refreshAuthToken:(nonnull NSString *)authToken;
- (void)updateAuthToken:(nonnull NSString *)authToken;

// was callees array
- (void)call:(nonnull NSString *)callee
    callHandler:(NXMCallHandler)callHandler
    delegate:(nullable id<NXMCallDelegate>)delegate
  completion:(void(^_Nullable)(NSError * _Nullable error, NXMCall * _Nullable call))completion;
completionHandler:(void(^_Nullable)(NSError * _Nullable error, NXMCall * _Nullable call))completionHandler;
```


NXMClientDelegate renamed:
```
@protocol NXMClientDelegate <NSObject>

// was - (void)connectionStatusChanged:(NXMConnectionStatus)status reason:(NXMConnectionStatusReason)reason;
- (void)client:(nonnull NXMClient *)client didChangeConnectionStatus:(NXMConnectionStatus)status reason:(NXMConnectionStatusReason)reason;

// was - (void)incomingCall:(nonnull NXMCall *)call;
- (void)client:(nonnull NXMClient *)client didReceiveCall:(nonnull NXMCall *)call;

// was - (void)incomingConversation:(nonnull NXMConversation *)conversation;
- (void)client:(nonnull NXMClient *)client didReceiveConversation:(nonnull NXMConversation *)conversation;
@end
```

NXMConversation otherMembers property renamed to allMembers.
```
NXMConversation myConversation = someConversation;
NSArray<NXMMember *> * allMembers = myConversation.allMembers // return the all conversation members

- (void)joinMemberWithUsername:(nonnull NSString *)username // username instead of userId
```

NXMConversationDelegate renamed methods:
```
// was - (void)customEvent:(nonnull NXMCustomEvent *)customEvent;
- (void)conversation:(nonnull NXMConversation *)conversation didReceiveCustomEvent:(nonnull NXMCustomEvent *)event;

// was - (void)textEvent:(nonnull NXMMessageEvent *)textEvent;
- (void)conversation:(nonnull NXMConversation *)conversation didReceiveTextEvent:(nonnull NXMTextEvent *)event;

// was - (void)attachmentEvent:(nonnull NXMMessageEvent *)attachmentEvent;
- (void)conversation:(nonnull NXMConversation *)conversation didReceiveImageEvent:(nonnull NXMImageEvent *)event;

// - (void)messageStatusEvent:(nonnull NXMMessageStatusEvent *)messageStatusEvent;
- (void)conversation:(nonnull NXMConversation *)conversation didReceiveMessageStatusEvent:(nonnull NXMMessageStatusEvent *)event;

// was - (void)typingEvent:(nonnull NXMTextTypingEvent *)typingEvent;
- (void)conversation:(nonnull NXMConversation *)conversation didReceiveTypingEvent:(nonnull NXMTextTypingEvent *)event;

// was - (void)memberEvent:(nonnull NXMMemberEvent *)memberEvent;
- (void)conversation:(nonnull NXMConversation *)conversation didReceiveMemberEvent:(nonnull NXMMemberEvent *)event;

// was - (void)legStatusEvent:(nonnull NXMLegStatusEvent *)legStatusEvent;
- (void)conversation:(nonnull NXMConversation *)conversation didReceiveLegStatusEvent:(nonnull NXMLegStatusEvent *)event;

// was - (void)mediaEvent:(nonnull NXMEvent *)mediaEvent;
- (void)conversation:(nonnull NXMConversation *)conversation didReceiveMediaEvent:(nonnull NXMMediaEvent *)event;
```

Use username instead of userId
NXMCallDelegate Renamed:
```
// was - (void)statusChanged:(nonnull NXMCallMember *)callMember;
- (void)didUpdate:(nonnull NXMCallMember *)callMember status:(NXMCallMemberStatus)status; 
- (void)didUpdate:(nonnull NXMCallMember *)callMember muted:(BOOL)muted;

// was - (void)DTMFReceived:(nonnull NSString *)dtmf callMember:(nonnull NXMCallMember *)callMember;
- (void)didReceive:(nonnull NSString *)dtmf fromCallMember:(nonnull NXMCallMember *)callMember;
```

NXMEvent and NXMMemberEvent add member object instead of memberId:
```
@property (nonatomic, readonly, nonnull) NXMMember *member;
```

NXMImageInfo renamed properties
```
@property NSInteger sizeInBytes; // was size
@property NXMImageSize size; // was type
```

NXMMessageStatusEvent renamed property
```
@property NSInteger referenceEventId; // was refEventId
```

NexmoClient logger exposed - NXMLogger object
```
[NXMLogger setLogLevel:NXMLoggerLevelDebug];
NSArray *logNames = [NXMLogger getLogFileNames];
```
Removed NXMLoggerDelegate
```
NXMClient myClient
[myClient setLoggerDelegate:LoggerDelegate];
```

## [0.3.0] - 2019-06-02
### Added
- Calls JS and Native SDKs support.

### Changed
- Add member channel and direction data
```
NXMCallMember
@property (nonatomic, readonly, nullable) NXMChannel *channel;


NXMChannel channel {
	NXMDirection from {
		NXMDirectionType type,
		NSString Data
	},
	NXMDirection to {
		NXMDirectionType type,
		NSString Data
	}
}
```

Deprecated
```
NXMCallMember
@property (nonatomic, copy, nullable) NSString *phoneNumber;
@property (nonatomic, copy, nonnull) NSString *channelType;
```


## [0.2.56] - 2019-01-24
### Added
- Change log file.

### Changed
- Memory management improvements.
- Fetch missing and new events on network changes.
- Returning User objects instead of Ids.
- Bug fixes.
- Add nonnull or nullable to properties
- Rename call.decline to call.reject.


## [0.1.52] - 2019-01-21
- Initial beta release with basic call and chat features.

	- Please refer to list of features and usage  
	  https://developer.nexmo.com/

	- **Cocoapods**  
	  https://cocoapods.org/pods/nexmoclient
