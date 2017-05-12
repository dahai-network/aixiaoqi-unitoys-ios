//
//  VerificationPhoneController.m
//  unitoys
//
//  Created by 黄磊 on 2017/5/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "VerificationPhoneController.h"
#import "UNPushKitMessageManager.h"
#import "NSString+Addition.h"
#import "UNDataTools.h"

@interface VerificationPhoneController ()
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@end

@implementation VerificationPhoneController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"viewWillAppear--VerificationPhoneController");
    [UNDataTools sharedInstance].isShowVerificationVc = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSLog(@"viewDidDisappear--VerificationPhoneController");
    [UNDataTools sharedInstance].isShowVerificationVc = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"手机号验证";
    self.navigationController.navigationBar.barTintColor = DefultColor;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    self.navigationController.navigationBar.translucent = NO;
    self.phoneTextField.leftViewMode = UITextFieldViewModeAlways;
    self.phoneTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, self.phoneTextField.un_height)];
//    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_close"] style:UIBarButtonItemStyleDone target:self action:@selector(dismissVc)];
}

- (void)dismissVc
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)verificationAction:(UIButton *)sender {
    sender.enabled = NO;
    //验证
    if ([self verificationPhone:self.phoneTextField.text]) {
        //发送验证请求
    }
    sender.enabled = YES;
}

- (BOOL)verificationPhone:(NSString *)phone
{
    //验证号码
    if (![phone isValidateMobile]) {
        kWeakSelf
        [self showAlertView:INTERNATIONALSTRING(@"您输入的号码格式不正确") cancelAction:^{
            weakSelf.phoneTextField.text = nil;
        }];
        return NO;
    }
    return YES;
}

- (void)showAlertView:(NSString *)title cancelAction:(void(^)())cancel
{
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (cancel) {
            cancel();
        }
    }];
    [alertVc addAction:cancelAction];
    [self presentViewController:alertVc animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

@end
