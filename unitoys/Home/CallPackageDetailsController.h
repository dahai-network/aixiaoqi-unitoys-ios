//
//  CallPackageDetailsController.h
//  unitoys
//
//  Created by 黄磊 on 2017/2/27.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BaseTableController.h"

@interface CallPackageDetailsController :BaseTableController
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *fristNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *fristRightLabel;

@property (weak, nonatomic) IBOutlet UILabel *userDescLabel;

@property (weak, nonatomic) IBOutlet UILabel *careRuleLabel;

@property (weak, nonatomic) IBOutlet UIButton *buyButton;

@end
