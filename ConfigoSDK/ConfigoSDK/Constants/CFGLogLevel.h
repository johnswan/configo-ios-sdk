//
//  CFGLogLevel.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 11/19/15.
//  Copyright © 2015 Configo. All rights reserved.
//


/**
 *	@brief  The ConfigoSDK logging level.
 */
typedef NS_ENUM(NSUInteger, CFGLogLevel) {
    /** All logs will be produced. */
    CFGLogLevelVerbose = 0,
    /** Only warning will be logged. */
    CFGLogLevelWarning,
    /** Only errors will be logged. */
    CFGLogLevelError,
    /** No logs will be produced. */
    CFGLogLevelNone,
};

