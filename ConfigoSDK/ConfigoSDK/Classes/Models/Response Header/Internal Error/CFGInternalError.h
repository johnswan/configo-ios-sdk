//
//  CFGInternalError.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 19/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NNJSONObject.h"

@interface CFGInternalError : NNJSONObject
@property (nonatomic, readonly) NSInteger statusCode;
@property (nonatomic, readonly) NSString *errorDescription;
@property (nonatomic, readonly) NSString *devStack;

- (NSError *)error;

@end
