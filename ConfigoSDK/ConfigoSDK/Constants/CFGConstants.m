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

#pragma mark - Private Constants

//NSString *const CFGBaseLocalPath = @"http://local.configo.io:8001";
NSString *const CFGBaseDevelopmentPath = @"http://local.configo.io:8001";
NSString *const CFGBaseProductionPath = @"https://api.configo.io";

NSString *const CFGGetConfigPath = @"/user/getConfig";
NSString *const CFGStatusPollPath = @"/user/status";

NSInteger const CFGDefaultPollingInterval = 25;

NSString *const CFGVersionOne = @"/v1";
NSString *const CFGVersionTwo = @"/v2";

typedef NS_ENUM(NSUInteger, CFGApiVersion) {
    CFGApiVersionOne,
    CFGApiVersionTwo
};


#pragma mark - Implementation

@implementation CFGConstants

+ (NSURL *)getConfigURL {
    CFGApiVersion version = CFGPrivateFeatureFlag(@"GET-CONFIG-V2") ? CFGApiVersionTwo : CFGApiVersionOne;
    NSString *urlString = [self apiURLStringWithVersion: version withPath: CFGGetConfigPath];
    return [NSURL URLWithString: urlString];
}

+ (NSURL *)statusPollURL {
    NSString *urlStr = [self apiURLStringWithVersion: CFGApiVersionOne withPath: CFGStatusPollPath];
    return [NSURL URLWithString: urlStr];
}

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
    }
    return retval;
}

+ (CFGEnvironment)currentEnvironment {
#warning Always Production
    if(false && ([NNUtilities isDebugMode] && [UIDevice isDeviceSimulator])) {
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
