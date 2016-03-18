//
//  CFGNetworkController.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 27/08/15.
//  Copyright (c) 2015 Configo. All rights reserved.
//

#ifndef CFGNetwork_HEADER
#define CFGNetwork_HEADER

#import <Foundation/Foundation.h>

@class CFGResponse;
@class CFGConfigoData;

typedef void(^CFGConfigLoadCallback)(CFGResponse *response, NSError *error);
typedef void(^CFGStatusPollCallback)(BOOL shouldUpdate, NSError *error);
typedef void(^CFGSendEventsCallback)(BOOL success, NSError *error);

@interface CFGNetworkController : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithDevKey:(NSString *)devKey appId:(NSString *)appId;

- (void)requestConfigWithConfigoData:(NSDictionary *)data callback:(CFGConfigLoadCallback)callback;
- (void)pollStatusWithUdid:(NSString *)udid callback:(CFGStatusPollCallback)callback;
- (void)sendEvents:(NSArray *)events withUdid:(NSString *)udid withCallback:(CFGSendEventsCallback)callback;


@end

#endif