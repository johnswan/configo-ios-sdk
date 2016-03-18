//
//  CFGLoggerTests.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 14/03/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "CFGLogger.h"

@interface CFGLoggerTests : XCTestCase

@end

@implementation CFGLoggerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFormat {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    [CFGLogger logLevel: CFGLogLevelVerbose log: @"Testing Logger"];
}

@end
