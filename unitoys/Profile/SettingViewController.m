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

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 当前软件的版本号（从Info.plist中获得）
    NSString *key = @"CFBundleShortVersionString";
    self.versionNumberStr = [NSBundle mainBundle].infoDictionary[key];
    self.lblVersionNumber.text = self.versionNumberStr;
}

- (IBAction)logout:(id)sender {
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:@"确定要退出登录吗？" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *certailAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //点击事件
        self.checkToken = YES;
        
        [self getBasicHeader];
        NSLog(@"表演头：%@",self.headers);
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
        
        //注销极光推送
        [JPUSHService setTags:nil alias:nil fetchCompletionHandle:^(int iResCode, NSSet *iTags, NSString *iAlias) {
            
        }];
//        [[UIApplication sharedApplication] unregisterForRemoteNotifications];
        //关闭tcp
        [[NSNotificationCenter defaultCenter] postNotificationName:@"disconnectTCP" object:@"disconnectTCP"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
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
            NSString *str = [NSString stringWithFormat:@"当前版本%@", self.versionNumberStr];
            HUDNormal(str)
        }
    }
}
@end
