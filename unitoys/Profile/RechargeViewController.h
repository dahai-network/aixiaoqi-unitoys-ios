//
//  RechargeViewController.h
//  unitoys
//
//  Created by sumars on 16/10/2.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseTableController.h"

@interface RechargeViewController : BaseTableController
@property (weak, nonatomic) IBOutlet UIButton *btnWeipay;
@property (weak, nonatomic) IBOutlet UIButton *btnAlipay;

@property (weak, nonatomic) IBOutlet UITextField *edtRechargeValue;

@property (readwrite) NSString *orderNumber;
@property (readwrite) NSString *orderAmount;

@property (weak, nonatomic) IBOutlet UIButton *btn20;
@property (weak, nonatomic) IBOutlet UIButton *btn50;
@property (weak, nonatomic) IBOutlet UIButton *btn100;
@property (weak, nonatomic) IBOutlet UIButton *btn300;
@property (weak, nonatomic) IBOutlet UIButton *btn500;


@property (readwrite) NSArray *arrValues;
@property (readwrite) UIButton *btnSelected;

@property (readwrite) NSString *payValue;

- (IBAction)switchPayment:(id)sender;

- (IBAction)payment:(id)sender;

@end
