//
//  CFGEvent.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 13/03/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#import "CFGEvent.h"

#import "NSDictionary+NNAdditions.h"

static NSString *const kNameKey = @"name";
static NSString *const kSessionIdKey = @"sessionId";
static NSString *const kTimestampKey = @"timestamp";
static NSString *const kPropertiesKey = @"properties";

@implementation CFGEvent

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if(self = [super initWithDictionary: dict]) {
        
    }
    return self;
}

- (NSDictionary *)jsonRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    return dict;
}

@end
