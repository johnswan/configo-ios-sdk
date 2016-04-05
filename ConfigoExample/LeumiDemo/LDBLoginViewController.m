//
//  ViewController.m
//  LeumiDemo
//
//  Created by Natan Abramov on 03/04/2016.
//  Copyright © 2016 Turrisio. All rights reserved.
//

#import "LDBLoginViewController.h"
#import <ConfigoSDK/ConfigoSDK.h>

@interface LDBLoginViewController ()
@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (weak, nonatomic) IBOutlet UIButton *transferBtn;
@property (weak, nonatomic) IBOutlet UIButton *scanPayBtn;
@property (weak, nonatomic) IBOutlet UIButton *depositBtn;
@property (weak, nonatomic) IBOutlet UIButton *branchesBtn;
@property (weak, nonatomic) IBOutlet UIButton *helpBtn;
@property (weak, nonatomic) IBOutlet UIButton *whatsNewBtn;
@property (weak, nonatomic) IBOutlet UISegmentedControl *abSegment;
@end

@implementation LDBLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupConfigoCallback];
}

- (void)setupConfigoCallback {
    [[Configo sharedInstance] setCallback: ^(NSError *error, NSDictionary *rawConfig, NSArray *featuresList) {
        _welcomeLabel.text = [[Configo sharedInstance] configValueForKeyPath: @"welcomeString" fallbackValue: _welcomeLabel.text];
        BOOL transfersFeature = [[Configo sharedInstance] featureFlagForKey: @"transfers-pre-login" fallback: NO];
        _transferBtn.hidden = !transfersFeature;
    }];
}

//- (void)updateStateText {
//    NSString *stateText = nil;
//    CFGConfigLoadState state = [[Configo sharedInstance] state];
//    switch(state) {
//        case CFGConfigNotAvailable:
//            stateText = @"Config Not Available";
//            break;
//        case CFGConfigLoadingInProgress:
//            stateText = @"Config is loading";
//            break;
//        case CFGConfigLoadedFromStorage:
//            stateText = @"Config is loaded from storage";
//            break;
//        case CFGConfigLoadedFromServer:
//            stateText = @"Config is loaded from server";
//            break;
//        case CFGConfigFailedLoadingFromServer:
//            stateText = @"Config failed loading from server";
//            break;
//        default:
//            break;
//    }
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
