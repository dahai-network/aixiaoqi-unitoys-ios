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
//    for (UIButton *button in self.selectMonthButtons) {
//        button.layer.borderWidth = 1.0;
//        button.layer.borderColor = UIColorFromRGB(0xe5e5e5).CGColor;
//    }
}

//contentViewWidth:kwidth - 30 height:buttonHeight * count + 7*(count-1)
//buttonheight:50 buttonwidthMargin:
- (void)updateCellWithDatas:(NSDictionary *)dict
{
#warning 测试数量
    NSArray *array = @[@"1", @"2", @"3", @"4"];
    NSInteger colCount = 3;
    NSInteger rowCount = (array.count + colCount - 1) / colCount;
    CGFloat widthMargin = 10;
    CGFloat heightMargin = 7;
    CGFloat buttonWidth = (kScreenWidthValue - 30 - (colCount - 1) * widthMargin) / (CGFloat)colCount;
    CGFloat buttonHeight = 50;
    self.monthContentViewHeight.constant = buttonHeight * rowCount + heightMargin * (rowCount - 1);
    CGFloat buttonX;
    CGFloat buttonY;
    for (NSInteger i = 0; i < array.count; i++) {
        buttonX = (i % colCount) * (buttonWidth + widthMargin);
        buttonY = i / colCount * (buttonHeight + heightMargin);
        UIButton *monthButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.monthContentView addSubview:monthButton];
        monthButton.frame = CGRectMake(buttonX, buttonY, buttonWidth, buttonHeight);
        [monthButton setTitle:[NSString stringWithFormat:@"%@个月",array[i]] forState:UIControlStateNormal];
        monthButton.tag = i;
        [monthButton addTarget:self action:@selector(selectMonthAction:) forControlEvents:UIControlEventTouchDown];
        monthButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [monthButton setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
        [monthButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        monthButton.layer.borderWidth = 1.0;
        monthButton.layer.borderColor = UIColorFromRGB(0xe5e5e5).CGColor;
    }
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}
- (void)selectMonthAction:(UIButton *)sender {
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
