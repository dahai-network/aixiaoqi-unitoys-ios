//
//  UNHudViewController.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/16.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNHudViewController.h"
#import "MBProgressHUD+UNTip.h"
#import "UNHudView.h"
#import <Masonry/Masonry.h>

@interface UNHudViewController ()

@property (nonatomic, strong) UNHudView *hudView;

@end

@implementation UNHudViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

//自定义Loading
- (void)showLoadingView
{
    if (!_hudView) {
        _hudView = [[UNHudView alloc] init];
        [_hudView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view);
            make.left.equalTo(self.view);
            make.width.equalTo(self.view);
            make.height.equalTo(self.view);
        }];
        [self.view addSubview:_hudView];
        [_hudView startLoading];
    }
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
