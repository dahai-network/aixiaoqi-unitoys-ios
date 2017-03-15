//
//  PaySuccessViewController.m
//  unitoys
//
//  Created by sumars on 16/11/5.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "PaySuccessViewController.h"

@interface PaySuccessViewController ()

@end

@implementation PaySuccessViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.lblPayAmount.text = self.strPayAmount;
    self.lblPayMethod.text = self.strPayMethod;
    
    [self.btnHintInfo setTitle:self.title forState:UIControlStateNormal];
    // Do any additional setup after loading the view.
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



- (IBAction)resultConfrim:(id)sender {
    if ([self.title isEqualToString:INTERNATIONALSTRING(@"购买成功")]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BuyConfrim" object:nil];
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NeedRefreshAmount" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChargeConfrim" object:nil];
    }
}
@end
