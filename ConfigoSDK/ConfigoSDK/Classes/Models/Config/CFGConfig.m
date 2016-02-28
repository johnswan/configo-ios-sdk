//
//  CFGConfig.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 1/18/16.
//  Copyright © 2016 Turrisio. All rights reserved.
//

#import "CFGConfig.h"
#import "CFGFeature.h"

#import "NNJSONUtilities.h"

static NSString *const kConfigKey = @"config";
static NSString *const kFeaturesKey = @"features";

@implementation CFGConfig

- (instancetype)initWithConfig:(NSDictionary *)config features:(NSArray *)features {
    if(self = [super init]) {
        _configDictionary = config;
        _featuresArray = [self parseFeaturesArray: features];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if(self = [super initWithDictionary: dict]) {
        _configDictionary = [self validObjectFromObject: dict[kConfigKey]];
        _featuresArray = [self parseFeaturesArray: dict[kFeaturesKey]];
    }
    return self;
}

- (NSArray *)parseFeaturesArray:(NSArray *)features {
    NSMutableArray *retArr = [NSMutableArray array];
    for(id featureDict in features) {
        if([featureDict isKindOfClass: [NSDictionary class]]) {
            CFGFeature *feature = [[CFGFeature alloc] initWithDictionary: featureDict];
            if(feature) {
                [retArr addObject: feature];
            }
        } else {
            retArr = [NSMutableArray arrayWithArray: features];
            break;
        }
    }
    return retArr.count == 0 ? nil : retArr;
}

@end
