//
//  CFGFeature.m
//  Pods
//
//  Created by Natan Abramov on 2/28/16.
//
//

#import "CFGFeature.h"

static NSString *const kEnabledKey = @"enabled";
static NSString *const kKeyKey = @"key"; //LOL

@implementation CFGFeature

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if(self = [super initWithDictionary: dict]) {
        _enabled = [self validBooleanFromObject: dict[kEnabledKey]];
        _key = [self validObjectFromObject: dict[kKeyKey]];
    }
    return self;
}

@end
