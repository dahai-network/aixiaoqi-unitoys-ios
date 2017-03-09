//
//  LoginViewController.m
//  unitoys
//
//  Created by sumars on 16/9/16.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "LoginViewController.h"
#import "JPUSHService.h"


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
    NSString *strGetLogin = [apiGetLogin stringByAppendingString:[self getParamStr]];
    
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    if (userdata) {
        strGetLogin = [NSString stringWithFormat:@"%@&TOKEN=%@",strGetLogin,[userdata objectForKey:@"Token"]];
        //
    }
    HUDNoStop1(@"正在登录...")
    [SSNetworkRequest getRequest:strGetLogin params:nil success:^(id resonseObj){
        
        if (resonseObj) {
            if ([[resonseObj objectForKey:@"status"] intValue]==1) {
//                NSString *alias = [NSString stringWithFormat:@"aixiaoqi%@", userdata[@"Tel"]];
                //更新别名为token
                NSString *alias = [NSString stringWithFormat:@"aixiaoqi%@", userdata[@"Token"]];
                [JPUSHService setTags:nil alias:alias fetchCompletionHandle:^(int iResCode, NSSet *iTags, NSString *iAlias) {
                    NSLog(@"极光别名：irescode = %d\n itags = %@\n ialias = %@", iResCode, iTags, iAlias);
                }];
                NSLog(@"拿到数据：%@",resonseObj);
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                if (storyboard) {
                    UIViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
                    if (mainViewController) {
                        [self presentViewController:mainViewController animated:YES completion:nil];
                    }
                }
                
                //                [[UITabBar appearance] setBackgroundImage:<#(UIImage * _Nullable)#>:[UIColor blueColor]];
            }else if ([[resonseObj objectForKey:@"status"] intValue]==-999){
                
                [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"999" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
            }
        }else{
            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"服务器好像有点忙，请稍后重试" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
        }
        
    }failure:^(id dataObj, NSError *error) {
        NSLog(@"登录失败：%@",[error description]);
        HUDNormal(@"网络连接超时")
//        HUDNormal([error description])
    } headers:nil];
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
        [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"请输入正确的手机号" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
        return;
    }
    if (self.edtPassText.text.length<6) {
        [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"请输入正确的密码" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
        return;
    }
    HUDNoStop1(@"正在登录...")
    NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:self.edtUserName.text,@"Tel",self.edtPassText.text,@"PassWord", @"webApi", @"LoginTerminal",nil];
    [SSNetworkRequest postRequest:[apiCheckLogin stringByAppendingString:[self getParamStr]] params:info success:^(id resonseObj){
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
                
//                NSString *alias = [NSString stringWithFormat:@"aixiaoqi%@", userData[@"Tel"]];
                //更新别名为token
                NSString *alias = [NSString stringWithFormat:@"aixiaoqi%@", userData[@"Token"]];
                [JPUSHService setTags:nil alias:alias fetchCompletionHandle:^(int iResCode, NSSet *iTags, NSString *iAlias) {
                    NSLog(@"极光别名：irescode = %d\n itags = %@\n ialias = %@", iResCode, iTags, iAlias);
                }];
                NSLog(@"拿到数据：%@",resonseObj);
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                if (storyboard) {
                    UIViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
                    if (mainViewController) {
                        [self presentViewController:mainViewController animated:YES completion:nil];
                    }
                }
                //                [[UITabBar appearance] setBackgroundImage:<#(UIImage * _Nullable)#>:[UIColor blueColor]];
            }else{
                if (resonseObj[@"msg"]) {
                    [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[resonseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
                }else{
                    HUDNormal(@"登录失败")
                }
//                HUDNormal(resonseObj[@"msg"])
            }
        }else{
            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"服务器好像有点忙，请稍后重试" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
        }
    }failure:^(id dataObj, NSError *error) {
        NSLog(@"登录失败：%@",[error description]);
//        [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"服务器可能罢工中，请稍后重试" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
        HUDNormal(@"网络连接失败")
//        HUDNormal([error description])
    } headers:nil];
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
