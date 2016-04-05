//
//  ConfigoConstants.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 17/08/15.
//  Copyright (c) 2015 Configo. All rights reserved.
//

#import "CFGConstants.h"
#import "NNUtilities.h"
#import "UIDevice+NNAdditions.h"
#import "CFGPrivateConfigService.h"

#pragma mark - Global Constants

NSString *const ConfigoSDKVersion = @"0.4.4";
NSString *const CFGFileNamePrefix = @"configo";
NSString *const CFGErrorDomain = @"io.configo.error";
NSString *const CFGSessionStartEventName = @"CONFIGO_SESSION_START";
NSString *const CFGSessionEndEventName = @"CONFIGO_SESSION_END";

#pragma mark - Private Constants

//NSString *const CFGBaseLocalPath = @"http://local.configo.io:8001";
NSString *const CFGBaseDevelopmentPath = @"http://local.configo.io:8001";
NSString *const CFGBaseProductionPath = @"https://api.configo.io";
NSString *const CFGBaseYosiMachinePath = @"http://10.56.108.19:8001";

NSString *const CFGGetConfigPath = @"/user/getConfig";
NSString *const CFGStatusPollPath = @"/user/status";
NSString *const CFGEventsPushPath = @"/events/push";

NSInteger const CFGDefaultPollingInterval = 25;
NSInteger const CFGDefaultEventPushInterval = 5;

NSString *const CFGVersionOne = @"/v1";
NSString *const CFGVersionTwo = @"/v2";

typedef NS_ENUM(NSUInteger, CFGApiVersion) {
    CFGApiVersionOne,
    CFGApiVersionTwo
};


#pragma mark - Implementation

@implementation CFGConstants

#pragma mark - Error Builder

+ (NSError *)errorWithType:(CFGErrorCode)code userInfo:(NSDictionary *)info {
    NSString *domain = [CFGErrorDomain stringByAppendingFormat: @".%@", [self errorCodeToString: code]];
    return [NSError errorWithDomain: domain code: code userInfo: info];
}

+ (NSString *)errorCodeToString:(CFGErrorCode)code {
    NSString *retval = nil;
    switch(code) {
        case CFGErrorBadResponse:
            retval = @"badResponse";
            break;
        case CFGErrorRequestFailed:
            retval = @"requestFailed";
            break;
        default:
            retval = @"unexpected";
            break;
    }
    return retval;
}

#pragma mark - URL Builders

+ (NSURL *)getConfigURL {
    CFGApiVersion version = CFGPrivateFeatureFlag(@"GET-CONFIG-V2") ? CFGApiVersionTwo : CFGApiVersionOne;
    NSString *urlString = [self apiURLStringWithVersion: version withPath: CFGGetConfigPath];
    return [NSURL URLWithString: urlString];
}

+ (NSURL *)statusPollURL {
    NSString *urlStr = [self apiURLStringWithVersion: CFGApiVersionOne withPath: CFGStatusPollPath];
    return [NSURL URLWithString: urlStr];
}

+ (NSURL *)eventsPushUrl {
    NSString *urlStr = [self apiURLStringWithVersion: CFGApiVersionOne withPath: CFGEventsPushPath];
    return [NSURL URLWithString: urlStr];
}

#pragma mark - Builders

+ (NSString *)apiURLStringWithVersion:(CFGApiVersion)version withPath:(NSString *)path {
    NSMutableString *urlString = [NSMutableString string];
    [urlString appendString: [self baseURLString]];
    [urlString appendString: [self apiVersionToString: version]];
    [urlString appendString: path];
    return urlString;
}

+ (NSString *)baseURLString {
    NSString *retval = nil;
    switch([self currentEnvironment]) {
        case CFGEnvironmentDevelopment:
            retval = CFGBaseDevelopmentPath;
            break;
        case CFGEnvironmentProduction:
            retval = CFGBaseProductionPath;
            break;
        case CFGEnvironmentYosiMachine:
            retval = CFGBaseYosiMachinePath;
            break;
    }
    return retval;
}

+ (CFGEnvironment)currentEnvironment {
    BOOL useYosiMachine = YES;
    if(useYosiMachine) {
        return CFGEnvironmentYosiMachine;
    } else if(false && ([NNUtilities isDebugMode] && [UIDevice isDeviceSimulator])) {
        return CFGEnvironmentDevelopment;
    } else {
        return CFGEnvironmentProduction;
    }
}

#pragma mark - Helpers

+ (NSString *)apiVersionToString:(CFGApiVersion)version {
    switch(version) {
        case CFGApiVersionOne:
        default:
            return CFGVersionOne;
        case CFGApiVersionTwo:
            return CFGVersionTwo;
    }
}

@end
