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
#import "OrderListViewController.h"

#import "UNDataTools.h"
#import "UITabBar+UNRedTip.h"
#import "UNDatabaseTools.h"
#import "StatuesViewDetailViewController.h"

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
@property (weak, nonatomic) IBOutlet UIButton *offButton;
@property (nonatomic, assign) BOOL isOpened;//开关是否打开
@property (nonatomic, strong)UIView *statuesView;
@property (nonatomic, strong)UILabel *statuesLabel;
@property (nonatomic, strong)UIView *registProgressView;

@end

@implementation AboutViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = nil;
    [self setRedLabel:self.haspackageTipMsgLabel];
    [self setRedLabel:self.hasNewVersionLabel];
    
    [self tipMessageStatuChange];
    
    //添加状态栏
    self.statuesView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, STATUESVIEWHEIGHT)];
    self.statuesView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.6];
    //添加手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(jumpToShowDetail)];
    [self.statuesView addGestureRecognizer:tap];
    //添加百分比
    if ([[BlueToothDataManager shareManager].stepNumber intValue] != 0 && [[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_REGISTING]) {
        int longStr = [[BlueToothDataManager shareManager].stepNumber intValue];
        CGFloat progressWidth;
        if ([[BlueToothDataManager shareManager].operatorType intValue] == 1 || [[BlueToothDataManager shareManager].operatorType intValue] == 2) {
            progressWidth = kScreenWidthValue *(longStr/160.00);
        } else if ([[BlueToothDataManager shareManager].operatorType intValue] == 3) {
            progressWidth = kScreenWidthValue *(longStr/340.00);
        } else {
            progressWidth = 0;
        }
        self.registProgressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, progressWidth, STATUESVIEWHEIGHT)];
    } else {
        self.registProgressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, STATUESVIEWHEIGHT)];
    }
    self.registProgressView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.6];
    [self.statuesView addSubview:self.registProgressView];
    //添加图片
    UIImageView *leftImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_bc"]];
    leftImg.frame = CGRectMake(15, (STATUESVIEWHEIGHT-STATUESVIEWIMAGEHEIGHT)/2, STATUESVIEWIMAGEHEIGHT, STATUESVIEWIMAGEHEIGHT);
    [self.statuesView addSubview:leftImg];
    //添加label
    self.statuesLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftImg.frame)+5, 0, kScreenWidthValue-30-leftImg.frame.size.width, STATUESVIEWHEIGHT)];
//    self.statuesLabel.text = [BlueToothDataManager shareManager].statuesTitleString;
    [self setStatuesLabelTextWithLabel:self.statuesLabel String:[BlueToothDataManager shareManager].statuesTitleString];
    self.statuesLabel.font = [UIFont systemFontOfSize:14];
    self.statuesLabel.textColor = UIColorFromRGB(0x999999);
    [self.statuesView addSubview:self.statuesLabel];
    if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_SIGNALSTRONG]) {
        self.statuesView.un_height = 0;
        self.registProgressView.un_width = 0;
        [self.tableView reloadData];
    }
    
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tipMessageStatuChange) name:@"TipMessageStatuChange" object:nil];
    //处理状态栏文字及高度
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aboutViewChangeStatuesView:) name:@"changeStatuesViewLable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showRegistProgress:) name:@"changeStatue" object:nil];//改变状态和百分比
}

#pragma mark 手势点击事件
- (void)jumpToShowDetail {
    if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_REGISTING] || [[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_NOTCONNECTED]) {
        if ([BlueToothDataManager shareManager].isBounded) {
            //有绑定
            UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
            BindDeviceViewController *bindDeviceViewController = [mainStory instantiateViewControllerWithIdentifier:@"bindDeviceViewController"];
            if (bindDeviceViewController) {
                self.tabBarController.tabBar.hidden = YES;
                bindDeviceViewController.hintStrFirst = [BlueToothDataManager shareManager].statuesTitleString;
                [self.navigationController pushViewController:bindDeviceViewController animated:YES];
            }
        }
    } else {
        StatuesViewDetailViewController *statuesViewDetailVC = [[StatuesViewDetailViewController alloc] init];
        [self.navigationController pushViewController:statuesViewDetailVC animated:YES];
    }
}

- (void)aboutViewChangeStatuesView:(NSNotification *)sender {
    NSLog(@"状态栏文字 --> %@", sender.object);
//    self.statuesLabel.text = sender.object;
    [self setStatuesLabelTextWithLabel:self.statuesLabel String:sender.object];
    if ([sender.object isEqualToString:HOMESTATUETITLE_SIGNALSTRONG]) {
        self.statuesView.un_height = 0;
        self.registProgressView.un_width = 0;
    } else {
        if (![sender.object isEqualToString:HOMESTATUETITLE_REGISTING]) {
            self.registProgressView.un_width = 0;
        }
        self.statuesView.un_height = STATUESVIEWHEIGHT;
    }
    [self.tableView reloadData];
}

- (void)showRegistProgress:(NSNotification *)sender {
    NSString *senderStr = [NSString stringWithFormat:@"%@", sender.object];
    NSLog(@"接收到传过来的通知 -- %@", senderStr);
    if (![BlueToothDataManager shareManager].isRegisted && [BlueToothDataManager shareManager].isBeingRegisting) {
        [self countAndShowRegistPercentage:senderStr];
    } else {
        NSLog(@"注册成功的时候处理");
    }
}

- (void)countAndShowRegistPercentage:(NSString *)senderStr {
    if ([[BlueToothDataManager shareManager].operatorType intValue] == 1 || [[BlueToothDataManager shareManager].operatorType intValue] == 2) {
        if ([senderStr intValue] < 160) {
            float count = (float)[senderStr intValue]/160;
            self.registProgressView.un_width = kScreenWidthValue * count;
        } else {
            self.registProgressView.un_width = kScreenWidthValue * 0.99;
        }
    } else if ([[BlueToothDataManager shareManager].operatorType intValue] == 3) {
        if ([senderStr intValue] < 340) {
            float count = (float)[senderStr intValue]/340;
            self.registProgressView.un_width = kScreenWidthValue * count;
        } else {
            self.registProgressView.un_width = kScreenWidthValue * 0.99;
        }
    } else {
        self.registProgressView.un_width = 0;
    }
}

- (void)tipMessageStatuChange
{
    //刷新提示界面
    if ([UNDataTools sharedInstance].isHasNotActiveTip) {
        self.haspackageTipMsgLabel.hidden = NO;
    }else{
        self.haspackageTipMsgLabel.hidden = YES;
    }
    if ([UNDataTools sharedInstance].isHasFirmwareUpdateTip) {
        self.hasNewVersionLabel.hidden = NO;
    }else{
        self.hasNewVersionLabel.hidden = YES;
    }
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
//    self.isOpened = NO;
//    [self.offButton setImage:[UIImage imageNamed:@"btn_kg_close"] forState:UIControlStateNormal];
    if ([sender.object isEqualToString:HOMESTATUETITLE_SIGNALSTRONG]) {
        self.operatorImg.image = [UIImage imageNamed:@"icon_nor"];
        [self checkOpertaorTypeName];
//        self.isOpened = YES;
//        [self.offButton setImage:[UIImage imageNamed:@"btn_kg_open"] forState:UIControlStateNormal];
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
    if ([BlueToothDataManager shareManager].isConnected) {
        [self dj_alertAction:self alertTitle:nil actionTitle:@"继续" message:@"您将要与蓝牙设备解除绑定？" alertAction:^{
            if ([BlueToothDataManager shareManager].isConnected) {
                [[UNBlueToothTool shareBlueToothTool] buttonToUnboundAction];
            } else {
                [self checkHasBindDevice];
            }
        }];
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
                [self.tableView reloadData];
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
    if ([BlueToothDataManager shareManager].isBounded) {
        self.connectedDeviceView.hidden = NO;
        if ([BlueToothDataManager shareManager].isConnected) {
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
            self.operatorName.text = @"----";
            self.electricNum.text = @"----";
            self.deviceName.text = [NSString stringWithFormat:@"设备：---"];
        }
        
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] isEqualToString:@"on"]) {
            self.isOpened = YES;
            [self.offButton setImage:[UIImage imageNamed:@"btn_kg_open"] forState:UIControlStateNormal];
        } else {
            self.isOpened = NO;
            [self.offButton setImage:[UIImage imageNamed:@"btn_kg_close"] forState:UIControlStateNormal];
        }
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
            if ([responseObj[@"data"][@"Unactivated"][@"TotalNumFlow"] isEqualToString:@"0"] && [responseObj[@"data"][@"Used"][@"TotalNum"] isEqualToString:@"0"]) {
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
            
//            if ([responseObj[@"data"][@"Unactivated"][@"TotalNumFlow"] intValue]) {
//                //总未激活流量套餐数
//                [UNDataTools sharedInstance].isHasNotActiveTip = YES;
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"TipMessageStatuChange" object:nil];
//            }else{
//                [UNDataTools sharedInstance].isHasNotActiveTip = NO;
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"TipMessageStatuChange" object:nil];
//            }
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

#pragma mark 开关点击事件
- (IBAction)offButtonAction:(UIButton *)sender {
    if (![BlueToothDataManager shareManager].isBeingRegisting) {
        self.isOpened = !self.isOpened;
        if (self.isOpened) {
            [sender setImage:[UIImage imageNamed:@"btn_kg_open"] forState:UIControlStateNormal];
            NSString *statueStr = @"on";
            [[NSUserDefaults standardUserDefaults] setObject:statueStr forKey:@"offsetStatue"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            if ([BlueToothDataManager shareManager].isConnected) {
                [[UNBlueToothTool shareBlueToothTool] checkSystemInfo];
            }
        } else {
            //添加注销注册的功能
            [self dj_alertAction:self alertTitle:@"温馨提示" actionTitle:@"继续" message:@"关闭此功能后您将无法正常使用电话和短信等相关功能，是否继续？" alertAction:^{
                [sender setImage:[UIImage imageNamed:@"btn_kg_close"] forState:UIControlStateNormal];
                NSString *statueStr = @"off";
                [[NSUserDefaults standardUserDefaults] setObject:statueStr forKey:@"offsetStatue"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                if ([BlueToothDataManager shareManager].isConnected && [BlueToothDataManager shareManager].isTcpConnected) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeServiceNotifi" object:@"closeServiceNotifi"];
                }
                [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NOTSERVICE;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"changeStatueAll" object:HOMESTATUETITLE_NOTSERVICE];
            }];
        }
    } else {
        HUDNormal(@"你不能在卡注册状态下更改此设置！")
    }
}


- (void)queryAmount {
    NSDictionary *userData = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    
    self.lblNickName.text = [userData objectForKey:@"NickName"];
    self.lblPhoneNumber.text = [userData objectForKey:@"Tel"];
    
    //    NSString *imageUrl = [NSString stringWithFormat:@"http://manage.ali168.com%@",[userData objectForKey:@"UserHead"]];\\
    
    NSString *imageUrl = [userData objectForKey:@"UserHead"];
    
    NSLog(@"头像头像:%@",imageUrl);
    
//    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
    
    
    
//    [self.ivUserHead sd_setImageWithURL:[NSURL URLWithString:imageUrl]];
    [self.ivUserHead sd_setImageWithURL:[NSURL URLWithString:imageUrl] placeholderImage:[UIImage imageNamed:@"pic_tx_pre"]];
    
    
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
    switch (indexPath.row) {
        case 2:
            [self amountDetail];
            break;
        case 3:
        {
            OrderListViewController *orderListViewController = [[OrderListViewController alloc] init];
            if (orderListViewController) {
                if ([UNDataTools sharedInstance].isHasNotActiveTip) {
                    [UNDataTools sharedInstance].isHasNotActiveTip = NO;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"TipMessageStatuChange" object:nil];
                }
                [self.navigationController pushViewController:orderListViewController animated:YES];
            }
        }
            break;
        case 4:
            if ([UNDataTools sharedInstance].isHasFirmwareUpdateTip) {
                [UNDataTools sharedInstance].isHasFirmwareUpdateTip = NO;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"TipMessageStatuChange" object:nil];
            }
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
        case 5:
        {
            PurviewSettingViewController *purviewSettingVC = [[PurviewSettingViewController alloc] init];
            [self.navigationController pushViewController:purviewSettingVC animated:YES];
        }
            break;
        case 6:
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
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section{
    view.tintColor = UIColorFromRGB(0xf5f5f5);
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return self.statuesView.frame.size.height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return self.statuesView;
}

#pragma mark -- Table
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 7;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            return 171;
            break;
        case 1:
            return 55;
            break;
        case 2:
            return 60;
            break;
        case 3:
            return 125;
            break;
        case 4:
            return 125;
            break;
        case 5:
            return 55;
            break;
        case 6:
            return 65;
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"changeStatuesViewLable" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"changeStatue" object:nil];
}
@end
