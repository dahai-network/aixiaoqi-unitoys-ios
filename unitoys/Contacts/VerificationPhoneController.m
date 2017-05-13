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
#import "BlueToothDataManager.h"

#define VeriIntervalTime 3
#define VeriTotalTime 15

@interface VerificationPhoneController ()
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UIButton *veriButton;

@property (nonatomic, strong) NSTimer *veriTimer;
@property (nonatomic, assign) NSInteger veriTimeOut;
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
    self.veriButton.enabled = NO;
    //验证
    if ([self verificationPhone:self.phoneTextField.text]) {
        [self.veriButton endEditing:YES];
        //发送验证请求
        [self sendVeriRequest];
    }else{
        sender.enabled = YES;
    }
}

- (void)sendVeriRequest
{
    [BlueToothDataManager shareManager].isShowHud = YES;
    HUDNoStop1(INTERNATIONALSTRING(@"正在验证..."))
    self.checkToken = YES;
    [self getBasicHeader];
    self.veriIccidString = self.veriIccidString ? self.veriIccidString : @"";
    NSDictionary *params = @{@"Tel" : self.phoneTextField.text, @"ICCID" : self.veriIccidString};
    NSLog(@"当前验证号码%@", params);
    [SSNetworkRequest postRequest:apiUserDeviceTelConfirmed params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.veriTimer = [NSTimer scheduledTimerWithTimeInterval:VeriIntervalTime target:self selector:@selector(updateVeriTime) userInfo:nil repeats:YES];
                [self checkVeriResult];
            });
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [BlueToothDataManager shareManager].isShowHud = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            [BlueToothDataManager shareManager].isShowHud = NO;
        }
    } failure:^(id dataObj, NSError *error) {
        NSLog(@"啥都没：%@",[error description]);
        HUDNormal(INTERNATIONALSTRING(@"验证失败"))
        [BlueToothDataManager shareManager].isShowHud = NO;
    } headers:self.headers];
}

- (void)updateVeriTime
{
    self.veriTimeOut++;
    NSLog(@"updateVeriTime--%zd", self.veriTimeOut);
}

- (void)checkVeriResult
{
    self.checkToken = YES;
    [self getBasicHeader];
//    NSDictionary *params = @{@"checkVeriId" : self.phoneTextField.text};
    [SSNetworkRequest getRequest:apiUserDeviceTelGetFirst params:nil success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            if ([responseObj[@"data"][@"ICCID"] isEqualToString:self.veriIccidString]) {
                NSLog(@"验证成功");
                //关闭定时器
                [self deleteVeriTimer];
                //存储IccId
                if(responseObj[@"data"][@"Tel"]){
                    [[NSUserDefaults standardUserDefaults] setObject:responseObj[@"data"][@"Tel"] forKey:[NSString stringWithFormat:@"ValidateICCID%@", self.veriIccidString]];
                }
                //提示验证成功
                HUDNormal(INTERNATIONALSTRING(@"验证成功"))
                [BlueToothDataManager shareManager].isShowHud = NO;
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self dismissVc];
                });
            }else{
                if ((self.veriTimeOut * VeriIntervalTime) >= VeriTotalTime) {
                    //关闭定时器
                    [self deleteVeriTimer];
                    //提示验证失败
                    HUDNormal(INTERNATIONALSTRING(@"验证失败"))
                    [BlueToothDataManager shareManager].isShowHud = NO;
                }else{
                    //再次验证
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(VeriIntervalTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self checkVeriResult];
                    });
                }
            }
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            //关闭定时器
            [self deleteVeriTimer];
            [BlueToothDataManager shareManager].isShowHud = NO;
        }else{
            //关闭定时器
            [self deleteVeriTimer];
            //数据请求失败
            [BlueToothDataManager shareManager].isShowHud = NO;
        }
    } failure:^(id dataObj, NSError *error) {
        NSLog(@"啥都没：%@",[error description]);
        HUDNormal(INTERNATIONALSTRING(@"验证失败"))
        //关闭定时器
        [self deleteVeriTimer];
        [BlueToothDataManager shareManager].isShowHud = NO;
    } headers:self.headers];
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

- (void)deleteVeriTimer
{
    self.veriTimeOut = 0;
    if (self.veriTimer) {
        [self.veriTimer invalidate];
        self.veriTimer = nil;
    }
    self.veriButton.enabled = YES;
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
