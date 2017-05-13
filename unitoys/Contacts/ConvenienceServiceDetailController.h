//
//  ConvenienceServiceDetailController.h
//  unitoys
//
//  Created by 黄磊 on 2017/5/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BaseViewController.h"

@interface ConvenienceServiceDetailController : BaseViewController
@property (weak, nonatomic) IBOutlet UIImageView *bannerImageView;
@property (weak, nonatomic) IBOutlet UIImageView *detailImageView;

@property (nonatomic, copy) NSString *packageId;
@property (nonatomic, copy) NSString *currentPhoneNum;
@property (weak, nonatomic) IBOutlet UILabel *phoneNumLabel;
@end
