//
//  PageViewController.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BaseViewController.h"
//#import "HudViewController.h"

@interface PageViewController : BaseViewController <UIPageViewControllerDelegate, UIPageViewControllerDataSource>

@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic, copy) NSArray *viewControllers;

- (void)setupViewControllers;

- (BOOL)isAllowScrollView;

@end
