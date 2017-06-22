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
#import "IsBoundingTableViewCell.h"

#define ANIMATIONTIME 0.6

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
@property (weak, nonatomic) IBOutlet UIView *searchView;
@property (weak, nonatomic) IBOutlet UITableView *showDeviceTableView;
@property (nonatomic, strong) NSMutableArray *deviceDataArr;
@property (nonatomic, assign)BOOL isShowBackButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchViewWidth;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchViewCenter;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchButtonBottom;

@end

@implementation IsBoundingViewController

- (NSMutableArray *)deviceDataArr {
    if (!_deviceDataArr) {
        self.deviceDataArr = [NSMutableArray array];
    }
    return _deviceDataArr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //添加接收者
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectedSuccess) name:@"boundSuccess" object:@"boundSuccess"];//绑定成功
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectFail) name:@"connectFail" object:@"connectFail"];//绑定失败
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchNoDevice) name:@"searchNoDevice" object:@"searchNoDevice"];//没有搜索到手环
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchNoDevice) name:@"needToIgnore" object:@"needToIgnore"];//需要先忽略
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundFail) name:@"boundDeviceFailNotifi" object:@"boundDeviceFailNotifi"];//绑定失败
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundSuccess) name:@"secondCkeckBoundSuccess" object:@"secondCkeckBoundSuccess"];//二次确认绑定成功
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBoundDeviceInfo:) name:@"checkBoundDeviceInfo" object:nil];//接收传过来的绑定信息
    
    // Do any additional setup after loading the view from its nib.
}

- (void)refreshBoundDeviceInfo:(NSNotification *)sender {
    self.isShowBackButton = YES;
    [self setLeftButton:[UIImage imageNamed:@"btn_back"]];
    self.searchAnimationImg.image = [UIImage imageNamed:@"pic_zy_pre"];
    self.deviceDataArr = sender.object;
    if (sender) {
        [self.cancelButton setTitle:@"首选连接" forState:UIControlStateNormal];
        [self changeFrame];
        UNDebugLogVerbose(@"传过来的设备数组:%@", self.deviceDataArr);
    } else {
        UNDebugLogVerbose(@"传过来的设备数组是空的");
        HUDNormal(@"未搜索到设备")
    }
    [self.showDeviceTableView reloadData];
}

- (void)leftButtonClick {
    if (self.isShowBackButton) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)searchNoDevice {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    self.handupImg.hidden = YES;
    [self returnFrame];
    self.searchAnimationImg.image = [UIImage imageNamed:@"pic_by_z"];
    [self.cancelButton setTitle:@"暂不搜索" forState:UIControlStateNormal];
    self.cancelButton.hidden = NO;
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
        UNDebugLogVerbose(@"这是什么鬼类型？");
    }
}

- (void)changeFrame {
    self.topView.hidden = YES;
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:ANIMATIONTIME animations:^{
        self.tableViewHeight.constant = kScreenHeightValue*0.46;
        self.searchViewWidth.constant = 160*(kScreenWidthValue/320);
        self.searchViewCenter.constant = -((40+40*0.46)/2);
        self.searchButtonBottom.constant = 40*0.46;
        [self.view layoutIfNeeded];
    }];
}

- (void)returnFrame {
    [self setLeftButton:@""];
    self.title = @"";
    self.topView.hidden = NO;
    self.isShowBackButton = NO;
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:ANIMATIONTIME animations:^{
        self.tableViewHeight.constant = 0;
        self.searchViewWidth.constant = 220;
        self.searchViewCenter.constant = 0;
        self.searchButtonBottom.constant = 40;
        [self.view layoutIfNeeded];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.deviceDataArr removeAllObjects];
    [BlueToothDataManager shareManager].isShowAlert = NO;
    [self.timer setFireDate:[NSDate distantFuture]];
//    [self.clickAnimationTimer setFireDate:[NSDate distantFuture]];
    if (self.isback) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"stopScanBLE" object:@"stopScanBLE"];
        [BlueToothDataManager shareManager].isShowAlert = YES;
    }
}

#pragma mark 取消扫描
- (IBAction)cancelScanAction:(UIButton *)sender {
    if ([sender.titleLabel.text isEqualToString:@"首选连接"]) {
        //首选连接
        for (int i = 0; i < self.deviceDataArr.count; i++) {
            NSDictionary *info = self.deviceDataArr[i];
            if ([info[@"isAlreadyBind"] isEqualToString:@"0"]) {
                NSString *indexRow = [NSString stringWithFormat:@"%d", i];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"clickAndConnectingPer" object:indexRow];
                UNDebugLogVerbose(@"发送过去连接的是第几个：%@", indexRow);
                return;
            }
        }
    } else if ([sender.titleLabel.text isEqualToString:@"暂不绑定"]) {
        self.handupImg.hidden = YES;
        [self.handupImg stopAnimating];
        [[UNBlueToothTool shareBlueToothTool] cancelToBound];
        self.isShowBackButton = YES;
        [self.cancelButton setTitle:@"首选连接" forState:UIControlStateNormal];
        [self setLeftButton:[UIImage imageNamed:@"btn_back"]];
        //            self.searchAnimationImg.image = [UIImage imageNamed:@"pic_zy_pre"];
        [self changeFrame];
    } else if ([sender.titleLabel.text isEqualToString:@"暂不搜索"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"stopScanBLE" object:@"stopScanBLE"];
        [BlueToothDataManager shareManager].isShowAlert = YES;
        self.time = 0;
        [self.timer setFireDate:[NSDate distantPast]];
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        UNDebugLogVerbose(@"按钮有问题:%s,%d", __FUNCTION__, __LINE__);
    }
}


- (void)connectedSuccess {
    [self returnFrame];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATIONTIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.time = 0;
        [self.timer setFireDate:[NSDate distantFuture]];
        self.firstTitle.text = @"请按一下双待王按键";
        self.subTitleLbl.text = [NSString stringWithFormat:@"已找到双待王%@，请连接", [BlueToothDataManager shareManager].deviceMacAddress];
        [self.cancelButton setTitle:@"暂不绑定" forState:UIControlStateNormal];
        self.searchAnimationImg.image = [UIImage imageNamed:@"pic_zy_pre"];
        [self startToShowClickAnimation];
    });
}

- (void)startToShowClickAnimation {
    UNDebugLogVerbose(@"走了启动动画的方法：%s,%d", __FUNCTION__, __LINE__);
    self.handupImg.hidden = NO;
    [self showClickAnimation];
//    if (!self.clickAnimationTimer) {
//        self.clickAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(showClickAnimation) userInfo:nil repeats:YES];
//        //如果不添加下面这条语句，在UITableView拖动的时候，会阻塞定时器的调用
//        [[NSRunLoop currentRunLoop] addTimer:self.clickAnimationTimer forMode:UITrackingRunLoopMode];
//    } else {
//        [self.clickAnimationTimer setFireDate:[NSDate distantPast]];
//    }
}

- (void)showClickAnimation {
    self.handupImg.frame = CGRectMake(self.handupImg.frame.origin.x, self.handupImg.frame.origin.y+15, self.handupImg.frame.size.width, self.handupImg.frame.size.height);
    [UIView beginAnimations:@"属性动画" context:nil];
    //    动画执行多长时间
    [UIView setAnimationDuration:1];
    //    设置是否有路径回退效果
        [UIView setAnimationRepeatAutoreverses:YES];
    //    设置重复次数（可以设置窗口抖动效果）
    [UIView setAnimationRepeatCount:15];
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
    self.typeImg.image = [UIImage imageNamed:@"icon_bound_success"];
    [self.handupImg stopAnimating];
    self.handupImg.hidden = YES;
    self.cancelButton.hidden = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //    有绑定
        UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
        if (!self.bindDeviceVC) {
            self.bindDeviceVC = [mainStory instantiateViewControllerWithIdentifier:@"bindDeviceViewController"];
        }
        
        if(![self.navigationController.topViewController isKindOfClass:[BindDeviceViewController class]]) {
            self.time = 0;
            [self.timer setFireDate:[NSDate distantFuture]];
            self.tabBarController.tabBar.hidden = YES;
//            self.bindDeviceVC.hintStrFirst = INTERNATIONALSTRING(@"连接中");
            [self.navigationController pushViewController:self.bindDeviceVC animated:YES];
        }
    });
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
        
//        [self dj_alertAction:self alertTitle:nil actionTitle:@"重试" message:@"未能搜索到爱小器设备" alertAction:^{
//            self.time = 0;
//            [self.timer setFireDate:[NSDate distantPast]];
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"scanToConnect" object:@"connect"];
//            [BlueToothDataManager shareManager].isNeedToBoundDevice = YES;
//        }];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.deviceDataArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    return 65;
}

//0流量/1通话/2大王卡/3双卡双待
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"IsBoundingTableViewCell";
    IsBoundingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell=[[[NSBundle mainBundle] loadNibNamed:@"IsBoundingTableViewCell" owner:nil options:nil] firstObject];
        [cell.btnConnect addTarget:self action:@selector(connectingAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (self.deviceDataArr.count) {
        NSDictionary *info = self.deviceDataArr[indexPath.row];
        cell.btnConnect.indexPath = indexPath;
        cell.lblDeviceName.text = [NSString stringWithFormat:@"Unibox-%@", info[@"mac"]];
//        cell.lblDeviceName.text = info[@"mac"];
        if ([info[@"isAlreadyBind"] isEqualToString:@"0"]) {
            cell.lblDeviceStatue.text = @"未绑定";
            cell.lblDeviceName.textColor = UIColorFromRGB(0x333333);
            cell.lblDeviceStatue.hidden = YES;
            cell.btnConnect.hidden = NO;
        } else if ([info[@"isAlreadyBind"] isEqualToString:@"1"]) {
            cell.lblDeviceStatue.text = @"已绑定";
            cell.lblDeviceName.textColor = UIColorFromRGB(0xe5e5e5);
            cell.lblDeviceStatue.hidden = NO;
            cell.btnConnect.hidden = YES;
        } else {
            UNDebugLogVerbose(@"状态有问题，%s;%d", __FUNCTION__, __LINE__);
        }
    }
    return cell;
}

- (void)connectingAction:(CutomButton *)sender {
//    NSDictionary *info = self.deviceDataArr[sender.indexPath.row];
//    NSString *showStr = [NSString stringWithFormat:@"要连接的设备是\n%@", info[@"mac"]];
    NSString *indexRow = [NSString stringWithFormat:@"%ld", (long)sender.indexPath.row];
    //发送IMEI过去连接
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clickAndConnectingPer" object:indexRow];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"boundSuccess" object:@"boundSuccess"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"connectFail" object:@"connectFail"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"searchNoDevice" object:@"searchNoDevice"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"needToIgnore" object:@"needToIgnore"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"boundDeviceFailNotifi" object:@"boundDeviceFailNotifi"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"secondCkeckBoundSuccess" object:@"secondCkeckBoundSuccess"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"checkBoundDeviceInfo" object:nil];
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
