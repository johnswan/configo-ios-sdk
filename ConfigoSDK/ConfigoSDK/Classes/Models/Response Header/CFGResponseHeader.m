//
//  CFGResponseHeader.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 17/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import "CFGResponseHeader.h"
#import "CFGInternalError.h"

#import <NNLibraries/NNJSONUtilities.h>
#import <NNLibraries/NSDictionary+NNAdditions.h>

#pragma mark - Constants

static NSString *const kTrxIdKey = @"trxId";
static NSString *const kStatusCodeKey = @"statusCode";
static NSString *const kStatusMessageKey = @"statusMessage";
static NSString *const kInternalErrorKey = @"internalError";

#pragma mark - Implementation

@implementation CFGResponseHeader

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if(self = [super initWithDictionary: dict]) {
        _trxId = [NNJSONUtilities validObjectFromObject: dict[kTrxIdKey]];
        _statusCode = [NNJSONUtilities validIntegerFromObject: dict[kStatusCodeKey]];
        _statusMessage = [NNJSONUtilities validObjectFromObject: dict[kStatusMessageKey]];
        NSDictionary *internalErrorDict = [NNJSONUtilities validObjectFromObject: dict[kInternalErrorKey]];
        if(internalErrorDict) {
            _internalError = [[CFGInternalError alloc] initWithDictionary: internalErrorDict];
        }
    }
    return self;
}

- (NSDictionary *)jsonRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [super jsonRepresentation]];
    [dict nnSafeSetObject: _trxId forKey: kTrxIdKey];
    [dict nnSafeSetObject: @(_statusCode) forKey: kStatusCodeKey];
    [dict nnSafeSetObject: _statusMessage forKey: kStatusMessageKey];
    [dict nnSafeSetObject: [_internalError jsonRepresentation] forKey: kInternalErrorKey];
    return dict;
}

- (NSDictionary *)dictionaryRepresentation {
    return [self jsonRepresentation];
}

@end
