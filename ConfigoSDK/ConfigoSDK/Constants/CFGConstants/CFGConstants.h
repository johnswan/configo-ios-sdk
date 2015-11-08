//
//  ConfigoConstants.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 17/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CFGErrorConstants.h"

/********************************************************
 String Constants
 ********************************************************/
FOUNDATION_EXPORT NSString *const CFGFileNamePrefix;
FOUNDATION_EXPORT NSString *const CFGCryptoKey;

FOUNDATION_EXPORT NSString *const CFGErrorDomain;

/********************************************************
 Other Constants
 ********************************************************/
FOUNDATION_EXPORT NSInteger const kPullConfigTimerDelay;

/********************************************************
 Interface Declaration
 ********************************************************/

typedef NS_ENUM(NSUInteger, CFGEnvironment) {
    CFGEnvironmentDevelopment,
    CFGEnvironmentProduction,
};

@interface CFGConstants : NSObject

+ (NSString *)sdkVersionString;

+ (NSURL *)getConfigURL;
+ (NSString *)baseURLString;
+ (CFGEnvironment)currentEnvironment;

@end
