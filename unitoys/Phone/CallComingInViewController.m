//
//  CallComingInViewController.m
//  unitoys
//
//  Created by 董杰 on 2016/12/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "CallComingInViewController.h"

@interface CallComingInViewController ()
@property (weak, nonatomic) IBOutlet UILabel *refuseLabel;
@property (weak, nonatomic) IBOutlet UIView *refuseView;
@property (weak, nonatomic) IBOutlet UIView *connectView;
@property (nonatomic, assign)BOOL isNeedToRefresh;
@property (weak, nonatomic) IBOutlet UIButton *muteOffButton;//静音按钮
@property (weak, nonatomic) IBOutlet UIButton *handfreeOffButton;//扩音按钮

@end

@implementation CallComingInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.lbName.text = self.nameStr;
    // Do any additional setup after loading the view from its nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getCallingMessage:) name:@"CallingMessage" object:nil];
    self.lbTime.text = @"新来电";
    
    if (self.isPresentInCallKit) {
        self.connectView.hidden = YES;
        CGPoint center = self.refuseView.center;
        center.x = [UIScreen mainScreen].bounds.size.width/2;
        self.refuseView.center = center;
        self.isNeedToRefresh = YES;
        [self acceptCallFromCallKit];
    }
}

#pragma mark 拒绝按钮点击事件
- (IBAction)refuseButtonAction:(UIButton *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"Hungup"];
    //直接挂断
    [self endCallPhone];
}

#pragma mark 拒绝按钮动画
- (void)refuseViewAnimations {
    self.connectView.hidden = YES;
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        CGPoint center = self.refuseView.center;
        center.x = [UIScreen mainScreen].bounds.size.width/2;
        self.refuseView.center = center;
    } completion:nil];
}

#pragma mark 接听按钮点击事件
- (IBAction)answerButtonAction:(UIButton *)sender {
    self.refuseLabel.text = @"挂断";
    self.muteOffButton.hidden = NO;
    self.handfreeOffButton.hidden = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"Answer"];
    //开始计时
    self.callTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(displayTime) userInfo:nil repeats:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self refuseViewAnimations];
        self.isNeedToRefresh = YES;
    });
}

//从callKit弹出通话界面
- (void)acceptCallFromCallKit
{
    self.refuseLabel.text = @"挂断";
    self.muteOffButton.hidden = NO;
    self.handfreeOffButton.hidden = NO;
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"Answer"];
    //开始计时
    self.callTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(displayTime) userInfo:nil repeats:YES];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self refuseViewAnimations];
//        self.isNeedToRefresh = YES;
//    });
}

- (void)setUpMuteButtonStatu:(BOOL)isMute
{
    if (isMute) {
        [_btnMuteStatus setImage:[UIImage imageNamed:@"tel_muteon"] forState:UIControlStateNormal];
    }else{
        [_btnMuteStatus setImage:[UIImage imageNamed:@"tel_muteoff"] forState:UIControlStateNormal];
    }
}
- (void)setUpSpeakerButtonStatus:(BOOL)isSpeaker
{
    if (isSpeaker) {
        [_btnSpeakerStatus setImage:[UIImage imageNamed:@"tel_handfreeon"] forState:UIControlStateNormal];
    }else{
        [_btnSpeakerStatus setImage:[UIImage imageNamed:@"tel_handfreeoff"] forState:UIControlStateNormal];
    }
}
- (void)endCallPhone
{
    if (self.callTimer) {
        [self.callTimer setFireDate:[NSDate distantFuture]];
    }
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [super dismissViewControllerAnimated:flag completion:completion];
}

#pragma mark 静音按钮点击事件
- (IBAction)muteOffButtonClickAction:(UIButton *)sender {
//    HUDNormal(@"静音")
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"MuteSound"];
    
    if (_btnMuteStatus.tag==0) {
        [_btnMuteStatus setImage:[UIImage imageNamed:@"tel_muteon"] forState:UIControlStateNormal];
        _btnMuteStatus.tag=1;
    } else {
        [_btnMuteStatus setImage:[UIImage imageNamed:@"tel_muteoff"] forState:UIControlStateNormal];
        _btnMuteStatus.tag=0;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"MuteSound" userInfo:@{@"isMuteon" : @(_btnMuteStatus.tag)}];
}

#pragma mark 扩音按钮点击事件
- (IBAction)handfreeOffButtonClickAction:(UIButton *)sender {
//    HUDNormal(@"扩音")
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"SwitchSound"];
    
    if (_btnSpeakerStatus.tag==0) {
        [_btnSpeakerStatus setImage:[UIImage imageNamed:@"tel_handfreeon"] forState:UIControlStateNormal];
        _btnSpeakerStatus.tag=1;
    } else {
        [_btnSpeakerStatus setImage:[UIImage imageNamed:@"tel_handfreeoff"] forState:UIControlStateNormal];
        _btnSpeakerStatus.tag=0;
    }
    
    //解决通话前设置扩音无效问题
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"SwitchSound" userInfo:@{@"isHandfreeon" : @(_btnSpeakerStatus.tag)}];
}

- (void)displayTime {
    self.callSeconds +=1;
    self.lbTime.text = [NSString stringWithFormat:@"%02d:%02d",self.callSeconds/60,self.callSeconds%60];
}

- (void)viewDidLayoutSubviews {
    if (self.isNeedToRefresh) {
        self.refuseView.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, self.refuseView.center.y);
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)getCallingMessage :(NSNotification *)notification {
    if (notification.object) {
        self.lbTime.text = notification.object;

        
        if ([self.lbTime.text isEqualToString:@"呼叫接通"]) {
            
        }else if ([self.lbTime.text isEqualToString:@"正在通话"]) {
       
        }else if([self.lbTime.text isEqualToString:@"通话结束"]){
            //关掉当前
            [self endCallPhone];
        }else{
            
        }
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
