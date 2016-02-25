//
//  CFGValueFetcher.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 2/24/16.
//  Copyright © 2016 Configo. All rights reserved.
//

#import "CFGConfigValueFetcher.h"

#import "NNJSONUtilities.h"

#import "CFGConfig.h"

@interface CFGConfigValueFetcher ()

@end

@implementation CFGConfigValueFetcher

#pragma mark - Init

- (instancetype)initWithConfig:(CFGConfig *)config {
    if(self = [super init]) {
        _config = config;
        _useFallbackConfig = NO;
    }
    return self;
}

#pragma mark - Value Fetchers

- (id)configValueForKeyPath:(NSString *)keyPath fallbackValue:(id)value {
    id retval = [NNJSONUtilities valueForKeyPath: keyPath inObject: _config.configDictionary];
    if(!retval && _useFallbackConfig) {
        retval = [NNJSONUtilities valueForKeyPath: keyPath inObject: _fallbackConfig.configDictionary];
    }
    return retval ?: value;
}

- (BOOL)featureFlagForKey:(NSString *)key fallback:(BOOL)fallback {
    BOOL retval = [_config.featuresArray containsObject: key];
    if(!retval && _useFallbackConfig) {
        retval = [_fallbackConfig.featuresArray containsObject: key];
    }
    return retval ?: fallback;
}

@end
