//
//  CFGEventsController.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 14/03/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#import "CFGEventsController.h"
#import "CFGEvent.h"
#import "CFGConstants.h"

#import "CFGNetworkController.h"
#import "CFGPrivateConfigService.h"

#import "NNUtilities.h"
#import "NSArray+NNAdditions.h"
#import "NNLogger.h"

@interface CFGEventsController ()
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *devKey;
@property (nonatomic, copy) NSString *udid;
@property (nonatomic, strong) CFGNetworkController *netController;
@property (nonatomic, strong, getter=_events) NSMutableArray *events;
@property (nonatomic, strong) NSTimer *sendScheduler;
@end

@implementation CFGEventsController

#pragma mark - Init & Setup

- (instancetype)init {
    NSAssert(false, @"Use initWithDevKey:appId:udid: instead.");
    return nil;
}

- (instancetype)initWithDevKey:(NSString *)devKey appId:(NSString *)appId udid:(NSString *)udid {
    NSParameterAssert(devKey);
    NSParameterAssert(appId);
    NSParameterAssert(udid);
    if(self = [super init]) {
        _state = CFGEventsStateQueued;
        self.devKey = devKey;
        self.appId = appId;
        self.udid = udid;
        _sessionId = [NNUtilities uniqueIdentifier];
        _events = [NSMutableArray array];
        _netController = [[CFGNetworkController alloc] initWithDevKey: _devKey
                                                                appId: _appId];
        [self startSession];
        [self observeApplicationTerminateNotification];
        [self setupTimer];
    }
    return self;
}

- (void)setupTimer {
    NSTimeInterval interval = CFGPrivateConfigDouble(@"events-push-interval.ios");
    if(interval == 0) {
        interval = CFGDefaultEventPushInterval;
    }
    _sendScheduler = [NSTimer scheduledTimerWithTimeInterval: interval target: self selector: @selector(sendEvents) userInfo: nil repeats: YES];
}

- (void)observeApplicationTerminateNotification {
    [[NSNotificationCenter defaultCenter] addObserverForName: UIApplicationWillTerminateNotification object: [UIApplication sharedApplication] queue: [NSOperationQueue mainQueue] usingBlock: ^(NSNotification *note) {
        [self endSession];
    }];
}

#pragma mark - Getters

- (NSArray *)events {
    return _events;
}

#pragma mark - Session Events

- (void)startSession {
    NNLogDebug(@"Start session", nil);
    [self addEvent: CFGSessionStartEventName withProperties: nil];
}

- (void)endSession {
    NNLogDebug(@"End session", nil);
    [self addEvent: CFGSessionEndEventName withProperties: nil];
}

#pragma mark - Event Addition & Removal

- (void)addEvent:(NSString *)name withProperties:(NSDictionary *)properties {
    if(!name) {
        return;
    }
    //TODO: Cleanup the properties, or at least check that it's valid.
    CFGEvent *event = [[CFGEvent alloc] initWithName: name withProperties: properties];
    [self addEvent: event];
}

- (void)addEvent:(CFGEvent *)event {
    [event setSessionId: _sessionId];
    BOOL added = [_events nnSafeAddObject: event];
    NNLogDebug(added ? @"Event added" : @"Event not added", event);
}

- (void)addEvents:(NSArray *)events {
    for(id obj in events) {
        if([obj isKindOfClass: [CFGEvent class]]) {
            [self addEvent: (CFGEvent *)obj];
        }
    }
}

- (void)flushEvents {
    _state = CFGEventsStateQueued;
    NNLogDebug(@"Flushing events", @(_events.count));
    [_events removeAllObjects];
}

#pragma mark - Event Sending

- (void)sendEvents {
    if(_events.count == 0 || _state == CFGEventsStateInProgress) {
        NNLogDebug(@"No events to send, or already sending", nil);
        return;
    }
    NNLogDebug(@"Sending events", nil);
    _state = CFGEventsStateInProgress;
    [_netController sendEvents: _events withUdid: _udid withCallback: ^(BOOL success, NSError *error) {
        if(success && !error) {
            NNLogDebug(@"Sending events success", nil);
            [self flushEvents];
        } else {
            _state = CFGEventsStateFailed;
            NNLogDebug(@"Failed to send events", error);
        }
    }];
}

@end
