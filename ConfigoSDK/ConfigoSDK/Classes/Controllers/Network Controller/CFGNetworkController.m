//
//  CFGNetworkController.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 27/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import "CFGNetworkController.h"
#import "CFGConstants.h"
#import "CFGResponse.h"
#import "CFGResponseHeader.h"
#import "CFGInternalError.h"

#import <NNLibraries/NNLibrariesEssentials.h>
#import <NNLibraries/NNURLConnectionManager.h>

//HTTP header keys constants
static NSString *const kHTTPHeaderKey_authHeader = @"x-configo-auth";
static NSString *const kHTTPHeaderKey_devKey = @"x-configo-devKey";
static NSString *const kHTTPHeaderKey_appId = @"x-configo-appId";

//HTTP JSON Response key consants
static NSString *const kResponseKey_header = @"header";
static NSString *const kResponseKey_response = @"response";

@implementation CFGNetworkController

- (void)requestConfigWithDevKey:(NSString *)devKey appId:(NSString *)appId configoData:(NSDictionary *)data callback:(CFGConfigLoadCallback)callback {
    NNLogDebug(@"Loading Config: start", nil);
    
    NNURLConnectionManager *connectionMgr = [NNURLConnectionManager sharedManager];
    
    NSDictionary *headers = @{kHTTPHeaderKey_authHeader : @"natanavra",
                              kHTTPHeaderKey_devKey : devKey,
                              kHTTPHeaderKey_appId : appId};
    [connectionMgr setHttpHeaders: headers];
    connectionMgr.requestSerializer = [NNJSONRequestSerializer serializer];
    connectionMgr.responseSerializer = [NNJSONResponseSerializer serializer];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary: data];
    
    NSURL *baseConfigURL = [CFGConstants getConfigURL];
    NNLogDebug(@"Loading Config: GET", (@{@"URL" : baseConfigURL, @"Headers" : headers, @"Params" : params}));
    
    [connectionMgr GET: baseConfigURL parameters: params completion: ^(NSHTTPURLResponse *response, id object, NSError *error) {
        NNLogDebug(@"LoadingConfig: HTTPResponse", response);
        NSError *retError = error;
        
        CFGResponse *configoResponse = nil;
        if([object isKindOfClass: [NSDictionary class]]) {
            configoResponse = [[CFGResponse alloc] initWithDictionary: object];
            CFGResponseHeader *responseHeader = [configoResponse responseHeader];
            if(responseHeader.internalError) {
                NNLogDebug(@"Loading Config: Internal error", responseHeader.internalError);
                retError = [responseHeader.internalError error];
            } else if(configoResponse) {
                NNLogDebug(@"Loading Config: Done", configoResponse.config);
            } else {
                retError = [NSError errorWithDomain: @"com.configo.config.badResponse" code: 41 userInfo: nil];
            }
        }
        
        if(callback) {
            callback(configoResponse, retError);
        }
    }];
}

@end
