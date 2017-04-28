//
//  UCallPhoneButton.m
//  unitoys
//
//  Created by 黄磊 on 2017/2/16.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UCallPhoneButton.h"
#import "global.h"
#import "UIView+Utils.h"

@interface UCallPhoneButton ()

@property (nonatomic, copy) NSString *topTitle;
@property (nonatomic, copy) NSString *bottomTitle;

@property (nonatomic, weak) UILabel *topLabel;
@property (nonatomic, weak) UILabel *bottomLabel;

@end

@implementation UCallPhoneButton

+ (instancetype)callPhoneButtonWithTopTitle:(NSString *)topTitle BottomTitle:(NSString *)bottomTitle IsCanLongPress:(BOOL)isCanLongPress
{
    return [[self alloc] initWithCallPhoneButtonWithTopTitle:topTitle BottomTitle:bottomTitle IsCanLongPress:isCanLongPress];
}

- (instancetype)initWithCallPhoneButtonWithTopTitle:(NSString *)topTitle BottomTitle:(NSString *)bottomTitle IsCanLongPress:(BOOL)isCanLongPress
{
    if (self = [super init]) {
        self.topTitle = topTitle;
        self.bottomTitle = bottomTitle;
        if (isCanLongPress) {
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
            [self addGestureRecognizer:longPress];
        }
        [self initWithSubViews];
    }
    return self;
}

- (void)initWithSubViews
{
    UILabel *topLabel = [[UILabel alloc] init];
    _topLabel = topLabel;
    topLabel.text = self.topTitle;
    topLabel.textColor = [UIColor blackColor];
    topLabel.font = [UIFont systemFontOfSize:23];
    [topLabel sizeToFit];
    [self addSubview:topLabel];
    
    UILabel *bottomLabel = [[UILabel alloc] init];
    _bottomLabel = bottomLabel;
    bottomLabel.text = self.bottomTitle;
    bottomLabel.textColor = [UIColor darkGrayColor];
    bottomLabel.font = [UIFont systemFontOfSize:14];
    [bottomLabel sizeToFit];
    [self addSubview:bottomLabel];
}

- (void)setIsTransparent:(BOOL)isTransparent
{
    _isTransparent = isTransparent;
    if (isTransparent) {
        self.topLabel.textColor = [UIColor whiteColor];
        self.bottomLabel.textColor = [UIColor whiteColor];
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    if (_isTransparent) {
        if (highlighted) {
            self.topLabel.textColor = UIColorFromRGB(0x00a0e9);
            self.bottomLabel.textColor = UIColorFromRGB(0x00a0e9);
        }else{
            self.topLabel.textColor = [UIColor whiteColor];
            self.bottomLabel.textColor = [UIColor whiteColor];
        }
    }else{
//        if (highlighted) {
//            self.backgroundColor = UIColorFromRGB(0xd2d2d2);
//        }else{
//            self.backgroundColor = [UIColor whiteColor];
//        }
        if (highlighted) {
            self.topLabel.textColor = UIColorFromRGB(0x00a0e9);
            self.bottomLabel.textColor = UIColorFromRGB(0x00a0e9);
        }else{
            self.topLabel.textColor = [UIColor blackColor];
            self.bottomLabel.textColor = [UIColor darkGrayColor];
        }
    }
}

- (void)longPressAction:(UILongPressGestureRecognizer *)pressGestureRecognizer
{
    if (pressGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (_phoneButtonLongPressAction) {
            _phoneButtonLongPressAction(self.topTitle);
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
//    self.topLabel.bottom = self.height * 0.5;
//    self.topLabel.centerX = self.width * 0.5;
//    self.bottomLabel.top = self.height * 0.5 + 2;
//    self.bottomLabel.centerX = self.topLabel.centerX;
    
    self.topLabel.un_centerY = self.un_height * 0.5;
    self.topLabel.un_right = self.un_width * 0.5 - 10;
    self.bottomLabel.un_bottom = self.topLabel.un_bottom - 3;
    self.bottomLabel.un_left = self.un_width * 0.5;
}

@end
