//
//  ConfigoPrivate.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 18/03/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#ifndef ConfigoPrivate_h
#define ConfigoPrivate_h

@class CFGConfigoDataController, CFGFileController, CFGEventsController, CFGNetworkController, CFGConfigValueFetcher;
@class CFGResponse;

@interface Configo ()
@property (nonatomic, assign) BOOL badCredentials;
@property (nonatomic, copy) NSString *devKey;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, strong) CFGConfigoDataController *configoDataController;
@property (nonatomic, strong) CFGFileController *fileController;
@property (nonatomic, strong) CFGEventsController *eventsController;
@property (nonatomic, strong) CFGNetworkController *networkController;
@property (nonatomic, strong) CFGConfigValueFetcher *configValueFetcher;

@property (nonatomic, strong) CFGResponse *activeConfigoResponse;
@property (nonatomic, strong) CFGResponse *latestConfigoResponse;

@property (nonatomic, copy) CFGCallback listenerCallback;
@property (nonatomic, copy) CFGCallback tempListenerCallback;
@property (nonatomic, strong) NSMutableArray *callbacks;

@property (nonatomic, copy) NSTimer *pollingTimer;
@end

#endif /* ConfigoPrivate_h */
