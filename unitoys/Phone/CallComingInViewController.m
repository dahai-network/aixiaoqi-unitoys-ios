//
//  CallComingInViewController.m
//  unitoys
//
//  Created by 董杰 on 2016/12/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "CallComingInViewController.h"
#import "UCallPhonePadView.h"
#import "AddTouchAreaButton.h"
#import <AVFoundation/AVFoundation.h>
#import <notify.h>

#define NotificationLock CFSTR("com.apple.springboard.lockcomplete")
static CallComingInViewController *selfClass =nil;

@interface CallComingInViewController ()
@property (weak, nonatomic) IBOutlet UILabel *refuseLabel;
@property (weak, nonatomic) IBOutlet UIView *refuseView;
@property (weak, nonatomic) IBOutlet UIView *connectView;
@property (nonatomic, assign)BOOL isNeedToRefresh;
@property (weak, nonatomic) IBOutlet UIButton *muteOffButton;//静音按钮
@property (weak, nonatomic) IBOutlet UIButton *handfreeOffButton;//扩音按钮

@property (nonatomic, assign) BOOL isDismissing;

@property (nonatomic, strong) UCallPhonePadView *phonePadView;
@property (nonatomic, copy) NSString *currentNickName;

//是否已接听
@property (nonatomic, assign) BOOL isCallAnswer;
@end

@implementation CallComingInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    selfClass = self;
    
    self.hideKeyboardButton.touchEdgeInset = UIEdgeInsetsMake(10, 10, 10, 10);
    self.btnMuteStatus.tag = 0;
    self.btnSpeakerStatus.tag = 0;
    
    self.lbName.text = self.nameStr;
    // Do any additional setup after loading the view from its nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getCallingMessage:) name:@"CallingMessage" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sipRegisterFailed) name:@"NetWorkPhoneRegisterFailed" object:nil];
    //app将要被杀死时调用
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillBeKilled) name:@"AppWillBeKilled" object:nil];
    
    [self initAudioObserver];
    
    self.lbTime.text = INTERNATIONALSTRING(@"新来电");
    
    if (self.isPresentInCallKit) {
        self.connectView.hidden = YES;
        CGPoint center = self.refuseView.center;
        center.x = [UIScreen mainScreen].bounds.size.width/2;
        self.refuseView.center = center;
        self.isNeedToRefresh = YES;
        [self acceptCallFromCallKit];
    }
    
    
}

- (void)initAudioObserver
{
//    NSError *error;
//    [[AVAudioSession sharedInstance] setActive:YES error:&error];
//    if (error) {
//        UNDebugLogVerbose(@"error==%@", error);
//    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(systemSoundValueChange:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, screenLockStateChanged, NotificationLock, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

- (void)systemSoundValueChange:(NSNotification *)noti
{
    NSDictionary *userInfo = noti.userInfo;
    UNDebugLogVerbose(@"点击了音量按键====%@",userInfo);
    if ([userInfo[@"AVSystemController_AudioVolumeChangeReasonNotificationParameter"] isEqualToString:@"ExplicitVolumeChange"]) {
        //解决通话前设置扩音无效问题
        if (!self.isCallAnswer) {
            UNDebugLogVerbose(@"点击了音量按键====%@",userInfo);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"SoundValueChange"];
        }
    }
}


static void screenLockStateChanged(CFNotificationCenterRef center,void* observer,CFStringRef name,const void* object,CFDictionaryRef userInfo){
    
    NSString* lockstate = (__bridge NSString*)name;
    if ([lockstate isEqualToString:(__bridge  NSString*)NotificationLock]) {
        UNDebugLogVerbose(@"screen Lock.");
        screenLockFunction();
    } else {
        UNDebugLogVerbose(@"lock state changed.");
        // 此处监听到屏幕解锁事件（锁屏也会掉用此处一次，锁屏事件要在上面实现）
    }
}
void screenLockFunction(){
    [selfClass screenLockAction];
}

- (void)screenLockAction
{
    if (!self.isCallAnswer) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"SoundValueChange"];
    }
}

- (void)sipRegisterFailed
{
//    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:INTERNATIONALSTRING(@"错误提示") message:INTERNATIONALSTRING(@"通话异常,请检查网络或账号正常") preferredStyle:UIAlertControllerStyleAlert];
//    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"Hungup"];
//        [self endCallPhone];
//    }];
//    [alertVC addAction:action];
//    [self presentViewController:alertVC animated:YES completion:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"Hungup"];
    [self endCallPhone];
}

- (void)appWillBeKilled
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"Hungup"];
    //直接挂断
    [self endCallPhone];
}

#pragma mark 拒绝按钮点击事件
- (IBAction)refuseButtonAction:(UIButton *)sender {
    sender.enabled = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"Hungup"];
    //直接挂断
    [self endCallPhone];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        sender.enabled = YES;
    });
}

#pragma mark 刷新界面
- (void)refuseViewAnimations {
    self.connectView.hidden = YES;
    self.containerView.hidden = NO;
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        CGPoint center = self.refuseView.center;
        center.x = [UIScreen mainScreen].bounds.size.width/2;
        self.refuseView.center = center;
    } completion:nil];
}

#pragma mark 接听按钮点击事件
- (IBAction)answerButtonAction:(UIButton *)sender {
    //是否已接听
    if (!self.isCallAnswer) {
        self.isCallAnswer = YES;
    }
    self.refuseLabel.text = INTERNATIONALSTRING(@"挂断");
    self.containerView.hidden = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"Answer"];
    if (!self.isPresentInCallKit) {
        if (self.callTimer) {
            [self.callTimer invalidate];
            self.callTimer = nil;
        }
        //开始计时
        self.callTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(displayTime) userInfo:nil repeats:YES];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self refuseViewAnimations];
        self.isNeedToRefresh = YES;
    });
}

//弹出键盘
- (IBAction)callNumberAction:(UIButton *)sender
{
    [self showphonePadView];
}

//隐藏键盘
- (IBAction)hideKeyBAction:(UIButton *)sender
{
    [self hidePhonePadView];
}

- (void)showphonePadView
{
    if (!self.currentNickName) {
        self.currentNickName = [self.lbName.text copy];
    }
    self.containerView.hidden = YES;
    if (!_phonePadView) {
        kWeakSelf
        _phonePadView = [[UCallPhonePadView alloc] initWithFrame:CGRectMake(0, kScreenHeightValue - 34 - 45 - 70 - 225, kScreenWidthValue, 225) IsTransparentBackground:YES];
        _phonePadView.completeBlock = ^(NSString *btnText, NSString *currentNum) {
            UNDebugLogVerbose(@"总字符---%@=====当前字符-----%@", btnText, currentNum);
            weakSelf.lbName.text = btnText;
            if([currentNum isEqualToString:@"DEL"]) {
                UNDebugLogVerbose(@"输入异常");
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
    self.lbName.text = self.currentNickName;
}

//- (void)showCenterView
//{
//    if (self.callTimer) {
//        [self.callTimer invalidate];
//        self.callTimer = nil;
//    }
//    self.refuseLabel.text = INTERNATIONALSTRING(@"挂断");
//    self.containerView.hidden = NO;
//    //开始计时
//    self.callTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(displayTime) userInfo:nil repeats:YES];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self refuseViewAnimations];
//        self.isNeedToRefresh = YES;
//    });
//}

//从callKit弹出通话界面
- (void)acceptCallFromCallKit
{

    self.refuseLabel.text = INTERNATIONALSTRING(@"挂断");
    self.containerView.hidden = NO;
    //开始计时
//    if (self.callTimer) {
//        [self.callTimer invalidate];
//        self.callTimer = nil;
//    }
//    self.callTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(displayTime) userInfo:nil repeats:YES];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self refuseViewAnimations];
//        self.isNeedToRefresh = YES;
//    });
}

- (void)setUpMuteButtonStatu:(BOOL)isMute
{
    if (isMute) {
        [_btnMuteStatus setImage:[UIImage imageNamed:@"icon_jy_pre"] forState:UIControlStateNormal];
    }else{
        [_btnMuteStatus setImage:[UIImage imageNamed:@"icon_jy_nor"] forState:UIControlStateNormal];
    }
}
- (void)setUpSpeakerButtonStatus:(BOOL)isSpeaker
{
    if (isSpeaker) {
        [_btnSpeakerStatus setImage:[UIImage imageNamed:@"hands_free_pre"] forState:UIControlStateNormal];
    }else{
        [_btnSpeakerStatus setImage:[UIImage imageNamed:@"hands_free_nor"] forState:UIControlStateNormal];
    }
}
- (void)endCallPhone
{
    if (self.isDismissing) {
        return;
    }
    self.isDismissing = YES;
    if (self.callTimer) {
        [self.callTimer setFireDate:[NSDate distantFuture]];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:^{
            self.isDismissing = NO;
        }];
    });
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
        [_btnMuteStatus setImage:[UIImage imageNamed:@"icon_jy_pre"] forState:UIControlStateNormal];
        _btnMuteStatus.tag=1;
    } else {
        [_btnMuteStatus setImage:[UIImage imageNamed:@"icon_jy_nor"] forState:UIControlStateNormal];
        _btnMuteStatus.tag=0;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"MuteSound" userInfo:@{@"isMuteon" : @(_btnMuteStatus.tag)}];
}

#pragma mark 扩音按钮点击事件
- (IBAction)handfreeOffButtonClickAction:(UIButton *)sender {
//    HUDNormal(@"扩音")
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"SwitchSound"];
    
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

- (void)displayTime {
    self.callSeconds +=1;
    self.lbTime.text = [NSString stringWithFormat:@"%02d:%02d",self.callSeconds/60,self.callSeconds%60];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
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
        if ([self.lbTime.text isEqualToString:INTERNATIONALSTRING(@"呼叫接通")]) {
            
        }else if ([self.lbTime.text isEqualToString:INTERNATIONALSTRING(@"正在通话")]) {
            UNDebugLogVerbose(@"getCallingMessage--正在通话");
            if (!self.callTimer) {
                self.callTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(displayTime) userInfo:nil repeats:YES];
            }
        }else if([self.lbTime.text isEqualToString:INTERNATIONALSTRING(@"通话结束")]){
            //关掉当前
            [self endCallPhone];
        }else{
            
        }
    }
}

- (void)dealloc
{
//    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, screenLockStateChanged, NotificationLock, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, NotificationLock, NULL);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
