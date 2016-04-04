//
//  CFGEvent.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 13/03/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CFGEvent.h"

#import "NSDictionary+NNAdditions.h"

static NSString *const kNameKey = @"name";
static NSString *const kSessionIdKey = @"sessionId";
static NSString *const kTimestampKey = @"timestamp";
static NSString *const kPropertiesKey = @"properties";

@implementation CFGEvent

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if(self = [super initWithDictionary: dict]) {
        _name = [dict[kNameKey] copy];
        if(!_name) {
            return nil;
        }
        
        _sessionId = [dict[kSessionIdKey] copy];
        NSNumber *timestampNumber = dict[kTimestampKey];
        _timestamp = [timestampNumber doubleValue];
        _properties = [dict[kPropertiesKey] copy];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name withProperties:(NSDictionary *)properties {
    return [self initWithSession: nil withName: name withProperties: properties];
}

- (instancetype)initWithSession:(NSString *)session withName:(NSString *)name withProperties:(NSDictionary *)properties {
    if(!name) {
        return nil;
    }
    if(self = [super init]) {
        _sessionId = [session copy];
        _name = [name copy];
        _properties = properties;
        _timestamp = [[NSDate date] timeIntervalSince1970];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name sessionId:(NSString *)session timestamp:(NSTimeInterval)stamp properties:(NSDictionary *)props {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict nnSafeSetObject: name forKey: kNameKey];
    [dict nnSafeSetObject: session forKey: kSessionIdKey];
    [dict nnSafeSetObject: @(stamp) forKey: kTimestampKey];
    [dict nnSafeSetObject: props forKey: kPropertiesKey];
    return [self initWithDictionary: dict];
}

- (void)setSessionId:(NSString *)session {
    if(!_sessionId) {
        _sessionId = [session copy];
    }
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict nnSafeSetObject: self.name forKey: kNameKey];
    [dict nnSafeSetObject: self.sessionId forKey: kSessionIdKey];
    [dict nnSafeSetObject: [NSNumber numberWithDouble: self.timestamp] forKey: kTimestampKey];
    [dict nnSafeSetObject: _properties forKey: kPropertiesKey];
    return dict;
}

@end
