//
//  OrderCell.h
//  unitoys
//
//  Created by sumars on 16/9/29.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OrderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *ivLogoPic;
@property (weak, nonatomic) IBOutlet UILabel *lblFlow;
@property (weak, nonatomic) IBOutlet UILabel *lblTotalPrice;
@property (weak, nonatomic) IBOutlet UILabel *lblExpireDays;

@property (weak, nonatomic) IBOutlet UIButton *btnOrderStatus;

@end
