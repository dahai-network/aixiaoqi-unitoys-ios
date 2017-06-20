//
//  HLCircleView.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/19.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "HLCircleView.h"

@implementation HLCircleView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initCirclePath];
    }
    return self;
}

- (void)initCirclePath
{
    CGPoint center = CGPointMake(CGRectGetWidth(self.frame) * 0.5, CGRectGetHeight(self.frame) * 0.5);
    CGPathRef circlePath = [UIBezierPath bezierPathWithArcCenter:center radius:center.x startAngle:0 endAngle:2 * (M_PI) clockwise:YES].CGPath;
    _circleShapeLayer = [CAShapeLayer layer];
    _circleShapeLayer.path = circlePath;
    _circleShapeLayer.strokeEnd = 1;
    _circleShapeLayer.strokeColor = DefultColor.CGColor;
    _circleShapeLayer.fillColor = [UIColor clearColor].CGColor;
    [self.layer addSublayer:_circleShapeLayer];
}

- (void)setStrokeEnd:(CGFloat)strokeEnd
{
    if (self.isRotating) {
        return;
    }
    _strokeEnd = strokeEnd;
    _circleShapeLayer.strokeEnd = strokeEnd;
}

- (void)setBorderColor:(UIColor *)borderColor
{
    _borderColor = borderColor;
    _circleShapeLayer.borderColor = borderColor.CGColor;
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    _borderWidth = borderWidth;
    _circleShapeLayer.lineWidth = borderWidth;
}

- (void)startRotateAnimation
{
    if (_isRotating) {
        return;
    }
    _isRotating = YES;
    CAKeyframeAnimation *keyAnima = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
    keyAnima.values = @[@0, @(2 * M_PI)];
    keyAnima.duration = 0.3;
    keyAnima.repeatCount = CGFLOAT_MAX;
    keyAnima.removedOnCompletion = NO;
    [self.layer addAnimation:keyAnima forKey:@"CircleRotateAnimation"];
}

- (void)stopRotateAnimation
{
    if (!_isRotating) {
        return;
    }
    [self.layer removeAllAnimations];
    _isRotating = NO;
}

@end
