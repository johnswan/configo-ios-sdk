//
//  CFGPrivateConfigService.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 11/16/15.
//  Copyright © 2015 Turrisio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CFGResponse.h"

#define PrivateConfigValue(key)     [[CFGPrivateConfigService sharedConfigService] valueForKeyPath: key]
#define PrivateConfigString(key)    [[CFGPrivateConfigService sharedConfigService] stringForKeyPath: key]
#define PrivateConfigInteger(key)   [[CFGPrivateConfigService sharedConfigService] integerForKeyPath: key]

//TODO: Save the config to file
//TODO: Think about how to save the fallback (initial) config (Object/File/Inline JSON)

@interface CFGPrivateConfigService : NSObject

+ (instancetype)sharedConfigService;

- (id)valueForKeyPath:(NSString *)keyPath;
- (NSString *)stringForKeyPath:(NSString *)keyPath;
- (NSInteger)integerForKeyPath:(NSString *)keyPath;

- (BOOL)featureFlagForKey:(NSString *)key;

@end