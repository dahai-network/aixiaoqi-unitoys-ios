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

//contentViewWidth:kwidth - 30 height:buttonHeight * count + 7*(count-1)
//buttonheight:50 buttonwidthMargin:
- (void)updateCellWithDatas:(NSDictionary *)dict
{
//    NSArray *array = dict[@""];
//    NSArray *array = [NSArray array];
//    for (NSInteger i = 0; i < array.count; i++) {
//        UIButton *monthButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    }
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
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
