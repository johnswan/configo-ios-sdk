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
#import "CFGNetworkController.h"

#import "CFGConstants.h"
#import "CFGResponse.h"

#import <NNLibraries/NNLibrariesEssentials.h>
#import <NNLibraries/NNReachabilityManager.h>

@import CoreTelephony;

#pragma mark - Constants

//NSNotification domains constants
NSString *const ConfigoConfigurationLoadCompleteNotification = @"com.configo.config.loadFinished";
NSString *const ConfigoConfigurationLoadErrorNotification = @"com.configo.config.loadError";
NSString *const ConfigoNotificationUserInfoErrorKey = @"configoError";


#pragma mark - Private Declarations

@interface Configo ()
@property (nonatomic, copy) NSString *devKey;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, strong) CFGConfigoDataController *configoDataController;
@property (nonatomic, strong) CFGNetworkController *networkController;

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
        _networkController = [[CFGNetworkController alloc] init];
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
    
    NSDictionary *configoData = [_configoDataController configoDataForRequest];
    [_networkController requestConfigWithDevKey: _devKey appId: _appId configoData: configoData callback: ^(CFGResponse *response, NSError *error) {
        if(response) {
            _state = CFGConfigLoadedFromServer;
            _configoResponse = response;
            
            [_configoDataController saveConfigoDataWithDevKey: _devKey appId: _appId];
            [self saveResponse: _configoResponse withDevKey: _devKey withAppId: _appId];
            
            if(!_activeConfigoResponse || _dynamicallyRefreshValues) {
                _activeConfigoResponse = _configoResponse;
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName: ConfigoConfigurationLoadCompleteNotification object: self userInfo: [self rawConfig]];
        } else {
            _state = CFGConfigFailedLoading;
            NNLogDebug(@"Loading Config: Error", error);
            NSDictionary *userInfo = @{ConfigoNotificationUserInfoErrorKey : error};
            [[NSNotificationCenter defaultCenter] postNotificationName: ConfigoConfigurationLoadErrorNotification object: self userInfo: userInfo];
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

- (NSDictionary *)rawConfig {
    return _activeConfigoResponse.config;
}

- (id)configValueForKeyPath:(NSString *)keyPath {
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
