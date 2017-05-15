//
//  SettingViewController.m
//  unitoys
//
//  Created by sumars on 16/9/21.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "SettingViewController.h"
#import "LinkUsViewController.h"
#import "JPUSHService.h"
#import "UNDatabaseTools.h"
#import "BlueToothDataManager.h"
#import "UNBlueToothTool.h"
#import "AddressBookManager.h"
#import "ShowPathViewController.h"

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSDictionary *userData = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    NSString *phoneNumberStr = [userData objectForKey:@"Tel"];
    if ([phoneNumberStr isEqualToString:@"15802747295"]) {
        [self setRightButton:@"轨迹"];
    }
    // 当前软件的版本号（从Info.plist中获得）
    NSString *key = @"CFBundleShortVersionString";
    self.versionNumberStr = [NSBundle mainBundle].infoDictionary[key];
    self.lblVersionNumber.text = self.versionNumberStr;
}

- (void)rightButtonClick {
    ShowPathViewController *showPathVC = [[ShowPathViewController alloc] init];
    [self.navigationController pushViewController:showPathVC animated:YES];
}

- (IBAction)logout:(id)sender {
//    NSString *str = NSLocalizedString(@"确定要退出登录吗？", nil);
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:INTERNATIONALSTRING(@"确定要退出登录吗？") preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(@"取消") style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *certailAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(@"确定") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [UNBlueToothTool shareBlueToothTool].isKill = YES;
        //点击事件
        self.checkToken = YES;
        
        [self getBasicHeader];
//        NSLog(@"表演头：%@",self.headers);
        [SSNetworkRequest getRequest:apiLogout params:nil success:^(id responseObj) {
            //
            NSLog(@"查询到的用户数据：%@",responseObj);
            
        } failure:^(id dataObj, NSError *error) {
            //
            NSLog(@"啥都没：%@",[error description]);
        } headers:self.headers];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];  //清除密码信息
//        [userDefaults setObject:@"" forKey:@"KEY_USER_NAME"];
        [userDefaults setObject:@"" forKey:@"KEY_PASS_WORD"];
        [userDefaults synchronize];
        
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
        [[UNDatabaseTools sharedFMDBTools] deleteTableWithAPIName:@"apiDeviceBracelet"];
        
        if ([BlueToothDataManager shareManager].isConnected) {
            if ([UNBlueToothTool shareBlueToothTool].peripheral) {
                [[UNBlueToothTool shareBlueToothTool].mgr cancelPeripheralConnection:[UNBlueToothTool shareBlueToothTool].peripheral];
            }
        }
//        [UNBlueToothTool shareBlueToothTool].isInitInstance = NO;
//        [UNBlueToothTool shareBlueToothTool] = nil;
//        [[UNBlueToothTool shareBlueToothTool] clearInstance];
        
        [AddressBookManager shareManager].isOpenedAddress = NO;
        //注销极光推送
        [JPUSHService setTags:nil alias:nil fetchCompletionHandle:^(int iResCode, NSSet *iTags, NSString *iAlias) {
            
        }];
//        [[UIApplication sharedApplication] unregisterForRemoteNotifications];
        NSLog(@"退出登录");
        //关闭tcp
        [[NSNotificationCenter defaultCenter] postNotificationName:@"disconnectTCP" object:@"disconnectTCP"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"appIsKilled" object:@"appIsKilled"];
        [[UNBlueToothTool shareBlueToothTool] clearInstance];
    }];
    [alertVC addAction:cancelAction];
    [alertVC addAction:certailAction];
    [self presentViewController:alertVC animated:YES completion:nil];
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
    if (indexPath.section==0) {
        //
        if (indexPath.row==0) {
            UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Setting" bundle:nil];
            LinkUsViewController *linkUsViewController = [mainStory instantiateViewControllerWithIdentifier:@"linkUsViewController"];
            if (linkUsViewController) {
                linkUsViewController.vwLink.arcValue = 10;
                [self.navigationController pushViewController:linkUsViewController animated:YES];
            }
        }else if (indexPath.row==1) {
            UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Setting" bundle:nil];
            UIViewController *feedbackViewController = [mainStory instantiateViewControllerWithIdentifier:@"feedbackViewController"];
            if (feedbackViewController) {
                [self.navigationController pushViewController:feedbackViewController animated:YES];
            }
        }
        
    } else {
        if (indexPath.row==0) {
            UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Setting" bundle:nil];
            UIViewController *agreementViewController = [mainStory instantiateViewControllerWithIdentifier:@"agreementViewController"];
            if (agreementViewController) {
                [self.navigationController pushViewController:agreementViewController animated:YES];
            }
        } else if (indexPath.row==1) {
            [self checkVersion];
        }
    }
}

- (void)checkVersion {
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"0", @"TerminalCode", [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"], @"Version", nil];
    [SSNetworkRequest getRequest:[apiUpgrade stringByAppendingString:[self getParamStr]] params:info success:^(id responseObj){
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"app升级信息 -- %@", responseObj);
            if (responseObj[@"data"][@"Descr"]) {
                NSString *infoStr = [NSString stringWithFormat:@"新版本：%@\n%@", responseObj[@"data"][@"Version"], responseObj[@"data"][@"Descr"]];
                if ([responseObj[@"data"][@"Mandatory"] intValue] == 0) {
                    //不强制
                    [self dj_alertActionWithAlertTitle:@"版本升级" leftActionTitle:@"下次再说" rightActionTitle:@"现在升级" message:infoStr rightAlertAction:^{
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ai-xiao-qi/id1184825159?mt=8"]];
                    }];
                } else if ([responseObj[@"data"][@"Mandatory"] intValue] == 1) {
                    //强制
                    [self dj_alertActionWithAlertTitle:@"版本升级" rightActionTitle:@"确定" message:infoStr rightAlertAction:^{
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ai-xiao-qi/id1184825159?mt=8"]];
                    }];
                } else {
                    NSLog(@"不知道是不是强制性的");
                }
            } else {
                NSString *str = [NSString stringWithFormat:@"%@%@",INTERNATIONALSTRING(@"当前版本") , self.versionNumberStr];
                HUDNormal(str)
            }
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            NSLog(@"数据请求失败 -- %@", responseObj[@"mag"]);
        }
    }failure:^(id dataObj, NSError *error) {
        HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        NSLog(@"数据错误：%@",[error description]);
        
    } headers:nil];
}

- (void)dj_alertActionWithAlertTitle:(NSString *)alertTitle leftActionTitle:(NSString *)leftActionTitle rightActionTitle:(NSString *)rightActionTitle message:(NSString *)message rightAlertAction:(void (^)())rightAlertAction {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:INTERNATIONALSTRING(alertTitle) message:INTERNATIONALSTRING(message) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(leftActionTitle) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *certailAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(rightActionTitle) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        rightAlertAction();
    }];
    [alertVC addAction:cancelAction];
    [alertVC addAction:certailAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)dj_alertActionWithAlertTitle:(NSString *)alertTitle rightActionTitle:(NSString *)rightActionTitle message:(NSString *)message rightAlertAction:(void (^)())rightAlertAction {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:INTERNATIONALSTRING(alertTitle) message:INTERNATIONALSTRING(message) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *certailAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(rightActionTitle) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        rightAlertAction();
    }];
    [alertVC addAction:certailAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}
@end
