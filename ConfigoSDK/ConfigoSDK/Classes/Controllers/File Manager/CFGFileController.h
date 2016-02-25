//
//  CFGFileManager.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 25/08/15.
//  Copyright (c) 2015 Configo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CFGConfigoData;
@class CFGResponse;

@interface CFGFileController : NSObject

+ (instancetype)sharedManager DEPRECATED_MSG_ATTRIBUTE("No longer a singleton, use initWithDevKey:appId:");

- (instancetype)initWithDevKey:(NSString *)devKey appId:(NSString *)appId;

//NEW APIs
- (BOOL)saveResponse:(CFGResponse *)response error:(NSError **)err;
- (CFGResponse *)readResponse:(NSError **)err;

- (BOOL)saveConfigoData:(CFGConfigoData *)configoData error:(NSError **)err;
- (CFGConfigoData *)readConfigoData:(NSError **)err;

//OLD APIs
- (BOOL)saveResponse:(CFGResponse *)response withDevKey:(NSString *)devKey withAppId:(NSString *)appId error:(NSError **)err;
- (CFGResponse *)loadLastResponseForDevKey:(NSString *)devKey appId:(NSString *)appId error:(NSError **)err;

- (BOOL)saveConfigoData:(CFGConfigoData *)configoData withDevKey:(NSString *)devKey appId:(NSString *)appId error:(NSError **)err;
- (CFGConfigoData *)loadConfigoDataForDevKey:(NSString *)devKey appId:(NSString *)appId error:(NSError **)err;
@end
