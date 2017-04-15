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
#import "LoginViewController.h"
#import "JPUSHService.h"
#import "navHomeViewController.h"
#import "UNDatabaseTools.h"
#import "UNBlueToothTool.h"
#import "BlueToothDataManager.h"

typedef enum : NSUInteger {
    DEFULTCOLOR,
    BLACKCOLOR,
    BLUECOLOR,
    YELLOWCOLOR,
} CHOOSECOLOR;

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
    
    self.tabBar.tintColor = [UIColor colorWithRed:1/255.0 green:208/255.0 blue:192/255.0 alpha:1];
    self.tabBar.backgroundColor = [UIColor whiteColor];
    
    
    navHomeViewController *navPhoneViewController = [self.childViewControllers objectAtIndex:1];
//    PhoneViewController *phoneViewController = [[PhoneViewController alloc] init];
    PhoneIndexController *phoneViewController;
    phoneViewController = [navPhoneViewController.childViewControllers objectAtIndex:0];
    
    if (phoneViewController) {
       [phoneViewController initEngine];
    }
    
    [self addProgressWindow];
    
    //注册接受者
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedSport) name:@"jumpToSport" object:@"jump"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedMessage) name:@"jumpToMessage" object:@"jumpToMessage"];
    
    //接收重新登入通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloginAction) name:@"reloginNotify" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appIsKilled) name:@"appIsKilled" object:@"appIsKilled"];
    
    //是否隐藏上面进度条
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeShowProgressStatue:) name:@"isShowProgress" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeStatuesAll:) name:@"changeStatueAll" object:nil];//状态改变
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkNotUse:) name:@"netWorkNotToUse" object:nil];//网络状态不可用

}

- (void)changeStatuesAll:(NSNotification *)sender {
    self.showLabelStr = sender.object;
    self.titleLabel.text = self.showLabelStr;
    if (![self.showLabelStr isEqualToString:HOMESTATUETITLE_SIGNALSTRONG]) {
        [self addProgressWindow];
    } else {
        self.registProgress = nil;
    }
//    if (![BlueToothDataManager shareManager].isRegisted) {
//        [self addProgressWindow];
//    } else {
//        self.registProgress = nil;
//    }
}

- (void)networkNotUse:(NSNotification *)sender {
    if ([sender.object isEqualToString:@"0"]) {
        self.showLabelStr = @"当前网络不可用";
        self.titleLabel.text = self.showLabelStr;
        [self addProgressWindow];
    } else {
        //有网络
        NSLog(@"当前网络可用");
        if (![BlueToothDataManager shareManager].isRegisted) {
            [self addProgressWindow];
        } else {
            self.registProgress = nil;
        }
     }
}

- (void)changeShowProgressStatue:(NSNotification *)sender {
    NSString *str = sender.object;
    if ([str isEqualToString:@"1"] && ![BlueToothDataManager shareManager].isRegisted) {
        [self addProgressWindow];
    } else {
        self.registProgress = nil;
    }
}

- (void)addProgressWindow {
    if (!self.registProgress) {
        self.registProgress = [[UIWindow alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, 24)];
        self.registProgress.windowLevel = UIWindowLevelStatusBar+1;
        self.registProgress.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.6];
        UIImageView *leftImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_bc"]];
        leftImg.frame = CGRectMake(15, 2, 20, 20);
        [self.registProgress addSubview:leftImg];
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftImg.frame)+5, 0, [UIScreen mainScreen].bounds.size.width-30-leftImg.frame.size.width, 24)];
        self.titleLabel.text = self.showLabelStr;
        self.titleLabel.font = [UIFont systemFontOfSize:14];
        self.titleLabel.textColor = UIColorFromRGB(0x999999);
        [self.registProgress addSubview:self.titleLabel];
        [self.registProgress makeKeyAndVisible];
    }
}

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
    //注销极光推送
    [JPUSHService setTags:nil alias:nil fetchCompletionHandle:^(int iResCode, NSSet *iTags, NSString *iAlias) {
    }];
    //关闭tcp
    [[NSNotificationCenter defaultCenter] postNotificationName:@"disconnectTCP" object:@"disconnectTCP"];
    
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
    [UNBlueToothTool shareBlueToothTool].isInitInstance = NO;
    
    UIApplication *application = [UIApplication sharedApplication];
    if ([application.keyWindow.rootViewController isKindOfClass:[LoginViewController class]]) {
        [self dismissViewControllerAnimated:YES completion:nil];
        
    }else{
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        if (storyboard) {
            UIViewController *loginViewController = [storyboard instantiateViewControllerWithIdentifier:@"loginViewController"];
            if (loginViewController) {
                application.keyWindow.rootViewController = loginViewController;
                
                [application.keyWindow makeKeyAndVisible];
                
                //                        [self presentViewController:mainViewController animated:YES completion:nil];
            }
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
    
//    UIViewController *currentViewController = [tabBarController.selectedViewController.childViewControllers objectAtIndex:0];
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
}

@end
