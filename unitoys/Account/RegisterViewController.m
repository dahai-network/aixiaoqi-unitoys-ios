//
//  RegisterViewController.m
//  unitoys
//
//  Created by sumars on 16/9/17.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "RegisterViewController.h"
#import "AgreementViewController.h"

@implementation RegisterViewController


- (void)viewDidLoad {
    
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
        [self.btnAction setTitle:@"确定" forState:UIControlStateNormal];
        
        self.title = @"找回密码";
        
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
        [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"请输入手机号" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
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
        hintInfo = @"已发送验证码，请查看并输入完成密码找回";
    }else{
        hintInfo = @"已发送验证码，请查看并输入完整注册信息";
    }
    
    [SSNetworkRequest postRequest:[apiSendSMS stringByAppendingString:[self getParamStr]] params:params success:^(id resonseObj){
        if ([[resonseObj objectForKey:@"status"] intValue]==1) {
            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:hintInfo delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
            
            [self.edtVerifyCode becomeFirstResponder];
            self.hintTime = 60;
            self.btnSendVerifyCode.enabled = false;
            self.hintTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(hintTimeOut) userInfo:nil repeats:YES];
            [self.btnSendVerifyCode setTitle:[NSString stringWithFormat:@"(%d)",self.hintTime] forState:UIControlStateNormal];
            [self.btnSendVerifyCode setTintColor:[UIColor grayColor]];
            [self.hintTimer fire];
            
        }else{
            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[resonseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
        }
        
    }failure:^(id dataObj, NSError *error) {
        NSLog(@"数据:%@ 错误:%@",dataObj,[error description]);
        NSLog(@"登录异常");
        
    } headers:nil];
}

- (void)hintTimeOut {
    self.hintTime = self.hintTime-1;
    
    if (self.hintTime==0) {
        self.btnSendVerifyCode.enabled = YES;
        [self.btnSendVerifyCode setTitle:@"重新发送" forState:UIControlStateNormal];
        
        [self.btnSendVerifyCode setTintColor:[UIColor blueColor]];
        
        [self.hintTimer invalidate];
        NSLog(@"就这么断了？");
    }else
      [self.btnSendVerifyCode setTitle:[NSString stringWithFormat:@"重新发送（%d）",self.hintTime] forState:UIControlStateNormal];
}

- (IBAction)registerUser:(id)sender {
    
    if (!_bAggre) {
        [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"请先阅读并同意用户许可" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
        return;
    }
    
    if (self.edtVerifyCode.text.length!=4) {
        [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"请输入正确的验证码" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
        return;
    }
    
    
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.edtPhoneNumber.text,@"Tel",self.edtPassCode.text,@"PassWord", self.edtVerifyCode.text,@"smsVerCode", nil];
    
    [SSNetworkRequest postRequest:[apiRegisterUser stringByAppendingString:[self getParamStr]] params:params success:^(id resonseObj){
        if ([[resonseObj objectForKey:@"status"] intValue]==1) {
//            [[[UIAlertView alloc] initWithTitle:@"注册提示" message:@"用户注册成功" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
//            [self dismissViewControllerAnimated:YES completion:nil];
            //注册成功之后登录
            [self registerSuccessAndLogin];
        }else{
            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[NSString stringWithFormat:@"用户注册失败：%@",[resonseObj objectForKey:@"msg"]] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
        }
        
    }failure:^(id dataObj, NSError *error) {
        NSLog(@"数据:%@ 错误:%@",dataObj,[error description]);
        NSLog(@"登录异常");
        
    } headers:nil];
}

#pragma mark 注册成功之后后台登录
- (void)registerSuccessAndLogin {
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.edtPhoneNumber.text,@"Tel",self.edtPassCode.text,@"PassWord", @"webApi", @"LoginTerminal",nil];
    
    [SSNetworkRequest postRequest:[apiCheckLogin stringByAppendingString:[self getParamStr]] params:params success:^(id resonseObj){
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
                NSLog(@"拿到数据：%@",resonseObj);
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                if (storyboard) {
                    UIViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
                    if (mainViewController) {
                        [self presentViewController:mainViewController animated:YES completion:nil];
                    }
                }
                
            }else{
                [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[resonseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
            }
        }else{
            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"服务器好像有点忙，请稍后重试" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
        }
        
    }failure:^(id dataObj, NSError *error) {
        NSLog(@"登录失败：%@",[error description]);
        [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"服务器可能罢工中，请稍后重试" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
        
    } headers:nil];
}

- (IBAction)forgetPassword:(id)sender {
    
    if (self.edtVerifyCode.text.length!=4) {
        [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"请输入正确的验证码" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
        return;
    }
    
    
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.edtPhoneNumber.text,@"Tel",self.edtPassCode.text,@"newPassWord", self.edtVerifyCode.text,@"smsVerCode", nil];
    
    [SSNetworkRequest postRequest:[apiForgetPassword stringByAppendingString:[self getParamStr]] params:params success:^(id resonseObj){
        if ([[resonseObj objectForKey:@"status"] intValue]==1) {
            [[[UIAlertView alloc] initWithTitle:@"注册提示" message:@"密码找回成功" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
            [self dismissViewControllerAnimated:YES completion:nil];
        }else{
            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[NSString stringWithFormat:@"密码找回失败：%@",[resonseObj objectForKey:@"msg"]] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
        }
        
    }failure:^(id dataObj, NSError *error) {
        NSLog(@"数据:%@ 错误:%@",dataObj,[error description]);
        NSLog(@"登录异常");
        
    } headers:nil];
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
