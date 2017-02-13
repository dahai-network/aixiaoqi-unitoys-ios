//
//  OrderActivationViewController.h
//  unitoys
//
//  Created by sumars on 16/10/23.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseTableController.h"

@interface OrderActivationViewController : BaseTableController
@property (weak, nonatomic) IBOutlet UILabel *lblDeviceStatus;
@property (weak, nonatomic) IBOutlet UILabel *lblActivationDate;
@property (weak, nonatomic) IBOutlet UILabel *lblExprieDays;

@property (readwrite) NSDictionary *dicOrderDetail;

- (IBAction)activationOrder:(id)sender;

@end
