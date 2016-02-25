//
//  CFGResponseFactory.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 1/21/16.
//  Copyright © 2016 Turrisio. All rights reserved.
//

#import "CFGResponseFactory.h"
#import "CFGResponse.h"

@implementation CFGResponseFactory

+ (CFGResponse *)staticSuccessResponse {
    NSDictionary *dict = [self successResponseDictionary];
    return [[CFGResponse alloc] initWithDictionary: dict];
}

+ (CFGResponse *)dynamicSuccessResponse {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [self successResponseDictionary]];
    int randomInt = arc4random() % 1000;
    NSNumber *randomNumber = [NSNumber numberWithInt: randomInt];
    dict[@"response"][@"config"][@"key"] = randomNumber;
    return [[CFGResponse alloc] initWithDictionary: dict];
}

+ (NSDictionary *)successResponseDictionary {
    return @{@"header" : @{
                     
                     },
             @"response" : @{
                     @"config" : @{
                             @"key" : @"value"
                             },
                     @"features" : @[
                             @"coolFeature"
                             ]
                     }
             };
}


@end
