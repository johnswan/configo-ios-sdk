//
//  ConfigoConstants.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 17/08/15.
//  Copyright (c) 2015 Configo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CFGErrorConstants.h"

/********************************************************
 String Constants
 ********************************************************/
FOUNDATION_EXPORT NSString *const ConfigoSDKVersion;
FOUNDATION_EXPORT NSString *const CFGFileNamePrefix;
FOUNDATION_EXPORT NSString *const CFGErrorDomain;
FOUNDATION_EXPORT NSString *const CFGSessionStartEventName;
FOUNDATION_EXPORT NSString *const CFGSessionEndEventName;

/********************************************************
 Other Constants
 ********************************************************/
FOUNDATION_EXPORT NSInteger const CFGDefaultPollingInterval;
FOUNDATION_EXPORT NSInteger const CFGDefaultEventPushInterval;

/********************************************************
 Interface Declaration
 ********************************************************/

typedef NS_ENUM(NSUInteger, CFGEnvironment) {
    CFGEnvironmentDevelopment,
    CFGEnvironmentProduction, 
    CFGEnvironmentLocalServer
};

@interface CFGConstants : NSObject

+ (NSURL *)getConfigURL;
+ (NSURL *)statusPollURL;
+ (NSURL *)eventsPushUrl;
+ (CFGEnvironment)currentEnvironment;

+ (NSError *)errorWithType:(CFGErrorCode)code userInfo:(NSDictionary *)info;


@end
