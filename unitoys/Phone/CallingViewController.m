//
//  CallingViewController.m
//  CloudEgg
//
//  Created by sumars on 16/2/24.
//  Copyright © 2016年 ququ-iOS. All rights reserved.
//

#import "CallingViewController.h"
#import "UCallPhonePadView.h"
#import "AddTouchAreaButton.h"

@interface CallingViewController ()
@property (nonatomic, assign) BOOL isDismissing;

@property (nonatomic, strong) UCallPhonePadView *phonePadView;

@property (nonatomic, copy) NSString *currentNickName;
@end

@implementation CallingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hideKeyboardButton.touchEdgeInset = UIEdgeInsetsMake(10, 10, 10, 10);
    self.btnMuteStatus.tag = 0;
    self.btnSpeakerStatus.tag = 0;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getCallingMessage:) name:@"CallingMessage" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sipRegisterFailed) name:@"NetWorkPhoneRegisterFailed" object:nil];
}

- (void)sipRegisterFailed
{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:INTERNATIONALSTRING(@"错误提示") message:INTERNATIONALSTRING(@"通话异常,请检查网络或账号正常") preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"Hungup"];
        [self endCallPhone];
    }];
    [alertVC addAction:action];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)getCallingMessage :(NSNotification *)notification {
    if (notification.object) {
        self.lblCallingHint.text = notification.object;
        if ([self.lblCallingHint.text isEqualToString:INTERNATIONALSTRING(@"对方振铃...")]) {
            
        }else if ([self.lblCallingHint.text isEqualToString:INTERNATIONALSTRING(@"呼叫接通")]) {
            self.callingStatus = YES;
        }else if ([self.lblCallingHint.text isEqualToString:INTERNATIONALSTRING(@"正在通话")]) {
            self.callingStatus = YES;
            if (!self.callTimer) {
                //开始计时
                self.callTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(displayTime) userInfo:nil repeats:YES];
            }
        }else if([self.lblCallingHint.text isEqualToString:INTERNATIONALSTRING(@"通话结束")]){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateMaximumPhoneCallTime" object:nil userInfo:@{@"CallTime" : @(self.callSeconds)}];
            [self endCallPhone];
        }else{
            self.callingStatus = NO;
        }
    }
}

- (void)displayTime {
    self.callSeconds +=1;
    self.lblCallingHint.text = [NSString stringWithFormat:@"%02d:%02d",self.callSeconds/60,self.callSeconds%60];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)muteCalling:(id)sender {
    if (_btnMuteStatus.tag==0) {
        [_btnMuteStatus setImage:[UIImage imageNamed:@"icon_jy_pre"] forState:UIControlStateNormal];
        _btnMuteStatus.tag=1;
    } else {
        [_btnMuteStatus setImage:[UIImage imageNamed:@"icon_jy_nor"] forState:UIControlStateNormal];
        _btnMuteStatus.tag=0;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"MuteSound" userInfo:@{@"isMuteon" : @(_btnMuteStatus.tag)}];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLBEStatuWithPushKit" object:nil];
    [super dismissViewControllerAnimated:flag completion:completion];
}

- (IBAction)handfreeCalling:(id)sender {
    
    if (_btnSpeakerStatus.tag==0) {
        [_btnSpeakerStatus setImage:[UIImage imageNamed:@"hands_free_pre"] forState:UIControlStateNormal];
        _btnSpeakerStatus.tag=1;
    } else {
        [_btnSpeakerStatus setImage:[UIImage imageNamed:@"hands_free_nor"] forState:UIControlStateNormal];
        _btnSpeakerStatus.tag=0;
    }
    //解决通话前设置扩音无效问题
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"SwitchSound" userInfo:@{@"isHandfreeon" : @(_btnSpeakerStatus.tag)}];
}

- (IBAction)callNumAction:(UIButton *)sender
{
    [self showphonePadView];
}

- (IBAction)hideKeyBoardAction:(UIButton *)sender
{
    [self hidePhonePadView];
}

- (void)showphonePadView
{
    if (!self.currentNickName) {
        self.currentNickName = [self.lblCallingInfo.text copy];
    }
    self.containerView.hidden = YES;
    if (!_phonePadView) {
        kWeakSelf
        _phonePadView = [[UCallPhonePadView alloc] initWithFrame:CGRectMake(0, kScreenHeightValue - 34 - 45 - 70 - 225, kScreenWidthValue, 225) IsTransparentBackground:YES];
        _phonePadView.completeBlock = ^(NSString *btnText, NSString *currentNum) {
            NSLog(@"总字符---%@=====当前字符-----%@", btnText, currentNum);
            weakSelf.lblCallingInfo.text = btnText;
            if ([currentNum isEqualToString:@"DEL"]) {
                NSLog(@"输入异常");
            }else{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CallPhoneKeyBoard" object:currentNum];
            }
        };
        [self.view addSubview:_phonePadView];
    }
    [self.phonePadView showCallViewNoDelLabel];
    self.hideKeyboardButton.hidden = NO;
}

- (void)hidePhonePadView
{
    if (_phonePadView) {
        [_phonePadView hideCallViewNoDelLabel];
    }
    self.hideKeyboardButton.hidden = YES;
    self.containerView.hidden = NO;
    self.lblCallingInfo.text = self.currentNickName;
}

- (void)endCallPhone
{
    if (self.isDismissing) {
        return;
    }
    self.isDismissing = YES;
    //关掉当前
    if (self.callTimer) {
//        [self.callTimer setFireDate:[NSDate distantFuture]];
        [self.callTimer invalidate];
        self.callTimer = nil;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:^{
            self.isDismissing = NO;
        }];
    });
}

- (IBAction)hungupCalling:(UIButton *)sender {
    sender.enabled = NO;
    self.hadRing = NO;
     [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"Hungup"];
    [self endCallPhone];
    sender.enabled = YES;
}

@end
