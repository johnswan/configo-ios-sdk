//
//  CFGNetworkController.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 27/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CFGResponse;
@class CFGConfigoData;

typedef void(^CFGConfigLoadCallback)(CFGResponse *, NSError *);

@interface CFGNetworkController : NSObject

- (void)requestConfigWithDevKey:(NSString *)devKey appId:(NSString *)appId configoData:(NSDictionary *)data callback:(CFGConfigLoadCallback)callback;

@end
