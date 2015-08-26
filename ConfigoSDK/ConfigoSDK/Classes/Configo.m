//
//  Configo.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 16/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import "Configo.h"
#import "CFGFileManager.h"
#import "CFGConfigoDataController.h"

#import "CFGConstants.h"
#import "CFGConfigoData.h"
#import "CFGResponse.h"
#import "CFGResponseHeader.h"
#import "CFGInternalError.h"

#import <NNLibraries/NNLibrariesEssentials.h>
#import <NNLibraries/NNURLConnectionManager.h>
#import <NNLibraries/NNReachabilityManager.h>

@import CoreTelephony;

#pragma mark - Constants

//NSNotification domains constants
NSString *const ConfigoConfigurationLoadCompleteNotification = @"com.configo.config.loadFinished";
NSString *const ConfigoConfigurationLoadErrorNotification = @"com.configo.config.loadError";
NSString *const ConfigoNotificationUserInfoErrorKey = @"configoError";

//Keychain constants
static NSString *const kKeychainKey_deviceDetails = @"deviceDetails";

//HTTP header keys constants
static NSString *const kHTTPHeaderKey_authHeader = @"x-configo-auth";
static NSString *const kHTTPHeaderKey_devKey = @"x-configo-devKey";
static NSString *const kHTTPHeaderKey_appId = @"x-configo-appId";

//HTTP JSON Response key consants
static NSString *const kResponseKey_header = @"header";
static NSString *const kResponseKey_response = @"response";

#pragma mark - Private Declarations

@interface Configo ()
@property (nonatomic, copy) NSString *devKey;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, strong) CFGConfigoDataController *configoDataController;

@property (nonatomic, strong) CFGResponse *activeConfigoResponse;
@property (nonatomic, strong) CFGResponse *configoResponse;
@end

#pragma mark - Implementation

@implementation Configo

#pragma mark - Init

static id _shared = nil;

+ (void)initWithDevKey:(NSString *)devKey appId:(NSString *)appId {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[self alloc] initWithDevKey: devKey appId: appId];
    });
}

+ (instancetype)sharedConfigo {
    return _shared;
}

- (instancetype)init {
    return nil;
}

- (instancetype)initWithDevKey:(NSString *)devKey appId:(NSString *)appId {
    if(!devKey || !appId) {
        return nil;
    }
    
    if(self = [super init]) {
        [NNReachabilityManager sharedManager];
        
        self.devKey = devKey;
        self.appId = appId;
        _configoDataController = [[CFGConfigoDataController alloc] initWithDevKey: devKey appId: appId];
        
        _configoResponse = [self responseFromFileWithDevKey: devKey withAppId: appId];
        _activeConfigoResponse = _configoResponse;
        if(_configoResponse) {
            _state = CFGConfigLoadedFromStorage;
        } else {
            _state = CFGConfigNotAvailable;
        }
        
        [self pullConfig];
        
        NNLogDebug(@"Configo: Init", (@{@"devKey" : devKey, @"appId" : appId}));
    }
    return self;
}

#pragma mark - Config Handling

- (void)refreshValues {
    if(_activeConfigoResponse != _configoResponse) {
        _activeConfigoResponse = _configoResponse;
    }
}

- (void)pullConfig {
    [self pullBaseConfig];
}

- (void)pullBaseConfig {
    NNLogDebug(@"Loading Config: start", nil);
    _state = CFGConfigLoadingInProgress;
    
    NNURLConnectionManager *connectionMgr = [NNURLConnectionManager sharedManager];
    
    NSDictionary *headers = @{kHTTPHeaderKey_authHeader : @"natanavra",
                              kHTTPHeaderKey_devKey : _devKey,
                              kHTTPHeaderKey_appId : _appId};
    [connectionMgr setHttpHeaders: headers];
    connectionMgr.requestSerializer = [NNJSONRequestSerializer serializer];
    connectionMgr.responseSerializer = [NNJSONResponseSerializer serializer];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary: [_configoDataController configoDataForRequest]];
    
    NSURL *baseConfigURL = [CFGConstants getConfigURL];
    NNLogDebug(@"Loading Config: GET", (@{@"URL" : baseConfigURL, @"Headers" : headers, @"Params" : params}));
    
    [connectionMgr GET: baseConfigURL parameters: params completion: ^(NSHTTPURLResponse *response, id object, NSError *error) {
        NNLogDebug(@"LoadingConfig: HTTPResponse", response);
        NSError *retError = error;
        
        if([object isKindOfClass: [NSDictionary class]]) {
            _configoResponse = [[CFGResponse alloc] initWithDictionary: object];
            CFGResponseHeader *responseHeader = [_configoResponse responseHeader];
            if(responseHeader.internalError) {
                _state = CFGConfigFailedLoading;
                NNLogDebug(@"Loading Config: Internal error", responseHeader.internalError);
                retError = [responseHeader.internalError error];
            } else if(_configoResponse) {
                _state = CFGConfigLoadedFromServer;
                [_configoDataController saveConfigDataWithDevKey: _devKey appId: _appId error: nil];
                [self saveResponse: _configoResponse withDevKey: _devKey withAppId: _appId];
                NNLogDebug(@"Loading Config: Done", _configoResponse.config);
            } else {
                _state = CFGConfigFailedLoading;
                retError = [NSError errorWithDomain: @"com.configo.config.badResponse" code: 41 userInfo: nil];
            }
            
            if(!_activeConfigoResponse) {
                _activeConfigoResponse = _configoResponse;
            } else if(_dynamicallyRefreshValues) {
                _activeConfigoResponse = _configoResponse;
            }
        }
        
        if(retError) {
            _state = CFGConfigFailedLoading;
            NNLogDebug(@"Loading Config: Error", retError);
            NSDictionary *userInfo = @{ConfigoNotificationUserInfoErrorKey : retError};
            [[NSNotificationCenter defaultCenter] postNotificationName: ConfigoConfigurationLoadErrorNotification object: self userInfo: userInfo];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName: ConfigoConfigurationLoadCompleteNotification object: self userInfo: [self config]];
        }
    }];
}

#pragma mark - Setters

- (void)setCustomUserId:(NSString *)userId {
    [self setCustomUserId: userId userContext: nil];
}

- (void)setCustomUserId:(NSString *)userId userContext:(NSDictionary *)context {
    [self setCustomUserId: userId userContext: context error: nil];
}

- (void)setCustomUserId:(NSString *)userId userContext:(NSDictionary *)context error:(NSError *)err {
    BOOL userIdChanged = [_configoDataController setCustomUserId: userId];
    BOOL contextChanged = [_configoDataController setUserContext: context];
    if(userIdChanged || contextChanged) {
        [self pullConfig];
    }
}

- (void)setUserContextValue:(id)value forKey:(NSString *)key {
    BOOL contextChanged = [_configoDataController setUserContextValue: value forKey: key];
    if(contextChanged) {
        [self pullConfig];
    }
}

#pragma mark - Getters

- (NSDictionary *)config {
    return _activeConfigoResponse.config;
}

- (id)configForKeyPath:(NSString *)keyPath {
    NSDictionary *config = _activeConfigoResponse.config;
    id value = [NNJSONUtilities valueForKeyPath: keyPath inObject: config];
    return value;
}

#pragma mark - File Storage

- (BOOL)saveResponse:(CFGResponse *)response withDevKey:(NSString *)devKey withAppId:(NSString *)appId {
    NSError *err = nil;
    BOOL success = [[CFGFileManager sharedManager] saveResponse: response withDevKey: devKey withAppId: appId error: &err];
    NNLogDebug(([NSString stringWithFormat: @"Configo save response %@", success ? @"success" : @"failed"]), (success ? nil : err));
    return success;
}

- (CFGResponse *)responseFromFileWithDevKey:(NSString *)devKey withAppId:(NSString *)appId {
    CFGResponse *retval = nil;
    NSError *err = nil;
    retval = [[CFGFileManager sharedManager] loadLastResponseForDevKey: devKey appId: appId error: &err];
    NNLogDebug(([NSString stringWithFormat: @"Configo load response %@", retval ? @"success" : @"failed"]), (retval ? nil : err));
    return retval;
}

@end
