//
//  CFGResponse.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 17/08/15.
//  Copyright (c) 2015 Configo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NNJSONObject.h"

@class CFGResponseHeader, CFGConfig;

@interface CFGResponse : NNJSONObject

/** @brief The time when this response was recieved (UTC) */
@property (nonatomic, readonly) NSTimeInterval timestamp;
@property (nonatomic, readonly) CFGResponseHeader *responseHeader;
@property (nonatomic, readonly) NSDictionary *config DEPRECATED_MSG_ATTRIBUTE("Use ConfigObj instead");
@property (nonatomic, readonly) NSArray *features DEPRECATED_MSG_ATTRIBUTE("Use ConfigObj instead");

@property (nonatomic, readonly) CFGConfig *configObj;

@end
