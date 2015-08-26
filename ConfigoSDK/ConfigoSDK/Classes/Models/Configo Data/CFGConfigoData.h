//
//  CFGConfigoData.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 25/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import <NNLibraries/NNJSONObject.h>

@interface CFGConfigoData : NNJSONObject <NSCopying>

@property (nonatomic, copy) NSString *udid;
@property (nonatomic, copy) NSString *customUserId;
@property (nonatomic, strong) NSDictionary *deviceDetails;


- (NSDictionary *)userContext;
- (void)setUserContext:(NSDictionary *)userContext;

- (void)setUserContextValue:(id)value forKey:(NSString *)key;

@end
