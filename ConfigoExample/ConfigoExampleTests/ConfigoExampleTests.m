//
//  ConfigoExampleTests.m
//  ConfigoExampleTests
//
//  Created by Natan Abramov on 11/8/15.
//  Copyright © 2015 Turrisio. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ConfigoSDK/ConfigoSDK.h>

@interface ConfigoExampleTests : XCTestCase {
    Configo *_configo;
}
@end

@implementation ConfigoExampleTests

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

- (void)testDynamicallyUpdateValues {
    XCTestExpectation *callbackExpectation = [self expectationWithDescription: @"Configo Callback Expectation"];
    
    [_configo setDynamicallyRefreshValues: YES];
    
    __weak Configo *weakConfigo = _configo;
    NSInteger __block numCalls = 0;
    [_configo setCallback: ^(NSError *error, NSDictionary *rawConfig, NSArray *featuresList) {
        numCalls ++;
        NSLog(@"Callback called");
        if(numCalls == 2) {
            [callbackExpectation fulfill];
        } else {
            NSInteger random = arc4random() % 1000;
            NSNumber *number = [NSNumber numberWithInteger: random];
            [weakConfigo setUserContextValue: number forKey: @"key1"];
            [weakConfigo pullConfig];
        }
    }];
    
    [self waitForExpectationsWithTimeout: 10.0 handler: ^(NSError *error) {
        NSLog(@"Callbacks called twice");
    }];
}

- (void)testTemporaryCallback {
    XCTestExpectation *callbackExpectation = [self expectationWithDescription: @"Configo Temporary Callback"];
    
    [_configo pullConfig: ^(NSError *error, NSDictionary *rawConfig, NSArray *featuresList) {
        NSLog(@"Temporary Callback");
        [callbackExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout: 10.0 handler: ^(NSError *error) {
        NSLog(@"Expectation fulfilled");
    }];
}

@end
