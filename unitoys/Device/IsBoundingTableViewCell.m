//
//  IsBoundingTableViewCell.m
//  unitoys
//
//  Created by 董杰 on 2017/6/5.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "IsBoundingTableViewCell.h"

@implementation IsBoundingTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
//    [self.btnConnect setColor:UIColorFromRGB(0x00a0e9)];
    self.btnConnect.isHiddenLine = YES;
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
