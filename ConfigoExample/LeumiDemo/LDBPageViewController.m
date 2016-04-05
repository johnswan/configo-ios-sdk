//
//  LDBPageViewController.m
//  ConfigoExample
//
//  Created by Natan Abramov on 04/04/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#import "LDBPageViewController.h"


@implementation LDBPageViewController

static NSString *const kLoginViewControllerId = @"loginController";
static NSString *const kBalanceViewControllerId = @"balanceController";

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataSource = self;
    self.delegate = self;
    
    UIViewController *controller1 = [self.storyboard instantiateViewControllerWithIdentifier: kBalanceViewControllerId];
    UIViewController *controller2 = [self.storyboard instantiateViewControllerWithIdentifier: kLoginViewControllerId];
    _pagesControllers = @[controller1, controller2];
    [self setViewControllers: @[controller2] direction: UIPageViewControllerNavigationDirectionReverse animated: NO completion: nil];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger idx = [_pagesControllers indexOfObject: viewController];
    return idx == 1 ? _pagesControllers[0] : nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger idx = [_pagesControllers indexOfObject: viewController];
    return idx == 0 ? _pagesControllers[1] : nil;
}

@end
