//
//  CFGBaseTestCase.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 16/03/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#ifndef CFGBaseTestCase_h
#define CFGBaseTestCase_h

#import <XCTest/XCTest.h>

@interface CFGBaseTestCase : XCTestCase
- (void)checkAssertBlock:(void(^)())block afterDelay:(NSTimeInterval)delay;
@end

#endif /* CFGBaseTestCase_h */
