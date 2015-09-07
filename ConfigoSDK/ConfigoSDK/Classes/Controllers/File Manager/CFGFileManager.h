//
//  CFGFileManager.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 25/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CFGConfigoData;
@class CFGResponse;

@interface CFGFileManager : NSObject

+ (instancetype)sharedManager;

- (BOOL)saveResponse:(CFGResponse *)response withDevKey:(NSString *)devKey withAppId:(NSString *)appId error:(NSError **)err;
- (CFGResponse *)loadLastResponseForDevKey:(NSString *)devKey appId:(NSString *)appId error:(NSError **)err;

- (BOOL)saveConfigoData:(CFGConfigoData *)configoData withDevKey:(NSString *)devKey appId:(NSString *)appId error:(NSError **)err;
- (CFGConfigoData *)loadConfigoDataForDevKey:(NSString *)devKey appId:(NSString *)appId error:(NSError **)err;
@end
