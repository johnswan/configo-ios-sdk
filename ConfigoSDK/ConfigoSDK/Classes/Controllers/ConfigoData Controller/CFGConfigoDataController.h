//
//  CFGConfigoDataController.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 26/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CFGConfigoData;

@interface CFGConfigoDataController : NSObject

- (BOOL)detailsChanged;
- (NSString *)udid;

- (instancetype)initWithDevKey:(NSString *)devKey appId:(NSString *)appId;
- (instancetype)initWithConfigoData:(CFGConfigoData *)configoData;

- (NSDictionary *)configoDataForRequest;

- (BOOL)setCustomUserId:(NSString *)customUserId;

- (NSDictionary *)userContext;
- (BOOL)setUserContext:(NSDictionary *)userContext;
- (BOOL)setUserContextValue:(id)value forKey:(NSString *)key;

- (BOOL)saveConfigoDataWithDevKey:(NSString *)devKey appId:(NSString *)appId;
- (BOOL)saveConfigoDataWithDevKey:(NSString *)devKey appId:(NSString *)appId error:(NSError **)err;

@end
