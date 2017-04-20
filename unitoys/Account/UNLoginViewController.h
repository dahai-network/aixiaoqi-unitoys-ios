//
//  UNLoginViewController.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/18.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BaseViewController.h"
@class AddTouchAreaButton;
@class CutomButton;

typedef NS_ENUM(NSUInteger, LoginVCStatuType) {
    LoginVCStatuTypeLogin = 0,  //登录
    LoginVCStatuTypeRegister = 1,   //注册
    LoginVCStatuTypeForgetPwd = 2,  //忘记密码
};
@interface UNLoginViewController : BaseViewController

//@property (strong, nonatomic) UIWindow *window;
//顶部提示label
@property (weak, nonatomic) IBOutlet UILabel *tipLabel;
@property (weak, nonatomic) IBOutlet UILabel *pwdTipLabel;
@property (weak, nonatomic) IBOutlet UILabel *reCaptchaTipLabel;


//是否阅读协议button
@property (weak, nonatomic) IBOutlet AddTouchAreaButton *readButton;
//协议button
@property (weak, nonatomic) IBOutlet AddTouchAreaButton *agreementButton;
//协议view
@property (weak, nonatomic) IBOutlet UIView *agreementView;

@property (weak, nonatomic) IBOutlet UIView *middleView;
//验证textField
@property (weak, nonatomic) IBOutlet UITextField *reCaptchaField;
//整个登陆view高度
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *middleViewHeight;

//@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (weak, nonatomic) IBOutlet UIButton *registerbtn;
@property (weak, nonatomic) IBOutlet UITextField *accountField;
@property (weak, nonatomic) IBOutlet UITextField *passWordField;
@property (weak, nonatomic) IBOutlet CutomButton *forgetPwdBtn;
//获取验证码
@property (weak, nonatomic) IBOutlet UIButton *getCaptchaBtn;
//@property (weak, nonatomic) IBOutlet UIView *captchaLineView;

//账号下方分割线
@property (weak, nonatomic) IBOutlet UIView *topLineView;
//确定
//@property (weak, nonatomic) IBOutlet UIButton *confirmLogin;
//登录
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@property (weak, nonatomic) IBOutlet UIView *reCaptchaView;

@property (nonatomic, assign) LoginVCStatuType currentStatuType;

//默认33
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *forgetBottomMargin;
//默认41
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *registerBottomMargin;
//默认-45
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *middleCenterY;
//默认60
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *iconBottomMargin;
//默认15
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tipBottomMargin;

@end
