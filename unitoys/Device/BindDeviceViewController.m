//
//  BindDeviceViewController.m
//  unitoys
//
//  Created by sumars on 16/11/16.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BindDeviceViewController.h"
#import "BlueToothDataManager.h"
#import "WaterIdentifyView.h"
#import "UIImage+GIF.h"

@interface BindDeviceViewController ()
@property (weak, nonatomic) IBOutlet UILabel *lblStatue;
@property (weak, nonatomic) IBOutlet UIImageView *imgStatueImage;
@property (weak, nonatomic) IBOutlet UIButton *relieveBoundButton;
@property (nonatomic, strong)NSTimer *timer;
@property (weak, nonatomic) IBOutlet UIImageView *disconnectedImageView;

@end

@implementation BindDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    if (![BlueToothDataManager shareManager].isBounded) {
//        [self dj_alertAction:self alertTitle:nil actionTitle:@"去绑定" message:@"您还没有绑定设备，是否要绑定？" alertAction:^{
//            if ([BlueToothDataManager shareManager].isOpened) {
//                IsBoundingViewController *isBoundVC = [[IsBoundingViewController alloc] init];
//                [self.navigationController pushViewController:isBoundVC animated:YES];
//                //绑定设备
//                if ([BlueToothDataManager shareManager].isConnected) {
//                    //点击绑定设备
//                    [[NSNotificationCenter defaultCenter] postNotificationName:@"boundingDevice" object:@"bound"];
//                } else {
//                    //未连接设备，先扫描连接
//                    [[NSNotificationCenter defaultCenter] postNotificationName:@"scanToConnect" object:@"connect"];
//                }
//            } else {
//                HUDNormal(@"请先开启蓝牙")
//            }
//        }];
//    }
    
    //添加接收者
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addElectricQue) name:@"boundSuccess" object:@"boundSuccess"];//绑定成功
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disConnectToDevice) name:@"deviceIsDisconnect" object:@"deviceIsDisconnect"];//断开连接
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeStatueAction:) name:@"changeStatue" object:nil];//改变状态和百分比
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bleStatueChanged:) name:@"homeStatueChanged" object:nil];//连接成功或者失败
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cardNumberNotTrueActionForBind:) name:@"cardNumberNotTrue" object:nil];//号码有问题专用
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeStatueAll:) name:@"changeStatueAll" object:nil];//状态改变
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundDeviceFail) name:@"boundDeviceFailNotifi" object:@"boundDeviceFailNotifi"];//绑定钥匙扣的时候如果没有点击确认绑定就会发送此通知
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    self.lblStatue.text = self.hintStrFirst;
    if ([BlueToothDataManager shareManager].isConnected) {
        [self addElectricQue];
    } else {
        if (self.customView) {
            self.customView.hidden = YES;
        }
        self.hintLabel.text = INTERNATIONALSTRING(@"还没有连接设备，点击连接");
        self.versionNumber.hidden = YES;
        self.macAddress.hidden = YES;
        self.lblStatue.text = INTERNATIONALSTRING(@"未连接");
    }
    
    if ([BlueToothDataManager shareManager].isRegisted && [BlueToothDataManager shareManager].isConnected) {
        self.lblStatue.text = INTERNATIONALSTRING(@"信号强");
    }
    if ([BlueToothDataManager shareManager].isBeingRegisting && ![BlueToothDataManager shareManager].isRegisted && [BlueToothDataManager shareManager].isConnected) {
        //正在注册
        NSString *senderStr = [BlueToothDataManager shareManager].stepNumber;
        [self countAndShowPercentage:senderStr];
        //开启动画
        [self startTimerAction];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController popToRootViewControllerAnimated:YES];
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
        self.lblStatue.text = INTERNATIONALSTRING(self.hintStrFirst);
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
    self.disconnectedImageView.image = [UIImage imageNamed:@"blue_disconnected"];
    self.hintLabel.text = INTERNATIONALSTRING(@"还没有连接设备，点击连接");
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
        if (!self.customView) {
            self.customView = [[WaterIdentifyView alloc]initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width/2) - 50, 13, 100, 100)];
            self.customView.showBgLineView = YES;
            [self.headView addSubview:self.customView];
        }
        self.customView.hidden = NO;
        NSString *num = [BlueToothDataManager shareManager].electricQuantity;
        CGFloat a = (float)[num intValue]/100;
        self.customView.percent = a;
        //        self.hintLabel.hidden = YES;
//        if ([BlueToothDataManager shareManager].lastChargTime) {
//            self.hintLabel.text = [NSString stringWithFormat:@"上次充电时间:%@", [BlueToothDataManager shareManager].lastChargTime];
//        } else {
//            self.hintLabel.text = [NSString stringWithFormat:@"设备还未充过电"];
//        }
        if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNITOYS]) {
            self.hintLabel.text = INTERNATIONALSTRING(@"已连接爱小器手环");
        } else if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNIBOX]) {
            self.hintLabel.text = INTERNATIONALSTRING(@"已连接爱小器钥匙扣");
        } else {
            NSLog(@"这是连接的什么？");
        }
    } else {
        if (self.customView) {
            [self.customView removeFromSuperview];
            //            self.hintLabel.hidden = NO;
        }
        if (![BlueToothDataManager shareManager].isConnected) {
            self.hintLabel.text = INTERNATIONALSTRING(@"还没有连接设备，点击连接");
        }
        if ([BlueToothDataManager shareManager].isConnected && ![BlueToothDataManager shareManager].isBounded) {
            self.hintLabel.text = INTERNATIONALSTRING(@"还没有连接设备，点击绑定");
        }
    }
    self.disconnectedImageView.image = [UIImage imageNamed:@"blue_disconnected"];
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
            self.hintLabel.text = INTERNATIONALSTRING(@"正在搜索设备");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (![BlueToothDataManager shareManager].isConnected) {
                    self.disconnectedImageView.image = [UIImage imageNamed:@"blue_disconnected"];
                    self.hintLabel.text = INTERNATIONALSTRING(@"还没有连接设备，点击连接");
                }
            });
        } else if (![BlueToothDataManager shareManager].isConnected) {
            //未连接设备，先扫描连接
            [[NSNotificationCenter defaultCenter] postNotificationName:@"scanToConnect" object:@"connect"];
            [BlueToothDataManager shareManager].isNeedToBoundDevice = YES;
            [self addScanView];
            self.hintLabel.text = INTERNATIONALSTRING(@"正在搜索设备");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (![BlueToothDataManager shareManager].isConnected) {
                    self.disconnectedImageView.image = [UIImage imageNamed:@"blue_disconnected"];
                    self.hintLabel.text = INTERNATIONALSTRING(@"还没有连接设备，点击连接");
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
    NSLog(@"表头：%@",self.headers);
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
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

#pragma mark 调用解除绑定接口
- (void)unBindDevice {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        HUDNoStop1(INTERNATIONALSTRING(@"正在解绑..."))
        self.checkToken = YES;
        [self getBasicHeader];
        NSLog(@"表头：%@",self.headers);
        [SSNetworkRequest getRequest:apiUnBind params:nil success:^(id responseObj) {
            
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                NSLog(@"解除绑定结果：%@", responseObj);
                if ([[BlueToothDataManager shareManager].boundedDeviceName isEqualToString:MYDEVICENAMEUNIBOX]) {
                    HUDNormal(INTERNATIONALSTRING(@"已解除绑定"))
                }
                self.disconnectedImageView.image = [UIImage imageNamed:@"blue_disconnected"];
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
                if (self.customView) {
                    self.customView.hidden = YES;
                }
                self.versionNumber.hidden = YES;
                self.macAddress.hidden = YES;
                self.hintLabel.text = INTERNATIONALSTRING(@"还没有连接设备，点击连接");
                self.lblStatue.text = INTERNATIONALSTRING(@"未绑定");
                if (self.timer) {
                    [self.timer setFireDate:[NSDate distantFuture]];
                }
                [self.navigationController popToRootViewControllerAnimated:YES];
//                self.imgStatueImage.image = [UIImage imageNamed:@"deviceStatue_noSinge"];
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
                HUDNormal(responseObj[@"msg"])
            }
            NSLog(@"查询到的运动数据：%@",responseObj);
        } failure:^(id dataObj, NSError *error) {
            //
            NSLog(@"啥都没：%@",[error description]);
        } headers:self.headers];
    });
}

#pragma mark 调用空中升级接口
- (void)otaDownload {
    self.isBeingNet = YES;
    self.checkToken = YES;
    [self getBasicHeader];
    NSLog(@"表头：%@",self.headers);
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
                [self dj_alertAction:self alertTitle:@"设备固件有更新" actionTitle:@"升级" message:responseObj[@"data"][@"Descr"] alertAction:^{
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 15;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 1) {
        return 15;
    } else {
        return 0.01;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNITOYS]) {
        return 44;
    } else if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNIBOX]) {
        if (indexPath.section == 1 && indexPath.row == 0) {
            return 0;
        } else {
            return 44;
        }
    } else {
        NSLog(@"连接的设备类型有问题");
        return 44;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if ([BlueToothDataManager shareManager].isConnected) {
            if (![BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue) {
                if (![BlueToothDataManager shareManager].isBeingRegisting || [BlueToothDataManager shareManager].isRegisted) {
                    [self startAnimation];
                    [BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue = YES;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshStatueToCard" object:@"refreshStatueToCard"];
                }
            }
        } else {
            HUDNormal(INTERNATIONALSTRING(@"未连接手环"))
        }
    }
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            if ([BlueToothDataManager shareManager].isConnected) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"searchMyBluetooth" object:@"searchMyBluetooth"];
            } else {
                HUDNormal(INTERNATIONALSTRING(@"未连接手环"))
            }
        }
        if (indexPath.row == 1) {
            if ([BlueToothDataManager shareManager].isConnected) {
                if (!self.isBeingNet) {
                    [self otaDownload];
                }
            } else {
                HUDNormal(INTERNATIONALSTRING(@"未连接手环"))
            }
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
