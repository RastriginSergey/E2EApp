//
//  NXMRouter.m
//  NexmoConversationObjC
//
//  Created by Chen Lev on 3/7/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

#import "NXMRouter.h"
#import "NXMErrors.h"
#import "NXMErrorParser.h"
#import "NXMAddUserRequest.h"
#import "NXMSendTextEventRequest.h"
#import "NXMDeleteEventRequest.h"

@interface NXMRouter()

@property NSString *baseUrl;
@property (nonatomic) NSString *token;


@end
@implementation NXMRouter

- (nullable instancetype)initWitHost:(nonnull NSString *)host {
    if (self = [super init]) {
        self.baseUrl = host;
    }
    
    return self;
}

- (void)setToken:(NSString *)token {
    _token = token;
}

- (BOOL)getConversationWithId:(NSString*)convId  completionBlock:(void (^_Nullable)(NSError * _Nullable error, NXMConversationDetails * _Nullable conversation))completionBlock {

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/conversations/%@", self.baseUrl, convId]];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    [self addHeader:request];
    
    [self executeRequest:request responseBlock:^(NSError * _Nullable error, NSDictionary * _Nullable data) {
        if (error) {
            completionBlock(error, nil);
            return;
        }
        
        NSString *convId = @"uuid";
        NXMConversationDetails *details = [[NXMConversationDetails alloc] initWithId:convId];
        details.name = data[@"name"];
        details.created = data[@"timestamp"][@"created"];
        details.sequence_number = [data[@"sequence_number"] intValue];
        details.properties = data[@"properties"];
        
        NSMutableArray *members = [[NSMutableArray alloc] init];
        
        for (NSDictionary* memberJson in data[@"members"]) {
            NXMMember *member = [[NXMMember alloc] initWithMemberId:memberJson[@"member_id"] conversationId:convId user:memberJson[@"user_id"] name:memberJson[@"name"] state:memberJson[@"state"]];

            member.inviteDate = memberJson[@"timestamp"][@"invited"]; // TODO: NSDate
            member.joinDate = memberJson[@"timestamp"][@"joined"]; // TODO: NSDate
            member.leftDate = memberJson[@"timestamp"][@"left"]; // TODO: NSDate
            
            [members addObject:member];
        }

        completionBlock(nil, details);
    }];
    
    return YES;
}


- (void)createConversation:(nonnull NXMCreateConversationRequest*)createConversationRequest
             responseBlock:(void (^_Nullable)(NSError * _Nullable error, NSString * _Nullable  conversationId))responseBlock
{
    NSError *jsonErr;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:@{@"display_name": createConversationRequest.displayName} options:0 error: &jsonErr];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/conversations", self.baseUrl]];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    [self addHeader:request];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:jsonData];
    
    [self executeRequest:request responseBlock:^(NSError * _Nullable error, NSDictionary * _Nullable data) {
        if (error) {
            NSError *resError = [[NSError alloc] initWithDomain:NXMStitchErrorDomain code:[NXMErrorParser parseError:data] userInfo:nil];
            responseBlock(resError, nil);
            return;
        }
        
        //NXMConversation *conversation
        NSString *convId = data[@"id"];
        if (!convId) {
            // TODO: error conv failed
            responseBlock([[NSError alloc] initWithDomain:@"f" code:0 userInfo:nil], nil);
            return;
        }
        
        responseBlock(nil, convId);
        
    }];
}

- (void)addUserToConversation:(nonnull NXMAddUserRequest*)addUserRequest completionBlock:(void (^_Nullable)(NSError * _Nullable error, NSDictionary *))compeltionBlock{
    NSDictionary *dict = @{
                           @"user_id": addUserRequest.userID,
                           @"action": @"join",
                           @"channel": @{
                                   @"type": @"app"
                                   }
                           };
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/conversations/%@/members", self.baseUrl, addUserRequest.conversationID]];
    
    [self requestToServer:dict url:url httpMethod:@"POST" completionBlock:^(NSError * _Nullable error, NSDictionary * _Nullable data) {
        compeltionBlock(error,nil);
    }];
}

- (void)inviteUserToConversation:(nonnull NXMInviteUserRequest *)inviteUserRequest
        completionBlock:(void (^_Nullable)(NSError * _Nullable error, NSDictionary * _Nullable data))completionBlock{
    NSDictionary *dict = @{
                           @"user_id": inviteUserRequest.userID,
                           @"action": @"invite",
                           @"channel": @{
                                   @"type": @"app"
                                   }
                           };
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/conversations/%@/members", self.baseUrl, inviteUserRequest.conversationID]];
    
    [self requestToServer:dict url:url httpMethod:@"POST" completionBlock:^(NSError * _Nullable error, NSDictionary * _Nullable data) {
        completionBlock(error,nil);
    }];
}

- (void)joinMemberToConversation:(nonnull NXMJoinMemberRequest *)joinMembetRequest completionBlock:(void (^_Nullable)(NSError * _Nullable error,NSDictionary * _Nullable data))completionBlock{
    NSDictionary *dict = @{
                           @"member_id": joinMembetRequest.memberID,
                           @"action": @"join",
                           @"channel": @{
                                   @"type": @"app"
                                   }
                           };
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/conversations/%@/members", self.baseUrl, joinMembetRequest.conversationID]];
    
    [self requestToServer:dict url:url httpMethod:@"POST" completionBlock:^(NSError * _Nullable error, NSDictionary * _Nullable data) {
        completionBlock(error,nil);
    }];
}

- (void)removeMemberFromConversation:(nonnull NXMRemoveMemberRequest *)removeMemberRequest
            completionBlock:(void (^_Nullable)(NSError * _Nullable error,NSDictionary * _Nullable data))completionBlock{
    NSDictionary *dict = @{
                           };
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/conversations/%@/members/%@", self.baseUrl, removeMemberRequest.conversationID, removeMemberRequest.memberID]];
    
    [self requestToServer:dict url:url httpMethod:@"DELETE" completionBlock:^(NSError * _Nullable error, NSDictionary * _Nullable data) {
        completionBlock(error,nil);
    }];
}


- (void)sendTextToConversation:(nonnull NXMSendTextEventRequest*)sendTextEventRequest
            completionHandler:(void (^_Nullable)(NSError * _Nullable error, NSString * _Nullable textId))completionHandler {
    NSDictionary *dict = @{
                           @"from": sendTextEventRequest.memberID,
                           @"type": @"text",
                           @"body": @{
                                   @"text": sendTextEventRequest.textToSend
                                   }
                           };
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/conversations/%@/events", self.baseUrl, sendTextEventRequest.conversationID]];
    
    [self requestToServer:dict url:url httpMethod:@"POST" completionBlock:^(NSError * _Nullable error, NSDictionary * _Nullable data) {
        NSString *textId = data[@"id"];
        completionHandler(error, textId);
    }];
}
- (void)deleteTextFromConversation:(nonnull NXMDeleteEventRequest*)deleteEventRequest
            completionBlock:(void (^_Nullable)(NSError * _Nullable error, NSDictionary * _Nullable data))completionBlock{
    NSDictionary *dict = @{
                           @"from": deleteEventRequest.memberID,
                           };
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/conversations/%@/events/%@", self.baseUrl, deleteEventRequest.conversationID,deleteEventRequest.eventID]];
    
    NSString* requestType = @"DELETE";
    [self requestToServer:dict url:url httpMethod:requestType completionBlock:completionBlock];
}

- (BOOL)getConversationsPaging:( NSString* _Nullable )name dateStart:( NSString* _Nullable )dateStart  dateEnd:( NSString* _Nullable )dateEnd pageSize:(long)pageSize recordIndex:(long)recordIndex order:( NSString* _Nullable )order completionBlock:(void (^_Nullable)(NSError * _Nullable error, NSArray<NXMConversationDetails*> * _Nullable data))completionBlock{
    NSDictionary *dict = @{
                           };
    //TODO:for now we get the first 100 conversations
    //we need to have support in the server to get all the conversations
    NSString* vars = @"";
    if (pageSize > 0){
        vars = [NSString stringWithFormat:@"pageSize:%ld",MIN(100,pageSize)];
    }
    if (recordIndex > 0){
        vars = [NSString stringWithFormat:@"%@&&recordIndex:%ld",vars,recordIndex];
    }
    if (name != nil){
        vars = [NSString stringWithFormat:@"%@&&name:%@",vars,name];
    }
    if (dateStart != nil){
        vars = [NSString stringWithFormat:@"%@&&dateStart:%@",vars,dateStart];
    }
    if (dateEnd != nil){
        vars = [NSString stringWithFormat:@"%@&&dateEnd:%@",vars,dateEnd];
    }
    if (order != nil){
        vars = [NSString stringWithFormat:@"%@&&order:%@",vars,order];
    }
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/conversations?%@", self.baseUrl, vars]];
    
    NSString* requestType = @"GET";
    [self requestToServer:dict url:url httpMethod:requestType completionBlock:^(NSError * _Nullable error, NSDictionary * _Nullable data){
        if (data != nil){
            NSLog(@"getAllConversations result %@",data);
            NSMutableArray *conversations = [[NSMutableArray alloc] init];
            for (NSDictionary* conversationJson in data[@"_embedded"][@"conversations"]){
                NXMConversationDetails *details = [NXMConversationDetails alloc];
                details.name = conversationJson[@"name"];
                details.uuid = conversationJson[@"uuid"];
                [conversations addObject:details];
            }
            completionBlock(nil, conversations);
        }
        else{
            completionBlock(error,nil);
        }
    }];
    return YES;
}


- (void)getConversations:(nonnull NXMGetConversationsRequest*)getConvetsationsRequest
         completionBlock:(void (^_Nullable)(NSError * _Nullable error, NSArray<NXMConversationDetails *> * _Nullable data))completionBlock
{
    NSDictionary *dict = @{
                           };
    //TODO:for now we get the first 100 conversations
    //we need to have support in the server to get all the conversations
    NSString* vars = @"";
    if (getConvetsationsRequest.pageSize > 0){
        vars = [NSString stringWithFormat:@"pageSize:%ld",MIN(100,getConvetsationsRequest.pageSize)];
    }
    if (getConvetsationsRequest.recordIndex > 0){
        vars = [NSString stringWithFormat:@"%@&&recordIndex:%ld",vars,getConvetsationsRequest.recordIndex];
    }
    if (getConvetsationsRequest.name != nil){
        vars = [NSString stringWithFormat:@"%@&&name:%@",vars,getConvetsationsRequest.name];
    }
    if (getConvetsationsRequest.dateStart != nil){
        vars = [NSString stringWithFormat:@"%@&&dateStart:%@",vars,getConvetsationsRequest.dateStart];
    }
    if (getConvetsationsRequest.dateEnd != nil){
        vars = [NSString stringWithFormat:@"%@&&dateEnd:%@",vars,getConvetsationsRequest.dateEnd];
    }
    if (getConvetsationsRequest.order != nil){
        vars = [NSString stringWithFormat:@"%@&&order:%@",vars,getConvetsationsRequest.order];
    }
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/conversations?%@", self.baseUrl, vars]];
    
    NSString* requestType = @"GET";
    [self requestToServer:dict url:url httpMethod:requestType completionBlock:^(NSError * _Nullable error, NSDictionary * _Nullable data){
        if (data != nil){
            NSLog(@"getAllConversations result %@",data);
            NSMutableArray *conversations = [[NSMutableArray alloc] init];
            for (NSDictionary* conversationJson in data[@"_embedded"][@"conversations"]){
                NXMConversationDetails *details = [NXMConversationDetails alloc];
                details.name = conversationJson[@"name"];
                details.uuid = conversationJson[@"uuid"];
                [conversations addObject:details];
            }
            completionBlock(nil, conversations);
        }
        else{
            completionBlock(error,nil);
        }
    }];
}
- (void)getConversationDetails:(nonnull NSString*)conversationId
        completionBlock:(void (^_Nullable)(NSError * _Nullable error, NXMConversationDetails * _Nullable data))completionBlock{
    NSDictionary *dict = @{
                           };
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/conversations/%@", self.baseUrl, conversationId]];
    
    NSString* requestType = @"GET";
    [self requestToServer:dict url:url httpMethod:requestType completionBlock:^(NSError * _Nullable error, NSDictionary * _Nullable data){
        if (data != nil){
            NSLog(@"getConversationPressed result %@",data);
            NSString *convId = @"uuid";
            NXMConversationDetails *details = [[NXMConversationDetails alloc] initWithId:convId];
            details.name = data[@"name"];
            details.created = data[@"timestamp"][@"created"];
            details.sequence_number = [data[@"sequence_number"] intValue];
            details.properties = data[@"properties"];
            details.uuid = data[@"uuid"];
            
            NSMutableArray *members = [[NSMutableArray alloc] init];
            
            for (NSDictionary* memberJson in data[@"members"]) {
                NXMMember *member = [[NXMMember alloc] initWithMemberId:memberJson[@"member_id"] conversationId:convId user:memberJson[@"user_id"] name:memberJson[@"name"] state:memberJson[@"state"]];
                
                member.inviteDate = memberJson[@"timestamp"][@"invited"]; // TODO: NSDate
                member.joinDate = memberJson[@"timestamp"][@"joined"]; // TODO: NSDate
                member.leftDate = memberJson[@"timestamp"][@"left"]; // TODO: NSDate
                
                [members addObject:member];
            }
            completionBlock(nil, details);
        }
        else{
            completionBlock(error,nil);
        }
    }];
}


- (void)getUser:(nonnull NSString*)userId
        completionBlock:(void (^_Nullable)(NSError * _Nullable error, NXMUser * _Nullable data))completionBlock{
    NSDictionary *dict = @{
                           };
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@", self.baseUrl, userId]];
    
    NSString* requestType = @"GET";
    [self requestToServer:dict url:url httpMethod:requestType completionBlock:^(NSError * _Nullable error, NSDictionary * _Nullable data){
        if (data != nil){
            NSLog(@"getUser result %@",data);
            NXMUser *user = [NXMUser alloc];
            user.name = data[@"name"];
            user.uuid = data[@"id"];
           
            completionBlock(nil, user);
        }
        else{
            completionBlock(error,nil);
        }
    }];
}
#pragma mark - private

- (void)requestToServer:(nonnull NSDictionary*)dict url:(nonnull NSURL*)url httpMethod:(nonnull NSString*)httpMethod completionBlock:(void (^_Nullable)(NSError * _Nullable error, NSDictionary * _Nullable data))completionBlock{
    NSError *jsonErr;
    
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error: &jsonErr];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    
    [self addHeader:request];
    [request setHTTPMethod:httpMethod];
    [request setHTTPBody:jsonData];
    
    [self executeRequest:request responseBlock:completionBlock];
}

- (void)addHeader:(NSMutableURLRequest *)request {
    [request setValue:[NSString stringWithFormat:@"bearer %@", self.token] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
}

- (void)executeRequest:(NSURLRequest *)request  responseBlock:(void (^_Nullable)(NSError * _Nullable error, NSDictionary *      _Nullable data))responseBlock {
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            // TODO: network error
            responseBlock(error, nil);
            NSLog(@"Got response %@ with error %@.\n", response, error);
            return;
        }
        
        if (((NSHTTPURLResponse *)response).statusCode != 200){
            // TODO: map code from error msg
            NSError *resError = [[NSError alloc] initWithDomain:NXMStitchErrorDomain code:[NXMErrorParser parseErrorWithData:data] userInfo:nil];
            responseBlock(resError, nil);
            return;
        }
        
        
        NSError *jsonError;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!jsonDict || jsonError) {
            // TODO: map code from error msg
            NSError *resError = [[NSError alloc] initWithDomain:NXMStitchErrorDomain code:[NXMErrorParser parseErrorWithData:data] userInfo:nil];
            responseBlock(resError, nil);
            return;
        }
        
        responseBlock(nil, jsonDict);
        
    }] resume];
}


@end
