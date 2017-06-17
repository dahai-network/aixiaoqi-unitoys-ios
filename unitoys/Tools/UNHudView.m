//
//  UNHudView.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/17.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNHudView.h"
#import "HLLoadingView.h"
#import <Masonry/Masonry.h>

@interface UNHudView ()

@property (nonatomic, strong) HLLoadingView *loadingView;

@end

@implementation UNHudView

- (HLLoadingView *)loadingView
{
    if (!_loadingView) {
        _loadingView = [[HLLoadingView alloc] init];
        [_loadingView setLineWidth:3.0];
        [_loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(30, 30));
//            make.centerY.equalTo(self);
            make.center.equalTo(self);
//            make.right.mas_equalTo(- kMessageInputView_PadingHeight);
        }];
        [self addSubview:_loadingView];
    }
    return _loadingView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initSubViews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews
{
    [self loadingView];
}

- (void)startLoading
{
    [self.loadingView startAnimating];
}

- (void)stopLoading
{
    [self.loadingView stopAnimating];
}

@end
