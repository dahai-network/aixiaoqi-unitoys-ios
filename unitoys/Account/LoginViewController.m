//
//  LoginViewController.m
//  unitoys
//
//  Created by sumars on 16/9/16.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "LoginViewController.h"
#import "JPUSHService.h"
#import <sys/utsname.h>
#import "UNDatabaseTools.h"

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.edtUserName.text = [userDefaults objectForKey:@"KEY_USER_NAME"];
    self.edtPassText.text = [userDefaults objectForKey:@"KEY_PASS_WORD"];
    
    _edtPassText.bDrawBorder = YES;
    _edtUserName.bDrawBorder = YES;
    
    UIImageView *ivPhoneNumber = [[UIImageView alloc] initWithImage:[UIImage imageNamed: @"log_username"]];
    [ivPhoneNumber setFrame:CGRectMake(0, 0, 25, 30)];
    ivPhoneNumber.contentMode = UIViewContentModeCenter;
    self.edtUserName.leftView = ivPhoneNumber;
    self.edtUserName.leftViewMode = UITextFieldViewModeAlways;
    
    UIImageView *ivVerifyCode = [[UIImageView alloc] initWithImage:[UIImage imageNamed: @"log_password"]];
    [ivVerifyCode setFrame:CGRectMake(0, 0, 25, 30)];
    ivVerifyCode.contentMode = UIViewContentModeCenter;
    self.edtPassText.leftView = ivVerifyCode;
    self.edtPassText.leftViewMode = UITextFieldViewModeAlways;
    
//    [self checkLogin];
}

- (UIStatusBarStyle)preferredStatusBarStyle

{
    return UIStatusBarStyleLightContent;
}

- (void)checkLogin {
//    NSString *strGetLogin = [apiGetLogin stringByAppendingString:[self getParamStr]];
    
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
//    if (userdata) {
//        strGetLogin = [NSString stringWithFormat:@"%@&TOKEN=%@",strGetLogin,[userdata objectForKey:@"Token"]];
//        //
//    }
    HUDNoStop1(INTERNATIONALSTRING(@"正在登录..."))
    self.checkToken = YES;
    [self getBasicHeader];
    [SSNetworkRequest getRequest:apiGetLogin params:nil success:^(id resonseObj){
        
        if (resonseObj) {
            if ([[resonseObj objectForKey:@"status"] intValue]==1) {
//                NSString *alias = [NSString stringWithFormat:@"aixiaoqi%@", userdata[@"Tel"]];
                //更新别名为token
                NSString *alias = [NSString stringWithFormat:@"aixiaoqi%@", userdata[@"Token"]];
                [JPUSHService setTags:nil alias:alias fetchCompletionHandle:^(int iResCode, NSSet *iTags, NSString *iAlias) {
                    NSLog(@"极光别名：irescode = %d\n itags = %@\n ialias = %@", iResCode, iTags, iAlias);
                }];
//                NSLog(@"拿到数据：%@",resonseObj);
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                if (storyboard) {
                    UIViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
                    if (mainViewController) {
                        [self presentViewController:mainViewController animated:YES completion:nil];
                    }
                }
                
                //                [[UITabBar appearance] setBackgroundImage:<#(UIImage * _Nullable)#>:[UIColor blueColor]];
            }else if ([[resonseObj objectForKey:@"status"] intValue]==-999){
                [self showAlertViewWithMessage:@"999"];
            }
        }else{
            [self showAlertViewWithMessage:@"服务器好像有点忙，请稍后重试"];
        }
        
    }failure:^(id dataObj, NSError *error) {
        NSLog(@"登录失败：%@",[error description]);
        HUDNormal(INTERNATIONALSTRING(@"网络连接超时"))
//        HUDNormal([error description])
    } headers:self.headers];
}

- (IBAction)switchSecure:(id)sender {
    _bSecure = !_bSecure;
    _edtPassText.secureTextEntry = _bSecure;
    
    if (_bSecure) {
        [_btnSecure setImage:[UIImage imageNamed:@"log_hidewords"] forState:UIControlStateNormal];
    }else{
        [_btnSecure setImage:[UIImage imageNamed:@"log_showwords"] forState:UIControlStateNormal];
    }
}

- (IBAction)login:(id)sender {
    if (self.edtUserName.text.length!=11) {
        [self showAlertViewWithMessage:@"请输入正确的手机号"];
        return;
    }
    if (self.edtPassText.text.length<6) {
        [self showAlertViewWithMessage:@"请输入正确的密码"];
        return;
    }
    HUDNoStop1(INTERNATIONALSTRING(@"正在登录..."))
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    NSString *phoneModel = [self iphoneType];
    NSString *phoneNameAndSystem = [NSString stringWithFormat:@"%@,%@", phoneModel, systemVersion];
    NSLog(@"登录的设备是 --> %@", phoneNameAndSystem);
    NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:self.edtUserName.text,@"Tel",self.edtPassText.text,@"PassWord", phoneNameAndSystem, @"LoginTerminal",nil];
    kWeakSelf
    [self getBasicHeader];
    [SSNetworkRequest postRequest:apiCheckLogin params:info success:^(id resonseObj){
        NSMutableDictionary *userData = [[NSMutableDictionary alloc] initWithDictionary:[resonseObj objectForKey:@"data"]];
        if (resonseObj) {
            if ([[resonseObj objectForKey:@"status"] intValue]==1) {
                if ([NSNull null]== (NSNull *)[userData objectForKey:@"TrueName"]) {
                    [userData setObject:@"" forKey:@"TrueName"];
                }
                if ([NSNull null]== (NSNull *)[userData objectForKey:@"Email"]) {
                    [userData setObject:@"" forKey:@"Email"];
                }
                
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];  //保存登录信息
                [userDefaults setObject:userData forKey:@"userData"];
                [userDefaults setObject:self.edtUserName.text forKey:@"KEY_USER_NAME"];
                [userDefaults setObject:self.edtPassText.text forKey:@"KEY_PASS_WORD"];
                [userDefaults synchronize];
                
                //从服务器获取黑名单列表
                [weakSelf getBlackListsFromServer];
                
//                NSString *alias = [NSString stringWithFormat:@"aixiaoqi%@", userData[@"Tel"]];
                //更新别名为token
                NSString *alias = [NSString stringWithFormat:@"aixiaoqi%@", userData[@"Token"]];
                [JPUSHService setTags:nil alias:alias fetchCompletionHandle:^(int iResCode, NSSet *iTags, NSString *iAlias) {
                    NSLog(@"极光别名：irescode = %d\n itags = %@\n ialias = %@", iResCode, iTags, iAlias);
                }];
//                NSLog(@"拿到数据：%@",resonseObj);
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                if (storyboard) {
                    UIViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
                    if (mainViewController) {
                        [self presentViewController:mainViewController animated:YES completion:nil];
                    }
                }
            }else{
                if (resonseObj[@"msg"]) {
                    [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:[resonseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
                }else{
                    HUDNormal(INTERNATIONALSTRING(@"登录失败"))
                }
//                HUDNormal(resonseObj[@"msg"])
            }
        }else{
            [self showAlertViewWithMessage:@"服务器好像有点忙，请稍后重试"];
        }
    }failure:^(id dataObj, NSError *error) {
        NSLog(@"登录失败：%@",[error description]);
//        [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"服务器可能罢工中，请稍后重试" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
        HUDNormal(INTERNATIONALSTRING(@"网络连接失败"))
//        HUDNormal([error description])
    } headers:self.headers];
}

- (void)getBlackListsFromServer
{
    NSLog(@"LoginVC");
    kWeakSelf
    //从服务器获取黑名单
    self.checkToken = YES;
    [self getBasicHeader];
    [SSNetworkRequest getRequest:apiBlackListGet params:nil success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            [weakSelf addBlackLists:responseObj[@"data"]];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
        }
        NSLog(@"查询到的消息数据：%@",responseObj);
    } failure:^(id dataObj, NSError *error) {
        
    } headers:self.headers];
}

- (void)addBlackLists:(NSArray *)phoneList
{
    [[UNDatabaseTools sharedFMDBTools] insertBlackListWithPhoneLists:phoneList];
}

- (NSString *)iphoneType {
    
    //需要导入头文件：#import <sys/utsname.h>
    
    struct utsname systemInfo;
    
    uname(&systemInfo);
    
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    
    if ([platform isEqualToString:@"iPhone1,1"]) return @"iPhone 2G";
    
    if ([platform isEqualToString:@"iPhone1,2"]) return @"iPhone 3G";
    
    if ([platform isEqualToString:@"iPhone2,1"]) return @"iPhone 3GS";
    
    if ([platform isEqualToString:@"iPhone3,1"]) return @"iPhone 4";
    
    if ([platform isEqualToString:@"iPhone3,2"]) return @"iPhone 4";
    
    if ([platform isEqualToString:@"iPhone3,3"]) return @"iPhone 4";
    
    if ([platform isEqualToString:@"iPhone4,1"]) return @"iPhone 4S";
    
    if ([platform isEqualToString:@"iPhone5,1"]) return @"iPhone 5";
    
    if ([platform isEqualToString:@"iPhone5,2"]) return @"iPhone 5";
    
    if ([platform isEqualToString:@"iPhone5,3"]) return @"iPhone 5c";
    
    if ([platform isEqualToString:@"iPhone5,4"]) return @"iPhone 5c";
    
    if ([platform isEqualToString:@"iPhone6,1"]) return @"iPhone 5s";
    
    if ([platform isEqualToString:@"iPhone6,2"]) return @"iPhone 5s";
    
    if ([platform isEqualToString:@"iPhone7,1"]) return @"iPhone 6 Plus";
    
    if ([platform isEqualToString:@"iPhone7,2"]) return @"iPhone 6";
    
    if ([platform isEqualToString:@"iPhone8,1"]) return @"iPhone 6s";
    
    if ([platform isEqualToString:@"iPhone8,2"]) return @"iPhone 6s Plus";
    
    if ([platform isEqualToString:@"iPhone8,4"]) return @"iPhone SE";
    
    if ([platform isEqualToString:@"iPhone9,1"]) return @"iPhone 7";
    
    if ([platform isEqualToString:@"iPhone9,2"]) return @"iPhone 7 Plus";
    
    if ([platform isEqualToString:@"iPod1,1"])  return @"iPod Touch 1G";
    
    if ([platform isEqualToString:@"iPod2,1"])  return @"iPod Touch 2G";
    
    if ([platform isEqualToString:@"iPod3,1"])  return @"iPod Touch 3G";
    
    if ([platform isEqualToString:@"iPod4,1"])  return @"iPod Touch 4G";
    
    if ([platform isEqualToString:@"iPod5,1"])  return @"iPod Touch 5G";
    
    if ([platform isEqualToString:@"iPad1,1"])  return @"iPad 1G";
    
    if ([platform isEqualToString:@"iPad2,1"])  return @"iPad 2";
    
    if ([platform isEqualToString:@"iPad2,2"])  return @"iPad 2";
    
    if ([platform isEqualToString:@"iPad2,3"])  return @"iPad 2";
    
    if ([platform isEqualToString:@"iPad2,4"])  return @"iPad 2";
    
    if ([platform isEqualToString:@"iPad2,5"])  return @"iPad Mini 1G";
    
    if ([platform isEqualToString:@"iPad2,6"])  return @"iPad Mini 1G";
    
    if ([platform isEqualToString:@"iPad2,7"])  return @"iPad Mini 1G";
    
    if ([platform isEqualToString:@"iPad3,1"])  return @"iPad 3";
    
    if ([platform isEqualToString:@"iPad3,2"])  return @"iPad 3";
    
    if ([platform isEqualToString:@"iPad3,3"])  return @"iPad 3";
    
    if ([platform isEqualToString:@"iPad3,4"])  return @"iPad 4";
    
    if ([platform isEqualToString:@"iPad3,5"])  return @"iPad 4";
    
    if ([platform isEqualToString:@"iPad3,6"])  return @"iPad 4";
    
    if ([platform isEqualToString:@"iPad4,1"])  return @"iPad Air";
    
    if ([platform isEqualToString:@"iPad4,2"])  return @"iPad Air";
    
    if ([platform isEqualToString:@"iPad4,3"])  return @"iPad Air";
    
    if ([platform isEqualToString:@"iPad4,4"])  return @"iPad Mini 2G";
    
    if ([platform isEqualToString:@"iPad4,5"])  return @"iPad Mini 2G";
    
    if ([platform isEqualToString:@"iPad4,6"])  return @"iPad Mini 2G";
    
    if ([platform isEqualToString:@"i386"])      return @"iPhone Simulator";
    
    if ([platform isEqualToString:@"x86_64"])    return @"iPhone Simulator";
    
    return platform;
    
}

- (void)showAlertViewWithMessage:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(message) delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
}

- (IBAction)forget:(id)sender {
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *regUserViewController = [mainStory instantiateViewControllerWithIdentifier:@"regUserViewController"];
    if (regUserViewController) {
        [[NSUserDefaults standardUserDefaults] setObject:@"ForgetMode" forKey:@"UserMode"];
        [self presentViewController:regUserViewController animated:YES completion:nil];
    }
}

- (IBAction)regUser:(id)sender {
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *regUserViewController = [mainStory instantiateViewControllerWithIdentifier:@"regUserViewController"];
    if (regUserViewController) {
        [[NSUserDefaults standardUserDefaults] setObject:@"RegisterMode" forKey:@"UserMode"];
        [self presentViewController:regUserViewController animated:YES completion:nil];
    }
}


#pragma -mark UITextField Delegate
//-(void)textFieldDidBeginEditing:(UITextField *)textField{
//    
//    CGRect frame = textField.frame;
//    
//    //在这里我多加了62，（加上了输入中文选择文字的view高度）这个依据自己需求而定
//    int offset = (frame.origin.y+172)-(self.view.frame.size.height-216.0);//键盘高度216
//    
//    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
//    
//    [UIView setAnimationDuration:0.30f];//动画持续时间
//    
//    if (offset>0) {
//        //将视图的Y坐标向上移动offset个单位，以使下面腾出地方用于软键盘的显示
//        self.view.frame = CGRectMake(0.0f, -offset, self.view.frame.size.width, self.view.frame.size.height);
//        [UIView commitAnimations];
//    }
//    
//}

/**
 *当用户按下return键或者按回车键，我们注销KeyBoard响应，它会自动调用textFieldDidEndEditing函数
 */
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.edtUserName) {
        if (string.length == 0) return YES;
        
        NSInteger existedLength = textField.text.length;
        NSInteger selectedLength = range.length;
        NSInteger replaceLength = string.length;
        if (existedLength - selectedLength + replaceLength > 11) {
            return NO;
        }
    }
    
    return YES;
}


-(void)textFieldDidEndEditing:(UITextField *)textField{
    //输入框编辑完成以后，当键盘即将消失时，将视图恢复到原始状态
    self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
}

@end
