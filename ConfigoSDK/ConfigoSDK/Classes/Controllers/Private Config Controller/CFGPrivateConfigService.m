//
//  CFGPrivateConfigService.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 11/16/15.
//  Copyright © 2015 Turrisio. All rights reserved.
//

#import "CFGPrivateConfigService.h"
#import "CFGNetworkController.h"

#import "CFGConstants.h"

#import <NNLibraries/NNJSONUtilities.h>
#import <NNLibraries/NNUtilities.h>
#import <NNLibraries/NNLogger.h>

@interface CFGPrivateConfigService ()
@property (nonatomic, strong) CFGNetworkController *restClient;
@property (nonatomic, strong) CFGResponse *fallbackConfig;
@property (nonatomic, strong) CFGResponse *configResponse;
@end


@implementation CFGPrivateConfigService

#pragma mark - Singleton

+ (instancetype)sharedConfigService {
    static id _shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[self alloc] init];
    });
    return _shared;
}

- (instancetype)init {
    if(self = [super init]) {
        _fallbackConfig = [[CFGResponse alloc] initWithDictionary: [self fallbackResponseDictionary]];
        NSString *devKey = @"add8b2b55e697cf274532352e2ff43bc";
        NSString *appId = @"5649d686dec65e3f64106aab";
        _restClient = [[CFGNetworkController alloc] initWithDevKey: devKey appId: appId];
        [self pullConfig];
    }
    return self;
}

- (void)pullConfig {
    [_restClient requestConfigWithConfigoData: [self sdkData] callback: ^(CFGResponse *response, NSError *error) {
        if(!error && response) {
            _configResponse = response;
            [self alertSDKVersion];
        }
        _restClient = nil;
    }];
}

#pragma mark - Default Config

- (NSDictionary *)fallbackResponseDictionary {
    static NSDictionary *dict = nil;
    if(!dict) {
        dict = @{
                 @"header": @{
                         @"trxId": @"3e49d546-06e4-d2dc-8104-2e9820b9ff06",
                         @"statusCode": @200,
                         @"statusMessage": @"OK"
                         },
                 @"response": @{
                         @"config": @{
                                 @"SDKVersion": @{
                                         @"ios": ConfigoSDKVersion,
                                         @"android": @"0.3.4"
                                         },
                                 @"pollingInterval": @{
                                         @"ios" : @(CFGDefaultPollingInterval),
                                         @"android" : @25000
                                         }
                                 },
                         @"features": @[],
                         @"groups": @[]
                         }
                 };
    }
    return dict;
}

#pragma mark - Getters

- (NSString *)stringForKeyPath:(NSString *)keyPath {
    id value = [self valueForKeyPath: keyPath];
    NSString *retval = nil;
    if([value respondsToSelector: @selector(stringValue)]) {
        retval = [value stringValue];
    } else if([value isKindOfClass: [NSString class]]) {
        retval = value;
    }
    return retval;
}

- (NSInteger)integerForKeyPath:(NSString *)keyPath {
    id value = [self valueForKeyPath: keyPath];
    NSInteger retval = 0;
    if([value respondsToSelector: @selector(integerValue)]) {
        retval = [value integerValue];
    }
    return retval;
}

- (id)valueForKeyPath:(NSString *)keyPath {
    id retval = [NNJSONUtilities valueForKeyPath: keyPath inObject: _configResponse.config];
    if(!retval) {
        retval = [NNJSONUtilities valueForKeyPath: keyPath inObject: _fallbackConfig.config];
    }
    return retval;
}

- (BOOL)featureFlagForKey:(NSString *)key {
    BOOL retval = [_configResponse.features containsObject: key];
    if(!retval) {
        retval = [_fallbackConfig.features containsObject: key];
    }
    return retval;
}

#pragma mark - Helpers

- (NSDictionary *)sdkData {
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    return @{@"udid": bundleId};
}

- (void)alertSDKVersion {
    NSString *remoteVersion = [self stringForKeyPath: @"SDKVersion.ios"];
    NSComparisonResult result = [NNUtilities compareVersionString: ConfigoSDKVersion toVersionString: remoteVersion];
    if(result == NSOrderedAscending) {
        NNLogDebug(@"Please update Configo to the laatest version", remoteVersion);
    } else if(result == NSOrderedSame) {
        NNLogDebug(@"Configo is up-to-date.", nil);
    } else {
        NNLogDebug(@"Configo local version is ahead of remote?! O_o", ConfigoSDKVersion);
    }
}

@end
