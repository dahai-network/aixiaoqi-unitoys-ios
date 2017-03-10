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

@interface IsBoundingViewController ()
@property (weak, nonatomic) IBOutlet UILabel *firstLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdLabel;
@property (weak, nonatomic) IBOutlet UILabel *forthLabel;
@property (weak, nonatomic) IBOutlet UILabel *fifthLabel;
@property (nonatomic, strong)NSTimer *timer;
@property (nonatomic, assign)int time;
@property (nonatomic, copy)NSString *currentLabel;
@property (nonatomic, assign) BOOL isback;//是否主动退出页面
@property (nonatomic, strong)BindDeviceViewController *bindDeviceVC;

@end

@implementation IsBoundingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"正在绑定";
    
    //添加接收者
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectedSuccess) name:@"boundSuccess" object:@"boundSuccess"];//绑定成功
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectFail) name:@"connectFail" object:@"connectFail"];//绑定失败
    
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [BlueToothDataManager shareManager].isShowAlert = YES;
    self.isback = YES;
    //倒计时
    self.time = 0;
    self.currentLabel = @"firstLabel";
    self.firstLabel.backgroundColor = currentColor;
    self.secondLabel.backgroundColor = defoultColor;
    self.thirdLabel.backgroundColor = defoultColor;
    self.forthLabel.backgroundColor = defoultColor;
    //开始计时
    [self startTimer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [BlueToothDataManager shareManager].isShowAlert = NO;
    if (self.isback) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"stopScanBLE" object:@"stopScanBLE"];
        [BlueToothDataManager shareManager].isShowAlert = YES;
    }
}

#pragma mark 取消扫描
- (IBAction)cancelScanAction:(UIButton *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"stopScanBLE" object:@"stopScanBLE"];
    [BlueToothDataManager shareManager].isShowAlert = YES;
    self.time = 0;
    [self.timer setFireDate:[NSDate distantPast]];
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)connectedSuccess {
    self.isback = NO;
    //有绑定
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
    if (!self.bindDeviceVC) {
        self.bindDeviceVC = [mainStory instantiateViewControllerWithIdentifier:@"bindDeviceViewController"];
    }
    
    if(![self.navigationController.topViewController isKindOfClass:[BindDeviceViewController class]]) {
        self.time = 0;
        [self.timer setFireDate:[NSDate distantFuture]];
        self.tabBarController.tabBar.hidden = YES;
        self.bindDeviceVC.hintStrFirst = @"连接中";
        [self.navigationController pushViewController:self.bindDeviceVC animated:YES];
    }
}

- (void)connectFail {
    self.isback = NO;
    self.time = 0;
    [self.timer setFireDate:[NSDate distantFuture]];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)startTimer {
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
    } else {
        self.time = 0;
        [self.timer setFireDate:[NSDate distantPast]];
    }
}

- (void)timerAction {
    if (self.time == BLESCANTIME * 2) {
        [self.timer setFireDate:[NSDate distantFuture]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"stopScanBLE" object:@"stopScanBLE"];
        [self dj_alertAction:self alertTitle:nil actionTitle:@"重试" message:@"未能搜索到爱小器手环" alertAction:^{
            self.time = 0;
            [self.timer setFireDate:[NSDate distantPast]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"scanToConnect" object:@"connect"];
            [BlueToothDataManager shareManager].isNeedToBoundDevice = YES;
        }];
    }
    self.time++;
    if ([self.currentLabel isEqualToString:@"firstLabel"]) {
        self.firstLabel.backgroundColor = defoultColor;
        self.secondLabel.backgroundColor = currentColor;
        self.currentLabel = @"secondLabel";
        return;
    }
    if ([self.currentLabel isEqualToString:@"secondLabel"]) {
        self.secondLabel.backgroundColor = defoultColor;
        self.thirdLabel.backgroundColor = currentColor;
        self.currentLabel = @"thirdLabel";
        return;
    }
    if ([self.currentLabel isEqualToString:@"thirdLabel"]) {
        self.thirdLabel.backgroundColor = defoultColor;
        self.forthLabel.backgroundColor = currentColor;
        self.currentLabel = @"forthLabel";
        return;
    }
    if ([self.currentLabel isEqualToString:@"forthLabel"]) {
        self.forthLabel.backgroundColor = defoultColor;
        self.fifthLabel.backgroundColor = currentColor;
        self.currentLabel = @"fifthLabel";
        return;
    }
    if ([self.currentLabel isEqualToString:@"fifthLabel"]) {
        self.fifthLabel.backgroundColor = defoultColor;
        self.firstLabel.backgroundColor = currentColor;
        self.currentLabel = @"firstLabel";
        return;
    }
}

- (void)dj_alertAction:(UIViewController *)controller alertTitle:(NSString *)alertTitle actionTitle:(NSString *)actionTitle message:(NSString *)message alertAction:(void (^)())alertAction {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:alertTitle message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }];
    UIAlertAction *certailAction = [UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        alertAction();
    }];
    [alertVC addAction:cancelAction];
    [alertVC addAction:certailAction];
    [controller presentViewController:alertVC animated:YES completion:nil];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"boundSuccess" object:@"boundSuccess"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"connectFail" object:@"connectFail"];
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
