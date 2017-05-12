//
//  UNPresentImageView.m
//  unitoys
//
//  Created by 黄磊 on 2017/5/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNPresentImageView.h"
//#import "SDWebImage/SDWebImage/UIImageView+WebCache.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface UNPresentImageView ()

@property (nonatomic, copy) ImageViewTapBlock imageTap;
@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, copy) NSString *cancelName;

@property (nonatomic, strong) UIWindow *bgWindow;

@property (nonatomic, strong) UIImageView *imageTapView;
@property (nonatomic, strong) UIButton *cancelButton;
@end

@implementation UNPresentImageView

-(UIWindow *)bgWindow
{
    if (!_bgWindow) {
        _bgWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _bgWindow.windowLevel = UIWindowLevelStatusBar;
        _bgWindow.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        [_bgWindow makeKeyAndVisible];
    }
    return _bgWindow;
}

+ (instancetype)sharePresentImageViewWithImageUrl:(NSString *)imageUrl cancelImageName:(NSString *)cancelName imageTap:(ImageViewTapBlock)imageBlock
{
    return [[UNPresentImageView alloc] initPresentImageViewWithImageUrl:imageUrl cancelImageName:cancelName imageTap:imageBlock];
}

- (instancetype)initPresentImageViewWithImageUrl:(NSString *)imageUrl cancelImageName:(NSString *)cancelName imageTap:(ImageViewTapBlock)imageBlock;
{
    if (self = [super init]) {
        _imageUrl = imageUrl;
        _cancelName = cancelName;
        if (imageBlock) {
            _imageTap = imageBlock;
        }
        [self initSubView];
    }
    return self;
}

- (void)initSubView
{
    [self.bgWindow addSubview:self];
    CGFloat widthMargin = X(40);
    CGFloat width = kScreenWidthValue - widthMargin * 2;
    CGFloat height = width / (561.0/691);
    
    _imageTapView = [[UIImageView alloc] init];
    _imageTapView.un_size = CGSizeMake(width, height);
    _imageTapView.userInteractionEnabled = YES;
    [_imageTapView sd_setImageWithURL:[NSURL URLWithString:self.imageUrl] placeholderImage:nil];
    [self addSubview:_imageTapView];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapAction)];
    [_imageTapView addGestureRecognizer:tap];
    
    _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_cancelButton setImage:[UIImage imageNamed:self.cancelName] forState:UIControlStateNormal];
    [_cancelButton sizeToFit];
    [_cancelButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_cancelButton];
}

- (void)imageTapAction
{
    if (self.imageTap) {
        self.imageTap();
        [self dismissWindow];
    }
}

- (void)cancelAction:(UIButton *)button
{
    [self dismissWindow];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.frame = [UIScreen mainScreen].bounds;
    self.imageTapView.center = self.center;
    self.cancelButton.un_top = self.imageTapView.un_bottom + 30;
    self.cancelButton.un_centerX = self.imageTapView.un_centerX;
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
