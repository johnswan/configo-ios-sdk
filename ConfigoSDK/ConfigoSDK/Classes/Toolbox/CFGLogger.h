//
//  CFGLogger.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 11/19/15.
//  Copyright © 2015 Turrisio. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CFGLogLevel.h"

@interface CFGLogger : NSObject

+ (void)setLoggingLevel:(CFGLogLevel)level;

+ (void)log:(NSString *)format, ...;

@end
