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
#import "IsBoundingViewController.h"

@interface BindDeviceViewController ()
@property (weak, nonatomic) IBOutlet UILabel *lblStatue;
@property (weak, nonatomic) IBOutlet UIImageView *imgStatueImage;
@property (weak, nonatomic) IBOutlet UIButton *relieveBoundButton;

@end

@implementation BindDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addElectricQue];
    
    if ([BlueToothDataManager shareManager].isRegisted && [BlueToothDataManager shareManager].isConnected) {
        self.lblStatue.text = @"信号强";
        self.imgStatueImage.image = [UIImage imageNamed:@"deviceStatue_StrongSinge"];
    }
    if ([BlueToothDataManager shareManager].isBeingRegisting && ![BlueToothDataManager shareManager].isRegisted) {
        //正在注册
        NSString *senderStr = [BlueToothDataManager shareManager].stepNumber;
        [self countAndShowPercentage:senderStr];
    }
    
    if (![BlueToothDataManager shareManager].isBounded) {
        [self dj_alertAction:self alertTitle:nil actionTitle:@"去绑定" message:@"您还没有绑定设备，是否要绑定？" alertAction:^{
            if ([BlueToothDataManager shareManager].isOpened) {
                IsBoundingViewController *isBoundVC = [[IsBoundingViewController alloc] init];
                [self.navigationController pushViewController:isBoundVC animated:YES];
                //绑定设备
                if ([BlueToothDataManager shareManager].isConnected) {
                    //点击绑定设备
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"boundingDevice" object:@"bound"];
                } else {
                    //未连接设备，先扫描连接
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"scanToConnect" object:@"connect"];
                }
            } else {
                HUDNormal(@"请先开启蓝牙")
            }
        }];
    }
    
    //添加接收者
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addElectricQue) name:@"boundSuccess" object:@"boundSuccess"];//绑定成功
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disConnectToDevice) name:@"deviceIsDisconnect" object:@"deviceIsDisconnect"];//断开连接
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeStatueAction:) name:@"changeStatue" object:nil];//改变状态和百分比
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bleStatueChanged:) name:@"homeStatueChanged" object:nil];//连接成功或者失败
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cardNumberNotTrueActionForBind:) name:@"cardNumberNotTrue" object:nil];//号码有问题专用
    // Do any additional setup after loading the view.
}

- (void)countAndShowPercentage:(NSString *)senderStr {
    if ([[BlueToothDataManager shareManager].operatorType intValue] == 1) {
        if ([senderStr intValue] < 160) {
            float count = (float)[senderStr intValue]/160;
            NSString *countStr = [NSString stringWithFormat:@"%.2f", count];
            if ([countStr floatValue] == 1) {
                self.lblStatue.text = @"正在注册99%";
            } else {
                self.lblStatue.text = [NSString stringWithFormat:@"正在注册%.0f%%", [countStr floatValue] * 100];
            }
        } else {
            self.lblStatue.text = @"正在注册99%";
        }
    }
    if ([[BlueToothDataManager shareManager].operatorType intValue] == 2) {
        if ([senderStr intValue] < 340) {
            float count = (float)[senderStr intValue]/340;
            NSString *countStr = [NSString stringWithFormat:@"%.2f", count];
            if ([countStr floatValue] == 1) {
                self.lblStatue.text = @"正在注册99%";
            } else {
                self.lblStatue.text = [NSString stringWithFormat:@"正在注册%.0f%%", [countStr floatValue] * 100];
            }
        } else {
            self.lblStatue.text = @"正在注册99%";
        }
    }
}

- (void)changeStatueAction:(NSNotification *)sender {
    if (![BlueToothDataManager shareManager].isRegisted) {
        NSString *senderStr = [NSString stringWithFormat:@"%@", sender.object];
        [self countAndShowPercentage:senderStr];
    } else {
        NSLog(@"注册成功的时候处理");
        self.lblStatue.text = @"信号强";
        self.imgStatueImage.image = [UIImage imageNamed:@"deviceStatue_StrongSinge"];
    }
}

- (void)bleStatueChanged:(NSNotification *)sender {
    if (![BlueToothDataManager shareManager].isRegisted) {
        NSString *statueStr = [NSString stringWithFormat:@"%@", sender.object];
        if ([statueStr isEqualToString:HOMESTATUETITLE_SIGNALSTRONG]) {
            self.lblStatue.text = @"信号强";
            self.imgStatueImage.image = [UIImage imageNamed:@"deviceStatue_StrongSinge"];
        } else {
            self.imgStatueImage.image = [UIImage imageNamed:@"deviceStatue_noSinge"];
        }
    }
}

- (void)cardNumberNotTrueActionForBind:(NSNotification *)sender {
    self.lblStatue.text = @"无信号";
    self.imgStatueImage.image = [UIImage imageNamed:@"deviceStatue_noSinge"];
}

- (void)disConnectToDevice {
    if (self.customView) {
        self.customView.hidden = YES;
    }
    self.hintLabel.text = @"还没有连接设备，点击连接";
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
        if ([BlueToothDataManager shareManager].lastChargTime) {
            self.hintLabel.text = [NSString stringWithFormat:@"上次充电时间:%@", [BlueToothDataManager shareManager].lastChargTime];
        } else {
            self.hintLabel.text = [NSString stringWithFormat:@"设备还未充过电"];
        }
    } else {
        if (self.customView) {
            [self.customView removeFromSuperview];
            //            self.hintLabel.hidden = NO;
        }
        if (![BlueToothDataManager shareManager].isConnected) {
            self.hintLabel.text = @"还没有连接设备，点击连接";
        }
        if ([BlueToothDataManager shareManager].isConnected && ![BlueToothDataManager shareManager].isBounded) {
            self.hintLabel.text = @"还没有绑定设备，点击绑定";
        }
    }
}

#pragma mark 点击手势连接设备
- (IBAction)tapToConnectingDevices:(UITapGestureRecognizer *)sender {
    if ([BlueToothDataManager shareManager].isConnected && ![BlueToothDataManager shareManager].isBounded) {
        //点击绑定设备
        [[NSNotificationCenter defaultCenter] postNotificationName:@"boundingDevice" object:@"bound"];
        IsBoundingViewController *isBoundVC = [[IsBoundingViewController alloc] init];
        [self.navigationController pushViewController:isBoundVC animated:YES];
    } else if (![BlueToothDataManager shareManager].isConnected) {
        //未连接设备，先扫描连接
        [[NSNotificationCenter defaultCenter] postNotificationName:@"scanToConnect" object:@"connect"];
        IsBoundingViewController *isBoundVC = [[IsBoundingViewController alloc] init];
        [self.navigationController pushViewController:isBoundVC animated:YES];
    } else {
        //已经绑定了
    }
}

#pragma mark 解除绑定
- (IBAction)relieveBoundButtonAction:(UIButton *)sender {
    if ([BlueToothDataManager shareManager].isBounded) {
        //点击解除绑定,发送解除绑定通知
        [[NSNotificationCenter defaultCenter] postNotificationName:@"relieveBound" object:@"relieve"];
        [self unBindDevice];
//        sender.enabled = NO;
    } else {
//        HUDNormal(@"没有可解绑的设备")
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
            [self dj_alertAction:self alertTitle:nil actionTitle:@"继续" message:@"没有连接绑定的设备，是否要解除已绑定的设备？" alertAction:^{
                [self unBindDevice];
            }];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else if ([[responseObj objectForKey:@"status"] intValue]==0){
            //数据请求失败
            NSLog(@"没有设备");
            HUDNormal(@"没有可解绑的设备")
        }
    } failure:^(id dataObj, NSError *error) {
        HUDNormal(@"网络貌似有问题")
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

#pragma mark 调用解除绑定接口
- (void)unBindDevice {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        HUDNoStop1(@"正在解绑...")
        self.checkToken = YES;
        [self getBasicHeader];
        NSLog(@"表头：%@",self.headers);
        [SSNetworkRequest getRequest:apiUnBind params:nil success:^(id responseObj) {
            
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                NSLog(@"解除绑定结果：%@", responseObj);
                HUDNormal(@"已解除绑定")
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
                if (self.customView) {
                    self.customView.hidden = YES;
                }
                self.versionNumber.hidden = YES;
                self.macAddress.hidden = YES;
                self.hintLabel.text = @"还没有连接设备，点击连接";
                self.lblStatue.text = @"无信号";
                self.imgStatueImage.image = [UIImage imageNamed:@"deviceStatue_noSinge"];
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
    self.checkToken = YES;
    [self getBasicHeader];
    NSLog(@"表头：%@",self.headers);
    NSString *versionStr;
    if ([BlueToothDataManager shareManager].versionNumber) {
        versionStr= [BlueToothDataManager shareManager].versionNumber;
    } else {
        versionStr = @"1";
    }
    NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:versionStr, @"Version", nil];
    [SSNetworkRequest getRequest:apiDeviceBraceletOTA params:info success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"空中升级的请求结果 -- %@", responseObj);
            if (responseObj[@"data"][@"Descr"]) {
                [self dj_alertAction:self alertTitle:nil actionTitle:@"升级" message:responseObj[@"data"][@"Descr"] alertAction:^{
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
    } failure:^(id dataObj, NSError *error) {
        HUDNormal(@"网络貌似有问题")
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            if ([BlueToothDataManager shareManager].isConnected) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"searchMyBluetooth" object:@"searchMyBluetooth"];
            } else {
                HUDNormal(@"未连接手环")
            }
        }
        if (indexPath.row == 1) {
            if ([BlueToothDataManager shareManager].isConnected) {
                [self otaDownload];
            } else {
                HUDNormal(@"未连接手环")
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
