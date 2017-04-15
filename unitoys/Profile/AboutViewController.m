//
//  AboutViewController.m
//  unitoys
//
//  Created by sumars on 16/9/20.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "AboutViewController.h"
#import "UIImageView+WebCache.h"
#import "BindDeviceViewController.h"
//#import "AlarmListViewController.h"
#import "BlueToothDataManager.h"
#import "ChooseDeviceTypeViewController.h"
#import "WristbandSettingViewController.h"
#import "PurviewSettingViewController.h"
#import "CutomButton.h"
#import "UNBlueToothTool.h"

#define CELLHEIGHT 44

@interface AboutViewController ()
@property (nonatomic, strong) ChooseDeviceTypeViewController *chooseDeviceTypeVC;
@property (weak, nonatomic) IBOutlet UILabel *commicateMin;//剩余通话时长
@property (weak, nonatomic) IBOutlet UILabel *flowLbl;//剩余流量
@property (weak, nonatomic) IBOutlet UILabel *totalPackageNum;//总套餐数
@property (weak, nonatomic) IBOutlet UILabel *electricNum;//电量
@property (weak, nonatomic) IBOutlet UILabel *operatorName;//运营商
@property (weak, nonatomic) IBOutlet UIImageView *operatorImg;//信号
@property (weak, nonatomic) IBOutlet UILabel *flowName;//流量套餐显示名称
@property (weak, nonatomic) IBOutlet UILabel *deviceName;//设备类型


@end

@implementation AboutViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = nil;
//    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    //消除导航栏横线
    //自定义一个NaVIgationBar
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    //消除阴影
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(needRefreshAmount) name:@"NeedRefreshAmount" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryAmount) name:@"NeedRefreshInfo" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chargeConfrim) name:@"ChargeConfrim" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkBLEStatue) name:@"deviceIsDisconnect" object:@"deviceIsDisconnect"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkBLEStatue) name:@"boundSuccess" object:@"boundSuccess"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statueChanged:) name:@"homeStatueChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkCannotUse:) name:@"netWorkNotToUse" object:nil];//网络状态改变
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkChangeStatuesAll:) name:@"changeStatueAll" object:nil];//状态改变
}

- (void)networkCannotUse:(NSNotification *)sender {
    if ([sender.object isEqualToString:@"0"]) {
        self.operatorImg.image = [UIImage imageNamed:@"icon_dis"];
        self.operatorName.text = @"----";
    } else {
        NSLog(@"网络可用");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self checkBLEStatue];
            [self checkPackageResidue];
        });
    }
}

- (void)statueChanged:(NSNotification *)sender {
    if ([sender.object isEqualToString:HOMESTATUETITLE_SIGNALSTRONG]) {
        self.operatorImg.image = [UIImage imageNamed:@"icon_nor"];
        [self checkOpertaorTypeName];
    } else {
        self.operatorImg.image = [UIImage imageNamed:@"icon_dis"];
        self.operatorName.text = @"----";
    }
}

- (void)checkChangeStatuesAll:(NSNotification *)sender {
    if ([sender.object isEqualToString:HOMESTATUETITLE_SIGNALSTRONG]) {
        self.operatorImg.image = [UIImage imageNamed:@"icon_nor"];
        [self checkOpertaorTypeName];
    } else if ([sender.object isEqualToString:HOMESTATUETITLE_AIXIAOQICARD]) {
        self.operatorImg.image = [UIImage imageNamed:@"icon_dis"];
        [self checkOpertaorTypeName];
    } else {
        self.operatorImg.image = [UIImage imageNamed:@"icon_dis"];
        self.operatorName.text = @"----";
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self queryAmount];
}

- (void)chargeConfrim {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark 套餐超市按钮点击事件
- (IBAction)renewAction:(CutomButton *)sender {
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Package" bundle:nil];
    UIViewController *countryListViewController = [mainStory instantiateViewControllerWithIdentifier:@"countryListViewController"];
    if (countryListViewController) {
        self.tabBarController.tabBar.hidden = YES;
        [self.navigationController pushViewController:countryListViewController animated:YES];
    }
}

#pragma mark 解绑按钮点击事件
- (IBAction)unboundAction:(CutomButton *)sender {
    [self dj_alertAction:self alertTitle:nil actionTitle:@"继续" message:@"您将要与蓝牙设备解除绑定？" alertAction:^{
        if ([BlueToothDataManager shareManager].isConnected) {
            [[UNBlueToothTool shareBlueToothTool] buttonToUnboundAction];
        } else {
           HUDNormal(@"蓝牙已断开")
        }
    }];
}


- (void)amountDetail {
    //显示详情
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
    if (storyboard) {
        self.tabBarController.tabBar.hidden = YES;
        UIViewController *amountDetailViewController = [storyboard instantiateViewControllerWithIdentifier:@"amountDetailViewController"];
        if (amountDetailViewController) {
            [self.navigationController pushViewController:amountDetailViewController animated:YES];
        }
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    self.tabBarController.tabBar.hidden = NO;
    [self checkPackageResidue];
    [self checkBLEStatue];
}

- (void)checkBLEStatue {
    if ([BlueToothDataManager shareManager].isConnected) {
        self.connectedDeviceView.hidden = NO;
        if ([BlueToothDataManager shareManager].electricQuantity) {
            self.electricNum.text = [NSString stringWithFormat:@"%@%%", [BlueToothDataManager shareManager].electricQuantity];
        } else {
            self.electricNum.text = @"----";
        }
        if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNITOYS]) {
            self.deviceName.text = [NSString stringWithFormat:@"设备：手环"];
        } else if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNIBOX]) {
            self.deviceName.text = [NSString stringWithFormat:@"设备：双待王"];
        } else {
            NSLog(@"这是连接的什么？");
        }
        if ([BlueToothDataManager shareManager].isRegisted) {
            self.operatorImg.image = [UIImage imageNamed:@"icon_nor"];
        } else {
            self.operatorImg.image = [UIImage imageNamed:@"icon_dis"];
        }
        [self checkOpertaorTypeName];
    } else {
        self.connectedDeviceView.hidden = YES;
    }
}

- (void)checkOpertaorTypeName {
    switch ([[BlueToothDataManager shareManager].operatorType intValue]) {
        case 0:
            //                NSLog(@"插卡，上电失败");
            self.operatorName.text = @"----";
            break;
        case 1:
            //                NSLog(@"插卡，移动");
            self.operatorName.text = @"中国移动";
            break;
        case 2:
            //                NSLog(@"插卡，联通");
            self.operatorName.text = @"中国联通";
            break;
        case 3:
            //                NSLog(@"插卡，电信");
            self.operatorName.text = @"中国电信";
            break;
        case 4:
            //                NSLog(@"插卡，爱小器");
            self.operatorName.text = @"爱小器卡";
            break;
        case 5:
            //                NSLog(@"无卡");
            self.operatorName.text = @"----";
            break;
        default:
            //                NSLog(@"插卡，无法识别");
            self.operatorName.text = @"----";
            break;
    }
}

#pragma mark 查询用户套餐余量
- (void)checkPackageResidue {
    self.checkToken = YES;
    
    [self getBasicHeader];
    [SSNetworkRequest getRequest:apiGetUserOrderUsageRemaining params:nil success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            if ([responseObj[@"data"][@"Used"][@"TotalNum"] isEqualToString:@"0"]) {
                self.havePackageView.hidden = YES;
                NSLog(@"没有已激活的套餐");
            } else {
                
                self.totalPackageNum.text = [NSString stringWithFormat:@"%@个", responseObj[@"data"][@"Used"][@"TotalNum"]];
                self.commicateMin.text = [NSString stringWithFormat:@"%@分钟", responseObj[@"data"][@"Used"][@"TotalRemainingCallMinutes"]];
                switch ([responseObj[@"data"][@"Used"][@"TotalNumFlow"] intValue]) {
                    case 0:
                        NSLog(@"没有已激活的流量套餐(买了没有激活或者没有购买套餐)");
                        if (responseObj[@"data"][@"Unactivated"][@"TotalNumFlow"]) {
                            self.flowLbl.text = [NSString stringWithFormat:@"%@个", responseObj[@"data"][@"Unactivated"][@"TotalNumFlow"]];
                        } else {
                            self.flowLbl.text = [NSString stringWithFormat:@"%@个", responseObj[@"data"][@"Used"][@"TotalNumFlow"]];
                        }
                        self.flowName.text = @"未激活流量";
                        break;
                    case 1:
//                        NSLog(@"没有已激活的流量套餐(买了没有激活或者没有购买套餐)");
                        if (responseObj[@"data"][@"Used"][@"FlowPackageName"]) {
                            self.flowLbl.text = [NSString stringWithFormat:@"%@", responseObj[@"data"][@"Used"][@"FlowPackageName"]];
                        } else {
                            self.flowLbl.text = [NSString stringWithFormat:@"%@个", responseObj[@"data"][@"Used"][@"TotalNumFlow"]];
                        }
                        self.flowName.text = @"激活流量";
                        break;
                    default:
                        if (responseObj[@"data"][@"Used"][@"TotalNumFlow"]) {
                            self.flowLbl.text = [NSString stringWithFormat:@"%@个", responseObj[@"data"][@"Used"][@"TotalNumFlow"]];
                        }
                        self.flowName.text = @"激活流量";
                        break;
                }
                
                self.havePackageView.hidden = NO;
            }
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            self.havePackageView.hidden = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            self.havePackageView.hidden = YES;
        }
        
                NSLog(@"查询到的用户套餐余量：%@",responseObj);
    } failure:^(id dataObj, NSError *error) {
        //
        self.havePackageView.hidden = YES;
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}


- (void)needRefreshAmount {
    self.checkToken = YES;
    
    [self getBasicHeader];
    //    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest getRequest:apiGetUserAmount params:nil success:^(id responseObj) {
        //
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
//            self.lblAmount.text = [[[responseObj objectForKey:@"data"] objectForKey:@"amount"] stringValue];
            float amount = [responseObj[@"data"][@"amount"] floatValue];
            self.lblAmount.text = [NSString stringWithFormat:@"余额：%.2f元", amount];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
        //        NSLog(@"查询到的用户数据：%@",responseObj);
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}



- (void)queryAmount {
    NSDictionary *userData = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    
    self.lblNickName.text = [userData objectForKey:@"NickName"];
    self.lblPhoneNumber.text = [userData objectForKey:@"Tel"];
    
    //    NSString *imageUrl = [NSString stringWithFormat:@"http://manage.ali168.com%@",[userData objectForKey:@"UserHead"]];\\
    
    NSString *imageUrl = [userData objectForKey:@"UserHead"];
    
    NSLog(@"头像头像:%@",imageUrl);
    
//    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
    
    
    
    [self.ivUserHead sd_setImageWithURL:[NSURL URLWithString:imageUrl]];
    
    
    [self.ivUserHead.layer setMasksToBounds:YES];
  
    [self.ivUserHead.layer setCornerRadius:self.ivUserHead.bounds.size.width/2];
    self.ivUserHead.layer.borderColor = [UIColor whiteColor].CGColor;
    self.ivUserHead.layer.borderWidth = 2;
    
//    self.ivUserHead.image = [UIImage imageWithData:imageData];

    
//    [self.ivUserHead drawRect:self.ivUserHead.frame];
    
    [self needRefreshAmount];
}

#pragma mark ---TableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.section) {
        case 0:
            if (indexPath.row == 2) {
                [self amountDetail];
            }
            break;
        case 1:
            HUDNormal(@"激活套餐")
            break;
        case 2:
            if ([BlueToothDataManager shareManager].isOpened) {
                //跳转到设备界面
                if ([BlueToothDataManager shareManager].isBounded) {
                    //有绑定
                    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
                    BindDeviceViewController *bindDeviceViewController = [mainStory instantiateViewControllerWithIdentifier:@"bindDeviceViewController"];
                    if (bindDeviceViewController) {
                        self.tabBarController.tabBar.hidden = YES;
                        bindDeviceViewController.hintStrFirst = [BlueToothDataManager shareManager].statuesTitleString;
                        [self.navigationController pushViewController:bindDeviceViewController animated:YES];
                    }
                } else {
                    //没绑定
                    if (!self.chooseDeviceTypeVC) {
                        self.chooseDeviceTypeVC = [[ChooseDeviceTypeViewController alloc] init];
                    }
                    [self.navigationController pushViewController:self.chooseDeviceTypeVC animated:YES];
                }
            } else {
                HUDNormal(@"蓝牙未开")
            }
            break;
        case 3:
            switch (indexPath.row) {
                case 0:
                {
                    PurviewSettingViewController *purviewSettingVC = [[PurviewSettingViewController alloc] init];
                    [self.navigationController pushViewController:purviewSettingVC animated:YES];
                }
                    break;
                case 1:
                {
                    //开始调用设置
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Setting" bundle:nil];
                    if (storyboard) {
                        self.tabBarController.tabBar.hidden = YES;
                        UIViewController *settingViewController = [storyboard instantiateViewControllerWithIdentifier:@"settingViewController"];
                        if (settingViewController) {
                            [self.navigationController pushViewController:settingViewController animated:YES];
                        }
                    }
                }
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section{
    view.tintColor = UIColorFromRGB(0xf5f5f5);
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 3) {
        return 10;
    } else {
        return 5;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

#pragma mark -- Table
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return 3;
            break;
        case 1:
            return 1;
            break;
        case 2:
            return 1;
            break;
        case 3:
            return 2;
            break;
            
        default:
            return 0;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    return 171;
                    break;
                case 1:
                    return 55;
                    break;
                case 2:
                    return 55;
                    break;
                default:
                    return 55;
                    break;
            }
            break;
        case 1:
            return 120;
            break;
        case 2:
            return 120;
            break;
        case 3:
            return 55;
            break;
        default:
            return 55;
            break;
    }
}

- (IBAction)accountRecharge:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
    if (storyboard) {
        self.tabBarController.tabBar.hidden = YES;
        UIViewController *rechargeViewController = [storyboard instantiateViewControllerWithIdentifier:@"rechargeViewController"];
        if (rechargeViewController) {
            [self.navigationController pushViewController:rechargeViewController animated:YES];
        }
    }
}

- (IBAction)editProfile:(id)sender {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
    if (storyboard) {
        self.tabBarController.tabBar.hidden = YES;
        UIViewController *profileViewController = [storyboard instantiateViewControllerWithIdentifier:@"profileViewController"];
        if (profileViewController) {
            [self.navigationController pushViewController:profileViewController animated:YES];
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NeedRefreshAmount" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NeedRefreshInfo" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ChargeConfrim" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"deviceIsDisconnect" object:@"deviceIsDisconnect"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"boundSuccess" object:@"boundSuccess"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"homeStatueChanged" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"netWorkNotToUse" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"changeStatueAll" object:nil];
}
@end
