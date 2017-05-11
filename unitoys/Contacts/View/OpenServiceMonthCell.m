//
//  OpenServiceMonthCell.m
//  unitoys
//
//  Created by 黄磊 on 2017/5/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "OpenServiceMonthCell.h"

@interface OpenServiceMonthCell()

@property (nonatomic, strong) UIButton *selectButton;

@end

@implementation OpenServiceMonthCell

- (void)awakeFromNib {
    [super awakeFromNib];
    for (UIButton *button in self.selectMonthButtons) {
        button.layer.borderWidth = 1.0;
        button.layer.borderColor = UIColorFromRGB(0xe5e5e5).CGColor;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (IBAction)selectMonthAction:(UIButton *)sender {
    if (sender.isSelected) {
        return;
    }
    self.selectButton.selected = NO;
    self.selectButton.backgroundColor = [UIColor whiteColor];
    sender.selected = YES;
    sender.backgroundColor = UIColorFromRGB(0xf21f20);
    self.selectButton = sender;
    sender.enabled = NO;
    if (_selectMonthBlock) {
        _selectMonthBlock(sender.tag);
    }
    sender.enabled = YES;
}

@end
