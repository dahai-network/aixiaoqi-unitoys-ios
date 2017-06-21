//
//  UNRefreshCircleHeader.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/19.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNRefreshCircleHeader.h"
#import "HLCircleView.h"

#define kCircleWidth 30
@interface UNRefreshCircleHeader ()

@property (nonatomic, strong) HLCircleView *circleView;

@end

@implementation UNRefreshCircleHeader

- (UIImageView *)gifView
{
    UIImageView *gView = [super gifView];
    if (!_circleView) {
        _circleView = [[HLCircleView alloc] initWithFrame:CGRectMake(0, 0, kCircleWidth, kCircleWidth)];
        [gView addSubview:_circleView];
    }
    return gView;
}

- (void)placeSubviews
{
    [super placeSubviews];
    _circleView.frame = CGRectMake((CGRectGetWidth(self.gifView.frame) - kCircleWidth) / 2,
                                   (CGRectGetHeight(self.gifView.frame) - kCircleWidth) / 2,
                                   kCircleWidth, kCircleWidth);
}

- (void)setPullingPercent:(CGFloat)pullingPercent
{
    [super setPullingPercent:pullingPercent];
//    UNDebugLogVerbose(@"pullingPercent===%.f", pullingPercent)
    if (pullingPercent < 0.96) {
        _circleView.strokeEnd = pullingPercent;
    }else{
        _circleView.strokeEnd = 0.96;
    }
}

- (void)setState:(MJRefreshState)state
{
    MJRefreshCheckState
    if (state == MJRefreshStateRefreshing) {
        UNDebugLogVerbose(@"startRotateAnimation")
        [_circleView startRotateAnimation];
    } else if (state == MJRefreshStateIdle) {
        UNDebugLogVerbose(@"stopRotateAnimation")
        [_circleView stopRotateAnimation];
    }
}

@end
