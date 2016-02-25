//
//  ConfigoSDKTests.m
//  ConfigoSDKTests
//
//  Created by Natan Abramov on 1/18/16.
//  Copyright © 2016 Turrisio. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Configo.h"

@interface ConfigoSDKTests : XCTestCase
@property (nonatomic, weak) Configo *configo;
@end

@implementation ConfigoSDKTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSString *devKey = @"***REMOVED***";
    NSString *appId = @"***REMOVED***";
    [Configo initWithDevKey: devKey appId: appId];
    _configo = [Configo sharedInstance];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)DISABLED_testThatCallbackIsCalledOnce {
    XCTestExpectation *expectation = [self expectationWithDescription: @"Configo Callback"];
    
    __block NSInteger numCalls = 0;
    [_configo setCallback: ^(NSError *error, NSDictionary *rawConfig, NSArray *featuresList) {
        numCalls ++;
        if(numCalls > 1) {
            [expectation fulfill];
        }
    }];
    
    NSTimeInterval timeout = 30.0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeout - 1) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout: timeout handler: ^(NSError *error) {
        XCTAssert(numCalls == 1, "Should only be called once");
    }];
}


/**
 @description The goal of this test is to mock changes and test if pullConfig is triggered
 */
- (void)DISABLED_testPullConfigOnContextChange {
    
}

@end
