//
//  PageViewController.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "PageViewController.h"

@interface PageViewController ()
@property (nonatomic, strong)UIView *statuesView;
@property (nonatomic, strong)UILabel *statuesLabel;

@end

@implementation PageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //添加状态栏
    self.statuesView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, STATUESVIEWHEIGHT)];
    self.statuesView.backgroundColor = UIColorFromRGB(0xffbfbf);
    UIImageView *leftImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_bc"]];
    leftImg.frame = CGRectMake(15, (STATUESVIEWHEIGHT-STATUESVIEWIMAGEHEIGHT)/2, STATUESVIEWIMAGEHEIGHT, STATUESVIEWIMAGEHEIGHT);
    [self.statuesView addSubview:leftImg];
    self.statuesLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftImg.frame)+5, 0, kScreenWidthValue-30-leftImg.frame.size.width, STATUESVIEWHEIGHT)];
    self.statuesLabel.text = @"这个状态栏比较6";
    self.statuesLabel.font = [UIFont systemFontOfSize:14];
    self.statuesLabel.textColor = UIColorFromRGB(0x999999);
    [self.statuesView addSubview:self.statuesLabel];
    [self.view addSubview:self.statuesView];
    
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
//    self.view.frame = CGRectMake(0, self.statuesView.frame.size.height, kScreenWidthValue, kScreenHeightValue-64-49-self.statuesView.frame.size.height);
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
//    _pageViewController.view.frame = CGRectMake(0, self.statuesView.frame.size.height, kScreenWidthValue, kScreenHeightValue-64-49-self.statuesView.frame.size.height);
    
    _pageViewController.view.top += self.statuesView.frame.size.height;
    _pageViewController.view.height -= (self.statuesView.frame.size.height+49);
    
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    
//    [self updateSubViewsFrame];
    
    // 设置首先要显示的控制器
    [_pageViewController setViewControllers:@[_viewControllers[0]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    [_pageViewController didMoveToParentViewController:self];
}

//- (void)updateSubViewsFrame
//{
//    NSLog(@"height--%.f,bounds--%@", kScreenHeightValue, NSStringFromCGRect(self.pageViewController.view.bounds));
//    if (self.viewControllers) {
//        for (UIViewController *vc in self.viewControllers) {
//            vc.view.frame = self.pageViewController.view.bounds;
//        }
//    }
//
//}

- (void)setupViewControllers
{
//    if (!self.viewControllers) {
//        // 设置所有ViewControllers
//        UIViewController *v1    = [UIViewController new];
//        UIViewController *v2    = [UIViewController new];
//        
//        v1.view.backgroundColor = [UIColor redColor];
//        v2.view.backgroundColor = [UIColor greenColor];
//        
//        _viewControllers        = @[v1, v2];
//    }
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
