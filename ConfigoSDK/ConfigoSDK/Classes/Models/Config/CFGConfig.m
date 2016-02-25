//
//  CFGConfig.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 1/18/16.
//  Copyright © 2016 Turrisio. All rights reserved.
//

#import "CFGConfig.h"

#import "NNJSONUtilities.h"

static NSString *const kConfigKey = @"config";
static NSString *const kFeaturesKey = @"features";

@implementation CFGConfig

- (instancetype)initWithConfig:(NSDictionary *)config features:(NSArray *)features {
    if(self = [super init]) {
        _configDictionary = config;
        _featuresArray = features;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if(self = [super initWithDictionary: dict]) {
        _configDictionary = [self validObjectFromObject: dict[kConfigKey]];
        _featuresArray = [self validObjectFromObject: dict[kFeaturesKey]];
    }
    return self;
}

@end
