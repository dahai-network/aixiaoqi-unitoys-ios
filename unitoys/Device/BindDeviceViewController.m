//
//  BindDeviceViewController.m
//  unitoys
//
//  Created by sumars on 16/11/16.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BindDeviceViewController.h"
#import "BlueToothDataManager.h"
#import "UIImage+GIF.h"
#import "WristbandSettingViewController.h"
#import "UNBlueToothTool.h"
#import "UNDatabaseTools.h"

@interface BindDeviceViewController ()
@property (weak, nonatomic) IBOutlet UILabel *lblStatue;
@property (weak, nonatomic) IBOutlet UIImageView *imgStatueImage;
@property (weak, nonatomic) IBOutlet UIButton *relieveBoundButton;
@property (nonatomic, strong)NSTimer *timer;
@property (weak, nonatomic) IBOutlet UIImageView *disconnectedImageView;
@property (nonatomic, assign) BOOL isNeedToPushNextVC;


@end

@implementation BindDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setRedLabel:self.versionLabel];
    [self checkIsHaveNewVersion];
    
    //添加接收者
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addElectricQue) name:@"boundSuccess" object:@"boundSuccess"];//绑定成功
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disConnectToDevice) name:@"deviceIsDisconnect" object:@"deviceIsDisconnect"];//断开连接
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeStatueAction:) name:@"changeStatue" object:nil];//改变状态和百分比
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bleStatueChanged:) name:@"homeStatueChanged" object:nil];//连接成功或者失败
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cardNumberNotTrueActionForBind:) name:@"cardNumberNotTrue" object:nil];//号码有问题专用
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeStatueAll:) name:@"changeStatueAll" object:nil];//状态改变
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundDeviceFail) name:@"boundDeviceFailNotifi" object:@"boundDeviceFailNotifi"];//绑定钥匙扣的时候如果没有点击确认绑定就会发送此通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chargeStatueChanged) name:@"chargeStatuChanged" object:@"chargeStatuChanged"];//充电状态改变了
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
//    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"img_nav_bj"] forBarMetrics:UIBarMetricsDefault];
//    self.lblStatue.text = self.hintStrFirst;
    self.lblStatue.text = [BlueToothDataManager shareManager].statuesTitleString;
    if ([BlueToothDataManager shareManager].isConnected) {
        [self addElectricQue];
    } else {
        if (self.customView) {
            self.customView.hidden = YES;
        }
        self.deviceName.hidden = YES;
        self.versionNumber.hidden = YES;
        self.macAddress.hidden = YES;
        self.lblStatue.text = INTERNATIONALSTRING(@"未连接");
    }
    
    if ([BlueToothDataManager shareManager].isRegisted && [BlueToothDataManager shareManager].isConnected && ![BlueToothDataManager shareManager].isBeingRegisting) {
        self.lblStatue.text = INTERNATIONALSTRING(@"信号强");
    }
    if ([BlueToothDataManager shareManager].isBeingRegisting && ![BlueToothDataManager shareManager].isRegisted && [BlueToothDataManager shareManager].isConnected) {
        //正在注册
        NSString *senderStr = [BlueToothDataManager shareManager].stepNumber;
        [self countAndShowPercentage:senderStr];
        //开启动画
        [self startTimerAction];
    }
    self.lblStatue.text = [BlueToothDataManager shareManager].statuesTitleString;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //自定义一个NaVIgationBar
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    //消除阴影
    self.navigationController.navigationBar.shadowImage = [UIImage new];
//    self.navigationController.navigationBarHidden = NO;
    if (!self.isNeedToPushNextVC) {
        [self.navigationController popToRootViewControllerAnimated:YES];
        self.isNeedToPushNextVC = NO;
    }
}

- (void)chargeStatueChanged {
    [self addElectricQue];
}

- (void)checkChargeStatue {
    switch ([BlueToothDataManager shareManager].chargingState) {
        case 1:
            self.customView.subTitleLabel.text = @"剩余电量";
            NSLog(@"剩余电量");
            break;
        case 2:
            self.customView.subTitleLabel.text = @"正在充电";
            NSLog(@"正在充电");
            break;
        case 3:
            self.customView.subTitleLabel.text = @"充电完成";
            NSLog(@"充电完成");
            break;
        default:
            self.customView.subTitleLabel.text = @"剩余电量";
            NSLog(@"充电状态有问题");
            break;
    }
}

- (void)boundDeviceFail {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)leftButtonAction {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)changeStatueAll:(NSNotification *)sender {
    self.hintStrFirst = sender.object;
    if (![BlueToothDataManager shareManager].isBeingRegisting) {
        if (![self.lblStatue.text containsString:INTERNATIONALSTRING(self.hintStrFirst)]) {
            self.lblStatue.text = INTERNATIONALSTRING(self.hintStrFirst);
        }
        NSLog(@"状态改变 --> %@ %@", self.hintStrFirst, self.lblStatue.text);
    }
    if (![self.hintStrFirst isEqualToString:HOMESTATUETITLE_REGISTING]) {
        if (self.timer) {
            [self.timer setFireDate:[NSDate distantFuture]];
        }
    } else {
        if (!self.timer) {
            //开启动画
            [self startTimerAction];
        }
    }
}

#pragma mark 计时器
- (void)startTimerAction {
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(startAnimation) userInfo:nil repeats:YES];
        //如果不添加下面这条语句，在UITableView拖动的时候，会阻塞定时器的调用
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:UITrackingRunLoopMode];
    } else {
        [self.timer setFireDate:[NSDate distantPast]];
    }
}

- (void)startAnimation {
//    进行Layer层旋转的
//    后面的字符串是固定名字，读取系统的文件信息
    CABasicAnimation *base = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    base.duration = 1;
//    起始的角度
    base.fromValue = @(0);
//    终止的角度
    base.toValue = @(M_PI_2 * 2);
//    将这个动画添加到layer上
    [self.imgStatueImage.layer addAnimation:base forKey:@"base"];
}

- (void)countAndShowPercentage:(NSString *)senderStr {
    if ([[BlueToothDataManager shareManager].operatorType intValue] == 1) {
        if ([senderStr intValue] < 160) {
            float count = (float)[senderStr intValue]/160;
            NSString *countStr = [NSString stringWithFormat:@"%.2f", count];
            if ([countStr floatValue] == 1) {
                self.lblStatue.text = [NSString stringWithFormat:@"%@99%%", INTERNATIONALSTRING(@"注册中")];
            } else {
                NSString *progress = [NSString stringWithFormat:@"%.0f", [countStr floatValue] * 100];
                if ([progress isEqualToString:@"0"]) {
                    self.lblStatue.text = INTERNATIONALSTRING(@"注册中");
                }else{
                    self.lblStatue.text = [NSString stringWithFormat:@"%@%@%%", INTERNATIONALSTRING(@"注册中"), progress];
                }
//                self.lblStatue.text = [NSString stringWithFormat:@"注册中%.0f%%", [countStr floatValue] * 100];
            }
        } else {
            self.lblStatue.text = [NSString stringWithFormat:@"%@99%%", INTERNATIONALSTRING(@"注册中")];
        }
    }
    if ([[BlueToothDataManager shareManager].operatorType intValue] == 2) {
        if ([senderStr intValue] < 340) {
            float count = (float)[senderStr intValue]/340;
            NSString *countStr = [NSString stringWithFormat:@"%.2f", count];
            if ([countStr floatValue] == 1) {
                self.lblStatue.text = [NSString stringWithFormat:@"%@99%%", INTERNATIONALSTRING(@"注册中")];
            } else {
                NSString *progress = [NSString stringWithFormat:@"%.0f", [countStr floatValue] * 100];
                if ([progress isEqualToString:@"0"]) {
                    self.lblStatue.text = INTERNATIONALSTRING(@"注册中");
                }else{
                    self.lblStatue.text = [NSString stringWithFormat:@"%@%@%%", INTERNATIONALSTRING(@"注册中"), progress];
                }
//                self.lblStatue.text = [NSString stringWithFormat:@"注册中%.0f%%", [countStr floatValue] * 100];
            }
        } else {
            self.lblStatue.text = [NSString stringWithFormat:@"%@99%%", INTERNATIONALSTRING(@"注册中")];
        }
    }
}

- (void)changeStatueAction:(NSNotification *)sender {
    NSString *senderStr = [NSString stringWithFormat:@"%@", sender.object];
    NSLog(@"接收到传过来的通知 -- %@", senderStr);
    if (![BlueToothDataManager shareManager].isRegisted && [BlueToothDataManager shareManager].isBeingRegisting) {
        if ([senderStr intValue] == 1) {
            [self startTimerAction];
        }
        [self countAndShowPercentage:senderStr];
    } else {
        NSLog(@"注册成功的时候处理");
        self.lblStatue.text = INTERNATIONALSTRING(@"信号强");
        if (self.timer) {
            [self.timer setFireDate:[NSDate distantFuture]];
        }
    }
}

- (void)bleStatueChanged:(NSNotification *)sender {
    if (![BlueToothDataManager shareManager].isRegisted && [BlueToothDataManager shareManager].isBeingRegisting) {
        NSString *statueStr = [NSString stringWithFormat:@"%@", sender.object];
        if ([statueStr isEqualToString:HOMESTATUETITLE_SIGNALSTRONG]) {
            self.lblStatue.text = INTERNATIONALSTRING(@"信号强");
            if (self.timer) {
                [self.timer setFireDate:[NSDate distantFuture]];
            }
        } else {
            NSLog(@"这是啥");
        }
    }
}

- (void)cardNumberNotTrueActionForBind:(NSNotification *)sender {
    self.lblStatue.text = INTERNATIONALSTRING(@"注册失败");
    if (self.timer) {
        [self.timer setFireDate:[NSDate distantFuture]];
    }
}

- (void)disConnectToDevice {
    if (self.customView) {
        self.customView.hidden = YES;
    }
    self.disconnectedImageView.image = [UIImage imageNamed:@"pic_zy_pre"];
    self.deviceName.hidden = YES;
    self.versionNumber.hidden = YES;
    self.macAddress.hidden = YES;
    self.lblStatue.text = INTERNATIONALSTRING(@"未连接");
    if (self.timer) {
        [self.timer setFireDate:[NSDate distantFuture]];
    }
}

#pragma mark 加载电量图形
- (void)addElectricQue {
    if ([BlueToothDataManager shareManager].isBounded) {
        self.versionNumber.hidden = NO;
        self.macAddress.hidden = NO;
        self.versionNumber.text = [BlueToothDataManager shareManager].versionNumber;
        self.macAddress.text = [BlueToothDataManager shareManager].deviceMacAddress;
        [self checkChargeStatue];
        if (!self.customView) {
            self.customView = [[LXWaveProgressView alloc]initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width/2), self.disconnectedImageView.frame.origin.y, 105, 105)];
            CGFloat flox = [UIScreen mainScreen].bounds.size.width/2;
            CGFloat floy = self.disconnectedImageView.center.y;
            self.customView.center = CGPointMake(flox, floy);
//            self.customView = [[WaterIdentifyView alloc]initWithFrame:self.disconnectedImageView.frame];
//            self.customView.showBgLineView = YES;
            [self.headView addSubview:self.customView];
        }
        self.customView.hidden = NO;
        NSString *num = [BlueToothDataManager shareManager].electricQuantity;
        CGFloat a = (float)[num intValue]/100.00;
        self.customView.progress = a;
        if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNITOYS]) {
            self.deviceName.text = @"手环";
            self.deviceName.hidden = NO;
        } else if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNIBOX]) {
            self.deviceName.text = @"双待王";
            self.deviceName.hidden = NO;
        } else {
            NSLog(@"这是连接的什么？");
        }
    } else {
        if (self.customView) {
            [self.customView removeFromSuperview];
        }
        if (![BlueToothDataManager shareManager].isConnected) {
            self.deviceName.hidden = YES;
        }
        if ([BlueToothDataManager shareManager].isConnected && ![BlueToothDataManager shareManager].isBounded) {
            self.deviceName.hidden = YES;
        }
    }
    self.disconnectedImageView.image = [UIImage imageNamed:@"pic_zy_pre"];
    [self.tableView reloadData];
}

#pragma mark 加载扫描图形
- (void)addScanView {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"scan" ofType:@"gif"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    UIImage *image = [UIImage sd_animatedGIFWithData:data];
    self.disconnectedImageView.image = image;
}

#pragma mark 点击手势连接设备
- (IBAction)tapToConnectingDevices:(UITapGestureRecognizer *)sender {
    if ([BlueToothDataManager shareManager].isOpened) {
        if ([BlueToothDataManager shareManager].isConnected && ![BlueToothDataManager shareManager].isBounded) {
            //点击绑定设备
            [[NSNotificationCenter defaultCenter] postNotificationName:@"boundingDevice" object:@"bound"];
            [self addScanView];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (![BlueToothDataManager shareManager].isConnected) {
                    self.disconnectedImageView.image = [UIImage imageNamed:@"pic_zy_pre"];
                }
            });
        } else if (![BlueToothDataManager shareManager].isConnected) {
            //未连接设备，先扫描连接
            [[NSNotificationCenter defaultCenter] postNotificationName:@"scanToConnect" object:@"connect"];
            [BlueToothDataManager shareManager].isNeedToBoundDevice = YES;
            [self addScanView];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (![BlueToothDataManager shareManager].isConnected) {
                    self.disconnectedImageView.image = [UIImage imageNamed:@"pic_zy_pre"];
                }
            });
        } else {
            //已经绑定了
        }
    } else {
        HUDNormal(INTERNATIONALSTRING(@"请开启蓝牙"))
    }
}

#pragma mark 解除绑定
- (IBAction)relieveBoundButtonAction:(UIButton *)sender {
    if ([BlueToothDataManager shareManager].isConnected) {
        //点击解除绑定,发送解除绑定通知
        [[NSNotificationCenter defaultCenter] postNotificationName:@"relieveBound" object:@"relieve"];
        [self unBindDevice];
    } else {
        [self checkHasBindDevice];
        
    }
}

#pragma mark 查询是否有绑定设备
- (void)checkHasBindDevice {
    self.checkToken = YES;
    [self getBasicHeader];
//    NSLog(@"表头：%@",self.headers);
    NSDictionary *info = [[NSDictionary alloc] init];
    [SSNetworkRequest getRequest:apiDeviceBracelet params:info success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"绑定的设备 -- %@", responseObj);
            if (![responseObj[@"msg"] isEqualToString:@"empty"]) {
                [self dj_alertAction:self alertTitle:nil actionTitle:@"继续" message:@"没有连接绑定的设备，是否要解除已绑定的设备？" alertAction:^{
                    [self unBindDevice];
                }];
            } else {
                HUDNormal(INTERNATIONALSTRING(@"该账号没有绑定设备"))
            }
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else if ([[responseObj objectForKey:@"status"] intValue]==0){
            //数据请求失败
            NSLog(@"没有设备");
            HUDNormal(INTERNATIONALSTRING(@"请求失败"))
        }
    } failure:^(id dataObj, NSError *error) {
        HUDNormal(INTERNATIONALSTRING(@"网络连接失败"))
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

#pragma mark 调用解除绑定接口
- (void)unBindDevice {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        HUDNoStop1(INTERNATIONALSTRING(@"正在解绑..."))
        self.checkToken = YES;
        [self getBasicHeader];
//        NSLog(@"表头：%@",self.headers);
        [SSNetworkRequest getRequest:apiUnBind params:nil success:^(id responseObj) {
            
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                NSLog(@"解除绑定结果：%@", responseObj);
                
                //将连接的信息存储到本地
                NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
                NSMutableDictionary *boundedDeviceInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"boundedDeviceInfo"]];
                if ([boundedDeviceInfo objectForKey:userdata[@"Tel"]]) {
                    [boundedDeviceInfo removeObjectForKey:userdata[@"Tel"]];
                }
                [[NSUserDefaults standardUserDefaults] setObject:boundedDeviceInfo forKey:@"boundedDeviceInfo"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                //删除存储的绑定信息
                [[UNDatabaseTools sharedFMDBTools] deleteTableWithAPIName:@"apiDeviceBracelet"];
                if ([BlueToothDataManager shareManager].isConnected) {
                    [[UNBlueToothTool shareBlueToothTool].mgr cancelPeripheralConnection:[UNBlueToothTool shareBlueToothTool].peripheral];
                }
                if ([[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"]) {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"offsetStatue"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                
                if ([[BlueToothDataManager shareManager].boundedDeviceName isEqualToString:MYDEVICENAMEUNIBOX]) {
                    HUDNormal(INTERNATIONALSTRING(@"已解除绑定"))
                }
                self.disconnectedImageView.image = [UIImage imageNamed:@"pic_zy_pre"];
                //发送解除绑定成功通知
                [[NSNotificationCenter defaultCenter] postNotificationName:@"noConnectedAndUnbind" object:@"noConnectedAndUnbind"];
                [BlueToothDataManager shareManager].isBounded = NO;
                [BlueToothDataManager shareManager].isConnected = NO;
                [BlueToothDataManager shareManager].isRegisted = NO;
                [BlueToothDataManager shareManager].deviceMacAddress = nil;
                [BlueToothDataManager shareManager].electricQuantity = nil;
                [BlueToothDataManager shareManager].versionNumber = nil;
                [BlueToothDataManager shareManager].stepNumber = nil;
                [BlueToothDataManager shareManager].bleStatueForCard = 0;
                [BlueToothDataManager shareManager].isBeingRegisting = NO;
                [BlueToothDataManager shareManager].chargingState = 1;
                [BlueToothDataManager shareManager].isNeedToCheckStatue = YES;
                if (self.customView) {
                    self.customView.hidden = YES;
                }
                self.versionNumber.hidden = YES;
                self.macAddress.hidden = YES;
                self.deviceName.hidden = YES;
                self.lblStatue.text = INTERNATIONALSTRING(@"未绑定");
                if (self.timer) {
                    [self.timer setFireDate:[NSDate distantFuture]];
                }
                [self.navigationController popToRootViewControllerAnimated:YES];
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
                HUDNormal(responseObj[@"msg"])
            }
            NSLog(@"查询到的运动数据：%@",responseObj);
        } failure:^(id dataObj, NSError *error) {
            NSLog(@"啥都没：%@",[error description]);
        } headers:self.headers];
    });
}

- (void)checkIsHaveNewVersion {
    self.checkToken = YES;
    [self getBasicHeader];
    //    NSLog(@"表头：%@",self.headers);
    NSString *versionStr;
    NSString *typeStr;
    if ([BlueToothDataManager shareManager].versionNumber) {
        versionStr= [BlueToothDataManager shareManager].versionNumber;
    } else {
        versionStr = @"1.0.0";
    }
    if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNITOYS]) {
        typeStr = @"0";
    } else if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNIBOX]) {
        typeStr = @"1";
    } else {
        typeStr = @"0";
        NSLog(@"连接的类型有问题");
    }
    NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:versionStr, @"Version", typeStr, @"DeviceType", nil];
    [SSNetworkRequest getRequest:apiDeviceBraceletOTA params:info success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"空中升级的请求结果 -- %@", responseObj);
            if (responseObj[@"data"][@"Descr"]) {
                self.versionLabel.hidden = NO;
            } else {
                self.versionLabel.hidden = YES;
            }
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else if ([[responseObj objectForKey:@"status"] intValue]==0){
            //数据请求失败
            NSLog(@"请求失败");
        }
    } failure:^(id dataObj, NSError *error) {
        HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

#pragma mark 调用空中升级接口
- (void)otaDownload {
    self.isBeingNet = YES;
    self.checkToken = YES;
    [self getBasicHeader];
//    NSLog(@"表头：%@",self.headers);
    NSString *versionStr;
    NSString *typeStr;
    if ([BlueToothDataManager shareManager].versionNumber) {
        versionStr= [BlueToothDataManager shareManager].versionNumber;
    } else {
        versionStr = @"1.0.0";
    }
    if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNITOYS]) {
        typeStr = @"0";
    } else if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNIBOX]) {
        typeStr = @"1";
    } else {
        typeStr = @"0";
        NSLog(@"连接的类型有问题");
    }
    NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:versionStr, @"Version", typeStr, @"DeviceType", nil];
    [SSNetworkRequest getRequest:apiDeviceBraceletOTA params:info success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"空中升级的请求结果 -- %@", responseObj);
            if (responseObj[@"data"][@"Descr"]) {
                NSString *infoStr = [NSString stringWithFormat:@"新版本：%@\n%@", responseObj[@"data"][@"Version"], responseObj[@"data"][@"Descr"]];
                [self dj_alertAction:self alertTitle:@"设备固件有更新" actionTitle:@"升级" message:infoStr alertAction:^{
                    //点击升级
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"OTAAction" object:responseObj[@"data"][@"Url"]];
                }];
            } else {
                HUDNormal(responseObj[@"msg"])
            }
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else if ([[responseObj objectForKey:@"status"] intValue]==0){
            //数据请求失败
            NSLog(@"请求失败");
        }
        self.isBeingNet = NO;
    } failure:^(id dataObj, NSError *error) {
        self.isBeingNet = NO;
        HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    return 15;
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
//    if (section == 1) {
//        return 15;
//    } else {
//        return 0.01;
//    }
//}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNITOYS]) {
        return 44;
    } else if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNIBOX]) {
        if (indexPath.section == 1 && (indexPath.row == 0 || indexPath.row == 1)) {
            return 0;
        } else {
            return 44;
        }
    } else {
        NSLog(@"连接的设备类型有问题 %@", [BlueToothDataManager shareManager].connectedDeviceName);
        if (indexPath.section == 1 && (indexPath.row == 0 || indexPath.row == 1)) {
            return 0;
        } else {
            return 44;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        if ([BlueToothDataManager shareManager].isConnected) {
            if (![BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue) {
//                if (![BlueToothDataManager shareManager].isBeingRegisting || [BlueToothDataManager shareManager].isRegisted) {
//                    [self startAnimation];
//                    [BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue = YES;
//                    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshStatueToCard" object:@"refreshStatueToCard"];
//                }
                 
                if (![[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_REGISTING]) {
                    [self startAnimation];
                    [BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue = YES;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshStatueToCard" object:@"refreshStatueToCard"];
                }
            }
        } else {
            HUDNormal(INTERNATIONALSTRING(@"未连接设备"))
        }
    }
    if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                if ([BlueToothDataManager shareManager].isConnected) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"searchMyBluetooth" object:@"searchMyBluetooth"];
                } else {
                    HUDNormal(INTERNATIONALSTRING(@"未连接设备"))
                }
                break;
            case 1:
            {
                self.isNeedToPushNextVC = YES;
                WristbandSettingViewController *wristbandSettingVC = [[WristbandSettingViewController alloc] init];
                [self.navigationController pushViewController:wristbandSettingVC animated:YES];
                break;
            }
            case 2:
                if ([BlueToothDataManager shareManager].isConnected) {
                    if (!self.isBeingNet) {
                        [self otaDownload];
                    }
                } else {
                    HUDNormal(INTERNATIONALSTRING(@"未连接设备"))
                }
                break;
            default:
                break;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"boundSuccess" object:@"boundSuccess"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"deviceIsDisconnect" object:@"deviceIsDisconnect"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"changeStatue" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"homeStatueChanged" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"cardNumberNotTrue" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"changeStatueAll" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"boundDeviceFailNotifi" object:@"boundDeviceFailNotifi"];
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
