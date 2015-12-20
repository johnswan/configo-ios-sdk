//
//  CFGResponse.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 17/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NNJSONObject.h"

@class CFGResponseHeader;

@interface CFGResponse : NNJSONObject

/** @brief The time when this response was recieved (UTC) */
@property (nonatomic, readonly) NSTimeInterval timestamp;
@property (nonatomic, readonly) CFGResponseHeader *responseHeader;
@property (nonatomic, readonly) NSDictionary *config;
@property (nonatomic, readonly) NSArray *features;

@end
