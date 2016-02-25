//
//  CFGResponseFactory.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 1/21/16.
//  Copyright © 2016 Turrisio. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CFGResponse;

@interface CFGResponseFactory : NSObject

+ (CFGResponse *)dynamicSuccessResponse;
+ (CFGResponse *)staticSuccessResponse;

@end
