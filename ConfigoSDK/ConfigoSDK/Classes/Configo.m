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
        NNLogDebug(@"Configo: Init", (@{@"devKey" : devKey, @"appId" : appId}));
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
    }
    return self;
}

+ (NSString *)sdkVersionString {
    return [CFGConstants sdkVersionString];
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
    [CFGNetworkController requestConfigWithDevKey: _devKey appId: _appId configoData: configoData callback: ^(CFGResponse *response, NSError *error) {
        if(response) {
            _state = CFGConfigLoadedFromServer;
            _configoResponse = response;
            
            if(!error) {
                [_configoDataController saveConfigoDataWithDevKey: _devKey appId: _appId];
                [self saveResponse: _configoResponse withDevKey: _devKey withAppId: _appId];
                
                if(!_activeConfigoResponse || _dynamicallyRefreshValues) {
                    _activeConfigoResponse = _configoResponse;
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName: ConfigoConfigurationLoadCompleteNotification
                                                                    object: self
                                                                  userInfo: [self rawConfig]];
            } else {
                NSDictionary *userInfo = @{ConfigoNotificationUserInfoErrorKey : error};
                [[NSNotificationCenter defaultCenter] postNotificationName: ConfigoConfigurationLoadErrorNotification
                                                                    object: self
                                                                  userInfo: userInfo];
            }
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

- (void)setUserContext:(NSDictionary *)context {
    [self setCustomUserId: nil userContext: context];
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

#pragma mark - DEBUG only code


+ (NSString *)developmentDevKey {
    NSString *retval = nil;
    switch ([CFGConstants currentEnvironment]) {
        case CFGEnvironmentLocal: {
            retval = @"YOUR_DEV_KEY";
            break;
        }
        case CFGEnvironmentDevelopment: {
            retval = @"123";
            break;
        }
        case CFGEnvironmentProduction: {
            retval = @"123";
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
        case CFGEnvironmentLocal: {
            retval = @"YOUR_APP_ID";
            break;
        }
        case CFGEnvironmentDevelopment: {
            retval = @"YOUR_APP_ID";
            break;
        }
        case CFGEnvironmentProduction: {
            retval = @"YOUR_APP_ID";
            break;
        }
        default:
            break;
    }
    return retval;
}

#endif

@end
