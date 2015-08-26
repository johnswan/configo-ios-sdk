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

@interface CFGConfigoData ()
@property (nonatomic, strong) NSMutableDictionary *mutableUserContext;
@end

@implementation CFGConfigoData

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if(self = [super initWithDictionary: dict]) {
        self.udid = [NNJSONUtilities validObjectFromObject: dict[kUdidKey]];
        self.customUserId = [NNJSONUtilities validObjectFromObject: dict[kCustomUserIdKey]];
        NSDictionary *dict = [NNJSONUtilities validObjectFromObject: dict[kUserContextKey]];
        self.userContext = [NSMutableDictionary dictionaryWithDictionary: dict];
        self.deviceDetails = [NNJSONUtilities validObjectFromObject: dict[kDeviceDetailsKey]];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    CFGConfigoData *copy = [[CFGConfigoData alloc] initWithDictionary: [self dictionaryRepresentation]];
    return copy;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict nnSafeSetObject: _udid forKey: kUdidKey];
    [dict nnSafeSetObject: _customUserId forKey: kCustomUserIdKey];
    [dict nnSafeSetObject: [self userContext] forKey: kUserContextKey];
    [dict nnSafeSetObject: _deviceDetails forKey: kDeviceDetailsKey];
    return dict;
}

- (NSDictionary *)userContext {
    return [_mutableUserContext copy];
}

- (void)setUserContext:(NSDictionary *)userContext {
    _mutableUserContext = [NSMutableDictionary dictionaryWithDictionary: userContext];
}

- (void)setUserContextValue:(id)value forKey:(NSString *)key {
    if(!key || !value) {
        return;
    }
    
    if(!_mutableUserContext) {
        _mutableUserContext = [NSMutableDictionary dictionary];
    }
    
    [_mutableUserContext nnSafeSetObject: [NNJSONUtilities makeValidJSONObject: value] forKey: key];
}

@end
