//
//  UNAnimateController.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/22.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNAnimateController.h"
#import "UNProgressView.h"

@interface UNAnimateController ()

@property (nonatomic, strong) UNProgressView *progressView;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) CGFloat progress;
@end

@implementation UNAnimateController

- (void)viewDidLoad {
    [super viewDidLoad];
    _progressView = [[UNProgressView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue - 2 *30, 30)];
    _progressView.un_centerX = kScreenWidthValue * 0.5;
    _progressView.un_centerY = kScreenHeightValue * 0.5;
    [self.view addSubview:_progressView];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"开始" forState:UIControlStateNormal];
    button.un_width = 90;
    button.un_height = 30;
    button.un_centerX = kScreenWidthValue * 0.5;
    button.un_centerY = kScreenHeightValue * 0.5 + 60;
    [button setBackgroundColor:DefultColor];
    [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)buttonAction:(UIButton *)button
{
    if (!_timer) {
        _progress = 0;
        self.progressView.progress = 0;
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(timeAction:) userInfo:nil repeats:YES];
    }
}

- (void)timeAction:(NSTimer *)timer
{
    _progress +=0.01;
    if (_progress <= 1.0) {
        self.progressView.progress = _progress;
    }else{
        _progress = 0;
        [_timer invalidate];
        _timer = nil;
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}



@end
