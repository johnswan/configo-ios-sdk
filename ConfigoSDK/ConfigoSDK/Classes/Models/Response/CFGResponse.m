//
//  CFGResponse.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 17/08/15.
//  Copyright (c) 2015 Configo. All rights reserved.
//

#import "CFGResponse.h"
#import "CFGResponseHeader.h"

#import "NNJSONUtilities.h"
#import "NSDictionary+NNAdditions.h"

#pragma mark - Constants
static NSString *const kHeaderKey = @"header";
static NSString *const kResponseKey = @"response";
static NSString *const kConfigKey = @"config";
static NSString *const kFeaturesKey = @"features";
static NSString *const kTimestampKey = @"timestamp";

@implementation CFGResponse

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if(self = [super initWithDictionary: dict]) {
        NSDictionary *header = [NNJSONUtilities validObjectFromObject: dict[kHeaderKey]];
        _responseHeader = [[CFGResponseHeader alloc] initWithDictionary: header];
        
        NSDictionary *response = [NNJSONUtilities validObjectFromObject: dict[kResponseKey]];
        _config = [NNJSONUtilities validObjectFromObject: response[kConfigKey]];
        _features = [NNJSONUtilities validObjectFromObject: response[kFeaturesKey]];
        
        NSNumber *timestampNum = dict[kTimestampKey];
        if(timestampNum) {
            _timestamp = [timestampNum doubleValue];
        } else {
            _timestamp = [[NSDate date] timeIntervalSince1970];
        }
        
    }
    return self;
}

- (NSDictionary *)jsonRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    NSNumber *timestampNum = [NSNumber numberWithDouble: _timestamp];
    [dict nnSafeSetObject: timestampNum forKey: kTimestampKey];
    
    [dict nnSafeSetObject: [_responseHeader dictionaryRepresentation] forKey: kHeaderKey];
    NSMutableDictionary *response = [NSMutableDictionary dictionary];
    [response nnSafeSetObject: _config forKey: kConfigKey];
    [response nnSafeSetObject: _features forKey: kFeaturesKey];
    [dict nnSafeSetObject: response forKey: kResponseKey];
    return dict;
}

-(NSDictionary *)dictionaryRepresentation {
    return [self jsonRepresentation];
}

@end
