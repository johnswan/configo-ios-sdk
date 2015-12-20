//
//  CFGResponseHeader.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 17/08/15.
//  Copyright (c) 2015 Configo. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NNJSONObject.h"

@class CFGInternalError;

@interface CFGResponseHeader : NNJSONObject
@property (nonatomic, readonly) NSString *trxId;
@property (nonatomic, readonly) NSInteger statusCode;
@property (nonatomic, readonly) NSString *statusMessage;
@property (nonatomic, readonly) CFGInternalError *internalError;
@end
