//
//  MainViewController.m
//  unitoys
//
//  Created by sumars on 16/9/19.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "MainViewController.h"
//#import "PhoneViewController.h"
#import "PhoneIndexController.h"
//#import "LoginViewController.h"
#import "UNLoginViewController.h"
#import "JPUSHService.h"
#import "navHomeViewController.h"
#import "UNDatabaseTools.h"
#import "UNBlueToothTool.h"
#import "BlueToothDataManager.h"
#import "UNDataTools.h"

#import "UNConvertFormatTool.h"
#import "UNPresentImageView.h"
#import "ConvenienceServiceController.h"
#import "UNPushKitMessageManager.h"
#import "VerificationPhoneController.h"

typedef enum : NSUInteger {
    DEFULTCOLOR,
    BLACKCOLOR,
    BLUECOLOR,
    YELLOWCOLOR,
} CHOOSECOLOR;

@interface MainViewController()

@property (nonatomic, weak) UNPresentImageView *presentImageView;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.delegate = self;
    for (navHomeViewController *controller in self.childViewControllers) {
        controller.navigationBar.tintColor = [UIColor whiteColor];
        controller.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        NSString *colorSrt = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentColor"];
        UIColor *currentColor;
        switch ([colorSrt intValue]) {
            case 0:
                currentColor = DefultColor;
                break;
            case 1:
                currentColor = [UIColor blackColor];
                break;
            case 2:
                currentColor = [UIColor blueColor];
                break;
            case 3:
                currentColor = [UIColor yellowColor];
                break;
            default:
                currentColor = DefultColor;
                break;
        }
        controller.navigationBar.barTintColor = currentColor;
        controller.navigationBar.translucent = NO;
    }
//    for (int i = 0; i < self.childViewControllers.count; i++) {
//        switch (i) {
//            case 0:
//                self.childViewControllers[i].tabBarItem.selectedImage = [[UIImage imageNamed:@"nav_homeSelected"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
//                break;
//            case 1:
//                break;
//            case 2:
//                self.childViewControllers[i].tabBarItem.selectedImage = [[UIImage imageNamed:@"nav_contactsSelected"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
//                break;
//            case 3:
//                self.childViewControllers[i].tabBarItem.selectedImage = [[UIImage imageNamed:@"nav_profileSelected"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
//                break;
//            default:
//                break;
//        }
//    }
    
//    self.tabBar.tintColor = [UIColor colorWithRed:1/255.0 green:208/255.0 blue:192/255.0 alpha:1];
    self.tabBar.tintColor = DefultColor;
    self.tabBar.backgroundColor = [UIColor whiteColor];
    
    
    navHomeViewController *navPhoneViewController = [self.childViewControllers objectAtIndex:1];
//    PhoneViewController *phoneViewController = [[PhoneViewController alloc] init];
    PhoneIndexController *phoneViewController;
    phoneViewController = [navPhoneViewController.childViewControllers objectAtIndex:0];
    
    if (phoneViewController) {
       [phoneViewController initEngine];
    }
    
//    [self addProgressWindow];
    
    //注册接受者
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedSport) name:@"jumpToSport" object:@"jump"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedMessage) name:@"jumpToMessage" object:@"jumpToMessage"];
    
    //接收重新登入通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloginAction) name:@"reloginNotify" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appIsKilled) name:@"appIsKilled" object:@"appIsKilled"];
    
    //是否隐藏上面进度条
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeShowProgressStatue:) name:@"isShowProgress" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeStatuesAll:) name:@"changeStatueAll" object:nil];//状态改变
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkNotUse:) name:@"netWorkNotToUse" object:nil];//网络状态不可用
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newCallInComing) name:@"NewCallInComing" object:nil];//有新呼叫
    //更新本地通话时长
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePhoneTime:) name:@"UpdateMaximumPhoneCallTime" object:nil];
    
    self.selectedViewController = self.childViewControllers[0];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.selectedViewController = self.childViewControllers[1];
    });
    
    
    [self showPresentImageView];
    [self updateCallTimeFromServer];
}

- (void)updatePhoneTime:(NSNotification *)noti
{
    if (noti.userInfo && noti.userInfo[@"maximumPhoneCallTime"]) {
        //更新本地时长
        NSDictionary *phoneTimeDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"MaxPhoneCallTime"];
        if (phoneTimeDict) {
            CGFloat time = [phoneTimeDict[@"maximumPhoneCallTime"] floatValue] - [noti.userInfo[@"maximumPhoneCallTime"] floatValue];
            NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:phoneTimeDict];
            mutableDict[@"maximumPhoneCallTime"] = @(time);
            [[NSUserDefaults standardUserDefaults] setObject:mutableDict forKey:@"MaxPhoneCallTime"];
        }
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateCallTimeFromServer];
    });
}

- (void)updateCallTimeFromServer
{
    [SSNetworkRequest getRequest:apiUserGetMaximumPhoneCallTimeAndExpiredTime params:nil success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"通话时间---responseObj===%@", responseObj);
//            expiredDate = 1497640553;
//            maximumPhoneCallTime = 0; 0为无限通话,-1为无通话时间
            [[NSUserDefaults standardUserDefaults] setObject:responseObj[@"data"] forKey:@"MaxPhoneCallTime"];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }
    } failure:^(id dataObj, NSError *error) {
        HUDNormal(INTERNATIONALSTRING(@"网络连接失败"))
        NSLog(@"啥都没：%@",[error description]);
    } headers:[UNDataTools sharedInstance].normalHeaders];
}

- (void)newCallInComing
{
    //dismisswindow
    if (self.presentImageView) {
        [self.presentImageView dismissWindow];
    }
}

- (void)showPresentImageView
{
//    BOOL isPresent = NO;
//    NSString *localDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"PresentConvenienceTime"];
//    NSDate *currentDate = [NSDate date];
//    NSString *currentDateStr = [UNConvertFormatTool dateStringYMDFromDate:currentDate];
//    if (localDate) {
//        if (![localDate isEqualToString:currentDateStr]) {
//            isPresent = YES;
//        }
//    }else{
//        isPresent = YES;
//        //        [[NSUserDefaults standardUserDefaults] setObject:currentDateStr forKey:@"PresentConvenienceTime"];
//    }
    
    __block NSString *currentDateStr;
    BOOL isPresent = [UNDataTools isSaveTodayDateWithKey:@"PresentConvenienceTime" TodayString:^(NSString *todayStr) {
        currentDateStr = todayStr;
    }];
    
#warning --测试数据,直接弹出
    isPresent = YES;
    kWeakSelf
    if (isPresent) {
        [SSNetworkRequest getRequest:apiPushContentGet params:nil success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                if (responseObj[@"data"][@"list"] && [responseObj[@"data"][@"list"] count]) {
                    NSString *imageUrl = responseObj[@"data"][@"list"][0][@"Image"];
                    NSLog(@"imageUrl---%@",imageUrl);
                    //需要判断当前是否正在通话,如果正在通话则不弹出
                    if (imageUrl) {
                        //如果有数据则出现
                        weakSelf.presentImageView = [UNPresentImageView sharePresentImageViewWithImageUrl:imageUrl cancelImageName:@"btn_close" imageTap:^{
                            [weakSelf presentConvenienceServiceVC];
                        }];
                        [[NSUserDefaults standardUserDefaults] setObject:currentDateStr forKey:@"PresentConvenienceTime"];
                    }
                }
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }
        } failure:^(id dataObj, NSError *error) {
            HUDNormal(INTERNATIONALSTRING(@"网络连接失败"))
            NSLog(@"啥都没：%@",[error description]);
        } headers:[UNDataTools sharedInstance].normalHeaders];
    }
}

- (void)presentConvenienceServiceVC
{
    if ([self.selectedViewController isKindOfClass:[navHomeViewController class]]) {
        ConvenienceServiceController *convenienceVC = [[ConvenienceServiceController alloc] init];
        [self.selectedViewController pushViewController:convenienceVC animated:YES];
    }
}



//- (void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//    self.selectedViewController = self.childViewControllers[1];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        self.selectedViewController = self.childViewControllers[1];
//    });
//    self.navigationController.navigationBar.translucent = NO;
//}

- (void)changeStatuesAll:(NSNotification *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeStatuesViewLable" object:sender.object];
//    self.showLabelStr = sender.object;
//    self.titleLabel.text = self.showLabelStr;
//    if (![self.showLabelStr isEqualToString:HOMESTATUETITLE_SIGNALSTRONG] && self.isMainView) {
//        [self addProgressWindow];
//    } else {
//        if ([BlueToothDataManager shareManager].isConnected && self.isNetworkCanUse) {
//            self.registProgress = nil;
//        } else {
//            if (self.isMainView) {
//                [self addProgressWindow];
//            } else {
//                self.registProgress = nil;
//            }
//        }
//    }
//    if (![BlueToothDataManager shareManager].isRegisted) {
//        [self addProgressWindow];
//    } else {
//        self.registProgress = nil;
//    }
    
    if ([sender.object isEqualToString:HOMESTATUETITLE_SIGNALSTRONG]) {
        if ([UNPushKitMessageManager shareManager].iccidString) {
            NSString *iccidKey = [NSString stringWithFormat:@"ValidateICCID%@", [UNPushKitMessageManager shareManager].iccidString];
            NSString *phoneStr = [[NSUserDefaults standardUserDefaults] objectForKey:iccidKey];
            if (!phoneStr || (phoneStr.length == 0)) {
                if ([self.selectedViewController isKindOfClass:[navHomeViewController class]]) {
                    if (![UNDataTools sharedInstance].isShowVerificationVc) {
                        VerificationPhoneController *verificationVc = [[VerificationPhoneController alloc] init];
                        verificationVc.veriIccidString = [UNPushKitMessageManager shareManager].iccidString;
                        navHomeViewController *nav = [[navHomeViewController alloc] initWithRootViewController:verificationVc];
                        [self.selectedViewController presentViewController:nav animated:YES completion:nil];
                    }
                }
            }
        }
    }
}

- (void)networkNotUse:(NSNotification *)sender {
    if ([sender.object isEqualToString:@"0"]) {
//        self.isNetworkCanUse = NO;
//        self.showLabelStr = @"当前网络不可用";
//        NSString *statuesLabelStr = @"当前网络不可用";
        [[NSNotificationCenter defaultCenter] postNotificationName:@"changeStatuesViewLable" object:HOMESTATUETITLE_NETWORKCANNOTUSE];
//        self.titleLabel.text = self.showLabelStr;
//        if (self.isMainView) {
//            [self addProgressWindow];
//        } else {
//            self.registProgress = nil;
//        }
    } else {
        //有网络
        NSLog(@"当前网络可用");
//        NSString *statuesLabelStr = @"注册中";
        [[NSNotificationCenter defaultCenter] postNotificationName:@"changeStatuesViewLable" object:HOMESTATUETITLE_REGISTING];
//        self.isNetworkCanUse = YES;
//        if (![[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_SIGNALSTRONG] && self.isMainView) {
//            [self addProgressWindow];
//        } else {
//            self.registProgress = nil;
//        }
     }
}

//- (void)changeShowProgressStatue:(NSNotification *)sender {
//    NSString *str = sender.object;
//    if ([str isEqualToString:@"1"] || [str isEqualToString:@"2"]) {
//        self.currentViewType = str;
//        self.isMainView = YES;
//        if (![[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_SIGNALSTRONG]) {
//            [self addProgressWindow];
//        } else {
//            if (self.isNetworkCanUse) {
//                self.registProgress = nil;
//            } else {
//                [self addProgressWindow];
//            }
//        }
//    } else {
//        self.isMainView = NO;
//        self.registProgress = nil;
//    }
//}
//
//- (void)addProgressWindow {
//    if (!self.registProgress) {
//        self.registProgress = [[UIWindow alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, 24)];
//        self.registProgress.windowLevel = UIWindowLevelAlert+1;
//        UIImageView *leftImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_bc"]];
//        leftImg.frame = CGRectMake(15, 2, 20, 20);
//        [self.registProgress addSubview:leftImg];
//        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftImg.frame)+5, 0, [UIScreen mainScreen].bounds.size.width-30-leftImg.frame.size.width, 24)];
//        self.titleLabel.text = self.showLabelStr;
//        self.titleLabel.font = [UIFont systemFontOfSize:14];
//        self.titleLabel.textColor = UIColorFromRGB(0x999999);
//        [self.registProgress addSubview:self.titleLabel];
//        [self.registProgress makeKeyAndVisible];
//    }
//    if ([self.currentViewType isEqualToString:@"2"]) {
//        self.registProgress.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.6];
//    } else {
//        self.registProgress.backgroundColor = UIColorFromRGB(0xffbfbf);
//    }
//}

#pragma mark app被杀死，注销电话
- (void)appIsKilled {
    navHomeViewController *navPhoneViewController = [self.childViewControllers objectAtIndex:1];
//    PhoneViewController *phoneViewController = [[PhoneViewController alloc] init];
    PhoneIndexController *phoneViewController;
    phoneViewController = [navPhoneViewController.childViewControllers objectAtIndex:0];
    
    if (phoneViewController) {
        [phoneViewController unregister];  //注销电话登入账号
        NSLog(@"电话注销了");
    }
}

- (void)reloginAction {
    NSLog(@"调用reloginAction方法");
//    [UNBlueToothTool shareBlueToothTool].isKill = YES;
    //删除存储的绑定信息
//    [[UNDatabaseTools sharedFMDBTools] deleteTableWithAPIName:@"apiDeviceBracelet"];
//    if ([BlueToothDataManager shareManager].isConnected) {
//        NSLog(@"断开蓝牙1");
//        if ([UNBlueToothTool shareBlueToothTool].peripheral) {
//            NSLog(@"断开蓝牙2");
//            [[UNBlueToothTool shareBlueToothTool].mgr cancelPeripheralConnection:[UNBlueToothTool shareBlueToothTool].peripheral];
//        }
//    }
    if ([BlueToothDataManager shareManager].isConnected && [BlueToothDataManager shareManager].isTcpConnected) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"closeServiceNotifi" object:@"closeServiceNotifi"];
    }
    [[UNBlueToothTool shareBlueToothTool] clearInstance];
    //清空数据库
    [[UNDatabaseTools sharedFMDBTools] logoutClearDatabase];
    [BlueToothDataManager shareManager].stepNumber = @"0";
    //注销极光推送
    [JPUSHService setTags:nil alias:nil fetchCompletionHandle:^(int iResCode, NSSet *iTags, NSString *iAlias) {
    }];
    //关闭tcp
    [[NSNotificationCenter defaultCenter] postNotificationName:@"disconnectTCP" object:@"disconnectTCP"];
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"appIsKilled" object:@"appIsKilled"];
    [self appIsKilled];
    //将连接的信息存储到本地
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    NSMutableDictionary *boundedDeviceInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"boundedDeviceInfo"]];
    if ([boundedDeviceInfo objectForKey:userdata[@"Tel"]]) {
        [boundedDeviceInfo removeObjectForKey:userdata[@"Tel"]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:boundedDeviceInfo forKey:@"boundedDeviceInfo"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"]) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"offsetStatue"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    //删除存储的绑定信息
//    [[UNDatabaseTools sharedFMDBTools] deleteTableWithAPIName:@"apiDeviceBracelet"];
//    [UNBlueToothTool shareBlueToothTool].isKill = YES;
//    if ([BlueToothDataManager shareManager].isConnected) {
//        if ([UNBlueToothTool shareBlueToothTool].peripheral) {
//            [[UNBlueToothTool shareBlueToothTool].mgr cancelPeripheralConnection:[UNBlueToothTool shareBlueToothTool].peripheral];
//        }
//    }
//    [[UNBlueToothTool shareBlueToothTool] clearInstance];
    
    [UNDataTools sharedInstance].normalHeaders = nil;
    
    UIApplication *application = [UIApplication sharedApplication];
    if ([application.keyWindow.rootViewController isKindOfClass:[UNLoginViewController class]]) {
        NSLog(@"dismissViewControllerAnimated");
        [self dismissViewControllerAnimated:YES completion:nil];
    }else{
//        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//        if (storyboard) {
//            UIViewController *loginViewController = [storyboard instantiateViewControllerWithIdentifier:@"loginViewController"];
//            if (loginViewController) {
//                application.keyWindow.rootViewController = loginViewController;
//                
//                [application.keyWindow makeKeyAndVisible];
//                
//                //                        [self presentViewController:mainViewController animated:YES completion:nil];
//            }
//        }
        UNLoginViewController *loginVc = [[UNLoginViewController alloc] init];
        NSLog(@"UNLoginViewController");
        if (loginVc) {
            application.keyWindow.rootViewController = loginVc;
            [application.keyWindow makeKeyAndVisible];
        }
    }
    
//    navHomeViewController *navPhoneViewController = [self.childViewControllers objectAtIndex:1];
//    PhoneViewController *phoneViewController = [[PhoneViewController alloc] init];
//    phoneViewController = [navPhoneViewController.childViewControllers objectAtIndex:0];
//    
//    if (phoneViewController) {
//        [phoneViewController unregister];  //注销电话登入账号
//    }
}

- (void)selectedSport {
    self.selectedViewController = self.childViewControllers[3];
}

- (void)selectedMessage {
    self.selectedViewController = self.childViewControllers[1];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
    
}

#pragma mark - UITabBarControllerDelegate
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController{
    
    if ([UNDataTools sharedInstance].isHasMallMessage) {
        UIViewController *nextViewController = [viewController.childViewControllers objectAtIndex:0];
        if ([nextViewController isKindOfClass:NSClassFromString(@"HomeViewController")]) {
            [UNDataTools sharedInstance].isHasMallMessage = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MallExtendMessage" object:nil];
        }
    }
    
//    if ([currentViewController isKindOfClass:[PhoneViewController class]]) {
//        //设置键盘的图标为拨打图标
//        [[self.tabBar.items objectAtIndex:1] setImage:[UIImage imageNamed:@"nav_call"]];
//        [[self.tabBar.items objectAtIndex:1] setSelectedImage:[UIImage imageNamed:@"nav_call"]];
//    }
//    {
//       UIViewController *nextViewController = [viewController.childViewControllers objectAtIndex:0];
//        if ([nextViewController isKindOfClass:[PhoneViewController class]]) {
            //从其他模块回到拨打界面时重置segmented的状态
//            [[(PhoneViewController *)nextViewController segmentType] setSelectedSegmentIndex:0];
//            if (![currentViewController isKindOfClass:[PhoneViewController class]]) {
//                if ([(PhoneViewController *)nextViewController segmentType].selectedSegmentIndex != 0) {
//                    [(PhoneViewController *)nextViewController segmentType].selectedSegmentIndex = 0;
//                    [(PhoneViewController *)nextViewController switchOperation:[(PhoneViewController *)nextViewController segmentType]];
//                }
//            }
            //如果切换到拨打面板则键盘的图标为键盘操作
//            if ([viewController isEqual:self.selectedViewController]) {
//                [(PhoneViewController *)nextViewController setNumberPadStatus:![(PhoneViewController *)nextViewController numberPadStatus]];
//                [(PhoneViewController *)nextViewController switchNumberPad:[(PhoneViewController *)nextViewController numberPadStatus]];
//                if ([(PhoneViewController *)nextViewController numberPadStatus]) {
//                    [[self.tabBar.items objectAtIndex:1] setImage:[UIImage imageNamed:@"tel_numberpad_pulloff"]];
//                    [[self.tabBar.items objectAtIndex:1] setSelectedImage:[UIImage imageNamed:@"tel_numberpad_pulloff"]];
//                }else{
//                    [[self.tabBar.items objectAtIndex:1] setImage:[UIImage imageNamed:@"tel_numberpad_pushon"]];
//                    [[self.tabBar.items objectAtIndex:1] setSelectedImage:[UIImage imageNamed:@"tel_numberpad_pushon"]];
//                }
//            }else{
//                if ([(PhoneViewController *)nextViewController numberPadStatus]) {
//                    [[self.tabBar.items objectAtIndex:1] setImage:[UIImage imageNamed:@"tel_numberpad_pulloff"]];
//                    [[self.tabBar.items objectAtIndex:1] setSelectedImage:[UIImage imageNamed:@"tel_numberpad_pulloff"]];
//                }else{
//                    [[self.tabBar.items objectAtIndex:1] setImage:[UIImage imageNamed:@"tel_numberpad_pushon"]];
//                    [[self.tabBar.items objectAtIndex:1] setSelectedImage:[UIImage imageNamed:@"tel_numberpad_pushon"]];
//                }
//            
//            }
            
//        }
//    }
    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"jumpToSport" object:@"jump"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"jumpToMessage" object:@"jumpToMessage"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"appIsKilled" object:@"appIsKilled"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"isShowProgress" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"changeStatueAll" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"netWorkNotToUse" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"reloginNotify" object:nil];
}

@end
