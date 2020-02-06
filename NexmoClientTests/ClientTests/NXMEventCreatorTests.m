//
//  NXMEventCreatorTests.m
//  NexmoClientTests
//
//  Created by Chen Lev on 1/29/20.
//  Copyright © 2020 Vonage. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NXMEventCreator.h"
#import "NXMConversationPrivate.h"
#import "NXMCoreEventsPrivate.h"

@interface NXMEventCreatorTests : XCTestCase

@end

@implementation NXMEventCreatorTests

- (void)testCreateInAppMemberStartCall {
    NSString *conversationID = @"CON-25b41186-51ab-442f-a846-248ba075889c";
    NSString *user4memberID = @"MEM-b0318b7b-5ef9-4f9f-87fd-ef18371c5e4d";
    NSString *user4userID = @"USR-effc7845-333c-4779-aeaf-fdbb4167f93c";
    NSString *user4userName = @"testuser4";
    NSString *pstnPhone = @"97250123456";

    NSDictionary *data = [self memberJoinedEventUser4];
    NXMMemberEvent *event1 = (NXMMemberEvent*)[NXMEventCreator createEvent:data[@"type"]
                                                                      data:data
                                                          conversationUuid:conversationID];
    XCTAssertEqual(event1.uuid, 1);
    XCTAssertTrue([event1 isKindOfClass:[NXMMemberEvent class]]);
    XCTAssertEqual(event1.conversationUuid, conversationID);
    XCTAssertEqual(event1.memberId, user4memberID);
    XCTAssertNotNil(event1.user);
    XCTAssertEqual(event1.user.uuid, user4userID);
    XCTAssertEqual(event1.user.name, user4userName);
    XCTAssertNotNil(event1.media);
    XCTAssertEqual(event1.media.isSuspended, NO);
    XCTAssertEqual(event1.media.isEnabled, NO);
    XCTAssertEqual(event1.state, NXMMemberStateJoined);
    XCTAssertNotNil(event1.channel);
    XCTAssertEqual(event1.channel.to.type, NXMDirectionTypePhone);
    XCTAssertEqual(event1.channel.to.data, pstnPhone);
    XCTAssertEqual(event1.channel.from.type, NXMDirectionTypeApp);
    XCTAssertEqual(event1.channel.from.data, user4userName);
    XCTAssertNil(event1.fromMemberId);
    XCTAssertNotNil(event1.creationDate);
}

- (void)testCreatePhoneMemberInviteWithAudio {
    NSString *conversationID = @"CON-25b41186-51ab-442f-a846-248ba075889c";
    NSString *pstnPhone = @"97250123456";
    NSString *pstnMemberId = @"MEM-7fb399f3-36fb-4805-9e35-30f6d5cbdadf";

    NSDictionary *data = [self memberPhoneInviteWithMedia];
    NXMMemberEvent *event1 = (NXMMemberEvent*)[NXMEventCreator createEvent:data[@"type"]
                                                                      data:data
                                                          conversationUuid:conversationID];
    XCTAssertEqual(event1.uuid, 7);
    XCTAssertTrue([event1 isKindOfClass:[NXMMemberEvent class]]);
    XCTAssertEqual(event1.conversationUuid, conversationID);
    XCTAssertEqual(event1.memberId, pstnMemberId);
    XCTAssertNotNil(event1.user);
    XCTAssertEqual(event1.user.uuid, @"USR-e41422f2-b4e9-489e-a1c7-7e1f0e0b428c");
    XCTAssertNotNil(event1.media);
    XCTAssertEqual(event1.media.isSuspended, NO);
    XCTAssertEqual(event1.media.isEnabled, YES);
    XCTAssertEqual(event1.state, NXMMemberStateInvited);
    XCTAssertNotNil(event1.channel);
    XCTAssertEqual(event1.channel.to.type, NXMDirectionTypePhone);
    XCTAssertEqual(event1.channel.to.data, pstnPhone);
    XCTAssertEqual(event1.channel.from.type, NXMDirectionTypePhone);
    XCTAssertEqual(event1.channel.from.data, @"12567814847");
    XCTAssertEqual(event1.channel.leg.status, NXMLegStatusStarted);
    XCTAssertNil(event1.fromMemberId);
    XCTAssertNotNil(event1.creationDate);
}

- (void)testMemberMediaEnabled {
    NSString *conversationID = @"CON-25b41186-51ab-442f-a846-248ba075889c";
    NSString *user4memberID = @"MEM-b0318b7b-5ef9-4f9f-87fd-ef18371c5e4d";
    
    NSDictionary *data = [self memberUser4MediaEnabledEvent];
    NXMMediaEvent *event = (NXMMediaEvent*)[NXMEventCreator createEvent:data[@"type"]
                                                                    data:data
                                                        conversationUuid:conversationID];
    XCTAssertEqual(event.uuid, 2);
    XCTAssertTrue([event isKindOfClass:[NXMMediaEvent class]]);
    XCTAssertEqual(event.conversationUuid, conversationID);
    XCTAssertEqual(event.fromMemberId, user4memberID);
    XCTAssertEqual(event.isSuspended, NO);
    XCTAssertEqual(event.isEnabled, YES);
    XCTAssertNotNil(event.creationDate);
}

- (void)testMemberLegStatusEvent {
    NSString *conversationID = @"CON-25b41186-51ab-442f-a846-248ba075889c";
    NSString *user4memberID = @"MEM-b0318b7b-5ef9-4f9f-87fd-ef18371c5e4d";
    
    NSDictionary *data = [self memberUser4LegStatusAnswered];
    NXMLegStatusEvent *event = (NXMLegStatusEvent*)[NXMEventCreator createEvent:data[@"type"]
                                                                   data:data
                                                       conversationUuid:conversationID];
    XCTAssertEqual(event.uuid, 3);
    XCTAssertTrue([event isKindOfClass:[NXMLegStatusEvent class]]);
    XCTAssertEqual(event.conversationUuid, conversationID);
    XCTAssertEqual(event.fromMemberId, user4memberID);
    XCTAssertNotNil(event.current);
    XCTAssertEqual(event.current.status, NXMLegStatusAnswered);
    XCTAssertEqual(event.current.type, NXMLegTypeApp);
    XCTAssertEqual(event.current.conversationUuid, conversationID);
    XCTAssertEqual(event.current.uuid, @"54446877-7788-4a35-9d1a-27bb8952730f");
    XCTAssertEqual(event.current.memberUUid, user4memberID);
    XCTAssertNotNil(event.current.date);
    XCTAssertNotNil(event.creationDate);
    XCTAssertEqual(event.history.count, 2);
}

- (void)testPhoneLegStatusEvent {
    NSString *conversationID = @"CON-25b41186-51ab-442f-a846-248ba075889c";
    NSString *pstnMemberId = @"MEM-7fb399f3-36fb-4805-9e35-30f6d5cbdadf";
    NSString *pstnCurrentLegId = @"f39c379d-8524-4882-a68f-2e7bf2bc3055";
    
    NSDictionary *data = [self phoneLegStatusRinging];
    NXMLegStatusEvent *event = (NXMLegStatusEvent*)[NXMEventCreator createEvent:data[@"type"]
                                                                           data:data
                                                               conversationUuid:conversationID];
    XCTAssertEqual(event.uuid, 8);
    XCTAssertTrue([event isKindOfClass:[NXMLegStatusEvent class]]);
    XCTAssertEqual(event.conversationUuid, conversationID);
    XCTAssertEqual(event.fromMemberId, pstnMemberId);
    XCTAssertNotNil(event.current);
    XCTAssertEqual(event.current.status, NXMLegStatusRinging);
    XCTAssertEqual(event.current.type, NXMLegTypePhone);
    XCTAssertEqual(event.current.conversationUuid, conversationID);
    XCTAssertEqual(event.current.uuid, pstnCurrentLegId);
    XCTAssertEqual(event.current.memberUUid, pstnMemberId);
    XCTAssertNotNil(event.current.date);
    XCTAssertNotNil(event.creationDate);
    XCTAssertEqual(event.history.count, 2);
}

- (NSDictionary *)memberJoinedEventUser4 {
    return @{
             @"id": @"1",
             @"type": @"member:joined",
             @"from": @"MEM-b0318b7b-5ef9-4f9f-87fd-ef18371c5e4d",
             @"body": @{
                     @"user": @{
                             @"id": @"USR-effc7845-333c-4779-aeaf-fdbb4167f93c",
                             @"user_id": @"USR-effc7845-333c-4779-aeaf-fdbb4167f93c",
                             @"name": @"testuser4"
                             },
                     @"channel": @{
                             @"headers": @{},
                             @"cpa": @"false",
                             @"preanswer": @"false",
                             @"to": @{
                                     @"type": @"phone",
                                     @"number": @"97250123456"
                                     },
                             @"type": @"app",
                             @"ring_timeout": @"-1",
                             @"cpa_time": @"-1",
                             @"max_length": @"-1",
                             @"legs": @[],
                             @"leg_settings": @{},
                             @"from": @{
                                     @"type": @"app",
                                     @"user": @"testuser4"
                                     },
                             @"knocking_id": @"knocker:9b93d881-378c-4378-ae8c-58b9718b48ee"
                             },
                     @"timestamp": @{
                             @"joined": @"2020-01-29T15:29:41.836Z"
                             },
                     @"initiator": @{
                             @"joined": @{
                                     @"isSystem": @"true"
                                     }
                             }
                     },
             @"timestamp": @"2020-01-29T15:29:41.841Z",
             @"href": @"https://api.nexmo.com/beta/conversations/CON-25b41186-51ab-442f-a846-248ba075889c/events/1"
             };
}

- (NSDictionary *)memberPhoneInviteWithMedia {
   return @{
      @"id": @"7",
      @"type": @"member:invited",
      @"from": @"MEM-7fb399f3-36fb-4805-9e35-30f6d5cbdadf",
      @"body": @{
              @"cname": @"NAM-b866435c-bd5e-4c52-ad3f-7dde24016506",
              @"conversation": @{
                      @"conversation_id": @"CON-25b41186-51ab-442f-a846-248ba075889c",
                      @"name": @"NAM-b866435c-bd5e-4c52-ad3f-7dde24016506"
                      },
              @"invited_by": @"USR-e41422f2-b4e9-489e-a1c7-7e1f0e0b428c",
              @"user": @{
                      @"member_id": @"MEM-7fb399f3-36fb-4805-9e35-30f6d5cbdadf",
                      @"user_id": @"USR-e41422f2-b4e9-489e-a1c7-7e1f0e0b428c",
                      @"media": @{
                              @"audio_settings": @{
                                      @"enabled": @"true",
                                      @"earmuffed": @"false",
                                      @"muted": @"false"
                                      },
                              @"audio": @"true"
                              },
                      @"name": @"vapi-user-83d6fa5255664cdc8b6338aaa9ce3b65"
                      },
              @"channel": @{
                      @"type": @"phone",
                      @"id": @"f39c379d-8524-4882-a68f-2e7bf2bc3055",
                      @"from": @{
                              @"number": @"12567814847",
                              @"headers": @{},
                              @"type": @"phone"
                              },
                      @"legs": @[
                              @{
                                  @"leg_id": @"f39c379d-8524-4882-a68f-2e7bf2bc3055",
                                  @"status": @"started"
                                  }
                              ],
                      @"to": @{
                              @"number": @"97250123456",
                              @"headers": @{},
                              @"type": @"phone"
                              },
                      @"headers": @{},
                      @"cpa": @"false",
                      @"preanswer": @"false",
                      @"ring_timeout": @"45000",
                      @"cpa_time": @"5000",
                      @"max_length": @"7200000"
                      },
              @"media": @{
                      @"audio_settings": @{
                              @"enabled": @"true",
                              @"earmuffed": @"false",
                              @"muted": @"false"
                              },
                      @"audio":@ "true"
                      },
              @"timestamp": @{
                      @"invited": @"2020-01-29T15:29:48.077Z"
                      },
              @"initiator": @{
                      @"invited": @{
                              @"isSystem": @"true"
                              }
                      }
              },
      @"timestamp": @"2020-01-29T15:29:48.093Z",
      @"href": @"https://api.nexmo.com/beta/conversations/CON-25b41186-51ab-442f-a846-248ba075889c/events/7"
      };
}

- (NSDictionary *)memberUser4MediaEnabledEvent {
    return @{
             @"id": @"2",
             @"type": @"member:media",
             @"from": @"MEM-b0318b7b-5ef9-4f9f-87fd-ef18371c5e4d",
             @"body": @{
                     @"audio": @"true",
                     @"media": @{
                             @"audio": @"true",
                             @"audio_settings": @{
                                     @"enabled": @"true",
                                     @"earmuffed": @"false",
                                     @"muted": @"false"
                                     }
                             },
                     @"channel": @{
                             @"id": @"54446877-7788-4a35-9d1a-27bb8952730f",
                             @"type": @"app",
                             @"to": @{
                                     @"type": @"phone",
                                     @"number": @"97250123456"
                                     },
                             @"from": @{
                                     @"type": @"app",
                                     @"user": @"testuser4"
                                     },
                             @"headers": @{}
                             }
                     },
             @"timestamp": @"2020-01-29T15:29:43.071Z",
             @"href": @"https://api.nexmo.com/beta/conversations/CON-25b41186-51ab-442f-a846-248ba075889c/events/2"
             };
}

- (NSDictionary *)memberUser4LegStatusAnswered {
    return @{
      @"id": @"3",
      @"type": @"leg:status:update",
      @"from": @"MEM-b0318b7b-5ef9-4f9f-87fd-ef18371c5e4d",
      @"body": @{
              @"leg_id": @"54446877-7788-4a35-9d1a-27bb8952730f",
              @"type": @"app",
              @"status": @"answered",
              @"statusHistory": @[
                      @{
                          @"status": @"ringing",
                          @"date": @"2020-01-29T15:29:43.052Z",
                          @"member_id": @"MEM-b0318b7b-5ef9-4f9f-87fd-ef18371c5e4d",
                          @"conversation_id": @"CON-25b41186-51ab-442f-a846-248ba075889c"
                          },
                      @{
                          @"status": @"answered",
                          @"date": @"2020-01-29T15:29:43.072Z",
                          @"member_id": @"MEM-b0318b7b-5ef9-4f9f-87fd-ef18371c5e4d",
                          @"conversation_id": @"CON-25b41186-51ab-442f-a846-248ba075889c"
                          }
                      ]
              },
      @"timestamp": @"2020-01-29T15:29:43.076Z",
      @"href": @"https://api.nexmo.com/beta/conversations/CON-25b41186-51ab-442f-a846-248ba075889c/events/3"
      };
}

- (NSDictionary *)phoneLegStatusRinging {
    return @{
        @"id": @"8",
        @"type": @"leg:status:update",
        @"from": @"MEM-7fb399f3-36fb-4805-9e35-30f6d5cbdadf",
        @"body": @{
                   @"leg_id": @"f39c379d-8524-4882-a68f-2e7bf2bc3055",
                   @"type": @"phone",
                   @"direction": @"outbound",
                   @"status": @"ringing",
                   @"statusHistory": @[
                           @{
                               @"status": @"started",
                               @"date": @"2020-01-29T15:29:48.091Z",
                               @"member_id": @"MEM-7fb399f3-36fb-4805-9e35-30f6d5cbdadf",
                               @"conversation_id": @"CON-25b41186-51ab-442f-a846-248ba075889c"
                               },
                           @{
                               @"status": @"ringing",
                               @"date": @"2020-01-29T15:29:53.761Z",
                               @"member_id": @"MEM-7fb399f3-36fb-4805-9e35-30f6d5cbdadf",
                               @"conversation_id": @"CON-25b41186-51ab-442f-a846-248ba075889c"
                               }
                           ]
                   },
        @"timestamp": @"2020-01-29T15:29:53.764Z",
        @"href": @"https://api.nexmo.com/beta/conversations/CON-25b41186-51ab-442f-a846-248ba075889c/events/8"
        };
}


@end
