//
//  CFGEventFactory.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 14/03/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#import "CFGEventFactory.h"
#import "CFGEvent.h"

@implementation CFGEventFactory

+ (CFGEvent *)randomEvent {
    NSString *name = [NSString stringWithFormat: @"event-name-%li", (long)[self randomNumberWithMinRange: 0 withMaxRange: 100000]];
    NSString *sessionId = @"session123";
    NSTimeInterval stamp = (NSTimeInterval)[self randomNumberWithMinRange: [[NSDate dateWithTimeIntervalSince1970: 0] timeIntervalSince1970]
                                                             withMaxRange: NSIntegerMax];
    
    NSMutableDictionary *properties = nil;
    BOOL withProperties = arc4random() % 2 == 0;
    if(withProperties) {
        properties = [NSMutableDictionary dictionary];
        int numProps = 1 + arc4random() % 3;
        for(int i = 0 ; i < numProps ; i ++) {
            NSString *value = [@"value " stringByAppendingFormat: @"%li", (long)[self randomNumberWithMinRange: 0 withMaxRange: 10]];
            NSString *key = [@"key " stringByAppendingFormat: @"%i", i];
            properties[key] = value;
        }
    }
    
    CFGEvent *event = [[CFGEvent alloc] initWithName: name sessionId: sessionId timestamp: stamp properties: properties];
    return event;
}

+ (NSInteger)randomNumberWithMinRange:(NSInteger)min withMaxRange:(NSInteger)max {
    return (min + arc4random() % (max - min + 1));
}

+ (NSArray *)randomEventsArray {
    NSInteger numEvents = [self randomNumberWithMinRange: 1 withMaxRange: 5];
    NSMutableArray *randomEvents = [NSMutableArray array];
    for(int i = 0 ; i < numEvents ; i ++) {
        [randomEvents addObject: [CFGEventFactory randomEvent]];
    }
    return randomEvents;
}

@end
