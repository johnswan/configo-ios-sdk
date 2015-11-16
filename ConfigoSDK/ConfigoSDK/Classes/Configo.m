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
#import <NNLibraries/NNTimer.h>

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
@property (nonatomic, strong) CFGNetworkController *networkController;

@property (nonatomic, strong) CFGResponse *activeConfigoResponse;
@property (nonatomic, strong) CFGResponse *latestConfigoResponse;

@property (nonatomic, copy) CFGCallback listenerCallback;
@property (nonatomic, copy) CFGCallback tempListenerCallback;

@property (nonatomic, copy) NSTimer *pullConfigTimer;
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

+ (instancetype)sharedInstance {
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
        _networkController = [[CFGNetworkController alloc] initWithDevKey: devKey appId: appId];
        
        _latestConfigoResponse = [self responseFromFileWithDevKey: devKey withAppId: appId];
        _activeConfigoResponse = _latestConfigoResponse;
        if(_latestConfigoResponse) {
            _state = CFGConfigLoadedFromStorage;
        } else {
            _state = CFGConfigNotAvailable;
        }
        
        self.listenerCallback = callback;
        
        [self pullConfig];
        [self setupPollingTimer];
    }
    return self;
}

+ (NSString *)VersionString {
    return ConfigoSDKVersion;
}

#pragma mark - Config Handling

- (void)setupPollingTimer {
    _pullConfigTimer = [NSTimer scheduledTimerWithTimeInterval: kPullConfigTimerDelay target: self selector: @selector(checkPolling) userInfo: nil repeats: YES];
}

- (void)checkPolling {
    NNLogDebug(@"TICK - Checking if pullConfig required", nil);
    //If the user's details changed (Device, context, custom id)
    //No loading progress currently
    if([_configoDataController detailsChanged]) {
        NNLogDebug(@"TICK - details changed pullConfig required", nil);
        [self pullConfig];
    } else {
        [self pollStatus];
    }
}

- (void)pollStatus {
    [_networkController pollStatusWithUdid: [_configoDataController udid] callback: ^(BOOL shouldUpdate, NSError *error) {
        if(!error && shouldUpdate) {
            NNLogDebug(@"TICK - shouldUpdate true", nil);
            [self pullConfig];
        } else {
            NNLogDebug(@"TICK - shouldUpdate false", nil);
        }
    }];
}

- (void)forceRefreshValues {
    if(_activeConfigoResponse != _latestConfigoResponse) {
        _activeConfigoResponse = _latestConfigoResponse;
    }
}

- (void)pullConfig {
    [self pullConfig: _tempListenerCallback];
}

- (void)pullConfig:(CFGCallback)callback {
    if(_state == CFGConfigLoadingInProgress) {
        return;
    }
    
    NNLogDebug(@"Loading Config: start", nil);
    
    self.tempListenerCallback = callback;
    
    if([self shouldUpdateActiveConfig]) {
        //Change the current config state only if the user is expecting it. It's possible the user does not need to know about the update.
        _state = CFGConfigLoadingInProgress;
    }
    
    NSDictionary *configoData = [_configoDataController configoDataForRequest];
    [_networkController requestConfigWithConfigoData: configoData callback: ^(CFGResponse *response, NSError *error) {
        if(response && !error) {
            _latestConfigoResponse = response;
            
            [_configoDataController saveConfigoDataWithDevKey: _devKey appId: _appId];
            [self saveResponse: _latestConfigoResponse withDevKey: _devKey withAppId: _appId];
            
            if([self shouldUpdateActiveConfig]) {
                _state = CFGConfigLoadedFromServer;
                _activeConfigoResponse = _latestConfigoResponse;
            }
        }
        //Declare an "error" state only if the config was supposed to be updated. So false states are not reported.
        else if([self shouldUpdateActiveConfig]) {
            _state = CFGConfigFailedLoadingFromServer;
            NNLogDebug(@"Loading Config: Error", error);
        }
        
        if([self shouldUpdateActiveConfig]) {
            //Invoke only if the user was expecting an update to the config
            //Invoke callbacks and send notifications with either success or errors (depends on the error object passed).
            [self sendNotificationWithError: error];
            [self invokeListenersCallbacksWithError: error];
        }
    }];
}

#pragma mark - Setters

- (void)setCallback:(CFGCallback)callback {
    BOOL shouldInvokeCallback = NO;
    
    if(!self.listenerCallback) {
        if(_state == CFGConfigLoadedFromServer && _activeConfigoResponse) {
            shouldInvokeCallback = YES;
        }
    }
    
    self.listenerCallback = callback;
    
    if(shouldInvokeCallback) {
        [self invokeListenersCallbacksWithError: nil];
    }
}

- (void)setCustomUserId:(NSString *)userId {
    [_configoDataController setCustomUserId: userId];
}

- (BOOL)setUserContext:(NSDictionary *)context {
    //Incorrect, will trigger changing the customUserId
    //[self setCustomUserId: nil userContext: context];
    if([NNJSONUtilities isValidJSONObject: context]) {
        [_configoDataController setUserContext: context];
        return YES;
    }
    return NO;
}

- (BOOL)setUserContextValue:(id)value forKey:(NSString *)key {
    if([NNJSONUtilities isValidJSONObject: value]) {
        [_configoDataController setUserContextValue: value forKey: key];
        return YES;
    }
    return NO;
    /*if(contextChanged) {
     //If user calls this method consecutively - this will be triggered every time.
     //[self pullConfig];
     }*/
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

- (id)configValueForKeyPath:(NSString *)keyPath fallbackValue:(id)fallbackValue {
    id val = [self configValueForKeyPath: keyPath];
    return val ?: fallbackValue;
}

#pragma mark - Feature Getters

- (NSArray *)featuresList {
    return _activeConfigoResponse.features;
}

- (BOOL)featureFlagForKey:(NSString *)key {
    return [self featureFlagForKey: key fallback: NO];
}

- (BOOL)featureFlagForKey:(NSString *)key fallback:(BOOL)fallbackFlag {
    if(!key) {
        return NO;
    }
    
    BOOL retval = NO;
    NSArray *features = [self featuresList];
    retval = [features containsObject: key];
    return retval ?: fallbackFlag;
}

#pragma mark - File Storage

- (BOOL)saveResponse:(CFGResponse *)response withDevKey:(NSString *)devKey withAppId:(NSString *)appId {
    NSError *err = nil;
    BOOL success = [[CFGFileManager sharedManager] saveResponse: response withDevKey: devKey withAppId: appId error: &err];
    NNLogDebug(([NSString stringWithFormat: @"Configo save response to file %@", success ? @"success" : @"failed"]), err);
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

- (BOOL)shouldUpdateActiveConfig {
    //If there's no currently active config (first time load)
    //If the currently active config is loaded from storage.
    //If the user set the 'dynamicalylRefreshValues' to YES.
    //If it's a 'pullConfig' that awaits a callback
    return (!_activeConfigoResponse ||
            _state == CFGConfigLoadedFromStorage ||
            _state == CFGConfigLoadingInProgress ||
            _dynamicallyRefreshValues ||
            _tempListenerCallback);
}

- (void)invokeListenersCallbacksWithError:(NSError *)error {
    if(_listenerCallback) {
        _listenerCallback(error, [self rawConfig], [self featuresList]);
    }
    if(_tempListenerCallback) {
        _tempListenerCallback(error, [self rawConfig], [self featuresList]);
        self.tempListenerCallback = nil;
    }
}

- (void)sendNotificationWithError:(NSError *)err {
    NSString *notificationName = nil;
    NSDictionary *userInfo = nil;
    if(err) {
        userInfo = @{ConfigoNotificationUserInfoErrorKey : err};
        notificationName = ConfigoConfigurationLoadErrorNotification;
    } else {
        userInfo = @{ConfigoNotificationUserInfoRawConfigKey : [self rawConfig],
                     ConfigoNotificationUserInfoFeaturesListKey : [self featuresList]};
        notificationName = ConfigoConfigurationLoadCompleteNotification;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName: notificationName object: self userInfo: userInfo];
}

#pragma mark - DEBUG only code
#ifdef DEBUG

+ (NSString *)developmentDevKey {
    NSString *retval = nil;
    switch ([CFGConstants currentEnvironment]) {
        case CFGEnvironmentDevelopment: {
            retval = @"6cfadcead7bf0514480e8d1d8f062b72";
            break;
        }
        case CFGEnvironmentProduction: {
            retval = @"2f0ad31bb0b266507483c96cc9f24cf0";
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
            retval = @"13a3e1b5ce827c75a941380de210a94f";
            break;
        }
        case CFGEnvironmentProduction: {
            retval = @"28f4d6feedbd35e42e431b90dec534cd";
            break;
        }
        default:
            break;
    }
    return retval;
}

#endif

@end
