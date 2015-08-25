//
//  CFGResponse.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 17/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NNLibraries/NNJSONObject.h>

@interface CFGResponse : NNJSONObject

@property (nonatomic, readonly) NSString *configID;
@property (nonatomic, readonly) NSDictionary *config;

@end
