//
//  ChooseDeviceTypeTableViewCell.h
//  unitoys
//
//  Created by 董杰 on 2017/3/9.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CutomButton.h"

@interface ChooseDeviceTypeTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lbltype;
@property (weak, nonatomic) IBOutlet UILabel *lblTypeDis;
@property (weak, nonatomic) IBOutlet UIImageView *imgType;
@property (weak, nonatomic) IBOutlet CutomButton *backGroundButton;

@end
