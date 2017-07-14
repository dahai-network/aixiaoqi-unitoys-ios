//
//  ActivityInPhoneViewController.m
//  unitoys
//
//  Created by 董杰 on 2017/7/8.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "ActivityInPhoneViewController.h"
#import "HelpViewController.h"
#import "navHomeViewController.h"
#import "UIImage+GIF.h"
#import <AVFoundation/AVFoundation.h>

@interface ActivityInPhoneViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *gifView;
@property (nonatomic, strong) AVPlayer *player;

@end

@implementation ActivityInPhoneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"手机内激活";
    self.player = [self player];
    
    [self setLeftButton:[UIImage imageNamed:@"x"]];
    
    [self setRightButton:@"帮助"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartPlay) name:@"appEnterForeground" object:@"appEnterForeground"];
    
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)leftButtonClick {
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    transition.type = kCATransitionReveal;
    transition.subtype = kCATransitionFromBottom;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)rightButtonClick {
    HelpViewController *helpVC = [[HelpViewController alloc] init];
    [self.navigationController pushViewController:helpVC animated:YES];
}

- (void)restartPlay {
    [self.player play];
}

- (AVPlayer *)player {
    if (_player == nil) {
        // 1.获取URL(远程/本地)
         NSURL *url = [[NSBundle mainBundle] URLForResource:@"手机内激活0713.mov" withExtension:nil];
        // 2.创建AVPlayerItem
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
        // 3.创建AVPlayer
        _player = [AVPlayer playerWithPlayerItem:item];
        [_player play];
        //注册通知
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(runLoopTheMovie:) name:AVPlayerItemDidPlayToEndTimeNotification object:item];
        // 4.添加AVPlayerLayer
        AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        layer.frame = CGRectMake(0, 0, self.gifView.un_width, self.gifView.un_height);
        [self.gifView.layer addSublayer:layer];
    }
    return _player;
}

#pragma mark 循环播放
- (void)runLoopTheMovie:(NSNotification *)notic {
    AVPlayerItem * p = notic.object;
    //关键代码
    [p seekToTime:kCMTimeZero];
    [self.player play];
}

- (IBAction)goToSystemSetView:(UIButton *)sender {
    if (kSystemVersionValue >= 8.0) {
        if (kSystemVersionValue >= 10.0) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-Prefs:root=Phone"] options:@{}     completionHandler:nil];
        }else{
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-Prefs:root=Phone"]];
        }
    }
    
//    [self dismissViewControllerAnimated:YES completion:nil];
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
