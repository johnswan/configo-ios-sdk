//
//  FileControllerTests.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 1/21/16.
//  Copyright © 2016 Turrisio. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "CFGFileController.h"
#import "CFGResponseFactory.h"

@interface FileControllerTests : XCTestCase
@property (nonatomic, strong) CFGFileController *fileController;
@end

@implementation FileControllerTests

- (void)setUp {
    [super setUp];
    NSString *devKey = @"test";
    NSString *appId = @"test";
    _fileController = [[CFGFileController alloc] initWithDevKey: devKey appId: appId];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFileControllerCreate {
    XCTAssertNotNil(_fileController);
}

- (void)testFileSave {
    NSError *err = nil;
    BOOL success = [_fileController saveResponse: [CFGResponseFactory staticSuccessResponse] error: &err];
    XCTAssertTrue(success);
    XCTAssertNil(err);
}

@end
