//
//  ViewController.m
//  ConfigoExample
//
//  Created by Natan Abramov on 16/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import "ViewController.h"

#import <ConfigoSDK/Configo.h>
#import "MBProgressHUD.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *drillField;
@property (weak, nonatomic) IBOutlet UITextView *configView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserverForName: ConfigoConfigurationLoadCompleteNotification
                                                      object: nil
                                                       queue: [NSOperationQueue mainQueue]
                                                  usingBlock: ^(NSNotification *note) {
                                                      NSDictionary *config = [note object];
                                                      NSLog(@"Configuration Loaded: %@", config);
                                                      [self clear: nil];
                                                  }];
    [Configo initWithDevKey: @"123" appId: @"9cd20be9cc21d6115a57e2bcbc534fd4"];
    
    [[Configo sharedConfigo] setCustomUserId: @"natanavra@gmail.com" userContext: @{@"age" : @22,
                                                                                    @"roles" : @[@"CTO", @"Co-founder"],
                                                                                    @"attributes" : @{@"height" : @182.5,
                                                                                                      @"charisma" : @"high"}}];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo: self.view animated: YES];
    hud.labelText =  @"Hello";
    [hud hide: YES afterDelay: 3];    
}

- (IBAction)pullConfig:(id)sender {
    [[Configo sharedConfigo] pullConfig];
}

- (IBAction)drill:(id)sender {
    id value = [[Configo sharedConfigo] configForKeyPath: _drillField.text];
    [_configView setText: value ? [NSString stringWithFormat: @"(%@): \n%@", NSStringFromClass([value class]), value] : @"Value not found"];
}

- (IBAction)clear:(id)sender {
    _drillField.text = nil;
    [_configView setText: [NSString stringWithFormat: @"%@", [[Configo sharedConfigo] config]]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

@end
