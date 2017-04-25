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
#import "AddTouchAreaButton.h"

#define leftMargin (50.0/375) * [UIScreen mainScreen].bounds.size.width
#define viewHeight 270

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
        _bgWindow.windowLevel = UIWindowLevelAlert;
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
//    self.alpha = 0;
    self.frame = self.bgWindow.bounds;
    UIView *presentView = [[UIView alloc] initWithFrame:CGRectMake(leftMargin, 0, self.bgWindow.un_width - 2 * leftMargin, viewHeight)];
    presentView.backgroundColor = [UIColor whiteColor];
    presentView.layer.borderWidth = 1.0;
    presentView.layer.borderColor = UIColorFromRGB(0xd5d5d5).CGColor;
    presentView.un_centerY = self.bgWindow.un_height * 0.5;
    [self addSubview:presentView];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = self.title;
    titleLabel.font = [UIFont systemFontOfSize:17];
    [titleLabel sizeToFit];
    titleLabel.un_top = 20;
    titleLabel.un_centerX = presentView.un_width * 0.5;
    [presentView addSubview:titleLabel];
    
    AddTouchAreaButton *dismissButton = [[AddTouchAreaButton alloc] init];
    dismissButton.touchEdgeInset = UIEdgeInsetsMake(5, 5, 5, 5);
    [dismissButton setImage:[UIImage imageNamed:@"order_unactive"] forState:UIControlStateNormal];
    [dismissButton sizeToFit];
    dismissButton.un_top = 5;
    dismissButton.un_right = presentView.un_width - 5;
    [dismissButton addTarget:self action:@selector(dismissWindow) forControlEvents:UIControlEventTouchUpInside];
    [presentView addSubview:dismissButton];
    
    UIButton *sureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [sureButton setTitle:self.buttonTitle forState:UIControlStateNormal];
    [sureButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    sureButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [sureButton sizeToFit];
    sureButton.un_bottom = presentView.un_height - 15;
    sureButton.un_centerX = presentView.un_width * 0.5;
    [sureButton addTarget:self action:@selector(dismissWindow) forControlEvents:UIControlEventTouchUpInside];
    [presentView addSubview:sureButton];
    
    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.text = self.descString;
    descLabel.numberOfLines = 0;
    descLabel.font = [UIFont systemFontOfSize:14];
    descLabel.textColor = [UIColor darkGrayColor];
    descLabel.un_width = presentView.un_width - 40;
    descLabel.un_top = titleLabel.un_bottom + 20;
    descLabel.un_height = sureButton.un_top - 20 - descLabel.un_top;
    descLabel.un_centerX = presentView.un_width * 0.5;
    [presentView addSubview:descLabel];
    
    
    CABasicAnimation *baseAnima = [CABasicAnimation animation];
    baseAnima.keyPath = @"transform.scale";
    baseAnima.duration = 0.3;
    baseAnima.fromValue = @0.7;
    baseAnima.toValue = @1;
    [presentView.layer addAnimation:baseAnima forKey:nil];
}


- (void)dismissWindow
{
    if (_bgWindow) {
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            _bgWindow.hidden = YES;
            self.hidden = YES;
            [self removeFromSuperview];
            _bgWindow = nil;
        }];
    }
}

@end
