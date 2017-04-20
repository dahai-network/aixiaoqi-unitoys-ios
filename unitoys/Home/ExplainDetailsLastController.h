//
//  ExplainDetailsLastController.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/20.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BaseViewController.h"

@interface ExplainDetailsLastController : BaseViewController

@property (nonatomic, copy) NSString *rootClassName;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *nextStepButton;

@end
