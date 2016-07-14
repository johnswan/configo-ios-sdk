//
//  CFGErrorConstants.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 25/08/15.
//  Copyright (c) 2015 Configo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CFGErrorCode) {
    CFGErrorNotConnected = 1,
    CFGErrorBadResponse = 40,
    CFGErrorRequestFailed = 41,
};