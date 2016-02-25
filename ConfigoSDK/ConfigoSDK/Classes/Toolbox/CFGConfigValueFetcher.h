//
//  CFGValueFetcher.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 2/24/16.
//  Copyright © 2016 Configo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CFGConfig;

@interface CFGConfigValueFetcher : NSObject
/**
 *  @brief Fallback to this config before returning fallbackValue / fallback.
 *  Will usually be used by the private config service.
 */
@property (nonatomic, strong) CFGConfig *fallbackConfig;
@property (nonatomic, strong) CFGConfig *config;

/** 
 *  @brief Determine wether <i>fallbackConfig</i> will be used. Defaults to NO.
 */
@property (nonatomic) BOOL useFallbackConfig;

- (instancetype)initWithConfig:(CFGConfig *)config;

- (id)configValueForKeyPath:(NSString *)keyPath fallbackValue:(id)value;
- (BOOL)featureFlagForKey:(NSString *)key fallback:(BOOL)fallback;

@end
