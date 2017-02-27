//
//  ExplainDetailsChildController.h
//  unitoys
//
//  Created by 黄磊 on 2017/2/27.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BaseViewController.h"

@interface ExplainDetailsChildController : BaseViewController
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UIImageView *explainImageView;
@property (weak, nonatomic) IBOutlet UIButton *gotoSystemButton;

@end
