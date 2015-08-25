//
//  CFGResponse.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 17/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import "CFGResponse.h"
#import <NNLibraries/NNJSONUtilities.h>
#import <NNLibraries/NSDictionary+NNAdditions.h>

#pragma mark - Constants
static NSString *const kConfigIDKey = @"_id";
static NSString *const kConfigKey = @"config";

@implementation CFGResponse

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if(self = [super initWithDictionary: dict]) {
        _configID = [NNJSONUtilities validObjectFromObject: dict[kConfigIDKey]];
        _config = [NNJSONUtilities validObjectFromObject: dict[kConfigKey]];
    }
    return self;
}

- (NSDictionary *)jsonRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict nnSafeSetObject: _configID forKey: kConfigIDKey];
    [dict nnSafeSetObject: _config forKey: kConfigKey];
    return dict;
}

@end
