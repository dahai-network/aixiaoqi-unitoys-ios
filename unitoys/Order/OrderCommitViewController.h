//
//  OrderCommitViewController.h
//  unitoys
//
//  Created by sumars on 16/9/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseTableController.h"
#import "ThroughLineLabel.h"

/*
//
//测试商品信息封装在Product中,外部商户可以根据自己商品实际情况定义
//
@interface ToyProduct : NSObject{
@private
    float     _price;
    NSString *_subject;
    NSString *_body;
    NSString *_orderId;
}

@property (nonatomic, assign) float price;
@property (nonatomic, copy) NSString *subject;
@property (nonatomic, copy) NSString *body;
@property (nonatomic, copy) NSString *orderId;

@end*/

@interface OrderCommitViewController : BaseTableController<UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *ivPackagePic;
@property (weak, nonatomic) IBOutlet UILabel *lblPackageName;
@property (weak, nonatomic) IBOutlet UILabel *lblExpireDays;
@property (weak, nonatomic) IBOutlet UILabel *lblPrice;
@property (weak, nonatomic) IBOutlet ThroughLineLabel *lblOldPrice;

@property (weak, nonatomic) IBOutlet UILabel *lblOrderCount;
@property (weak, nonatomic) IBOutlet UILabel *lblOrderPrice;
@property (weak, nonatomic) IBOutlet UILabel *lblOrderAmount;
@property (weak, nonatomic) IBOutlet UILabel *lblAmmountValue;
@property (weak, nonatomic) IBOutlet UILabel *lblFactPayment;

@property (weak, nonatomic) IBOutlet UIButton *btnAccountpay;
@property (weak, nonatomic) IBOutlet UIButton *btnWeipay;
@property (weak, nonatomic) IBOutlet UIButton *btnAlipay;
@property (weak, nonatomic) IBOutlet UILabel *lblOrderFee;

@property (readwrite) NSDictionary *dicPackage;
@property (strong,nonatomic) NSDictionary *dicOrder;

@property (readwrite) NSInteger orderCount;
@property (readwrite) double totalFee;

@property (readwrite) double ammountValue;

@property (readwrite) NSArray *arrMethod;
@property (readwrite) UIButton *btnMethod;

//@property (strong,nonatomic) ToyProduct *product;
- (IBAction)decAmount:(id)sender;
- (IBAction)addAmount:(id)sender;


- (IBAction)switchPayment:(id)sender;

- (IBAction)payment:(id)sender;

@end
