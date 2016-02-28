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
#import "CFGFeature.h"

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
    BOOL foundValue;
    BOOL retval = [self featureFlagForKey: key fromConfig: _config fallback: fallback foundValue: &foundValue];
    if(!foundValue && _useFallbackConfig) {
        retval = [self featureFlagForKey: key fromConfig: _fallbackConfig fallback: fallback foundValue: nil];
    }
    return retval;
}

- (BOOL)featureFlagForKey:(NSString *)key fromConfig:(CFGConfig *)config fallback:(BOOL)fallback foundValue:(BOOL *)found {
    id testerObj = [config.featuresArray firstObject];
    BOOL retval = fallback;
    //Testing for v2 compliance
    if([testerObj isKindOfClass: [CFGFeature class]]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"key = %@", key];
        NSArray *results = [config.featuresArray filteredArrayUsingPredicate: predicate];
        CFGFeature *featureFlag = [results firstObject];
        if(featureFlag) {
            retval = featureFlag.enabled;
            if(found) {
                *found = YES;
            }
        }
    } else {
        retval = [config.featuresArray containsObject: key];
        if(found) {
            *found = retval;
        }
        retval = retval ?: fallback;
    }
    return retval;
}

@end
