//
//  IsBoundingViewController.m
//  unitoys
//
//  Created by 董杰 on 2016/12/17.
//  Copyright © 2016年 sumars. All rights reserved.
//

#define defoultColor [UIColor whiteColor]
#define currentColor [UIColor colorWithRed:173/255.0 green:173/255.0 blue:173/255.0 alpha:1.0]

#import "IsBoundingViewController.h"
#import "BlueToothDataManager.h"
#import "BindDeviceViewController.h"
#import "UNBlueToothTool.h"

@interface IsBoundingViewController ()
@property (nonatomic, strong)NSTimer *clickAnimationTimer;
@property (nonatomic, strong)NSTimer *timer;
@property (nonatomic, assign)int time;
@property (nonatomic, copy)NSString *currentLabel;
@property (nonatomic, assign) BOOL isback;//是否主动退出页面
@property (nonatomic, strong)BindDeviceViewController *bindDeviceVC;
@property (weak, nonatomic) IBOutlet UIImageView *typeImg;
@property (weak, nonatomic) IBOutlet UIImageView *searchAnimationImg;
@property (weak, nonatomic) IBOutlet UIImageView *handupImg;
@property (weak, nonatomic) IBOutlet UILabel *firstTitle;
@property (weak, nonatomic) IBOutlet UILabel *subTitleLbl;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end

@implementation IsBoundingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"";
    
    //添加接收者
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectedSuccess) name:@"boundSuccess" object:@"boundSuccess"];//绑定成功
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectFail) name:@"connectFail" object:@"connectFail"];//绑定失败
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchNoDevice) name:@"searchNoDevice" object:@"searchNoDevice"];//没有搜索到手环
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchNoDevice) name:@"needToIgnore" object:@"needToIgnore"];//需要先忽略
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundFail) name:@"boundDeviceFailNotifi" object:@"boundDeviceFailNotifi"];//绑定失败
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundSuccess) name:@"secondCkeckBoundSuccess" object:@"secondCkeckBoundSuccess"];//二次确认绑定成功
    
    // Do any additional setup after loading the view from its nib.
}

- (void)searchNoDevice {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    self.handupImg.hidden = YES;
    self.searchAnimationImg.image = [UIImage imageNamed:@"pic_by_z"];
    [self.cancelButton setTitle:@"暂不搜索" forState:UIControlStateNormal];
    [self setLeftButton:@""];
    [BlueToothDataManager shareManager].isShowAlert = YES;
    self.isback = YES;
    //倒计时
    self.time = 0;
    //开始计时
    [self startTimer];
    if ([[BlueToothDataManager shareManager].deviceType isEqualToString:MYDEVICENAMEUNITOYS]) {
        //爱小器手环
        self.typeImg.image = [UIImage imageNamed:@"pic_cp_sh"];
        self.firstTitle.text = @"正在搜索爱小器手环";
        self.subTitleLbl.text = @"请将手环贴近手机";
    } else if ([[BlueToothDataManager shareManager].deviceType isEqualToString:MYDEVICENAMEUNIBOX]) {
        //爱小器双待王
        self.typeImg.image = [UIImage imageNamed:@"pic_sdw"];
        self.firstTitle.text = @"正在搜索爱小器双待王";
        self.subTitleLbl.text = @"请将双待王贴近手机";
    } else {
        NSLog(@"这是什么鬼类型？");
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [BlueToothDataManager shareManager].isShowAlert = NO;
    [self.timer setFireDate:[NSDate distantFuture]];
    [self.clickAnimationTimer setFireDate:[NSDate distantFuture]];
    if (self.isback) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"stopScanBLE" object:@"stopScanBLE"];
        [BlueToothDataManager shareManager].isShowAlert = YES;
    }
}

#pragma mark 取消扫描
- (IBAction)cancelScanAction:(UIButton *)sender {
    if (![BlueToothDataManager shareManager].isConnected) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"stopScanBLE" object:@"stopScanBLE"];
        [BlueToothDataManager shareManager].isShowAlert = YES;
        self.time = 0;
        [self.timer setFireDate:[NSDate distantPast]];
    } else {
        [[UNBlueToothTool shareBlueToothTool] cancelToBound];
    }
    [self.navigationController popToRootViewControllerAnimated:YES];
}


- (void)connectedSuccess {
    self.time = 0;
    [self.timer setFireDate:[NSDate distantFuture]];
    self.firstTitle.text = @"请按一下双待王按键";
    self.subTitleLbl.text = [NSString stringWithFormat:@"已找到双待王%@，请连接", [BlueToothDataManager shareManager].deviceMacAddress];
    [self.cancelButton setTitle:@"暂不绑定" forState:UIControlStateNormal];
    self.searchAnimationImg.image = [UIImage imageNamed:@"pic_zy_pre"];
    self.handupImg.hidden = NO;
    [self startToShowClickAnimation];
}

- (void)startToShowClickAnimation {
    if (!self.clickAnimationTimer) {
        self.clickAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(showClickAnimation) userInfo:nil repeats:YES];
        //如果不添加下面这条语句，在UITableView拖动的时候，会阻塞定时器的调用
        [[NSRunLoop currentRunLoop] addTimer:self.clickAnimationTimer forMode:UITrackingRunLoopMode];
    } else {
        [self.clickAnimationTimer setFireDate:[NSDate distantPast]];
    }
}

- (void)showClickAnimation {
    self.handupImg.frame = CGRectMake(self.handupImg.frame.origin.x, self.handupImg.frame.origin.y+15, self.handupImg.frame.size.width, self.handupImg.frame.size.height);
    [UIView beginAnimations:@"属性动画" context:nil];
    //    动画执行多长时间
    [UIView setAnimationDuration:1];
    //    设置是否有路径回退效果
//        [UIView setAnimationRepeatAutoreverses:YES];
    //    设置重复次数（可以设置窗口抖动效果）
    [UIView setAnimationRepeatCount:1];
    //    位置的变化,会有一个位置的平移效果
    self.handupImg.frame = CGRectMake(self.handupImg.frame.origin.x, self.handupImg.frame.origin.y, self.handupImg.frame.size.width, self.handupImg.frame.size.height);
    self.handupImg.frame = CGRectMake(self.handupImg.frame.origin.x, self.handupImg.frame.origin.y-15, self.handupImg.frame.size.width, self.handupImg.frame.size.height);
    //    提交动画
    [UIView commitAnimations];
}

- (void)boundFail {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)boundSuccess {
    self.isback = NO;
    //    有绑定
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
    if (!self.bindDeviceVC) {
        self.bindDeviceVC = [mainStory instantiateViewControllerWithIdentifier:@"bindDeviceViewController"];
    }
    
    if(![self.navigationController.topViewController isKindOfClass:[BindDeviceViewController class]]) {
        self.time = 0;
        [self.timer setFireDate:[NSDate distantFuture]];
        self.tabBarController.tabBar.hidden = YES;
        self.bindDeviceVC.hintStrFirst = INTERNATIONALSTRING(@"连接中");
        [self.navigationController pushViewController:self.bindDeviceVC animated:YES];
    }
}


- (void)connectFail {
    self.isback = NO;
    self.time = 0;
    [self.timer setFireDate:[NSDate distantFuture]];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)startTimer {
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
    } else {
        self.time = 0;
        [self.timer setFireDate:[NSDate distantPast]];
    }
}

- (void)timerAction {
    //    进行Layer层旋转的
    //    后面的字符串是固定名字，读取系统的文件信息
    CABasicAnimation *base = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    base.duration = 1;
    //    起始的角度
    base.fromValue = @(0);
    //    终止的角度
    base.toValue = @(M_PI_2 * 4);
    //    将这个动画添加到layer上
    [self.searchAnimationImg.layer addAnimation:base forKey:@"base"];
    
    if (self.time == BLESCANTIME) {
        [self.timer setFireDate:[NSDate distantFuture]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"stopScanBLE" object:@"stopScanBLE"];
        [self dj_alertAction:self alertTitle:nil actionTitle:@"重试" message:@"未能搜索到爱小器设备" alertAction:^{
            self.time = 0;
            [self.timer setFireDate:[NSDate distantPast]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"scanToConnect" object:@"connect"];
            [BlueToothDataManager shareManager].isNeedToBoundDevice = YES;
        }];
    }
    
    self.time++;
}

- (void)dj_alertAction:(UIViewController *)controller alertTitle:(NSString *)alertTitle actionTitle:(NSString *)actionTitle message:(NSString *)message alertAction:(void (^)())alertAction {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:INTERNATIONALSTRING(alertTitle) message:INTERNATIONALSTRING(message) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(@"取消") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }];
    UIAlertAction *certailAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(actionTitle) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        alertAction();
    }];
    [alertVC addAction:cancelAction];
    [alertVC addAction:certailAction];
    [controller presentViewController:alertVC animated:YES completion:nil];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"boundSuccess" object:@"boundSuccess"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"connectFail" object:@"connectFail"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"searchNoDevice" object:@"searchNoDevice"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"needToIgnore" object:@"needToIgnore"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"boundDeviceFailNotifi" object:@"boundDeviceFailNotifi"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"secondCkeckBoundSuccess" object:@"secondCkeckBoundSuccess"];
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
