//
//  HLLoadingView.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/16.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "HLLoadingView.h"

#define kCircleColor DefultColor

@interface HLLoadingView ()
// 圆形layer
@property (nonatomic, weak)  CAShapeLayer *outsideShapeLayer;

@property (nonatomic, assign, getter=isLoadAnimating) BOOL loadAnimating;

@property (nonatomic, assign) CGFloat loadingWidth;
@end

@implementation HLLoadingView

- (instancetype)initWithWidth:(CGFloat)width
{
    if (self = [super init]) {
        UNDebugLogVerbose(@"initWithWidth")
        [self createLoadingView:width];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        UNDebugLogVerbose(@"initWithFrame")
        [self createLoadingView:0];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        UNDebugLogVerbose(@"initWithCoder")
        [self createLoadingView:0];
    }
    return self;
}

- (void)createLoadingView:(CGFloat)width
{
    if (self.loadingWidth) {
        return;
    }
    UNDebugLogVerbose(@"createLoadingView")
    self.loadingWidth = width;
    CGPoint centerPoint;
    if (width) {
        centerPoint = CGPointMake(width * 0.5, width * 0.5);
    }else{
        centerPoint = CGPointMake(CGRectGetWidth(self.frame) * 0.5, CGRectGetHeight(self.frame) * 0.5);
    }
    if (self.circleShapeLayer) {
        return;
    }
    //内部Layer
    CAShapeLayer *insideShapeLayer = [CAShapeLayer layer];
    self.circleShapeLayer = insideShapeLayer;
    CGPathRef insidePath = [UIBezierPath bezierPathWithArcCenter:centerPoint radius:centerPoint.x
                                                       startAngle:0 endAngle:M_PI * 2 clockwise:YES].CGPath;
    insideShapeLayer.path = insidePath;
    insideShapeLayer.strokeColor = kCircleColor.CGColor;
    insideShapeLayer.fillColor = [UIColor clearColor].CGColor;
    insideShapeLayer.strokeEnd = 1;
    insideShapeLayer.lineWidth = 2.0f;
    [self.layer addSublayer:insideShapeLayer];
    
    //外部Layer
    CAShapeLayer *outsideShapeLayer = [CAShapeLayer layer];
    self.outsideShapeLayer = outsideShapeLayer;
    CGPathRef outsidePath = [UIBezierPath bezierPathWithArcCenter:centerPoint radius:centerPoint.x + 1 startAngle:0 endAngle:M_PI * 2 clockwise:YES].CGPath;
    outsideShapeLayer.path = outsidePath;
    outsideShapeLayer.strokeColor = kCircleColor.CGColor;
    outsideShapeLayer.fillColor = [UIColor clearColor].CGColor;
    outsideShapeLayer.strokeEnd = 1;
    [self.layer addSublayer:outsideShapeLayer];
}

- (void)setBorderColor:(UIColor *)borderColor
{
    _borderColor = borderColor;
    self.circleShapeLayer.strokeColor = borderColor.CGColor;
}

- (void)setLineWidth:(CGFloat)lineWidth
{
    _lineWidth = lineWidth;
    self.circleShapeLayer.lineWidth = lineWidth;
}

- (void)startStrokeAnimate
{
    CAKeyframeAnimation *strokeEndAnima = [CAKeyframeAnimation animationWithKeyPath:@"strokeEnd"];
    strokeEndAnima.values = @[@0, @1];
    strokeEndAnima.beginTime = 0.0f;
    strokeEndAnima.duration = 1.0f;
    strokeEndAnima.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    strokeEndAnima.removedOnCompletion = NO;
    
    
    CAKeyframeAnimation *strokeStartAnima = [CAKeyframeAnimation animationWithKeyPath:@"strokeStart"];
    strokeStartAnima.values = @[@0, @1];
    strokeStartAnima.beginTime = 1.0f;
    strokeStartAnima.duration = 1.0f;
    strokeStartAnima.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    strokeStartAnima.removedOnCompletion = NO;
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.animations = @[strokeEndAnima, strokeStartAnima];
    animationGroup.duration = 2.0f;
    animationGroup.repeatCount = CGFLOAT_MAX;
    animationGroup.removedOnCompletion = NO;
    [self.circleShapeLayer addAnimation:animationGroup forKey:@"groupAnimation"];
}

- (void)startRotateAnimate
{
    CAKeyframeAnimation *rotateAnima = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotateAnima.values = @[@0, @(2 * M_PI)];
    rotateAnima.duration = 2.0f;
    rotateAnima.repeatCount = CGFLOAT_MAX;
    rotateAnima.removedOnCompletion = NO;
    [self.layer addAnimation:rotateAnima forKey:@"rotateAnimate"];
}

- (void)startAnimating
{
    if (self.isLoadAnimating) {
        [self stopAnimating];
    }
    self.loadAnimating = YES;
    [self startStrokeAnimate];
    [self startRotateAnimate];
}

- (void)stopAnimating
{
    if (self.isLoadAnimating) {
        [self.circleShapeLayer removeAllAnimations];
        [self.layer removeAllAnimations];
        self.loadAnimating = NO;
    }
}

@end
