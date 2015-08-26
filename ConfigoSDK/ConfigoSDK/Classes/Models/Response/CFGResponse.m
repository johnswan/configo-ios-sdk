//
//  CFGResponse.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 17/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import "CFGResponse.h"
#import "CFGResponseHeader.h"

#import <NNLibraries/NNJSONUtilities.h>
#import <NNLibraries/NSDictionary+NNAdditions.h>

#pragma mark - Constants
static NSString *const kHeaderKey = @"header";
static NSString *const kResponseKey = @"response";
static NSString *const kConfigIDKey = @"_id";
static NSString *const kConfigKey = @"config";

@implementation CFGResponse

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if(self = [super initWithDictionary: dict]) {
        NSDictionary *header = [NNJSONUtilities validObjectFromObject: dict[kHeaderKey]];
        _responseHeader = [[CFGResponseHeader alloc] initWithDictionary: header];
        
        NSDictionary *response = [NNJSONUtilities validObjectFromObject: dict[kResponseKey]];
        _configID = [NNJSONUtilities validObjectFromObject: response[kConfigIDKey]];
        _config = [NNJSONUtilities validObjectFromObject: response[kConfigKey]];
    }
    return self;
}

- (NSDictionary *)jsonRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict nnSafeSetObject: [_responseHeader dictionaryRepresentation] forKey: kHeaderKey];
    NSMutableDictionary *response = [NSMutableDictionary dictionary];
    [response nnSafeSetObject: _configID forKey: kConfigIDKey];
    [response nnSafeSetObject: _config forKey: kConfigKey];
    [dict nnSafeSetObject: response forKey: kResponseKey];
    return dict;
}

-(NSDictionary *)dictionaryRepresentation {
    return [self jsonRepresentation];
}

@end
