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
    topLabel.textColor = [UIColor darkGrayColor];
    topLabel.font = [UIFont systemFontOfSize:18];
    [topLabel sizeToFit];
    [self addSubview:topLabel];
    
    UILabel *bottomLabel = [[UILabel alloc] init];
    _bottomLabel = bottomLabel;
    bottomLabel.text = self.bottomTitle;
    bottomLabel.textColor = UIColorFromRGB(0xd2d2d2);
    bottomLabel.font = [UIFont systemFontOfSize:14];
    [bottomLabel sizeToFit];
    [self addSubview:bottomLabel];
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
    self.topLabel.bottom = self.centerY;
    self.topLabel.centerX = self.width * 0.5;
    self.bottomLabel.top = self.centerY + 2;
    self.bottomLabel.centerX = self.topLabel.centerX;
}

@end
