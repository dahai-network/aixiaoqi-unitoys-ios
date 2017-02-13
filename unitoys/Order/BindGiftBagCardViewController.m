//
//  BindGiftBagCardViewController.m
//  unitoys
//
//  Created by 董杰 on 2017/1/4.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BindGiftBagCardViewController.h"

@interface BindGiftBagCardViewController ()
@property (weak, nonatomic) IBOutlet UITextField *txtGiftCard;

@end

@implementation BindGiftBagCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.txtGiftCard becomeFirstResponder];
    self.title = @"绑定礼包卡";
    // Do any additional setup after loading the view from its nib.
}

#pragma mark 绑定使用按钮点击事件
- (IBAction)boundleAndUse:(UIButton *)sender {
    [self.txtGiftCard resignFirstResponder];
    if (![self isBlankString:self.txtGiftCard.text]) {
        //        HUDNoStop1(@"正在绑定...")
        self.checkToken = YES;
        NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.txtGiftCard.text,@"CardPwd", nil];
        [self getBasicHeader];
        NSLog(@"表演头：%@",self.headers);
        
        [SSNetworkRequest postRequest:apiGiftCardBind params:params success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                HUDNormal(responseObj[@"msg"])
                [[NSNotificationCenter defaultCenter] postNotificationName:@"boundGiftCardSuccess" object:@"boundGiftCardSuccess"];
                [self.navigationController popViewControllerAnimated:YES];
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                NSLog(@"绑定礼包卡错误");
            }else{
                //数据请求失败
                //                NSLog(@"请求失败：%@", responseObj[@"msg"]);
                HUDNormal(responseObj[@"msg"])
            }
        } failure:^(id dataObj, NSError *error) {
            //
            NSLog(@"啥都没：%@",[error description]);
            HUDNormal([error description])
        } headers:self.headers];
    } else {
        HUDNormal(@"请填写卡密")
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
