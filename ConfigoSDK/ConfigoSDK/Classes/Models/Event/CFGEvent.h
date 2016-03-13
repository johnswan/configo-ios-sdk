//
//  CFGEvent.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 13/03/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#import "NNJSONObject.h"

@interface CFGEvent : NNJSONObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *sessionId;
@property (nonatomic) NSTimeInterval timestamp;
@property (nonatomic) NSDictionary *properties;

@end
