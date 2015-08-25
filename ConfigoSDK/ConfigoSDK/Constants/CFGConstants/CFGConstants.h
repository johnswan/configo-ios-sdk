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
 Interface Declaration
 ********************************************************/
@interface CFGConstants : NSObject

+ (NSURL *)getConfigURL;
+ (NSString *)baseURLString;

@end
