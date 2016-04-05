//
//  LDBPageViewController.h
//  ConfigoExample
//
//  Created by Natan Abramov on 04/04/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LDBPageViewController : UIPageViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate> {
    NSArray *_pagesControllers;
}
@end
