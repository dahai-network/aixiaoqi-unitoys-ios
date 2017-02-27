//
//  AbroadPackageDescView.m
//  unitoys
//
//  Created by 黄磊 on 2017/2/27.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "AbroadPackageDescView.h"
#import "UIView+Utils.h"
#import "global.h"

#define leftMargin 30
#define viewHeight 300

@interface AbroadPackageDescView ()

@property (nonatomic, strong) UIWindow *bgWindow;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *descString;
@property (nonatomic, copy) NSString *buttonTitle;

@end

@implementation AbroadPackageDescView

- (UIWindow *)bgWindow
{
    if (!_bgWindow) {
        _bgWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _bgWindow.windowLevel = UIWindowLevelStatusBar;
        _bgWindow.backgroundColor = [UIColor clearColor];
        _bgWindow.hidden = NO;
    }
    return _bgWindow;
}
+ (instancetype)showAbroadPackageDescViewWithTitle:(NSString *)title Desc:(NSString *)descString SureButtonTitle:(NSString *)buttonTitle
{
    return [[AbroadPackageDescView alloc] initWithAbroadPackageDescViewWithTitle:title Desc:descString SureButtonTitle:buttonTitle];
}

- (instancetype)initWithAbroadPackageDescViewWithTitle:(NSString *)title Desc:(NSString *)descString SureButtonTitle:(NSString *)buttonTitle
{
    if (self = [super init]) {
        self.title = title;
        self.descString = descString;
        self.buttonTitle = buttonTitle;
        [self.bgWindow addSubview:self];
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews
{
    self.alpha = 0;
    self.frame = self.bgWindow.bounds;
    UIView *presentView = [[UIView alloc] initWithFrame:CGRectMake(leftMargin, 0, self.bgWindow.width - 2 * leftMargin, viewHeight)];
    presentView.layer.borderWidth = 0.5;
    presentView.layer.borderColor = UIColorFromRGB(0xd5d5d5).CGColor;
    presentView.centerY = self.bgWindow.height * 0.5;
    [self addSubview:presentView];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = self.title;
    titleLabel.font = [UIFont systemFontOfSize:15];
    [titleLabel sizeToFit];
    titleLabel.top = 20;
    titleLabel.centerX = presentView.width * 0.5;
    [presentView addSubview:titleLabel];
    
    UIButton *dismissButton = [[UIButton alloc] init];
    [dismissButton setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
    [dismissButton sizeToFit];
    dismissButton.top = 10;
    dismissButton.right = presentView.width - 10;
    [dismissButton addTarget:self action:@selector(dismissWindow) forControlEvents:UIControlEventTouchUpInside];
    [presentView addSubview:dismissButton];
    
    UIButton *sureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [sureButton setTitle:self.buttonTitle forState:UIControlStateNormal];
    [sureButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    sureButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [sureButton sizeToFit];
    sureButton.bottom = presentView.height - 20;
    sureButton.centerX = presentView.width * 0.5;
    [sureButton addTarget:self action:@selector(dismissWindow) forControlEvents:UIControlEventTouchUpInside];
    [presentView addSubview:sureButton];
    
    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.text = self.descString;
    descLabel.numberOfLines = 0;
    descLabel.font = [UIFont systemFontOfSize:13];
    descLabel.textColor = [UIColor darkGrayColor];
    descLabel.width = presentView.width - 60;
    descLabel.top = titleLabel.bottom + 20;
    descLabel.height = sureButton.top - 20 - descLabel.top;
    descLabel.centerX = presentView.width * 0.5;
    [presentView addSubview:descLabel];
    
    [UIView animateWithDuration:1.0 animations:^{
        self.alpha = 1;
    }];
}

- (void)dismissWindow
{
    if (_bgWindow) {
        _bgWindow.hidden = YES;
        [self removeFromSuperview];
        _bgWindow = nil;
    }
}
@end
