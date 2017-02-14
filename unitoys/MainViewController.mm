//
//  MainViewController.m
//  unitoys
//
//  Created by sumars on 16/9/19.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "MainViewController.h"
#import "PhoneViewController.h"
#import "LoginViewController.h"
#import "JPUSHService.h"

@implementation MainViewController

- (void)viewDidLoad {
    
    self.delegate = self;
    
    for (UINavigationController *controller in self.childViewControllers) {
        controller.navigationBar.tintColor = [UIColor whiteColor];
        controller.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        controller.navigationBar.barTintColor = [UIColor blackColor];
        controller.navigationBar.translucent = NO;
    }
    for (int i = 0; i < self.childViewControllers.count; i++) {
        switch (i) {
            case 0:
                self.childViewControllers[i].tabBarItem.selectedImage = [[UIImage imageNamed:@"nav_homeSelected"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
                break;
            case 1:
                break;
            case 2:
                self.childViewControllers[i].tabBarItem.selectedImage = [[UIImage imageNamed:@"nav_contactsSelected"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
                break;
            case 3:
                self.childViewControllers[i].tabBarItem.selectedImage = [[UIImage imageNamed:@"nav_sportSelected"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
                break;
            case 4:
                self.childViewControllers[i].tabBarItem.selectedImage = [[UIImage imageNamed:@"nav_profileSelected"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
                break;
            default:
                break;
        }
    }
    
     self.tabBar.tintColor = [UIColor colorWithRed:1/255.0 green:208/255.0 blue:192/255.0 alpha:1];
    self.tabBar.backgroundColor = [UIColor whiteColor];
    
    UINavigationController *navPhoneViewController = [self.childViewControllers objectAtIndex:1];
    PhoneViewController *phoneViewController = [[PhoneViewController alloc] init];
    phoneViewController = [navPhoneViewController.childViewControllers objectAtIndex:0];
    
    if (phoneViewController) {
       [phoneViewController initEngine];
    }
    
    //注册接受者
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedSport) name:@"jumpToSport" object:@"jump"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedMessage) name:@"jumpToMessage" object:@"jumpToMessage"];
    
    //接收重新登入通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloginAction) name:@"reloginNotify" object:nil];

}

- (void)reloginAction {
    //注销极光推送
    [JPUSHService setTags:nil alias:nil fetchCompletionHandle:^(int iResCode, NSSet *iTags, NSString *iAlias) {
    }];
    
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
    
    UINavigationController *navPhoneViewController = [self.childViewControllers objectAtIndex:1];
    PhoneViewController *phoneViewController = [[PhoneViewController alloc] init];
    phoneViewController = [navPhoneViewController.childViewControllers objectAtIndex:0];
    
    if (phoneViewController) {
        [phoneViewController unregister];  //注销电话登入账号
    }
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
    
    UIViewController *currentViewController = [tabBarController.selectedViewController.childViewControllers objectAtIndex:0];
    
    if ([currentViewController isKindOfClass:[PhoneViewController class]]) {
        //设置键盘的图标为拨打图标
        [[self.tabBar.items objectAtIndex:1] setImage:[UIImage imageNamed:@"nav_call"]];
        [[self.tabBar.items objectAtIndex:1] setSelectedImage:[UIImage imageNamed:@"nav_call"]];
    }
    {
       
       UIViewController *nextViewController = [viewController.childViewControllers objectAtIndex:0];
        if ([nextViewController isKindOfClass:[PhoneViewController class]]) {
            
            //从其他模块回到拨打界面时重置segmented的状态
//            [[(PhoneViewController *)nextViewController segmentType] setSelectedSegmentIndex:0];
            if (![currentViewController isKindOfClass:[PhoneViewController class]]) {
                if ([(PhoneViewController *)nextViewController segmentType].selectedSegmentIndex != 0) {
                    [(PhoneViewController *)nextViewController segmentType].selectedSegmentIndex = 0;
                    [(PhoneViewController *)nextViewController switchOperation:[(PhoneViewController *)nextViewController segmentType]];
                }
            }
            
            //如果切换到拨打面板则键盘的图标为键盘操作
            
            if ([viewController isEqual:self.selectedViewController]) {
                [(PhoneViewController *)nextViewController setNumberPadStatus:![(PhoneViewController *)nextViewController numberPadStatus]];
                [(PhoneViewController *)nextViewController switchNumberPad:[(PhoneViewController *)nextViewController numberPadStatus]];
                if ([(PhoneViewController *)nextViewController numberPadStatus]) {
                    [[self.tabBar.items objectAtIndex:1] setImage:[UIImage imageNamed:@"tel_numberpad_pulloff"]];
                    [[self.tabBar.items objectAtIndex:1] setSelectedImage:[UIImage imageNamed:@"tel_numberpad_pulloff"]];
                }else{
                    [[self.tabBar.items objectAtIndex:1] setImage:[UIImage imageNamed:@"tel_numberpad_pushon"]];
                    [[self.tabBar.items objectAtIndex:1] setSelectedImage:[UIImage imageNamed:@"tel_numberpad_pushon"]];
                }
            }else{
            
                if ([(PhoneViewController *)nextViewController numberPadStatus]) {
                    [[self.tabBar.items objectAtIndex:1] setImage:[UIImage imageNamed:@"tel_numberpad_pulloff"]];
                    [[self.tabBar.items objectAtIndex:1] setSelectedImage:[UIImage imageNamed:@"tel_numberpad_pulloff"]];
                }else{
                    [[self.tabBar.items objectAtIndex:1] setImage:[UIImage imageNamed:@"tel_numberpad_pushon"]];
                    [[self.tabBar.items objectAtIndex:1] setSelectedImage:[UIImage imageNamed:@"tel_numberpad_pushon"]];
                }
            
            }
            
        }
    }
    
    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"jumpToSport" object:@"jump"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"jumpToMessage" object:@"jumpToMessage"];
}

@end
