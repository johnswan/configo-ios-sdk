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

#pragma mark - Global Constants
NSString *const ConfigoSDKVersion = @"0.4.2";

NSString *const CFGFileNamePrefix = @"configo";

NSString *const CFGErrorDomain = @"io.configo.error";

//NSString *const CFGBaseLocalPath = @"http://local.configo.io:8001";
NSString *const CFGBaseDevelopmentPath = @"http://local.configo.io:8001";
NSString *const CFGBaseProductionPath = @"https://api.configo.io";

NSString *const CFGCurrentVersionPath = @"/v1";
NSString *const CFGGetConfigPath = @"/user/getConfig";
NSString *const CFGStatusPollPath = @"/user/status";

NSInteger const CFGDefaultPollingInterval = 25;


#pragma mark - Implementation

@implementation CFGConstants

+ (NSURL *)getConfigURL {
    NSString *urlString = [self baseURLStringWithPath: CFGGetConfigPath];
    return [NSURL URLWithString: urlString];
}

+ (NSURL *)statusPollURL {
    NSString *urlStr = [self baseURLStringWithPath: CFGStatusPollPath];
    return [NSURL URLWithString: urlStr];
}

+ (NSString *)baseURLStringWithPath:(NSString *)path {
    NSMutableString *urlString = [NSMutableString string];
    [urlString appendString: [self baseURLString]];
    [urlString appendString: CFGCurrentVersionPath];
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

@end
