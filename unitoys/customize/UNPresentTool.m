//
//  UNPresentTool.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/21.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNPresentTool.h"

@interface UNPresentTool()

//@property (nonatomic, strong) UIView *popupView;
@property (nonatomic, weak) UIView *contentView;

@property (nonatomic, assign) BOOL isPresenting;
@end

@implementation UNPresentTool

- (void)presentContentView:(UIView *)contentView duration:(NSTimeInterval)duration inView:(UIView *)superView
{
    if (self.isPresenting) return;
    if (_contentView) {
        [_contentView removeFromSuperview];
        _contentView = nil;
    }
    CGPoint viewCenter;
    if (superView) {
        viewCenter = superView.center;
    }else{
        viewCenter = CGPointMake([UIScreen mainScreen].bounds.size.width * 0.5, ([UIScreen mainScreen].bounds.size.height - 64) * 0.5);
    }
    _contentView = contentView;
    _contentView.userInteractionEnabled = NO;
    _contentView.transform = CGAffineTransformMakeScale(0.1, 0.1);
    _contentView.center = viewCenter;
    [UIView animateWithDuration:duration
                          delay:0.0
         usingSpringWithDamping:0.6
          initialSpringVelocity:0.2
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         _contentView.transform = CGAffineTransformIdentity;
//                         _contentView.center = viewCenter;
                     } completion:^(BOOL finished) {
                         if (!finished) return;
                         _contentView.userInteractionEnabled = YES;
                         _isPresenting = YES;
                     }];
}

- (void)dismissDuration:(NSTimeInterval)duration
{
    if (!self.isPresenting) return;
    if (!_contentView) return;
    NSTimeInterval duration1 = duration * 0.25, duration2 = duration - duration1;
    [UIView animateWithDuration:duration1
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _contentView.transform = CGAffineTransformMakeScale(1.05, 1.05);
                     } completion:^(BOOL finished) {
                         
                         [UIView animateWithDuration:duration2
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveEaseInOut
                                          animations:^{
                                              _contentView.transform = CGAffineTransformMakeScale(0.05, 0.05);
                                              
                                          } completion:^(BOOL finished) {
                                              
                                              if (!finished) return;
//                                              [self removeSubviews];
                                              [_contentView removeFromSuperview];
                                              _isPresenting = NO;
                                              _contentView.transform = CGAffineTransformIdentity;
                                              _contentView = nil;
                                          }];
                     }];

}

@end
