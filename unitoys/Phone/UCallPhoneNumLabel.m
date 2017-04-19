//
//  UCallPhoneNumLabel.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UCallPhoneNumLabel.h"
#import "UIView+Utils.h"
#import "AddTouchAreaButton.h"
#import "global.h"

@implementation UCallPhoneNumLabel

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews
{
    self.backgroundColor = [UIColor whiteColor];
    UIView *topLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, 1)];
    topLineView.backgroundColor = UIColorFromRGB(0xf2f2f2);
    [self addSubview:topLineView];
    
    _phonelabel = [[UILabel alloc] init];
    _phonelabel.numberOfLines = 1;
    _phonelabel.font = [UIFont systemFontOfSize:24];
    _phonelabel.textColor = UIColorFromRGB(0x333333);
    _phonelabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_phonelabel];
    
    _deleteButton = [AddTouchAreaButton buttonWithType:UIButtonTypeCustom];
    _deleteButton.touchEdgeInset = UIEdgeInsetsMake(10, 10, 10, 10);
    [_deleteButton setImage:[UIImage imageNamed:@"icon_del_nor"] forState:UIControlStateNormal];
    _deleteButton.width = 60;
    _deleteButton.height = self.height;
    [_deleteButton addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_deleteButton];
}

- (void)updatePhoneLabel:(NSString *)phone currentNum:(NSString *)number
{
    if (phone) {
        _phonelabel.text = [phone copy];
    }else{
        _phonelabel.text = @"";
    }
    [self currentLabelText:_phonelabel.text currentNum:number];
}

- (void)deleteAction:(UIButton *)button
{
    if (_phonelabel.text.length > 1) {
        _phonelabel.text = [_phonelabel.text substringToIndex:_phonelabel.text.length - 1];
    }else{
        _phonelabel.text = @"";
    }
    [self currentLabelText:_phonelabel.text currentNum:@"DEL"];
}

- (void)currentLabelText:(NSString *)text currentNum:(NSString *)number
{
    NSLog(@"当前输入文字---%@",text);
    if (_phoneLabelChangeBlock) {
        _phoneLabelChangeBlock(text,number);
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _deleteButton.right = self.width;
    _deleteButton.centerY = self.height * 0.5;
    
    _phonelabel.frame = CGRectMake(0, 0, _deleteButton.left, self.height);
}

@end
