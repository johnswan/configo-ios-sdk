//
//  ConfigoSDKTests.m
//  ConfigoSDKTests
//
//  Created by Natan Abramov on 1/18/16.
//  Copyright © 2016 Turrisio. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Configo.h"

#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

@interface ConfigoSDKTests : XCTestCase
@property (nonatomic, weak) Configo *configo;
@end

@implementation ConfigoSDKTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSString *devKey = @"test";
    NSString *appId = @"test";
    [Configo initWithDevKey: devKey appId: appId];
    _configo = [Configo sharedInstance];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



@end
