//
//  UNHudViewController.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/16.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNHudViewController.h"
#import "MBProgressHUD+UNTip.h"

@interface UNHudViewController ()



@end

@implementation UNHudViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

//自定义Loading
- (void)showLoadingView
{

}
- (void)hideLoadingView
{
    
}


//MBLoading
- (void)showMBLoadingView
{
    [MBProgressHUD showLoading];
}

- (void)hideMBLoadingView
{
    [MBProgressHUD hideMBHUD];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


@end
