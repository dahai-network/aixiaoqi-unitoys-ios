//
//  UNPresentTool.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/21.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNPresentTool.h"
//#import "global.h"

@interface UNPresentTool()

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIWindow *superview;
@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, assign) BOOL isPresenting;

@property (nonatomic, weak) UIWindow *mainWindow;
@end

@implementation UNPresentTool

- (instancetype)init {
    self = [super init];
    if (!self)  return nil;
    _isPresenting             = NO;
    _maskView = [UIApplication sharedApplication].keyWindow;
    
    _superview = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _superview.windowLevel = UIWindowLevelAlert;
    [_superview makeKeyAndVisible];
    
    _maskView = [[UIView alloc] initWithFrame:_superview.bounds];
    _maskView.userInteractionEnabled = YES;
    _maskView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    return self;
}

- (void)presentContentView:(UIView *)contentView duration:(NSTimeInterval)duration inView:(UIView *)superView
{
    if (self.isPresenting) return;
    if (_contentView) {
        [_contentView removeFromSuperview];
        _contentView = nil;
    }
    CGPoint viewCenter;
    if (superView) {
        viewCenter = CGPointMake(superView.bounds.size.width * 0.5, superView.bounds.size.height * 0.5);
    }else if (contentView.frame.origin.x == 0){
        viewCenter = CGPointMake([UIScreen mainScreen].bounds.size.width * 0.5, ([UIScreen mainScreen].bounds.size.height - 64) * 0.5);
    }else{
        viewCenter = _contentView.center;
    }
    [self setContentView:contentView];
    [_superview addSubview:_maskView];
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
                         _maskView.alpha = 1;
                     } completion:^(BOOL finished) {
                         if (!finished) return;
                         _contentView.userInteractionEnabled = YES;
                         _isPresenting = YES;
                     }];
}

- (void)dismissDuration:(NSTimeInterval)duration completion: (void (^ __nullable)(void))completion
{
    if (!self.isPresenting) return;
    if (!_contentView) return;
    NSTimeInterval duration1 = duration * 0.25, duration2 = duration - duration1;
    [UIView animateWithDuration:duration1
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _contentView.transform = CGAffineTransformMakeScale(1.05, 1.05);
                         _maskView.alpha = 0.95;
                     } completion:^(BOOL finished) {
                         [UIView animateWithDuration:duration2
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveEaseInOut
                                          animations:^{
                                              _contentView.transform = CGAffineTransformMakeScale(0.05, 0.05);
                                              _maskView.alpha = 0;
                                          } completion:^(BOOL finished) {
                                              if (!finished) return;
                                              _contentView.transform = CGAffineTransformIdentity;
                                              [_contentView removeFromSuperview];
                                              _contentView = nil;
                                              [_maskView removeFromSuperview];
                                              _isPresenting = NO;
                                              
                                              [_mainWindow makeKeyAndVisible];
                                              _superview = nil;
                                              if (completion) {
                                                  completion();
                                              }
                                          }];
                     }];
}

- (void)setContentView:(UIView *)contentView {
    _contentView = contentView;
    if (nil == _contentView) {
        return;
    }
    [_maskView addSubview:_contentView];
}

@end
