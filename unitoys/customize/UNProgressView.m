//
//  UNProgressView.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/22.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNProgressView.h"

@interface UNProgressView()

@property (nonatomic, strong) CAShapeLayer *shapeLayer;

@end

@implementation UNProgressView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initSubViews];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self  initSubViews];
}


- (void)initSubViews
{
    _shapeLayer = [CAShapeLayer layer];
    UIBezierPath *bezier = [UIBezierPath bezierPath];
    [bezier moveToPoint:CGPointMake(0, 0)];
    [bezier addLineToPoint:CGPointMake(self.frame.size.width, 0)];
    _shapeLayer.lineWidth = 3.0;
    _shapeLayer.path = bezier.CGPath;
    _shapeLayer.fillColor = [UIColor whiteColor].CGColor;
    _shapeLayer.strokeColor = DefultColor.CGColor;
    _shapeLayer.strokeEnd = 0;
    [self.layer addSublayer:_shapeLayer];
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    self.shapeLayer.strokeEnd = progress;
}

@end
