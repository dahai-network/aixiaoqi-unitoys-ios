//
//  QuickSettingViewController.m
//  unitoys
//
//  Created by sumars on 16/11/12.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "QuickSettingViewController.h"
#import "BindDeviceViewController.h"
#import "BeforeOutViewController.h"

@interface QuickSettingViewController ()

@end

@implementation QuickSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 15;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==0) {
        UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
        BindDeviceViewController *bindDeviceViewController = [mainStory instantiateViewControllerWithIdentifier:@"bindDeviceViewController"];
        if (bindDeviceViewController) {
            self.tabBarController.tabBar.hidden = YES;
            [self.navigationController pushViewController:bindDeviceViewController animated:YES];
        }
    } else {
        if (indexPath.row==0) {
            UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
            BeforeOutViewController *beforeOutViewController = [mainStory instantiateViewControllerWithIdentifier:@"beforeOutViewController"];
            if (beforeOutViewController) {
                self.tabBarController.tabBar.hidden = YES;
                [self.navigationController pushViewController:beforeOutViewController animated:YES];
            }
        } else if (indexPath.row==1) {
            UIPageControl *pageControl = [UIPageControl appearance];
            pageControl.pageIndicatorTintColor = [UIColor blackColor];
            pageControl.currentPageIndicatorTintColor = [UIColor redColor];
            pageControl.backgroundColor = [UIColor clearColor];
            
            UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
            UIPageViewController *afterOutPageViewController = [mainStory instantiateViewControllerWithIdentifier:@"afterOutPageViewController"];
            if (afterOutPageViewController) {
                self.tabBarController.tabBar.hidden = YES;
                
                [self.navigationController pushViewController:afterOutPageViewController animated:YES];
            }
        } else if (indexPath.row==2) {
            UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
            UIPageViewController *beforeBackPageViewController = [mainStory instantiateViewControllerWithIdentifier:@"beforeBackPageViewController"];
            if (beforeBackPageViewController) {
                self.tabBarController.tabBar.hidden = YES;
                
                UIViewController *afterOutStep1 = [mainStory instantiateViewControllerWithIdentifier:@"afterOutStep1"];
                //                UIViewController *afterOutStep2 = [mainStory instantiateViewControllerWithIdentifier:@"afterOutStep2"];
                NSArray *viewControllers = @[afterOutStep1];
                [beforeBackPageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
                
                [self.navigationController pushViewController:beforeBackPageViewController animated:YES];
            }
        }
    }
}

@end
