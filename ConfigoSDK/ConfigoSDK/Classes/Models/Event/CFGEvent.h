//
//  CFGEvent.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 13/03/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#import "NNJSONObject.h"

@interface CFGEvent : NNJSONObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *sessionId;
@property (nonatomic, readonly) NSTimeInterval timestamp;
@property (nonatomic, copy, readonly) NSDictionary *properties;

- (instancetype)initWithName:(NSString *)name withProperties:(NSDictionary *)properties;
- (instancetype)initWithSession:(NSString *)session withName:(NSString *)name withProperties:(NSDictionary *)properties;

/** @brief Will only set the session on the first time, if it's <code>nil</code> */
- (void)setSessionId:(NSString *)session;

/**
 *  @warning Do not use this initializer, for testing purposes only.
 */
- (instancetype)initWithName:(NSString *)name sessionId:(NSString *)session timestamp:(NSTimeInterval)stamp properties:(NSDictionary *)props;

@end
