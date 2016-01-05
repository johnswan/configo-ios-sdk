//
//  CFGNetworkController.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 27/08/15.
//  Copyright (c) 2015 Configo. All rights reserved.
//

#import "CFGNetworkController.h"
#import "CFGConstants.h"
#import "CFGResponse.h"
#import "CFGResponseHeader.h"
#import "CFGInternalError.h"

#import "NNLibrariesEssentials.h"
#import "NNURLConnectionManager.h"

//HTTP header keys constants
static NSString *const kHTTPHeaderKey_authHeader = @"x-configo-auth";
static NSString *const kHTTPHeaderKey_devKey = @"x-configo-devKey";
static NSString *const kHTTPHeaderKey_appId = @"x-configo-appId";

//HTTP GET key constants
static NSString *const kGETKey_deviceId = @"deviceId";

//HTTP JSON Response key consants
static NSString *const kResponseKey_header = @"header";
static NSString *const kResponseKey_response = @"response";
static NSString *const kResponseKey_shouldUpdate = @"shouldUpdate";


@interface CFGNetworkController ()
@property (nonatomic, copy) NSString *devKey;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic) BOOL pollingStatus;
@end


@implementation CFGNetworkController

- (instancetype)initWithDevKey:(NSString *)devKey appId:(NSString *)appId {
    if(self = [super init]) {
        self.devKey = devKey;
        self.appId = appId;
    }
    return self;
}

- (void)requestConfigWithConfigoData:(NSDictionary *)data callback:(CFGConfigLoadCallback)callback {
    NNLogDebug(@"Loading Config: start", nil);
    
    NSDictionary *headers = [self requestHeaders];
    
    NNURLConnectionManager *connectionMgr = [NNURLConnectionManager sharedManager];
    [connectionMgr setHttpHeaders: headers];
    connectionMgr.requestSerializer = [NNJSONRequestSerializer serializer];
    connectionMgr.responseSerializer = [NNJSONResponseSerializer serializer];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary: data];
    
    NSURL *baseConfigURL = [CFGConstants getConfigURL];
    NNLogDebug(@"Loading Config: POST", (@{@"URL" : baseConfigURL, @"Headers" : headers, @"Params" : params}));
    
    [connectionMgr POST: baseConfigURL parameters: params completion: ^(NSHTTPURLResponse *response, id object, NSError *error) {
        //NNLogDebug(@"Loading Config: HTTPResponse", response);
        NNLogDebug(@"Loading Config: Response Data", object);
        NSError *retError = error;
        
        CFGResponse *configoResponse = nil;
        if([object isKindOfClass: [NSDictionary class]]) {
            configoResponse = [[CFGResponse alloc] initWithDictionary: object];
            CFGResponseHeader *responseHeader = [configoResponse responseHeader];
            if(error) {
                NNLogDebug(@"Loading Config: Error", error);
            } else if(responseHeader.internalError) {
                NNLogDebug(@"Loading Config: Internal error", responseHeader.internalError);
                retError = [responseHeader.internalError error];
            } else if(configoResponse) {
                NNLogDebug(@"Loading Config: Done", nil);
            } else {
                retError = [NSError errorWithDomain: @"io.configo.badResponse" code: 40 userInfo: nil];
            }
        }
        
        if(callback) {
            callback(configoResponse, retError);
        }
    }];
}


- (void)pollStatusWithUdid:(NSString *)udid callback:(CFGStatusPollCallback)callback {
    if(_pollingStatus) {
        NNLogDebug(@"Already Polling status", nil);
        return;
    }
    
    NNLogDebug(@"Polling status: start", nil);
    
    _pollingStatus = YES;
    
    NSDictionary *headers = [self requestHeaders];
    
    NNURLConnectionManager *connectionMgr = [NNURLConnectionManager sharedManager];
    [connectionMgr setHttpHeaders: headers];
    connectionMgr.requestSerializer = [NNHTTPRequestSerializer serializer];
    connectionMgr.responseSerializer = [NNJSONResponseSerializer serializer];
    
    NSURL *pollURL = [CFGConstants statusPollURL];
    NSDictionary *params = @{kGETKey_deviceId : udid};
    
    [connectionMgr GET: pollURL parameters: params completion: ^(NSHTTPURLResponse *response, id responseObject, NSError *error) {
        _pollingStatus = NO;
        
//        NNLogDebug(@"Polling Status: HTTPResponse", response);
//        NNLogDebug(@"Polling status: Response data", responseObject);
        
        NSError *retError = error;
        BOOL shouldUpdate = false;
        if(!error && [responseObject isKindOfClass: [NSDictionary class]]) {
            NSDictionary *json = (NSDictionary *)responseObject;
            NSDictionary *headerObj = [NNJSONUtilities validObjectFromObject: json[kResponseKey_header]];
            CFGResponseHeader *header = [[CFGResponseHeader alloc] initWithDictionary: headerObj];
            retError = [header.internalError error];
            
            NSDictionary *responseJson = [NNJSONUtilities validObjectFromObject: json[kResponseKey_response]];
            shouldUpdate = [NNJSONUtilities validBooleanFromObject: responseJson[kResponseKey_shouldUpdate]];
        }
        
        callback(shouldUpdate, retError);
    }];
}

#pragma mark - Helpers

- (NSDictionary *)requestHeaders {
    return @{kHTTPHeaderKey_authHeader : @"natanavra",
             kHTTPHeaderKey_devKey : _devKey,
             kHTTPHeaderKey_appId : _appId};
}


@end
