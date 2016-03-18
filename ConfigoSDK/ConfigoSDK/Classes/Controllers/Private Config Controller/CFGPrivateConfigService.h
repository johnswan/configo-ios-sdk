//
//  CFGPrivateConfigService.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 11/16/15.
//  Copyright © 2015 Configo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CFGResponse.h"

#define CFGPrivateConfigValue(key)      [[CFGPrivateConfigService sharedConfigService] valueForKeyPath: key]
#define CFGPrivateConfigString(key)     [[CFGPrivateConfigService sharedConfigService] stringForKeyPath: key]
#define CFGPrivateConfigInteger(key)    [[CFGPrivateConfigService sharedConfigService] integerForKeyPath: key]
#define CFGPrivateConfigDouble(key)     [[CFGPrivateConfigService sharedConfigService] doubleForKeyPath: key]
#define CFGPrivateFeatureFlag(key)      [[CFGPrivateConfigService sharedConfigService] featureFlagForKey: key]

//TODO: Save the config to file

FOUNDATION_EXPORT NSString *const CFGPrivateConfigLoadedNotification;

@interface CFGPrivateConfigService : NSObject

+ (instancetype)sharedConfigService;

- (id)valueForKeyPath:(NSString *)keyPath;
- (NSString *)stringForKeyPath:(NSString *)keyPath;
- (NSInteger)integerForKeyPath:(NSString *)keyPath;
- (double)doubleForKeyPath:(NSString *)keyPath;

- (BOOL)featureFlagForKey:(NSString *)key;

@end