//
//  BeforeBackPageViewController.m
//  unitoys
//
//  Created by sumars on 16/11/16.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BeforeBackPageViewController.h"

@interface BeforeBackPageViewController ()

@end

@implementation BeforeBackPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //左边按钮
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithImage:[[UIImage imageNamed:@"btn_back"] imageWithRenderingMode:/*去除渲染效果*/UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonAction)];
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

@end
