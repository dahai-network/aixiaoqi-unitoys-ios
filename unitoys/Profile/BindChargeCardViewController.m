//
//  BindChargeCardViewController.m
//  unitoys
//
//  Created by 董杰 on 2016/12/19.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BindChargeCardViewController.h"

@interface BindChargeCardViewController ()
@property (weak, nonatomic) IBOutlet UITextField *chargeCardNumber;//充值卡号

@end

@implementation BindChargeCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.chargeCardNumber becomeFirstResponder];
    self.title = INTERNATIONALSTRING(@"绑定充值卡");
    // Do any additional setup after loading the view from its nib.
}

#pragma mark 点击按钮
- (IBAction)bindingAndUse:(UIButton *)sender {
    [self.chargeCardNumber resignFirstResponder];
    if ([self isBlankString:self.chargeCardNumber.text]) {
        HUDNormal(INTERNATIONALSTRING(@"请输入正确的密码"))
    } else {
        self.checkToken = YES;
        NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:self.chargeCardNumber.text, @"CardPwd", nil];
        [self getBasicHeader];
//        NSLog(@"表演头：%@",self.headers);
        [SSNetworkRequest postRequest:apiRechargeCard params:info success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                //成功
                HUDNormal(responseObj[@"msg"])
                [self.navigationController popViewControllerAnimated:YES];
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
                NSLog(@"请求失败：%@", responseObj[@"msg"]);
                HUDNormal(responseObj[@"msg"])
            }
        } failure:^(id dataObj, NSError *error) {
            NSLog(@"啥都没：%@",[error description]);
        } headers:self.headers];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
