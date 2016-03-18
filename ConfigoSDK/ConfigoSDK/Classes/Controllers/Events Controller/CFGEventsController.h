//
//  CFGEventsController.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 14/03/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#import <Foundation/Foundation.h>

//TODO: Save events that we failed to send, on app exit / background.
//TODO: Send events when app is closed (register a task?)

@class CFGEvent;

typedef NS_ENUM(NSUInteger, CFGEventsState) {
    CFGEventsStateQueued = 0,
    CFGEventsStateInProgress,
    CFGEventsStateFailed,
};

@interface CFGEventsController : NSObject
@property (nonatomic, readonly) NSString *sessionId;
@property (nonatomic, readonly) CFGEventsState state;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDevKey:(NSString *)devKey appId:(NSString *)appId udid:(NSString *)udid;

- (NSArray *)events;
- (void)addEvent:(NSString *)name withProperties:(NSDictionary *)properties;
- (void)addEvent:(CFGEvent *)event;
- (void)addEvents:(NSArray *)events;

@end
