//
//  OrderListTableViewCell.h
//  unitoys
//
//  Created by 董杰 on 2017/4/18.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CutomButton.h"

@interface OrderListTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *ivLogoPic;
@property (weak, nonatomic) IBOutlet UILabel *lblFlow;
@property (weak, nonatomic) IBOutlet UILabel *lblExpireDays;
@property (weak, nonatomic) IBOutlet UILabel *lblPrice;
@property (weak, nonatomic) IBOutlet CutomButton *activityButton;

@end
