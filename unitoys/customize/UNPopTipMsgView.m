//
//  UNPopTipMsgView.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/21.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNPopTipMsgView.h"
#import "global.h"
#import "UIView+Utils.h"

#define margin 40
#define subMargin 5
#define bottomHeight 50
#define TitleHeight 50
@interface UNPopTipMsgView()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIView *topLineView;
//@property (nonatomic, strong) UIView *bottomLineView;

@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *detailTitle;
@end

@implementation UNPopTipMsgView

+ (instancetype)sharePopTipMsgViewTitle:(NSString *)title detailTitle:(NSString *)detail
{
    return [[UNPopTipMsgView alloc] initPopTipMsgViewTitle:title detailTitle:detail];
}

- (instancetype)initPopTipMsgViewTitle:(NSString *)title detailTitle:(NSString *)detail
{
    if (self = [super init]) {
        _title = title;
        _detailTitle = detail;
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews
{
    self.backgroundColor = [UIColor whiteColor];
    self.layer.cornerRadius = 8;
    self.layer.masksToBounds = YES;
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.numberOfLines = 1;
    _titleLabel.text = _title;
    _titleLabel.textColor = UIColorFromRGB(0x333333);
    _titleLabel.font = [UIFont systemFontOfSize:18];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_titleLabel];
    
    _topLineView = [[UIView alloc] init];
    _topLineView.backgroundColor = UIColorFromRGB(0xe5e5e5);
    [self addSubview:_topLineView];
    
    _detailLabel = [[UILabel alloc] init];
    _detailLabel.numberOfLines = 0;
    _detailLabel.text = _detailTitle;
    _detailLabel.textColor = UIColorFromRGB(0x333333);
    _detailLabel.font = [UIFont systemFontOfSize:14];
    _detailLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_detailLabel];
    
    _bottomView = [[UIView alloc] init];
    [self addSubview:_bottomView];
    
//    _bottomLineView = [[UIView alloc] init];
//    _bottomLineView.backgroundColor = UIColorFromRGB(0xe5e5e5);
//    [self addSubview:_bottomLineView];
    
    _leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_leftButton setTitle:@"取消" forState:UIControlStateNormal];
    _leftButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_leftButton setTitleColor:UIColorFromRGB(0x666666) forState:UIControlStateNormal];
    [_bottomView addSubview:_leftButton];
    [_leftButton addTarget:self action:@selector(leftButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_rightButton setTitle:@"确定" forState:UIControlStateNormal];
    _rightButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_rightButton setTitleColor:UIColorFromRGB(0x00a0e9) forState:UIControlStateNormal];
    [_bottomView addSubview:_rightButton];
    [_rightButton addTarget:self action:@selector(rightButtonAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)leftButtonAction:(UIButton *)button
{
    button.enabled = NO;
    if (_popTipButtonAction) {
        _popTipButtonAction(1);
    }
    button.enabled = YES;
}

- (void)rightButtonAction:(UIButton *)button
{
    button.enabled = NO;
    if (_popTipButtonAction) {
        _popTipButtonAction(2);
    }
    button.enabled = YES;
}


- (void)setLeftButtonText:(NSString *)leftButtonText
{
    _leftButtonText = leftButtonText;
    [self.leftButton setTitle:leftButtonText forState:UIControlStateNormal];
}

- (void)setRightButtonText:(NSString *)rightButtonText
{
    _rightButtonText = rightButtonText;
    [self.rightButton setTitle:rightButtonText forState:UIControlStateNormal];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.frame = CGRectMake(0, 0, kScreenWidthValue - margin * 2, kScreenWidthValue - margin * 2);
    self.center = CGPointMake(kScreenWidthValue * 0.5, kScreenHeightValue * 0.5 - self.topOffset);
    _titleLabel.frame = CGRectMake(0, 0, self.un_width, TitleHeight);
    _topLineView.frame = CGRectMake(subMargin, CGRectGetMaxY(_titleLabel.frame), self.un_width - subMargin * 2, 1);
    _bottomView.frame = CGRectMake(0, self.un_height - bottomHeight, self.un_width, bottomHeight);
//    _bottomLineView.frame = CGRectMake(0, _bottomView.top - 1, _bottomView.width, 1);
    _leftButton.frame = CGRectMake(0, 0, _bottomView.un_width * 0.5, _bottomView.un_height);
    _rightButton.frame = CGRectMake(_bottomView.un_width * 0.5, 0, _bottomView.un_width * 0.5, _bottomView.un_height);
    _detailLabel.frame = CGRectMake(subMargin, CGRectGetMaxY(_titleLabel.frame), self.un_width - subMargin * 2, self.un_height - _titleLabel.un_height - _bottomView.un_height);
}

@end
