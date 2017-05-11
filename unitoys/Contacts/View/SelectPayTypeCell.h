//
//  SelectPayTypeCell.h
//  unitoys
//
//  Created by 黄磊 on 2017/5/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SelectPayTypeCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UIImageView *selectImageVIew;
//default -2.5   8.0
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameLabelBottom;
@property (weak, nonatomic) IBOutlet UIView *lineView;
@end
