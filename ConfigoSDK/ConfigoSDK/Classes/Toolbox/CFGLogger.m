//
//  CFGLogger.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 11/19/15.
//  Copyright © 2015 Turrisio. All rights reserved.
//

#import "CFGLogger.h"
#import "CFGConstants.h"

@implementation CFGLogger

static CFGLogLevel logLevel = CFGLogLevelAll;

+ (void)setLoggingLevel:(CFGLogLevel)level {
    logLevel = level;
}

+ (void)log:(NSString *)format, ... {
    if(logLevel == CFGLogLevelAll) {
        va_list args;
        va_start(args, format);
        NSString *str = [[NSString alloc] initWithFormat: format arguments: args];
        NSString *header = [NSString stringWithFormat: @"******************* ConfigoSDK (%@) *******************", ConfigoSDKVersion];
        NSString *footer = [@"" stringByPaddingToLength: header.length withString: @"*" startingAtIndex: 0];
        NSLog(@"%@", header);
        NSLog(@"%@", str);
        NSLog(@"%@", footer);
    }
}

@end
