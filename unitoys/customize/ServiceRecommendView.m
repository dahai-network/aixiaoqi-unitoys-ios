//
//  ServiceRecommendView.m
//  unitoys
//
//  Created by 黄磊 on 2017/5/12.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "ServiceRecommendView.h"

@interface ServiceRecommendView ()

@property (nonatomic, copy) ButtonTapBlock buttonTapBlock;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *leftName;
@property (nonatomic, copy) NSString *rightName;

@property (nonatomic, strong) UIWindow *bgWindow;

@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *sureButton;
@property (nonatomic, assign) BOOL isNoTip;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIButton *tipButton;
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation ServiceRecommendView

-(UIWindow *)bgWindow
{
    if (!_bgWindow) {
        _bgWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _bgWindow.windowLevel = UIWindowLevelStatusBar;
        _bgWindow.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
        [_bgWindow makeKeyAndVisible];
    }
    return _bgWindow;
}

+ (instancetype)shareServiceRecommendViewWithTitle:(NSString *)title leftString:(NSString *)leftName rightString:(NSString *)rightName buttnTap:(ButtonTapBlock)buttonTapBlock
{
    return [[ServiceRecommendView alloc] initServiceRecommendViewWithTitle:title leftString:leftName rightString:rightName buttnTap:buttonTapBlock];
}

- (instancetype)initServiceRecommendViewWithTitle:(NSString *)title leftString:(NSString *)leftName rightString:(NSString *)rightName buttnTap:(ButtonTapBlock)buttonTapBlock
{
    if (self = [super init]) {
        _title = title;
        _leftName = leftName;
        _rightName = rightName;
        if (buttonTapBlock) {
            _buttonTapBlock = buttonTapBlock;
        }
        [self initSubView];
    }
    return self;
}

- (void)initSubView
{
    [self.bgWindow addSubview:self];
    self.isNoTip = NO;
    
    CGFloat widthMargin = X(40);
    CGFloat width = kScreenWidthValue - widthMargin * 2;
    CGFloat height = 200;
    _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    _contentView.backgroundColor = UIColorFromRGB(0xf5f5f5);
    _contentView.layer.borderColor = UIColorFromRGB(0xe5e5e5).CGColor;
    _contentView.layer.borderWidth = 1.0;
    _contentView.layer.cornerRadius = 3.0;
    _contentView.layer.masksToBounds = YES;
    [self addSubview:_contentView];
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:16];
    _titleLabel.text = self.title;
    _titleLabel.numberOfLines = 0;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [_contentView addSubview:_titleLabel];
    
    _tipButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_tipButton setImage:[UIImage imageNamed:@"icon_select_nor"] forState:UIControlStateNormal];
    [_tipButton setImage:[UIImage imageNamed:@"icon_select_pre"] forState:UIControlStateSelected];
    _tipButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [_tipButton setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
    [_tipButton setTitle:@"今日不提示" forState:UIControlStateNormal];
    [_tipButton addTarget:self action:@selector(tipButtonAction:) forControlEvents:UIControlEventTouchDown];
    [_tipButton sizeToFit];
    [_contentView addSubview:_tipButton];

    _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_cancelButton setTitle:self.leftName forState:UIControlStateNormal];
    _cancelButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [_cancelButton setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
    _cancelButton.tag = 0;
    _cancelButton.backgroundColor = UIColorFromRGB(0xd5d5d5);
//    _cancelButton.layer.borderColor = UIColorFromRGB(0xf5f5f5).CGColor;
//    _cancelButton.layer.borderWidth = 1.0;
    _cancelButton.layer.cornerRadius = 3.0;
    _cancelButton.layer.masksToBounds = YES;
    [_cancelButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_cancelButton];
    
    _sureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_sureButton setTitle:self.rightName forState:UIControlStateNormal];
    _sureButton.titleLabel.font = [UIFont systemFontOfSize:15];
    _sureButton.tag = 1;
    _sureButton.backgroundColor = UIColorFromRGB(0xf21f20);
//    _sureButton.layer.borderColor = UIColorFromRGB(0xf5f5f5).CGColor;
//    _sureButton.layer.borderWidth = 1.0;
    _sureButton.layer.cornerRadius = 3.0;
    _sureButton.layer.masksToBounds = YES;
    [_sureButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_sureButton];
}

- (void)tipButtonAction:(UIButton *)button
{
    button.selected = !button.isSelected;
    self.isNoTip = button.isSelected;
}

- (void)buttonAction:(UIButton *)button
{
    if (self.buttonTapBlock) {
        self.buttonTapBlock(button.tag, self.isNoTip);
    }
    [self dismissWindow];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.frame = [UIScreen mainScreen].bounds;
    self.contentView.center = self.center;
    self.cancelButton.un_size = CGSizeMake(self.contentView.un_width * 0.3, 30);
    self.cancelButton.un_bottom = self.contentView.un_height - 10;
    self.cancelButton.un_centerX = self.contentView.un_width * 0.25;
    self.sureButton.un_size = CGSizeMake(self.contentView.un_width * 0.3, 30);
    self.sureButton.un_bottom = self.contentView.un_height - 10;
    self.sureButton.un_centerX = self.contentView.un_width * (1-0.25);
    
    self.tipButton.un_bottom = self.cancelButton.un_top - 20;
    self.tipButton.un_left = 30;
    self.titleLabel.frame = CGRectMake(20, 20, self.contentView.un_width - 40, self.tipButton.un_top - 20);
}

- (void)dismissWindow
{
    if (_bgWindow) {
        [_bgWindow resignKeyWindow];
        [self removeFromSuperview];
        _bgWindow = nil;
    }
}

@end
