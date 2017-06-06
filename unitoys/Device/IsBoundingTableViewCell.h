//
//  IsBoundingTableViewCell.h
//  unitoys
//
//  Created by 董杰 on 2017/6/5.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CutomButton.h"

@interface IsBoundingTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lblDeviceName;
@property (weak, nonatomic) IBOutlet UILabel *lblDeviceStatue;
@property (weak, nonatomic) IBOutlet CutomButton *btnConnect;

@end
