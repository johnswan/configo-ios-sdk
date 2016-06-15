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
#import "NNSecurity.h"

//HTTP header keys constants
static NSString *const kHTTPHeaderKey_timestamp = @"x-configo-timestamp";
static NSString *const kHTTPHeaderKey_devKey = @"x-configo-devKey";
static NSString *const kHTTPHeaderKey_appId = @"x-configo-appId";

//HTTP GET key constants
static NSString *const kGETKey_deviceId = @"deviceId";

//HTTP JSON Response key consants
static NSString *const kResponseKey_header = @"header";
static NSString *const kResponseKey_response = @"response";
static NSString *const kResponseKey_shouldUpdate = @"shouldUpdate";
static NSString *const kResponseKey_message = @"message";


@interface CFGNetworkController ()
@property (nonatomic, copy) NSString *devKey;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic) BOOL pollingStatus;
@end


@implementation CFGNetworkController

- (instancetype)init {
    NSAssert(false, @"Use `initWithDevKey:appId:` instead.");
    return nil;
}

- (instancetype)initWithDevKey:(NSString *)devKey appId:(NSString *)appId {
    if(self = [super init]) {
        self.devKey = devKey;
        self.appId = appId;
    }
    return self;
}

- (void)requestConfigWithConfigoData:(NSDictionary *)data callback:(CFGConfigLoadCallback)callback {
    NNLogDebug(@"Loading Config: start", nil);
    
    NNURLConnectionManager *connectionMgr = [NNURLConnectionManager sharedManager];
    connectionMgr.requestSerializer = [NNJSONRequestSerializer serializer];
    connectionMgr.responseSerializer = [NNJSONResponseSerializer serializer];
    
    NSURL *configUrl = [CFGConstants getConfigURL];
    NSDictionary *headers = [self requestHeaders];
    NSNumber *timestampNumber = headers[kHTTPHeaderKey_timestamp];
    NSInteger timestamp = [timestampNumber longValue];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary: data];
    
    NNLogDebug(@"Loading Config: POST", (@{@"URL" : configUrl, @"Headers" : headers, @"Params" : params}));
    
    [connectionMgr POST: configUrl headers: headers parameters: params completion: ^(NSHTTPURLResponse *response, id object, NSError *error) {
        //NNLogDebug(@"Loading Config: HTTPResponse", response);
        NNLogDebug(@"Loading Config: Response Data", object);
        NSError *retError = nil;
        CFGResponse *configoResponse = [[CFGResponse alloc] initWithDictionary: object];

        if(!error && !configoResponse) {
            retError = [NSError errorWithDomain: CFGErrorDomain code: 40 userInfo: nil];
        } else if(error) {
            NNLogDebug(@"Loading Config: Error", error);
            retError = error;
        } else if(configoResponse) {
            CFGResponseHeader *responseHeader = [configoResponse responseHeader];
            if(responseHeader.internalError) {
                NNLogDebug(@"Loading Config: Internal error", responseHeader.internalError);
                retError = [responseHeader.internalError error];
            } else {
                NNLogDebug(@"Loading Config: Done", nil);
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
        
    NNURLConnectionManager *connectionMgr = [NNURLConnectionManager sharedManager];
    connectionMgr.requestSerializer = [NNHTTPRequestSerializer serializer];
    connectionMgr.responseSerializer = [NNJSONResponseSerializer serializer];
    
    NSURL *pollURL = [CFGConstants statusPollURL];
    NSDictionary *params = @{kGETKey_deviceId : udid};
    
    [connectionMgr GET: pollURL headers: [self requestHeaders] parameters: params completion: ^(NSHTTPURLResponse *response, id responseObject, NSError *error) {
        _pollingStatus = NO;
        
//        NNLogDebug(@"Polling Status: HTTPResponse", response);
        NNLogDebug(@"Polling status: Response data", responseObject);
        
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
        
        if(callback) {
            callback(shouldUpdate, retError);
        }
    }];
}

- (void)sendEvents:(NSArray *)events withUdid:(NSString *)udid withCallback:(CFGSendEventsCallback)callback {
    if(!udid || events.count == 0) {
        NNLogDebug(@"Bad params provided", nil);
    } else {
        NNURLConnectionManager *mgr = [NNURLConnectionManager sharedManager];
        mgr.requestSerializer = [NNJSONRequestSerializer serializer];
        mgr.responseSerializer = [NNJSONResponseSerializer serializer];
        
        NSURL *url = [CFGConstants eventsPushUrl];
        NSDictionary *params = @{@"udid" : udid,
                                 @"events" : events};
        NNLogDebug(@"Sending events", params);
        [mgr POST: url headers: [self requestHeaders] parameters: params completion: ^(NSHTTPURLResponse *response, id responseObject, NSError *error) {
            NNLogDebug(@"Send events response data:", responseObject);
            
            NSError *retError = error;
            BOOL success = NO;
            if([responseObject isKindOfClass: [NSDictionary class]] && !error) {
                NSDictionary *json = (NSDictionary *)responseObject;
                CFGResponseHeader *responseHeader = [[CFGResponseHeader alloc] initWithDictionary: json[kResponseKey_header]];
                if(responseHeader.internalError) {
                    retError = [responseHeader.internalError error];
                } else {
                    NSDictionary *responseContent = json[kResponseKey_response];
                    NSString *message = responseContent[kResponseKey_message];
                    success = [message caseInsensitiveCompare: @"success"] == NSOrderedSame;
                    if(!success) {
                        NSDictionary *userinfo = nil;
                        if(message) {
                            userinfo = @{@"message" : message};
                        }
                        retError = [NSError errorWithDomain: CFGErrorDomain code: CFGErrorRequestFailed userInfo: userinfo];
                    }
                }
            }
            
            if(!success && retError) {
                NNLogDebug(@"Failed to push events", retError);
            }
            if(callback) {
                callback(success, retError);
            }
        }];
    }
}

#pragma mark - Helpers

- (NSDictionary *)requestHeaders {
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    NSNumber *timestamp = [NSNumber numberWithLong: (long)interval];
    return @{
             kHTTPHeaderKey_timestamp : timestamp,
             kHTTPHeaderKey_devKey : _devKey,
             kHTTPHeaderKey_appId : _appId
             };
}


@end
