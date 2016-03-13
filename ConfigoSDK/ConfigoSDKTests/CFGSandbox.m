//
//  CFGSandbox.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 13/03/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NNJSONUtilities.h"

@interface CFGSandbox : XCTestCase

@end

@implementation CFGSandbox

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDictionaryToJsonBadObject {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    NSDictionary *dict = [self dict];
    BOOL result = [NSJSONSerialization isValidJSONObject: dict];
    XCTAssertFalse(result);
}

- (void)testJsonCleaner {
    NSDictionary *dict = [NNJSONUtilities makeValidJSONObject: [self dict]];
    NSLog(@"Clean dict: \n%@", dict);
    BOOL result = [NSJSONSerialization isValidJSONObject: dict];
    XCTAssertTrue(result);
}

- (void)testNumberToJson {
    NSNumber *num = @123;
    BOOL result = [NSJSONSerialization isValidJSONObject: num];
    XCTAssertFalse(result);
}

- (NSDictionary *)dict {
    NSDictionary *dict = @{
                           @"string" : @"value",
                           @"number" : @123,
                           @"forbidden" : [NSObject new],
                           @"dict" : @{
                                   @"nestedDict" : @{
                                           @"forbidden" : [NSObject new]
                                           },
                                   @"nestedBadArr" : @[
                                           [NSObject new],
                                           @"good",
                                           [NSObject new],
                                           @12
                                           ]
                                   },
                           @"badArr" : @[
                                   @"good",
                                   [NSObject new],
                                   @123
                                   ]
                           };
    return dict;
}

@end
