//
//  CFGConfig.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 1/18/16.
//  Copyright © 2016 Turrisio. All rights reserved.
//

#import "NNJSONObject.h"
#import <Foundation/Foundation.h>

@interface CFGConfig : NNJSONObject
@property (nonatomic, readonly) NSDictionary *configDictionary;
@property (nonatomic, readonly) NSArray *featuresArray;

- (instancetype)initWithConfig:(NSDictionary *)config features:(NSArray *)features;
@end
