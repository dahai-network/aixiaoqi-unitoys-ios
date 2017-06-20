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
        [self addSubview:_loadingView];
        [_loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(40, 40));
            make.center.mas_equalTo(self.center);
        }];
        [_loadingView createLoadingView:40];
        [_loadingView setLineWidth:3.0];
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
