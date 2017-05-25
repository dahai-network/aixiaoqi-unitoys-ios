//
//  UNLoginViewController.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/18.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNLoginViewController.h"
#import "JPUSHService.h"
#import "UIImage+Extension.h"
#import <pop/pop.h>
#import "AddTouchAreaButton.h"
#import "UNDatabaseTools.h"
#import <sys/utsname.h>
#import "CutomButton.h"
#import "AgreementViewController.h"
#import "UNDataTools.h"
#import "UNPushKitMessageManager.h"

@interface UNLoginViewController ()<UITextFieldDelegate>
// 时间计数
@property (nonatomic, assign) NSInteger secondsCountDown;

@property (nonatomic, strong) NSTimer *time;

@property (nonatomic, weak) UILabel *currentLabel;
@end

@implementation UNLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.readButton.touchEdgeInset = UIEdgeInsetsMake(15, 15, 15, 15);
    self.agreementButton.touchEdgeInset = UIEdgeInsetsMake(10, 10, 10, 10);
    [self.forgetPwdBtn setColor:UIColorFromRGB(0x00A0E9)];
    if (kScreenHeightValue < 667) {
        //iphone6以下
        self.forgetBottomMargin.constant = Y(25);
        self.registerBottomMargin.constant = Y(30);
        self.middleCenterY.constant = Y(-35);
        self.iconBottomMargin.constant = Y(20);
    }
    [self setUpInitialize];
    
}

//初始化
- (void)setUpInitialize
{
    [self.loginButton setBackgroundColor:UIColorFromRGB(0x00A0E9)];
    self.loginButton.layer.cornerRadius = self.loginButton.un_height * 0.5;
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.registerbtn setBackgroundColor:[UIColor whiteColor]];
    [self.registerbtn setTitleColor:UIColorFromRGB(0x00A0E9) forState:UIControlStateNormal];
    self.registerbtn.layer.cornerRadius = self.registerbtn.un_height * 0.5;
    self.registerbtn.layer.borderWidth = 0.5;
    self.registerbtn.layer.borderColor = UIColorFromRGB(0x00A0E9).CGColor;
    
    self.reCaptchaField.placeholder = @"请输入你的验证码";
    self.middleViewHeight.constant = 172;
    
    self.currentStatuType = LoginVCStatuTypeLogin;
    
    
    [self offsetLeftTextField:_accountField];
    [self offsetLeftTextField:_passWordField];
    [self offsetLeftTextField:_reCaptchaField];
    
    //清除按钮
//    [self setClearButtonTextField:_accountField];
    
    
    NSString *userName;
    NSString *password;
    if (userName){
        _accountField.text = userName;
        _passWordField.text = password;
    }
    _accountField.delegate = self;
    _passWordField.delegate = self;
    _reCaptchaField.delegate = self;
    
    _reCaptchaView.layer.anchorPoint = CGPointMake(0.5, 0);
    
    //增加立体效果
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -3/1000.0;
    _reCaptchaView.layer.transform = transform;
    
    [self.readButton addTarget:self action:@selector(readButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.agreementButton addTarget:self action:@selector(agreementButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.accountField.text = [userDefaults objectForKey:@"KEY_USER_NAME"];
    self.passWordField.text = [userDefaults objectForKey:@"KEY_PASS_WORD"];
}

//- (NSAttributedString *)getUnderlineAttributeString:(NSString *)string
//{
//    NSMutableAttributedString *attriStr = [[NSMutableAttributedString alloc] initWithString:string];
//    NSRange strRange = {0,[attriStr length]};
//    [attriStr addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:strRange];
//    return attriStr;
//}

- (void)readButtonAction:(UIButton *)button
{
    button.selected = !button.isSelected;
}

- (void)agreementButtonAction:(UIButton *)button
{
    button.enabled = NO;
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Setting" bundle:nil];
    AgreementViewController *agreementViewController = [mainStory instantiateViewControllerWithIdentifier:@"agreementViewController"];
    agreementViewController.lastControllerName = @"UNLoginViewController";
    if (agreementViewController) {
//        [self.navigationController pushViewController:agreementViewController animated:YES];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:agreementViewController];
        [self presentViewController:nav animated:YES completion:nil];
    }
    button.enabled = YES;
}


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}


//自定义clearButton
- (void)setClearButtonTextField:(UITextField *)textField
{
    UIButton *clearButton = [textField valueForKey:@"_clearButton"];
    [clearButton setImage:[UIImage imageNamed:@"ic_close"] forState:UIControlStateNormal];
    [clearButton setImage:[UIImage imageNamed:@"ic_close"] forState:UIControlStateHighlighted];
}

//获取验证码
- (IBAction)getCaptcha:(UIButton *)sender {
    if (self.accountField.text.length<10) {
        [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(@"请输入手机号") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
        return;
    }
    
    NSDictionary *params;
    NSString *hintInfo;
    if (self.currentStatuType == LoginVCStatuTypeForgetPwd) {
        params = [[NSDictionary alloc] initWithObjectsAndKeys:self.accountField.text,@"ToNum",[NSNumber numberWithInt:2],@"Type", nil];
        hintInfo = INTERNATIONALSTRING(@"已发送验证码，请查看并输入完成密码找回");
    } else {
        params = [[NSDictionary alloc] initWithObjectsAndKeys:self.accountField.text,@"ToNum",[NSNumber numberWithInt:1],@"Type", nil];
        hintInfo = INTERNATIONALSTRING(@"已发送验证码，请查看并输入完整注册信息");
    }
    [self.reCaptchaField becomeFirstResponder];
    kWeakSelf
    [SSNetworkRequest postRequest:[apiSendSMS stringByAppendingString:[self getParamStr]] params:params success:^(id resonseObj){
        if ([[resonseObj objectForKey:@"status"] intValue]==1) {
            [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:hintInfo delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
            [weakSelf startTimer];
        }else{
            [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:[resonseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
        }
        
    }failure:^(id dataObj, NSError *error) {
        NSLog(@"数据:%@ 错误:%@",dataObj,[error description]);
        NSLog(@"登录异常");
    } headers:nil];
}

//确定(登陆/注册)
- (IBAction)confirmLogin:(UIButton *)sender {
    if ([self validateParams] == NO) return ;
    //根据当前选择登陆或注册进行下一步
    NSLog(@"登录");
    [self loginRequest];
}

//注册
- (IBAction)registerClick:(UIButton *)sender{
    [self.view endEditing:YES];
    if (self.currentStatuType == LoginVCStatuTypeLogin) {
        //当前为登录界面,跳转到注册界面
        [self clearInputDataWithType:LoginVCStatuTypeRegister];
    }else if (self.currentStatuType == LoginVCStatuTypeRegister){
        if ([self validateParams] == NO) return ;
        //当前为注册界面,进行注册
        [self registerRrequest];
    }else{
        //当前为忘记密码界面,重置密码
        if ([self validateParams] == NO) return ;
        [self forgetRrequest];
    }
    self.topLineView.hidden = NO;
}

- (void)startAnimation{

    [_middleViewHeight pop_removeAllAnimations];
    [_reCaptchaView.layer pop_removeAllAnimations];
    [self.middleViewHeight pop_removeAllAnimations];
    
    POPBasicAnimation *rotationAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerRotationX];
    rotationAnimation.duration = 0.7;
    rotationAnimation.toValue = @(0);
    [_reCaptchaView.layer pop_addAnimation:rotationAnimation forKey:@"startRotationAnimation"];
    
    POPBasicAnimation *registerAnima = [POPBasicAnimation animationWithPropertyNamed:kPOPLayoutConstraintConstant];
    registerAnima.duration = 0.7;
    registerAnima.toValue = @(258);
    [self.middleViewHeight pop_addAnimation:registerAnima forKey:@"registerAnima"];
}

- (void)endAnimation{
    
    [_middleViewHeight pop_removeAllAnimations];
    [_reCaptchaView.layer pop_removeAllAnimations];
    [self.middleViewHeight pop_removeAllAnimations];
    
    POPBasicAnimation *rotationAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerRotationX];
    rotationAnimation.duration = 0.7;
    rotationAnimation.toValue = @(M_PI*(-90)/180);
    [_reCaptchaView.layer pop_addAnimation:rotationAnimation forKey:@"endRotationAnimation"];
    //约束动画
    POPBasicAnimation *loginAnima = [POPBasicAnimation animationWithPropertyNamed:kPOPLayoutConstraintConstant];
    loginAnima.duration = 0.7;
    loginAnima.toValue = @(172);
    [self.middleViewHeight pop_addAnimation:loginAnima forKey:@"loginAnima"];
}

//忘记密码
- (IBAction)forgetPwdClick:(UIButton *)sender {
    [self.view endEditing:YES];
    sender.enabled = NO;
    if (self.currentStatuType == LoginVCStatuTypeLogin) {
        //跳转到忘记密码界面
        [self clearInputDataWithType:LoginVCStatuTypeForgetPwd];
    }else{
        //跳转到登录界面
        [self resetCaptchButton];
        [self clearInputDataWithType:LoginVCStatuTypeLogin];
    }
    sender.enabled = YES;
}

- (void)clearInputDataWithType:(LoginVCStatuType)type
{
    _accountField.text = nil;
    _passWordField.text = nil;
    _reCaptchaField.text = nil;
    self.tipLabel.hidden = YES;
    self.pwdTipLabel.hidden = YES;
    self.reCaptchaTipLabel.hidden = YES;
    if (type == LoginVCStatuTypeRegister) {
        //展开折叠动画
        [self startAnimation];
        
        [self updateTextFieldPlaceholder:YES];
        self.passWordField.placeholder = @"请输入你的6-12为密码";
        self.agreementView.hidden = NO;
        self.loginButton.hidden = YES;

        [self.registerbtn setTitle:@"注册" forState:UIControlStateNormal];
        [self.registerbtn setBackgroundColor:UIColorFromRGB(0x00A0E9)];
        [self.registerbtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.forgetPwdBtn setTitle:@"有账号,直接登录" forState:UIControlStateNormal];
    }else if (type == LoginVCStatuTypeLogin){
        //收缩折叠动画
        [self endAnimation];
        [self updateTextFieldPlaceholder:NO];
        self.passWordField.placeholder = @"请输入你的账号密码";
        self.agreementView.hidden = YES;
        self.loginButton.hidden = NO;

        [self.registerbtn setTitle:@"注册" forState:UIControlStateNormal];
        [self.registerbtn setBackgroundColor:[UIColor whiteColor]];
        [self.registerbtn setTitleColor:UIColorFromRGB(0x00A0E9) forState:UIControlStateNormal];
        [self.forgetPwdBtn setTitle:@"忘记密码,马上找回" forState:UIControlStateNormal];
        self.readButton.selected = NO;
        
    }else{
        //展开折叠动画
        [self startAnimation];
        
        [self updateTextFieldPlaceholder:YES];
        self.passWordField.placeholder = @"请输入你的6-12为密码";
        self.agreementView.hidden = YES;
        self.loginButton.hidden = YES;

        [self.registerbtn setTitle:@"确定" forState:UIControlStateNormal];
        [self.registerbtn setBackgroundColor:UIColorFromRGB(0x00A0E9)];
        [self.registerbtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.forgetPwdBtn setTitle:@"有账号,直接登录" forState:UIControlStateNormal];
    }
    self.currentStatuType = type;
}

- (void)updateTextFieldPlaceholder:(BOOL)isLeft
{
    if (isLeft) {
        self.accountField.textAlignment = NSTextAlignmentLeft;
        self.passWordField.textAlignment = NSTextAlignmentLeft;
        self.tipLabel.textAlignment = NSTextAlignmentLeft;
        self.pwdTipLabel.textAlignment = NSTextAlignmentLeft;
    }else{
        self.accountField.textAlignment = NSTextAlignmentCenter;
        self.passWordField.textAlignment = NSTextAlignmentCenter;
        self.tipLabel.textAlignment = NSTextAlignmentCenter;
        self.pwdTipLabel.textAlignment = NSTextAlignmentCenter;
    }
}

//设置导航栏透明
//-(void)viewWillAppear:(BOOL)animated{
//    [super viewWillAppear:animated];
//    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
//    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
//}
//-(void)viewWillDisappear:(BOOL)animated{
//    [super viewWillDisappear:animated];
//    [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
//    [self.navigationController.navigationBar setShadowImage:nil];
//}

//设置占位文字位置
- (void)offsetLeftTextField:(UITextField *)tf
{
    UIView *leftV   = [UIView new];
    leftV.frame     = CGRectMake(0, 0, 11, 11);
    tf.leftView     = leftV;
    tf.rightView    = leftV;
    tf.leftViewMode = UITextFieldViewModeAlways;
    tf.rightViewMode = UITextFieldViewModeAlways;
}

//判断格式是否正确
- (BOOL)validateParams
{
    [self.view endEditing:YES];
    if (_accountField.text.length > 0 == NO) {
        [self showAlertViewWithMessage:@"手机号不能为空!"];
        return NO;
    }
    if (!(_accountField.text.length == 11)) {
        [self showAlertViewWithMessage:@"请输入正确的手机号!"];
        return NO;
    }
    if (self.currentStatuType != LoginVCStatuTypeLogin) {
        if (_reCaptchaField.text.length > 0 == NO) {
            [self showAlertViewWithMessage:@"请输入验证码!"];
            return NO;
        }
    }
    if (_passWordField.text.length < 6) {
        [self showAlertViewWithMessage:@"密码最少为6位"];
        return NO;
    }
    return YES;
}

#pragma mark ---登录请求
//登陆请求
- (void)loginRequest
{
    NSLog(@"登录");
    HUDNoStop1(INTERNATIONALSTRING(@"正在登录..."))
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    NSString *phoneModel = [self iphoneType];
    NSString *phoneNameAndSystem = [NSString stringWithFormat:@"%@,%@", phoneModel, systemVersion];
    NSLog(@"登录的设备是 --> %@", phoneNameAndSystem);
    NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:self.accountField.text,@"Tel",self.passWordField.text,@"PassWord", phoneNameAndSystem, @"LoginTerminal",nil];
    kWeakSelf
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
                [userDefaults setObject:self.accountField.text forKey:@"KEY_USER_NAME"];
                [userDefaults setObject:self.passWordField.text forKey:@"KEY_PASS_WORD"];
                [userDefaults synchronize];
                NSLog(@"登录成功之后时候的token - %@", userData[@"Token"]);
                [UNPushKitMessageManager shareManager].iccidString = nil;
                //从服务器获取黑名单列表
                [weakSelf getBlackListsFromServer];
                //                NSString *alias = [NSString stringWithFormat:@"aixiaoqi%@", userData[@"Tel"]];
                //更新别名为token
                NSString *alias = [NSString stringWithFormat:@"aixiaoqi%@", userData[@"Token"]];
                [JPUSHService setTags:nil alias:alias fetchCompletionHandle:^(int iResCode, NSSet *iTags, NSString *iAlias) {
                    NSLog(@"极光别名：irescode = %d\n itags = %@\n ialias = %@", iResCode, iTags, iAlias);
                }];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"loginSuccessAndCreatTcpNotif" object:@"loginSuccessAndCreatTcpNotif"];
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                if (storyboard) {
                    UIViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
                    if (mainViewController) {
                        [weakSelf presentViewController:mainViewController animated:YES completion:^{
                            [weakSelf resetCaptchButton];
                            [weakSelf clearInputDataWithType:LoginVCStatuTypeLogin];
                        }];
                    }
                }
            }else{
                if (resonseObj[@"msg"]) {
                    [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:[resonseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
                }else{
                    HUDNormal(INTERNATIONALSTRING(@"登录失败"))
                }
            }
        }else{
            [self showAlertViewWithMessage:@"服务器好像有点忙，请稍后重试"];
        }
    }failure:^(id dataObj, NSError *error) {
        NSLog(@"登录失败：%@",[error description]);
        HUDNormal(INTERNATIONALSTRING(@"网络连接失败"))
    } headers:nil];
}

- (void)showAlertViewWithMessage:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(message) delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
}

- (void)getBlackListsFromServer
{
    if (![[UNDatabaseTools sharedFMDBTools] deleteAllBlackLists]) {
        NSLog(@"清空黑名单失败");
    }
    kWeakSelf
    //从服务器获取黑名单
    self.checkToken = YES;
    [self getBasicHeader];
    [SSNetworkRequest getRequest:apiBlackListGet params:nil success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            [weakSelf addBlackLists:responseObj[@"data"]];
            [UNDataTools sharedInstance].blackLists = nil;
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
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


#pragma mark ---重置密码请求
//重置密码请求
- (void)forgetRrequest
{
    //注册成功后跳转到登录界面,重置状态
    NSLog(@"重置密码");
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.accountField.text,@"Tel",self.passWordField.text,@"newPassWord", self.reCaptchaField.text,@"smsVerCode", nil];
    [SSNetworkRequest postRequest:[apiForgetPassword stringByAppendingString:[self getParamStr]] params:params success:^(id resonseObj){
        if ([[resonseObj objectForKey:@"status"] intValue]==1) {
            [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(@"密码找回成功") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
//            [self dismissViewControllerAnimated:YES completion:nil];
            //跳转到登录界面
            [self resetCaptchButton];
            [self clearInputDataWithType:LoginVCStatuTypeLogin];
            self.accountField.text = params[@"Tel"];
        }else{
            [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:[NSString stringWithFormat:@"%@：%@", INTERNATIONALSTRING(@"密码找回失败"),[resonseObj objectForKey:@"msg"]] delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
        }
    }failure:^(id dataObj, NSError *error) {
        NSLog(@"数据:%@ 错误:%@",dataObj,[error description]);
        NSLog(@"登录异常");
    } headers:nil];
}

#pragma mark ---注册账号请求
//注册账号请求
- (void)registerRrequest
{
    [self.view endEditing:YES];
    //注册成功后跳转到登录界面,重置状态
    NSLog(@"注册");
    if (!self.readButton.isSelected) {
        [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(@"请先阅读并同意用户许可") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
        return;
    }
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.accountField.text,@"Tel",self.passWordField.text,@"PassWord", self.reCaptchaField.text,@"smsVerCode", nil];
    
    [SSNetworkRequest postRequest:[apiRegisterUser stringByAppendingString:[self getParamStr]] params:params success:^(id resonseObj){
        if ([[resonseObj objectForKey:@"status"] intValue]==1) {
            //注册成功之后登录
            [self registerSuccessAndLogin];
        }else{
            [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:[NSString stringWithFormat:@"%@：%@", INTERNATIONALSTRING(@"用户注册失败"),[resonseObj objectForKey:@"msg"]] delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
        }
        
    }failure:^(id dataObj, NSError *error) {
        NSLog(@"数据:%@ 错误:%@",dataObj,[error description]);
        NSLog(@"登录异常");
        
    } headers:nil];

}
#pragma mark 注册成功之后后台登录
- (void)registerSuccessAndLogin {
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.accountField.text,@"Tel",self.passWordField.text,@"PassWord", @"webApi", @"LoginTerminal",nil];
    kWeakSelf
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
                [[NSNotificationCenter defaultCenter] postNotificationName:@"loginSuccessAndCreatTcpNotif" object:@"loginSuccessAndCreatTcpNotif"];
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                if (storyboard) {
                    UIViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
                    if (mainViewController) {
                        [weakSelf presentViewController:mainViewController animated:YES completion:^{
                            [weakSelf resetCaptchButton];
                            [weakSelf clearInputDataWithType:LoginVCStatuTypeLogin];
                        }];
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
        
    } headers:nil];
}



#pragma mark ---验证码部分
- (void)startTimer {
    self.secondsCountDown = 60;
    self.getCaptchaBtn.enabled = NO;
    [self.getCaptchaBtn setTitle:[NSString stringWithFormat:@"%ld 秒后重发",self.secondsCountDown] forState:UIControlStateNormal];
    [self.getCaptchaBtn setBackgroundImage:[UIImage imageNamed:@"btn_yzm_pre"] forState:UIControlStateNormal];
    [self.getCaptchaBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    if (!self.time) {
        self.time = [NSTimer scheduledTimerWithTimeInterval:1.00
                                                     target:self
                                                   selector:@selector(poolTimer)
                                                   userInfo:nil
                                                    repeats:YES];
    }
}
- (void)poolTimer
{
    self.secondsCountDown --;
    if (self.secondsCountDown <= 0) {
        [self resetCaptchButton];
        return;
    }else{
        [self.getCaptchaBtn setTitle:[NSString stringWithFormat:@"%ld 秒后重发",self.secondsCountDown] forState:UIControlStateNormal];
    }
}

//重置验证按钮
- (void)resetCaptchButton
{
    if (self.time) {
        [self.time invalidate];
        self.time = nil;
    }
    self.secondsCountDown = 0;
    [self.getCaptchaBtn setTitle:@"发送验证码" forState:UIControlStateNormal];
    [self.getCaptchaBtn setBackgroundImage:[UIImage imageNamed:@"btn_yzm_nor"] forState:UIControlStateNormal];
    [self.getCaptchaBtn setTitleColor:UIColorFromRGB(0x00A0E9) forState:UIControlStateNormal];
    self.getCaptchaBtn.enabled = YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

#pragma mark ---UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self updateTipAndFrame:textField];
}

//更新提示和frame
- (void)updateTipAndFrame:(UITextField *)textField
{
    CGFloat offsetY = 0;
    if (self.currentStatuType == LoginVCStatuTypeLogin) {
        if (textField == self.accountField) {
            [self updateTipLabelShow:self.tipLabel];
            self.currentLabel.text = @"登录账号";
        }else{
            [self updateTipLabelShow:self.pwdTipLabel];
            self.currentLabel.text = @"登录密码";
            offsetY = - 80;
        }
    }else if (self.currentStatuType == LoginVCStatuTypeRegister){
        if (textField == self.accountField) {
            [self updateTipLabelShow:self.tipLabel];
            self.currentLabel.text = @"注册账号";
        }else if (textField == self.reCaptchaField){
            [self updateTipLabelShow:self.reCaptchaTipLabel];
            offsetY = - 80;
        }else{
            [self updateTipLabelShow:self.pwdTipLabel];
            self.currentLabel.text = @"注册密码";
            offsetY = - 80;
        }
    }else{
        if (textField == self.accountField) {
            [self updateTipLabelShow:self.tipLabel];
            self.currentLabel.text = @"登录账号";
        }else if (textField == self.reCaptchaField){
            [self updateTipLabelShow:self.reCaptchaTipLabel];
            offsetY = - 80;
        }else{
            [self updateTipLabelShow:self.pwdTipLabel];
            self.currentLabel.text = @"登录密码";
            offsetY = - 80;
        }
    }
    if (offsetY) {
        [UIView animateWithDuration:0.3f animations:^{
            self.view.frame = CGRectMake(0.0f, offsetY, self.view.frame.size.width, self.view.frame.size.height);
        }];
    }
}

- (void)updateTipLabelShow:(UILabel *)label
{
    self.currentLabel = label;
    self.currentLabel.hidden = NO;
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (self.currentLabel) {
        self.currentLabel.hidden = YES;
    }else{
        self.tipLabel.hidden = YES;
        self.tipLabel.text = nil;
        self.reCaptchaTipLabel.hidden = YES;
        self.pwdTipLabel.hidden = YES;
        self.pwdTipLabel.text = nil;
    }
    [UIView animateWithDuration:0.3f animations:^{
        self.view.frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.view endEditing:YES];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.accountField) {
        if (range.location >= 11){
            return NO;
        }else{
            return YES;
        }
    }else if (textField == self.reCaptchaField) {
        if (range.location >= 4){
            return NO;
        }else{
            return YES;
        }
    }else if (textField == self.passWordField){
        if (range.location >= 12) {
            return NO;
        }else{
            return YES;
        }
    }
    return YES;
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


- (void)dealloc
{
    if (self.time) {
        [self.time invalidate];
        self.time = nil;
    }
}

#pragma mark ---废弃方法
/*
//设置圆角
- (void)setCornerRadiusWithUIView:(UIView *)view byRoundingCorners:(UIRectCorner)corners cornerRadii:(CGSize)cornerRadii
{
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:view.bounds byRoundingCorners:corners cornerRadii:cornerRadii];

    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = view.bounds;
    maskLayer.path = maskPath.CGPath;
    view.layer.mask = maskLayer;
}
 
//验证码从右弹出动画
- (void)loginPopAnimation
{
    //    [self.reCapRightMargin pop_removeAnimationForKey:@"constantSpringAni"];
    POPBasicAnimation *constantBasicAni = [POPBasicAnimation animationWithPropertyNamed:kPOPLayoutConstraintConstant];
    constantBasicAni.fromValue = @(56);
    constantBasicAni.toValue = @(-[UIScreen mainScreen].bounds.size.width);
    //    [self.reCapRightMargin pop_addAnimation:constantBasicAni forKey:@"constantBasicAni"];
}

- (void)registerPopAnimation
{
    //    [self.reCapRightMargin pop_removeAnimationForKey:@"constantBasicAni"];
    POPSpringAnimation *constantSpringAni = [POPSpringAnimation animationWithPropertyNamed:kPOPLayoutConstraintConstant];
    constantSpringAni.fromValue = @(-[UIScreen mainScreen].bounds.size.width);
    constantSpringAni.springBounciness = 65;
    constantSpringAni.toValue = @(56);
    //    [self.reCapRightMargin pop_addAnimation:constantSpringAni forKey:@"constantSpringAni"];
}

*/

@end
