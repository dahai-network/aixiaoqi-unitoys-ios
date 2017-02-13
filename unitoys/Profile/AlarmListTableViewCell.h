//
//  AlarmListTableViewCell.h
//  unitoys
//
//  Created by 董杰 on 2017/1/12.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlarmListTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lblTimeNoon;//上/下午
@property (weak, nonatomic) IBOutlet UILabel *lblTimeDetail;//时间
@property (weak, nonatomic) IBOutlet UILabel *lblDescription;//描述
@property (weak, nonatomic) IBOutlet UISwitch *swOffOrOn;//开关

@end
