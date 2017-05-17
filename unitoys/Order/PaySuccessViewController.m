//
//  PaySuccessViewController.m
//  unitoys
//
//  Created by sumars on 16/11/5.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "PaySuccessViewController.h"
#import "ActivateGiftCardViewController.h"
#import "ConvenienceOrderDetailController.h"

@interface PaySuccessViewController ()

@end

@implementation PaySuccessViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.lblPayAmount.text = self.strPayAmount;
    self.lblPayMethod.text = self.strPayMethod;
    
    if (self.isConvenienceOrder) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(paySuccessAction)];
        [self.paySuccessButton setTitle:@"查看订单" forState:UIControlStateNormal];
    }
    
    [self.btnHintInfo setTitle:self.title forState:UIControlStateNormal];
    // Do any additional setup after loading the view.
}


- (void)paySuccessAction
{
    [self.navigationController popToRootViewControllerAnimated:YES];
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
        if (self.packageCategory == 5) {
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"BuyConfrim" object:nil];
//            ActivateGiftCardViewController *giftCardVC = [[ActivateGiftCardViewController alloc] init];
//            giftCardVC.packageCategory = self.packageCategory;
//            giftCardVC.idOrder = self.orderID;
//            giftCardVC.isPaySuccess = YES;
//            [self.navigationController pushViewController:giftCardVC animated:YES];
            ConvenienceOrderDetailController *convenienceOrderVc = [[ConvenienceOrderDetailController alloc] init];
            convenienceOrderVc.isNoClickDetail = self.isNoClickDetail;
            convenienceOrderVc.orderDetailId = self.orderID;
            [self.navigationController pushViewController:convenienceOrderVc animated:YES];
        }else{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BuyConfrim" object:nil];
            ActivateGiftCardViewController *giftCardVC = [[ActivateGiftCardViewController alloc] init];
            giftCardVC.packageCategory = self.packageCategory;
            giftCardVC.idOrder = self.orderID;
            giftCardVC.isPaySuccess = YES;
            [self.navigationController pushViewController:giftCardVC animated:YES];
        }
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NeedRefreshAmount" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChargeConfrim" object:nil];
    }
}
@end
