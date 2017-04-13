//
//  CallDetailsNameCell.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "CallDetailsNameCell.h"

@implementation CallDetailsNameCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setCellDatas:(NSDictionary *)cellDatas
{
    _cellDatas = cellDatas;
    self.nameLabel.text = cellDatas[@"cellTitle"];
}

@end
