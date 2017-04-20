//
//  ExplainDetailsChildController.h
//  unitoys
//
//  Created by 黄磊 on 2017/2/27.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BaseViewController.h"

typedef void(^NextStepActionBlock)(NSInteger currentPage, NSInteger totalPage);

@interface ExplainDetailsChildController : BaseViewController

@property (nonatomic, copy) NSString *rootClassName;
@property (nonatomic, copy) NSString *apnName;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) NSInteger totalPage;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailLabelHeight;
@property (weak, nonatomic) IBOutlet UILabel *pageNumber;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UIImageView *explainImageView;
@property (weak, nonatomic) IBOutlet UIButton *gotoSystemButton;
@property (weak, nonatomic) IBOutlet UIButton *nextStepButton;

@end
