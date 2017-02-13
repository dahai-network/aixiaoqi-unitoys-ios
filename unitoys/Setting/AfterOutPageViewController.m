//
//  AfterOutPageViewController.m
//  unitoys
//
//  Created by sumars on 16/11/16.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "AfterOutPageViewController.h"

@interface AfterOutPageViewController ()

@end

@implementation AfterOutPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //左边按钮
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithImage:[[UIImage imageNamed:@"btn_back"] imageWithRenderingMode:/*去除渲染效果*/UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonAction)];
    
    self.dataSource = self;
    
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
    
    UIViewController *afterOutStep1 = [mainStory instantiateViewControllerWithIdentifier:@"afterOutStep1"];
    //                UIViewController *afterOutStep2 = [mainStory instantiateViewControllerWithIdentifier:@"afterOutStep2"];
    NSArray *viewControllers = @[afterOutStep1];
    [self setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    // Do any additional setup after loading the view.
}

- (void)leftButtonAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
/*
- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return 2;
}*/

//- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    /*
    NSUInteger index =  ((PageContentViewController*) viewController).pageIndex;
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index];*/
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    /*
    NSUInteger index = ((PageContentViewController*) viewController).pageIndex;
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [self.pageTitles count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index];*/
    if ([viewController.title isEqualToString:@"Second"]) {
        return nil;
    }
    
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
    if (mainStory) {
        UIViewController *afterOutStep2 = [mainStory instantiateViewControllerWithIdentifier:@"afterOutStep2"];
        afterOutStep2.title = @"Second";
        return afterOutStep2;
    }else{
        return nil;
    }
    
}



@end
