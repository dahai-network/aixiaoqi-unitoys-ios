//
//  HLDragView.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/17.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "HLDragView.h"

@interface HLDragButton()

//是否已经拖拽过
@property (nonatomic, assign) BOOL isDragged;

@end

@implementation HLDragButton

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews
{
    self.userInteractionEnabled = YES;
    self.startPoint = CGPointMake(self.frame.origin.x, self.frame.origin.y);
    self.isDragged = NO;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint currentPoint = [[touches anyObject] locationInView:self];
    self.startPoint = currentPoint;
    self.startCenter = self.center;
    [self.superview bringSubviewToFront:self];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint currentPoint = [[touches anyObject] locationInView:self];
    CGFloat offsetX = currentPoint.x - self.startPoint.x;
    CGFloat offsetY = currentPoint.y - self.startPoint.y;
    CGPoint newCenter = CGPointMake(self.center.x + offsetX, self.center.y + offsetY);
    
    //设置拖动边界
    CGFloat midX = CGRectGetMidX(self.bounds);
    newCenter.x = MAX(midX, newCenter.x);
    newCenter.x = MIN(self.superview.bounds.size.width - midX, newCenter.x);
    CGFloat midY = CGRectGetMidY(self.bounds);
    newCenter.y = MAX(midY, newCenter.y);
    newCenter.y = MIN(self.superview.bounds.size.height - 49 - midY, newCenter.y);
    
    self.center = newCenter;
    //只要位移过大,直接设置为已拖动(不使用center计算是为了防止拖动了而控件center没变)
    if (fabs(offsetX) > 5.0 || fabs(offsetY) > 5.0) {
        if (!self.isDragged) {
            self.isDragged = YES;
        }
    }
//    CGPoint currentCenter = self.center;
//    CGFloat centerOffsetX = currentCenter.x - self.startCenter.x;
//    CGFloat centerOffsetY = currentCenter.y - self.startCenter.y;
//    if (fabs(centerOffsetX) > 2.0 || fabs(centerOffsetY) > 2.0) {
//        if (!self.isDragged) {
//            self.isDragged = YES;
//        }
//    }

//    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
//    CGPoint endPoint = [[touches anyObject] locationInView:self];
//    //计算总的偏移量.为了防止多次小距离拖动
//    CGFloat offsetX = endPoint.x - self.startPoint.x;
//    CGFloat offsetY = endPoint.y - self.startPoint.y;
    CGPoint currentCenter = self.center;
    CGFloat centerOffsetX = currentCenter.x - self.startCenter.x;
    CGFloat centerOffsetY = currentCenter.y - self.startCenter.y;
    if (fabs(centerOffsetX) > 2.0 || fabs(centerOffsetY) > 2.0) {
        self.isDragged = NO;
    }else{
        if (!self.isDragged) {
            [super touchesEnded:touches withEvent:event];
        }else{
            self.isDragged = NO;
        }
    }
    [self setHighlighted:NO];
}

@end
