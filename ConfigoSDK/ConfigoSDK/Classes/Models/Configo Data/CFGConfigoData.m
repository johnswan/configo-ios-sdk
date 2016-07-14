//
//  CFGConfigoData.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 25/08/15.
//  Copyright (c) 2015 Configo. All rights reserved.
//

#import "CFGConfigoData.h"

#import "NSDictionary+NNAdditions.h"
#import "NNJSONUtilities.h"

static NSString *const kUdidKey = @"udid";
static NSString *const kCustomUserIdKey = @"customUserId";
static NSString *const kUserContextKey = @"userContext";
static NSString *const kDeviceDetailsKey = @"deviceDetails";
static NSString *const kPushTokenKey = @"pushToken";

@interface CFGConfigoData ()
@property (nonatomic, strong) NSMutableDictionary *mutableUserContext;
@property (nonatomic, readwrite, copy) NSString *pushToken;
@end

@implementation CFGConfigoData

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if(self = [super initWithDictionary: dict]) {
        self.udid = [NNJSONUtilities validObjectFromObject: dict[kUdidKey]];
        self.customUserId = [NNJSONUtilities validObjectFromObject: dict[kCustomUserIdKey]];
        self.deviceDetails = [NNJSONUtilities validObjectFromObject: dict[kDeviceDetailsKey]];
        
        NSDictionary *contextDict = [NNJSONUtilities validObjectFromObject: dict[kUserContextKey]];
        self.userContext = [NSMutableDictionary dictionaryWithDictionary: contextDict];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    CFGConfigoData *copy = [[CFGConfigoData alloc] initWithDictionary: [self dictionaryRepresentation]];
    return copy;
}

- (NSDictionary *)jsonRepresentation {
    return [self dictionaryRepresentation];
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict nnSafeSetObject: _udid forKey: kUdidKey];
    [dict nnSafeSetObject: _customUserId forKey: kCustomUserIdKey];
    [dict nnSafeSetObject: [self userContext] forKey: kUserContextKey];
    [dict nnSafeSetObject: _deviceDetails forKey: kDeviceDetailsKey];
    [dict nnSafeSetObject: _pushToken forKey: kPushTokenKey];
    return dict;
}


- (void)clearUserContext {
    [_mutableUserContext removeAllObjects];
}

- (NSDictionary *)userContext {
    NSDictionary *retval = nil;
    if(_mutableUserContext.count > 0) {
        retval = [_mutableUserContext copy];
    }
    return retval;
}

- (void)setUserContext:(NSDictionary *)userContext {
    if(userContext) {
        _mutableUserContext = [NSMutableDictionary dictionaryWithDictionary: userContext];
    } else {
        _mutableUserContext = nil;
    }
}

- (void)setUserContextValue:(id)value forKey:(NSString *)key {
    if(!key) {
        return;
    }
    
    if(!_mutableUserContext) {
        _mutableUserContext = [NSMutableDictionary dictionary];
    }
    
    if(!value) {
        [_mutableUserContext removeObjectForKey: key];
    } else {
        [_mutableUserContext nnSafeSetObject: value forKey: key];
    }
}

- (void)setPushToken:(NSData *)token {
    NSCharacterSet *junkCharsSet = [NSCharacterSet characterSetWithCharactersInString: @"<>"];
    NSString *cleanToken = [[token description] stringByTrimmingCharactersInSet: junkCharsSet];
    cleanToken = [cleanToken stringByReplacingOccurrencesOfString: @" " withString: @""];
    self.pushToken = cleanToken;
}

- (void)setUdid:(NSString *)udid {
    _udid = udid;
}

@end
