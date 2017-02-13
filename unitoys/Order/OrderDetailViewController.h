//
//  OrderDetailViewController.h
//  unitoys
//
//  Created by sumars on 16/9/29.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseTableController.h"
#import "BorderButton.h"

@interface OrderDetailViewController : BaseTableController

@property (readwrite) NSString *idOrder;
@property (weak, nonatomic) IBOutlet UIImageView *ivLogoPic;
@property (weak, nonatomic) IBOutlet UILabel *lblPackageName;
@property (weak, nonatomic) IBOutlet UILabel *lblExpireDays;
@property (weak, nonatomic) IBOutlet UILabel *lblTotalPrice;
@property (weak, nonatomic) IBOutlet UILabel *lblQuantity;

@property (weak, nonatomic) IBOutlet UILabel *lblOrderStatus;
@property (weak, nonatomic) IBOutlet UILabel *lblExprieDay;


@property (weak, nonatomic) IBOutlet UILabel *lblOrderNum;
@property (weak, nonatomic) IBOutlet UILabel *lblOrderDate;
@property (weak, nonatomic) IBOutlet UILabel *lblPaymentMethod;

@property (weak, nonatomic) IBOutlet UILabel *lblOrderPrice;

@property (weak, nonatomic) IBOutlet BorderButton *btnOrderCancel;
@property (readwrite) NSDictionary *dicOrderDetail;


- (IBAction)orderAvation:(id)sender;

- (IBAction)orderCancel:(id)sender;

@end
