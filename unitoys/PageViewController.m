//
//  PageViewController.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "PageViewController.h"

@interface PageViewController ()

@end

@implementation PageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self commonInit];
}

- (void)commonInit
{
    [self setupViewControllers];
    
    NSDictionary *options          = @{UIPageViewControllerOptionSpineLocationKey:[NSNumber numberWithInteger:UIPageViewControllerSpineLocationNone]};
    
    _pageViewController            = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:options];
    
    if ([self isAllowScrollView]) {
        _pageViewController.delegate   = self;
        _pageViewController.dataSource = self;
    }
    
    // 设置首先要显示的控制器
    [_pageViewController setViewControllers:@[_viewControllers[0]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    [self.view addSubview:_pageViewController.view];
}

- (void)setupViewControllers
{
    if (!self.viewControllers) {
        // 设置所有ViewControllers
        UIViewController *v1    = [UIViewController new];
        UIViewController *v2    = [UIViewController new];
        UIViewController *v3    = [UIViewController new];
        
        v1.view.backgroundColor = [UIColor redColor];
        v2.view.backgroundColor = [UIColor greenColor];
        v3.view.backgroundColor = [UIColor blueColor];
        
        _viewControllers        = @[v1, v2, v3];
    }
}

- (BOOL)isAllowScrollView
{
    return NO;
}

#pragma mark
#pragma mark PageViewControllerDelegate

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSInteger index = [self.viewControllers indexOfObject:viewController];
    index--;
    
    if (index < 0) {
        return nil;
    }
    
    return self.viewControllers[index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSInteger index = [self.viewControllers indexOfObject:viewController];
    index++;
    
    if (index >= self.viewControllers.count) {
        return nil;
    }
    
    return self.viewControllers[index];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
