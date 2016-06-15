//
//  CFGFeature.m
//  Pods
//
//  Created by Natan Abramov on 2/28/16.
//
//

#import "CFGFeature.h"
#import "NSDictionary+NNAdditions.h"

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

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict nnSafeSetObject: @(_enabled) forKey: kEnabledKey];
    return dict.count > 0 ? dict : nil;
}

@end
