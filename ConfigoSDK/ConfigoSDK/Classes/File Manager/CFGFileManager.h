//
//  CFGFileManager.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 25/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CFGConfigoData;

@interface CFGFileManager : NSObject

+ (instancetype)sharedManager;

- (CFGConfigoData *)configoDataForDevKey:(NSString *)devKey appId:(NSString *)appId error:(NSError **)err;

- (BOOL)saveConfigoData:(CFGConfigoData *)configoData
             withDevKey:(NSString *)devKey
                  appId:(NSString *)appId
                  error:(NSError **)err;

@end
