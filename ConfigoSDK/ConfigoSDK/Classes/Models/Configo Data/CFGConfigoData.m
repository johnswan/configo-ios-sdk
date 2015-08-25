//
//  CFGConfigoData.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 25/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import "CFGConfigoData.h"

#import <NNLibraries/NSDictionary+NNAdditions.h>
#import <NNLibraries/NNJSONUtilities.h>

static NSString *const kUdidKey = @"udid";
static NSString *const kCustomUserIdKey = @"customUserId";
static NSString *const kUserContextKey = @"userContext";
static NSString *const kDeviceDetailsKey = @"deviceDetails";

@implementation CFGConfigoData

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if(self = [super initWithDictionary: dict]) {
        self.udid = [NNJSONUtilities validObjectFromObject: dict[kUdidKey]];
        self.customUserId = [NNJSONUtilities validObjectFromObject: dict[kCustomUserIdKey]];
        self.userContext = [NNJSONUtilities validObjectFromObject: dict[kUserContextKey]];
        self.deviceDetails = [NNJSONUtilities validObjectFromObject: dict[kDeviceDetailsKey]];
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict nnSafeSetObject: _udid forKey: kUdidKey];
    [dict nnSafeSetObject: _customUserId forKey: kCustomUserIdKey];
    [dict nnSafeSetObject: _userContext forKey: kUserContextKey];
    [dict nnSafeSetObject: _deviceDetails forKey: kDeviceDetailsKey];
    return dict;
}

@end
