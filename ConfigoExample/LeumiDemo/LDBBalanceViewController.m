//
//  LDBBalanceViewController.m
//  ConfigoExample
//
//  Created by Natan Abramov on 04/04/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#import "LDBBalanceViewController.h"

#import <ConfigoSDK/ConfigoSDK.h>

@implementation LDBBalanceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupConfigoCallback];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    [self displayBanner];
}

- (void)setupConfigoCallback {
    [[NSNotificationCenter defaultCenter] addObserverForName: ConfigoConfigurationLoadCompleteNotification object: [Configo sharedInstance] queue: [NSOperationQueue mainQueue] usingBlock: ^(NSNotification *note) {
        [self displayBanner];
    }];
}

- (void)displayBanner {
    UIView *banner = [self bannerView];
    [banner removeFromSuperview];
    
    [self.view addSubview: banner];
    NSDictionary *views = NSDictionaryOfVariableBindings(banner);
    
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"H:|-0-[banner]-0-|" options: kNilOptions metrics: nil views: views]];
    if([[Configo sharedInstance] featureFlagForKey: @"bottomBanner" fallback: NO]) {
        [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"V:[banner(100)]-|" options: kNilOptions metrics: nil views: views]];
    } else {
        [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-[banner(100)]" options: kNilOptions metrics: nil views: views]];
    }
}

- (UIView *)bannerView {
    if(!_bannerView) {
        _bannerView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, self.view.frame.size.width, 100)];
        _bannerView.backgroundColor = [UIColor redColor];
        _bannerView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _bannerView;
}

@end
