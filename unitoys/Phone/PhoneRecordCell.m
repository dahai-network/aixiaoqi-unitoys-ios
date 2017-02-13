//
//  PhoneRecordCell.m
//  unitoys
//
//  Created by sumars on 16/10/7.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "PhoneRecordCell.h"

@implementation PhoneRecordCell

- (void)awakeFromNib {
    [super awakeFromNib];
//    self.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    self.tintColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:255/255.0 alpha:1.0];//0079ff
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
