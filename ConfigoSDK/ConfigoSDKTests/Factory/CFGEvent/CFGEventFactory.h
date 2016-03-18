//
//  CFGEventFactory.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 14/03/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CFGEvent;

@interface CFGEventFactory : NSObject

+ (CFGEvent *)randomEvent;
+ (NSArray *)randomEventsArray;

@end
