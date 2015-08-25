//
//  ConfigoSDKTests.m
//  ConfigoSDKTests
//
//  Created by Natan Abramov on 16/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "Configo.h"

@interface ConfigoTests : XCTestCase

@end

@implementation ConfigoTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testValueForKeyPath {
    XCTestExpectation *expectation = [self expectationWithDescription: @"wait for config"];
    [Configo initWithDevKey: @"123" withAppID: @"9cd20be9cc21d6115a57e2bcbc534fd4"];
    [[NSNotificationCenter defaultCenter] addObserverForName: ConfigoConfigurationLoadCompleteNotification object: nil queue: [NSOperationQueue mainQueue] usingBlock: ^(NSNotification *note) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout: 10.0 handler: ^(NSError *error) {
        if(!error) {
            id value = [[Configo sharedConfig] configForKeyPath: @"data.items.tags[0]"];
            XCTAssertEqualObjects(@"GDD07", value);
        } else {
            XCTFail(@"%@", [error description]);
        }
    }];
}

@end
