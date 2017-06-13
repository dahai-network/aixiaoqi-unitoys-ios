//
//  RegisterViewController.m
//  unitoys
//
//  Created by sumars on 16/9/17.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "RegisterViewController.h"
#import "AgreementViewController.h"
#import <sys/utsname.h>

@implementation RegisterViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
//    //左边按钮
//    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithImage:[[UIImage imageNamed:@"btn_back"] imageWithRenderingMode:/*去除渲染效果*/UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonAction)];
    
    self.btnSendVerifyCode.layer.masksToBounds = YES;
    self.btnSendVerifyCode.layer.cornerRadius = 3;
    self.btnSendVerifyCode.layer.borderWidth = 1;
    self.btnSendVerifyCode.layer.borderColor = [UIColor blackColor].CGColor;
    
    NSString *userMode = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserMode"];
    
    if ([userMode isEqualToString:@"ForgetMode"]) {
        self.bForgetMode = YES;
        
        self.btnAgreement.hidden = YES;
        self.btnLicense.hidden = YES;
        [self.btnAction setTitle:INTERNATIONALSTRING(@"确定") forState:UIControlStateNormal];
        
        self.title = INTERNATIONALSTRING(@"找回密码");
        
    }
    
    
    
    _bSecure = YES;
    _bAggre = YES;
    
    UIImageView *ivPhoneNumber = [[UIImageView alloc] initWithImage:[UIImage imageNamed: @"reg_phonenumber"]];
    [ivPhoneNumber setFrame:CGRectMake(0, 0, 25, 30)];
    ivPhoneNumber.contentMode = UIViewContentModeCenter;
    self.edtPhoneNumber.leftView = ivPhoneNumber;
    self.edtPhoneNumber.leftViewMode = UITextFieldViewModeAlways;
    
    UIImageView *ivVerifyCode = [[UIImageView alloc] initWithImage:[UIImage imageNamed: @"reg_verifycode"]];
    [ivVerifyCode setFrame:CGRectMake(0, 0, 25, 30)];
    ivVerifyCode.contentMode = UIViewContentModeCenter;
    self.edtVerifyCode.leftView = ivVerifyCode;
    self.edtVerifyCode.leftViewMode = UITextFieldViewModeAlways;
    
    
    UIImageView *ivPassCode = [[UIImageView alloc] initWithImage:[UIImage imageNamed: @"reg_password"]];
    [ivPassCode setFrame:CGRectMake(0, 0, 25, 30)];
    ivPassCode.contentMode = UIViewContentModeCenter;
    self.edtPassCode.leftView = ivPassCode;
    self.edtPassCode.leftViewMode = UITextFieldViewModeAlways;
    
    _edtPhoneNumber.bDrawBorder = YES;
    _edtVerifyCode.bDrawBorder = YES;
    _edtPassCode.bDrawBorder = YES;
    
    _edtPhoneNumber.delegate = self;
    _edtVerifyCode.delegate = self;
    _edtPassCode.delegate =self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)leftButtonAction {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle

{
    
    return UIStatusBarStyleLightContent;
    
}


//#pragma -mark UITextField Delegate
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
    if (textField == self.edtPhoneNumber) {
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

- (IBAction)switchHidden:(id)sender {
    _bSecure = !_bSecure;
    _edtPassCode.secureTextEntry = _bSecure;
    
    if (_bSecure) {
        [_btnShowWords setImage:[UIImage imageNamed:@"reg_hidewords"] forState:UIControlStateNormal];
    }else{
        [_btnShowWords setImage:[UIImage imageNamed:@"reg_showwords"] forState:UIControlStateNormal];
    }
    
}

- (IBAction)sendVerifyCode:(id)sender {
    if (self.edtPhoneNumber.text.length<10) {
        [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(@"请输入手机号") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
        return;
    }
    
    NSDictionary *params;
    
    if (self.bForgetMode) {
        params = [[NSDictionary alloc] initWithObjectsAndKeys:self.edtPhoneNumber.text,@"ToNum",[NSNumber numberWithInt:2],@"Type", nil];
    } else {
        params = [[NSDictionary alloc] initWithObjectsAndKeys:self.edtPhoneNumber.text,@"ToNum",[NSNumber numberWithInt:1],@"Type", nil];
    }
    
    NSString *hintInfo;
    
    NSString *userMode = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserMode"];

    if ([userMode isEqualToString:@"ForgetMode"]) {
        hintInfo = INTERNATIONALSTRING(@"已发送验证码，请查看并输入完成密码找回");
    }else{
        hintInfo = INTERNATIONALSTRING(@"已发送验证码，请查看并输入完整注册信息");
    }
    
    [self getBasicHeader];
    [SSNetworkRequest postRequest:apiSendSMS params:params success:^(id resonseObj){
        if ([[resonseObj objectForKey:@"status"] intValue]==1) {
            [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:hintInfo delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
            
            [self.edtVerifyCode becomeFirstResponder];
            self.hintTime = 60;
            self.btnSendVerifyCode.enabled = false;
            self.hintTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(hintTimeOut) userInfo:nil repeats:YES];
            [self.btnSendVerifyCode setTitle:[NSString stringWithFormat:@"(%d)",self.hintTime] forState:UIControlStateNormal];
            [self.btnSendVerifyCode setTintColor:[UIColor grayColor]];
            [self.hintTimer fire];
            
        }else{
            [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:[resonseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
        }
        
    }failure:^(id dataObj, NSError *error) {
        NSLog(@"数据:%@ 错误:%@",dataObj,[error description]);
        NSLog(@"登录异常");
        
    } headers:self.headers];
}

- (void)hintTimeOut {
    self.hintTime = self.hintTime-1;
    
    if (self.hintTime==0) {
        self.btnSendVerifyCode.enabled = YES;
        [self.btnSendVerifyCode setTitle:INTERNATIONALSTRING(@"重新发送") forState:UIControlStateNormal];
        
        [self.btnSendVerifyCode setTintColor:[UIColor blueColor]];
        
        [self.hintTimer invalidate];
        NSLog(@"就这么断了？");
    }else
      [self.btnSendVerifyCode setTitle:[NSString stringWithFormat:@"%@（%d）",INTERNATIONALSTRING(@"重新发送") ,self.hintTime] forState:UIControlStateNormal];
}

- (IBAction)registerUser:(id)sender {
    
    if (!_bAggre) {
        [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(@"请先阅读并同意用户许可") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
        return;
    }
    
    if (self.edtVerifyCode.text.length!=4) {
        [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(@"请输入正确的验证码") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
        return;
    }
    
    
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.edtPhoneNumber.text,@"Tel",self.edtPassCode.text,@"PassWord", self.edtVerifyCode.text,@"smsVerCode", nil];
    
    [self getBasicHeader];
    [SSNetworkRequest postRequest:apiRegisterUser params:params success:^(id resonseObj){
        if ([[resonseObj objectForKey:@"status"] intValue]==1) {
//            [[[UIAlertView alloc] initWithTitle:@"注册提示" message:@"用户注册成功" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
//            [self dismissViewControllerAnimated:YES completion:nil];
            //注册成功之后登录
            [self registerSuccessAndLogin];
        }else{
            [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:[NSString stringWithFormat:@"%@：%@", INTERNATIONALSTRING(@"用户注册失败"),[resonseObj objectForKey:@"msg"]] delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
        }
        
    }failure:^(id dataObj, NSError *error) {
        NSLog(@"数据:%@ 错误:%@",dataObj,[error description]);
        NSLog(@"登录异常");
        
    } headers:self.headers];
}

#pragma mark 注册成功之后后台登录
- (void)registerSuccessAndLogin {
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    NSString *phoneModel = [self iphoneType];
    NSString *phoneNameAndSystem = [NSString stringWithFormat:@"%@,%@", phoneModel, systemVersion];
    NSLog(@"登录的设备是 --> %@", phoneNameAndSystem);
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.edtPhoneNumber.text,@"Tel",self.edtPassCode.text,@"PassWord", phoneNameAndSystem, @"LoginTerminal",nil];
    
    [self getBasicHeader];
    [SSNetworkRequest postRequest:apiCheckLogin params:params success:^(id resonseObj){
        NSMutableDictionary *userData = [[NSMutableDictionary alloc] initWithDictionary:[resonseObj objectForKey:@"data"]];
        
        if (resonseObj) {
            if ([[resonseObj objectForKey:@"status"] intValue]==1) {
                if ([NSNull null]== (NSNull *)[userData objectForKey:@"TrueName"]) {
                    [userData setObject:@"" forKey:@"TrueName"];
                }
                
                if ([NSNull null]== (NSNull *)[userData objectForKey:@"Email"]) {
                    [userData setObject:@"" forKey:@"Email"];
                }
                
                [[NSUserDefaults standardUserDefaults] setObject:userData forKey:@"userData"];
//                NSLog(@"拿到数据：%@",resonseObj);
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                if (storyboard) {
                    UIViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
                    if (mainViewController) {
                        [self presentViewController:mainViewController animated:YES completion:nil];
                    }
                }
                
            }else{
                [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:[resonseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
            }
        }else{
            [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(@"服务器好像有点忙，请稍后重试") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
        }
        
    }failure:^(id dataObj, NSError *error) {
        NSLog(@"登录失败：%@",[error description]);
        [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(@"服务器好像有点忙，请稍后重试") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
        
    } headers:self.headers];
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

- (IBAction)forgetPassword:(id)sender {
    
    if (self.edtVerifyCode.text.length!=4) {
        [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(@"请输入正确的验证码") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
        return;
    }
    
    
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.edtPhoneNumber.text,@"Tel",self.edtPassCode.text,@"newPassWord", self.edtVerifyCode.text,@"smsVerCode", nil];
    
    [self getBasicHeader];
    [SSNetworkRequest postRequest:apiForgetPassword params:params success:^(id resonseObj){
        if ([[resonseObj objectForKey:@"status"] intValue]==1) {
            [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(@"密码找回成功") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
            [self dismissViewControllerAnimated:YES completion:nil];
        }else{
            [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:[NSString stringWithFormat:@"%@：%@", INTERNATIONALSTRING(@"密码找回失败"),[resonseObj objectForKey:@"msg"]] delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
        }
        
    }failure:^(id dataObj, NSError *error) {
        NSLog(@"数据:%@ 错误:%@",dataObj,[error description]);
        NSLog(@"登录异常");
        
    } headers:self.headers];
}

- (IBAction)doAction:(id)sender {
    
    if (self.bForgetMode) {
        [self forgetPassword:sender];
    }else{
        [self registerUser:sender];
    }
}

- (IBAction)switchAgreement:(id)sender {
    _bAggre = !_bAggre;
    
    
    if (_bAggre) {
        [_btnAgreement setImage:[UIImage imageNamed:@"reg_checked"] forState:UIControlStateNormal];
    }else{
        [_btnAgreement setImage:[UIImage imageNamed:@"reg_unchecked"] forState:UIControlStateNormal];
    }
}

- (IBAction)showAgreement:(id)sender {
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Setting" bundle:nil];
    UIViewController *agreementViewController = [mainStory instantiateViewControllerWithIdentifier:@"agreementViewController"];
    if (agreementViewController) {
        [self.navigationController pushViewController:agreementViewController animated:YES];
    }
}

- (IBAction)exit:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
