//
//  CFGResponseHeader.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 17/08/15.
//  Copyright (c) 2015 Configo. All rights reserved.
//

#import "CFGResponseHeader.h"
#import "CFGInternalError.h"

#import "NNJSONUtilities.h"
#import "NSDictionary+NNAdditions.h"

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
    return [self dictionaryRepresentation];
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [super dictionaryRepresentation]];
    [dict nnSafeSetObject: _trxId forKey: kTrxIdKey];
    [dict nnSafeSetObject: @(_statusCode) forKey: kStatusCodeKey];
    [dict nnSafeSetObject: _statusMessage forKey: kStatusMessageKey];
    [dict nnSafeSetObject: [_internalError dictionaryRepresentation] forKey: kInternalErrorKey];
    return dict;
}

@end
