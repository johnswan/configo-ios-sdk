//
//  CFGLogger.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 11/19/15.
//  Copyright © 2015 Configo. All rights reserved.
//

#import "CFGLogger.h"
#import "CFGConstants.h"

@implementation CFGLogger

static CFGLogLevel logLevel = CFGLogLevelVerbose;

+ (void)setLoggingLevel:(CFGLogLevel)level {
    logLevel = level;
}

+ (void)logLevel:(CFGLogLevel)level log:(NSString *)format, ... {
    if(logLevel <= level) {
        va_list args;
        va_start(args, format);
        NSString *log = [[NSString alloc] initWithFormat: format arguments: args];
        [self printLog: log withLogLevel: level];
    }
}

+ (void)printLog:(NSString *)log withLogLevel:(CFGLogLevel)level {
    NSLog(@"[ConfigoSDK (%@): %@] %@", ConfigoSDKVersion, [self stringFromLogLevel: level], log);
}

+ (NSString *)stringFromLogLevel:(CFGLogLevel)logLevel {
    NSString *retval = nil;
    switch(logLevel) {
        case CFGLogLevelVerbose:
            retval = @"Verbose";
            break;
        case CFGLogLevelWarning:
            retval = @"WARNING";
            break;
        case CFGLogLevelError:
            retval = @"ERROR";
            break;
        case CFGLogLevelNone:
        default:
            break;
    }
    return retval;
}


@end
