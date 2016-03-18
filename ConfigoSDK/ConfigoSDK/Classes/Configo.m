//
//  Configo.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 16/08/15.
//  Copyright (c) 2015 Configo. All rights reserved.
//

#import "Configo.h"
#import "CFGFileController.h"
#import "CFGConfigoDataController.h"
#import "CFGNetworkController.h"
#import "CFGEventsController.h"
#import "CFGPrivateConfigService.h"
#import "CFGConfigValueFetcher.h"
#import "CFGLogger.h"

#import "CFGConstants.h"
#import "CFGResponse.h"
#import "CFGConfig.h"

#import "NNLibrariesEssentials.h"
#import "NNReachabilityManager.h"

#pragma mark - Constants

//NSNotification domains constants
NSString *const ConfigoConfigurationLoadCompleteNotification = @"io.configo.config.loadFinished";
NSString *const ConfigoConfigurationLoadErrorNotification = @"io.configo.config.loadError";
NSString *const ConfigoNotificationUserInfoErrorKey = @"configoError";
NSString *const ConfigoNotificationUserInfoRawConfigKey = @"rawConfig";
NSString *const ConfigoNotificationUserInfoFeaturesListKey = @"featuresList";


#pragma mark - Private Declarations

@interface Configo ()
@property (nonatomic, copy) NSString *devKey;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, strong) CFGConfigoDataController *configoDataController;
@property (nonatomic, strong) CFGFileController *fileController;
@property (nonatomic, strong) CFGEventsController *eventsController;
@property (nonatomic, strong) CFGNetworkController *networkController;
@property (nonatomic, strong) CFGConfigValueFetcher *configValueFetcher;

@property (nonatomic, strong) CFGResponse *activeConfigoResponse;
@property (nonatomic, strong) CFGResponse *latestConfigoResponse;

@property (nonatomic, copy) CFGCallback listenerCallback;
@property (nonatomic, copy) CFGCallback tempListenerCallback;

@property (nonatomic, copy) NSTimer *pollingTimer;
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
        //Decide if Logging happens or not.
        [self determineShouldLog];
        
        NNLogDebug(@"Configo: Init", (@{@"devKey" : devKey, @"appId" : appId}));
        [CFGLogger logLevel: CFGLogLevelVerbose log: @"Configo Initialized \ndevKey: %@ \nappId: %@", devKey, appId];
        
        [NNReachabilityManager sharedManager];
        
        //Init private config
        [self observePrivateConfig];
        [CFGPrivateConfigService sharedConfigService];
        
        self.devKey = devKey;
        self.appId = appId;
        
        _configoDataController = [[CFGConfigoDataController alloc] initWithDevKey: devKey appId: appId];
        _fileController = [[CFGFileController alloc] initWithDevKey: devKey appId: appId];
        _networkController = [[CFGNetworkController alloc] initWithDevKey: devKey appId: appId];
        _eventsController = [[CFGEventsController alloc] initWithDevKey: devKey appId: appId udid: [_configoDataController udid]];
        _configValueFetcher = [[CFGConfigValueFetcher alloc] init];
        
        _latestConfigoResponse = [self responseFromFileWithDevKey: devKey withAppId: appId];
        _activeConfigoResponse = _latestConfigoResponse;
        if(_latestConfigoResponse) {
            _state = CFGConfigLoadedFromStorage;
            _configValueFetcher.config = _activeConfigoResponse.configObj;
        } else {
            _state = CFGConfigNotAvailable;
        }
        
        [self setCallback: callback];
        
        [self pullConfig];
    }
    return self;
}

+ (NSString *)sdkVersion {
    return ConfigoSDKVersion;
}

#pragma mark - Internal Config

- (void)observePrivateConfig {
    [[NSNotificationCenter defaultCenter] addObserverForName: CFGPrivateConfigLoadedNotification
                                                      object: nil queue: [NSOperationQueue mainQueue]
                                                  usingBlock: ^(NSNotification *note) {
                                                      NNLogDebug(@"New private config, rebooting poll timer", nil);
                                                      [_pollingTimer invalidate];
                                                      //If the config is already loaded, and we only got the internal config, we should start poll.
                                                      //Otherwise, the pullConfig completion will setup the poll timer.
                                                      if(_state == CFGConfigLoadedFromServer) {
                                                          [self setupPollingTimer];
                                                      }
                                                  }];
}

#pragma mark - Polling

- (void)setupPollingTimer {
    NSInteger pollingInterval = CFGPrivateConfigInteger(@"pollingInterval.ios");
    NNLogDebug(@"Setting up polling timer", [NSNumber numberWithInteger: pollingInterval]);
    _pollingTimer = [NSTimer scheduledTimerWithTimeInterval: pollingInterval
                                                     target: self
                                                   selector: @selector(checkPolling)
                                                   userInfo: nil
                                                    repeats: NO];
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
    //This is done to enable pulling polling interval every time.
    //Also to avoid 'invalidate', etc
    [self setupPollingTimer];
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

#pragma mark - Config Handling

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
    
    //Stop the polling timer
    [_pollingTimer invalidate];
    _pollingTimer = nil;
    
    NNLogDebug(@"Loading Config: start", nil);
    
    self.tempListenerCallback = callback;
    
    if([self shouldUpdateActiveConfig]) {
        //Change the current config state only if the user is expecting it. It's possible the user does not need to know about the update.
        _state = CFGConfigLoadingInProgress;
        [CFGLogger logLevel: CFGLogLevelVerbose log: @"Loading Config Start"];
    }
    
    NSDictionary *configoData = [_configoDataController configoDataForRequest];
    [_networkController requestConfigWithConfigoData: configoData callback: ^(CFGResponse *response, NSError *error) {
        //Check before hand (because it relies on statuses that change in this function)
        BOOL shouldNotifyUser = [self shouldUpdateActiveConfig];
        
        if(response && !error) {
            _latestConfigoResponse = response;
            
            [_configoDataController saveConfigoDataWithDevKey: _devKey appId: _appId];
            [self saveResponse: _latestConfigoResponse withDevKey: _devKey withAppId: _appId];
            
            if(shouldNotifyUser) {
                _state = CFGConfigLoadedFromServer;
                _activeConfigoResponse = _latestConfigoResponse;
                _configValueFetcher.config = _activeConfigoResponse.configObj;
                
                [CFGLogger logLevel: CFGLogLevelVerbose log: @"Loading Config Complete"];
            }
        }
        //Declare an "error" state only if the config was supposed to be updated. So false states are not reported.
        else if(shouldNotifyUser) {
            _state = CFGConfigFailedLoadingFromServer;
            NNLogDebug(@"Loading Config: Error", error);
            
            [CFGLogger logLevel: CFGLogLevelError log: @"Loading Config Failed: %@", error];
        }
        
        //Invoke only if the user was expecting an update to the config
        if(shouldNotifyUser) {
            //Invoke callbacks and send notifications with either success or errors (depends on the error object passed).
            [self sendNotificationWithError: error];
            [self invokeListenersCallbacksWithError: error];
        }
        //Start polling
        [self setupPollingTimer];
    }];
}

#pragma mark - Setters

- (void)setCallback:(CFGCallback)callback {
    if(!self.listenerCallback && _activeConfigoResponse && _state == CFGConfigLoadedFromServer) {
        self.listenerCallback = callback;
        [self invokeListenersCallbacksWithError: nil];
    } else {
        self.listenerCallback = callback;
    }
}

- (void)setCustomUserId:(NSString *)userId {
    [_configoDataController setCustomUserId: userId];
}

- (BOOL)setUserContext:(NSDictionary *)context {
    //[self setCustomUserId: nil userContext: context]; //Incorrect, will trigger changing the customUserId
    return [_configoDataController setUserContext: context];
}

- (BOOL)setUserContextValue:(id)value forKey:(NSString *)key {
    return [_configoDataController setUserContextValue: value forKey: key];
    /*if(contextChanged) {
     //If user calls this method consecutively - this will be triggered every time.
     //[self pullConfig];
     }*/
}

#pragma mark - Events Handling

- (void)trackEvent:(NSString *)event withProperties:(NSDictionary *)properties {
    [_eventsController addEvent: event withProperties: properties];
}

#pragma mark - Config Getters

- (NSDictionary *)rawConfig {
    return _activeConfigoResponse.configObj.configDictionary;
}

- (id)configValueForKeyPath:(NSString *)keyPath {
    return [self configValueForKeyPath: keyPath fallbackValue: nil];
}

- (id)configValueForKeyPath:(NSString *)keyPath fallbackValue:(id)fallbackValue {
    return [_configValueFetcher configValueForKeyPath: keyPath fallbackValue: fallbackValue];
}

#pragma mark - Feature Getters

- (NSArray *)featuresList {
    return _activeConfigoResponse.configObj.featuresArray;
}

- (BOOL)featureFlagForKey:(NSString *)key {
    return [self featureFlagForKey: key fallback: NO];
}

- (BOOL)featureFlagForKey:(NSString *)key fallback:(BOOL)fallbackFlag {
    return [_configValueFetcher featureFlagForKey: key fallback: fallbackFlag];
}

#pragma mark - File Storage

- (BOOL)saveResponse:(CFGResponse *)response withDevKey:(NSString *)devKey withAppId:(NSString *)appId {
    NSError *err = nil;
    BOOL success = [_fileController saveResponse: response error: &err];
    NNLogDebug(([NSString stringWithFormat: @"Configo save response to file %@", success ? @"success" : @"failed"]), err);
    return success;
}

- (CFGResponse *)responseFromFileWithDevKey:(NSString *)devKey withAppId:(NSString *)appId {
    CFGResponse *retval = nil;
    NSError *err = nil;
    retval = [_fileController readResponse: &err];
    NNLogDebug(([NSString stringWithFormat: @"Configo load response from file %@", retval ? @"success" : @"failed"]), (retval ? nil : err));
    return retval;
}

#pragma mark - Helpers

- (void)determineShouldLog {
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    if(bundleId) {
        [NNLogger setLogging: [bundleId isEqualToString: @"io.configo.example"]];
    } else {
        //Probably a testing target
    }
}

- (BOOL)shouldUpdateActiveConfig {
    //If there's no currently active config (first time load)
    //If the currently active config is loaded from storage.
    //If the user set the 'dynamicalylRefreshValues' to YES.
    //If it's a 'pullConfig' that awaits a callback
    return (!_activeConfigoResponse ||
            _state == CFGConfigLoadedFromStorage ||
            _state == CFGConfigLoadingInProgress ||
            _state == CFGConfigFailedLoadingFromServer ||
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
        userInfo = @{ConfigoNotificationUserInfoRawConfigKey : [self rawConfig] ?: [NSNull null],
                     ConfigoNotificationUserInfoFeaturesListKey : [self featuresList] ?: [NSNull null]};
        notificationName = ConfigoConfigurationLoadCompleteNotification;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName: notificationName object: self userInfo: userInfo];
}

- (void)setLoggingLevel:(CFGLogLevel)level {
    [self.class setLoggingLevel: level];
}

+ (void)setLoggingLevel:(CFGLogLevel)level {
    [CFGLogger setLoggingLevel: level];
}

@end
