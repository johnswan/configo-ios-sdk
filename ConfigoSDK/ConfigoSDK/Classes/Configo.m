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
#import <NNLibraries/UIColor+NNAdditions.h>

@import CoreTelephony;

#pragma mark - Constants

//NSNotification domains constants
NSString *const ConfigoConfigurationLoadCompleteNotification = @"com.configo.config.loadFinished";
NSString *const ConfigoConfigurationLoadErrorNotification = @"com.configo.config.loadError";
NSString *const ConfigoNotificationUserInfoErrorKey = @"configoError";
NSString *const ConfigoNotificationUserInfoRawConfigKey = @"rawConfig";
NSString *const ConfigoNotificationUserInfoFeaturesListKey = @"featuresList";


#pragma mark - Private Declarations

@interface Configo ()
@property (nonatomic, copy) NSString *devKey;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, strong) CFGConfigoDataController *configoDataController;

@property (nonatomic, strong) CFGResponse *activeConfigoResponse;
@property (nonatomic, strong) CFGResponse *latestConfigoResponse;

@property (nonatomic, copy) CFGCallback listenerCallback;
@property (nonatomic, copy) CFGCallback tempListenerCallback;
@end

#pragma mark - Implementation

@implementation Configo

#pragma mark - Init

static id _shared = nil;

+ (void)initWithDevKey:(NSString *)devKey appId:(NSString *)appId {
    [self initWithDevKey: devKey appId: appId callback: nil];
}

+ (void)initWithDevKey:(NSString *)devKey appId:(NSString *)appId callback:(CFGCallback)callback {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[self alloc] initWithDevKey: devKey appId: appId callback: callback];
    });
}

+ (instancetype)sharedConfigo {
    return _shared;
}

- (instancetype)init {
    return nil;
}

- (instancetype)initWithDevKey:(NSString *)devKey appId:(NSString *)appId callback:(CFGCallback)callback {
    if(!devKey || !appId) {
        return nil;
    }
    
    if(self = [super init]) {
        NNLogDebug(@"Configo: Init", (@{@"devKey" : devKey, @"appId" : appId}));
        [NNReachabilityManager sharedManager];
        
        self.devKey = devKey;
        self.appId = appId;
        _configoDataController = [[CFGConfigoDataController alloc] initWithDevKey: devKey appId: appId];
        
        _latestConfigoResponse = [self responseFromFileWithDevKey: devKey withAppId: appId];
        _activeConfigoResponse = _latestConfigoResponse;
        if(_latestConfigoResponse) {
            _state = CFGConfigLoadedFromStorage;
        } else {
            _state = CFGConfigNotAvailable;
        }
        
        self.listenerCallback = callback;
        [self pullConfig];
    }
    return self;
}

+ (NSString *)sdkVersionString {
    return [CFGConstants sdkVersionString];
}

#pragma mark - Config Handling

- (void)forceRefreshValues {
    if(_activeConfigoResponse != _latestConfigoResponse) {
        _activeConfigoResponse = _latestConfigoResponse;
    }
}

- (void)pullConfig {
    [self pullConfig: nil];
}

- (void)pullConfig:(CFGCallback)callback {
    NNLogDebug(@"Loading Config: start", nil);
    _state = CFGConfigLoadingInProgress;
    
    self.tempListenerCallback = callback;
    
    NSDictionary *configoData = [_configoDataController configoDataForRequest];
    [CFGNetworkController requestConfigWithDevKey: _devKey appId: _appId configoData: configoData callback: ^(CFGResponse *response, NSError *error) {
        if(response) {
            _state = CFGConfigLoadedFromServer;
            _latestConfigoResponse = response;
            
            [_configoDataController saveConfigoDataWithDevKey: _devKey appId: _appId];
            [self saveResponse: _latestConfigoResponse withDevKey: _devKey withAppId: _appId];
            
            if(!_activeConfigoResponse || _dynamicallyRefreshValues) {
                _activeConfigoResponse = _latestConfigoResponse;
            }
            
            [self invokeListenerCallback];
            [self invokeAndDeleteTempCallback];
            [self invokeSuccessNotification];
        } else {
            _state = CFGConfigFailedLoadingFromServer;
            NNLogDebug(@"Loading Config: Error", error);
            [self invokeErrorNotification: error];
        }
    }];
}

#pragma mark - Setters

- (void)setCallback:(CFGCallback)callback {
    self.listenerCallback = callback;
    if(_state == CFGConfigLoadedFromServer && _activeConfigoResponse) {
        [self invokeListenerCallback];
    }
}

- (void)setCustomUserId:(NSString *)userId {
    //Incorrect, will trigger changing the customUserId
    [_configoDataController setCustomUserId: userId];
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

- (void)setUserContext:(NSDictionary *)context {
    //Incorrect, will trigger changing the customUserId
    //[self setCustomUserId: nil userContext: context];
    [_configoDataController setUserContext: context];
}

- (void)setUserContextValue:(id)value forKey:(NSString *)key {
    BOOL contextChanged = [_configoDataController setUserContextValue: value forKey: key];
    if(contextChanged) {
        //If user calls this method consecutively - this will be triggered every time.
        //[self pullConfig];
    }
}

#pragma mark - Config Getters

- (NSDictionary *)rawConfig {
    return _activeConfigoResponse.config;
}

- (id)configValueForKeyPath:(NSString *)keyPath {
    NSDictionary *config = [self rawConfig];
    id value = [NNJSONUtilities valueForKeyPath: keyPath inObject: config];
    return value;
}

#pragma mark - Feature Getters

- (NSArray *)featuresList {
    return _activeConfigoResponse.features;
}

- (BOOL)featureFlagForKey:(NSString *)key {
    if(!key) {
        return NO;
    }
    
    BOOL retval = NO;
    NSArray *features = [self featuresList];
    retval = [features containsObject: key];
    return retval;
}

#pragma mark - File Storage

- (BOOL)saveResponse:(CFGResponse *)response withDevKey:(NSString *)devKey withAppId:(NSString *)appId {
    NSError *err = nil;
    BOOL success = [[CFGFileManager sharedManager] saveResponse: response withDevKey: devKey withAppId: appId error: &err];
    NNLogDebug(([NSString stringWithFormat: @"Configo save response to file %@", success ? @"success" : @"failed"]), (success ? nil : err));
    return success;
}

- (CFGResponse *)responseFromFileWithDevKey:(NSString *)devKey withAppId:(NSString *)appId {
    CFGResponse *retval = nil;
    NSError *err = nil;
    retval = [[CFGFileManager sharedManager] loadLastResponseForDevKey: devKey appId: appId error: &err];
    NNLogDebug(([NSString stringWithFormat: @"Configo load response from file %@", retval ? @"success" : @"failed"]), (retval ? nil : err));
    return retval;
}

#pragma mark - Helpers

- (void)invokeListenerCallback {
    if(_listenerCallback) {
        _listenerCallback([self rawConfig], [self featuresList]);
    }
}

- (void)invokeAndDeleteTempCallback {
    if(_tempListenerCallback) {
        _tempListenerCallback([self rawConfig], [self featuresList]);
        self.tempListenerCallback = nil;
    }
}

- (void)invokeSuccessNotification {
    NSDictionary *userInfo = @{ConfigoNotificationUserInfoRawConfigKey : [self rawConfig],
                               ConfigoNotificationUserInfoFeaturesListKey : [self featuresList]};
    [[NSNotificationCenter defaultCenter] postNotificationName: ConfigoConfigurationLoadCompleteNotification object: self userInfo: userInfo];
}

- (void)invokeErrorNotification:(NSError *)err {
    NSDictionary *userInfo = @{ConfigoNotificationUserInfoErrorKey : err};
    [[NSNotificationCenter defaultCenter] postNotificationName: ConfigoConfigurationLoadErrorNotification
                                                        object: self
                                                      userInfo: userInfo];
}

#pragma mark - DEBUG only code


+ (NSString *)developmentDevKey {
    NSString *retval = nil;
    switch ([CFGConstants currentEnvironment]) {
        case CFGEnvironmentDevelopment: {
            retval = @"YOUR_DEV_KEY";
            break;
        }
        case CFGEnvironmentProduction: {
            retval = @"YOUR_DEV_KEY";
            break;
        }
        default:
            break;
    }
    return retval;
}

+ (NSString *)developmentAppId {
    NSString *retval = nil;
    switch ([CFGConstants currentEnvironment]) {
        case CFGEnvironmentDevelopment: {
            retval = @"YOUR_APP_ID";
            break;
        }
        case CFGEnvironmentProduction: {
            retval = @"9976714e67d629a9b80199e4be40f60e";
            break;
        }
        default:
            break;
    }
    return retval;
}

#endif

@end
