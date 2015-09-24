//
//  ConfigoConstants.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 17/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import "CFGConstants.h"

#pragma mark - Global Constants

NSString *const CFGFileNamePrefix = @"configo";
NSString *const CFGCryptoKey = @"14504D2A42F6C2F08B9E8A1B2309A5BA";

NSString *const CFGErrorDomain = @"com.configo.error";

NSString *const CFGBaseLocalPath = @"http://192.168.1.251:8001";
NSString *const CFGBaseDevelopmentPath = @"http://192.168.1.252:8001";
NSString *const CFGBaseProductionPath = @"http://configo.io";

NSString *const CFGCurrentVersionPath = @"/v1";
NSString *const CFGGetConfigPath = @"/user/getConfig";


#pragma mark - Private Constants

NSString *const CFGAppIdKey = @"app_id";

#pragma mark - Implementation

@implementation CFGConstants

+ (NSString *)sdkVersionString {
    return @"0.1";
}

+ (NSURL *)getConfigURL {
    NSString *urlString = [self baseURLStringWithPath: CFGGetConfigPath];
    return [NSURL URLWithString: urlString];
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
        case CFGEnvironmentLocal:
            retval = CFGBaseLocalPath;
            break;
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
    return CFGEnvironmentLocal;
}

@end
