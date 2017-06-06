//
//  CutomButton.m
//  unitoys
//
//  Created by 董杰 on 2017/3/20.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "CutomButton.h"

@implementation CutomButton

- (void)awakeFromNib
{
    [super awakeFromNib];
    if (!lineColor) {
        lineColor = [UIColor whiteColor];
    }
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        lineColor = [UIColor whiteColor];
    }
    return self;
}

-(void)setColor:(UIColor *)color{
    lineColor = [color copy];
    [self setNeedsDisplay];
}


- (void) drawRect:(CGRect)rect {
    [super drawRect:rect];
    if (!self.isHiddenLine) {
        CGRect textRect = self.titleLabel.frame;
        CGContextRef contextRef = UIGraphicsGetCurrentContext();
        
        CGFloat descender = self.titleLabel.font.descender;
        if([lineColor isKindOfClass:[UIColor class]]){
            CGContextSetStrokeColorWithColor(contextRef, lineColor.CGColor);
        }
        
        CGContextMoveToPoint(contextRef, textRect.origin.x, textRect.origin.y + textRect.size.height + descender+3);
        CGContextAddLineToPoint(contextRef, textRect.origin.x + textRect.size.width, textRect.origin.y + textRect.size.height + descender+3);
        
        CGContextClosePath(contextRef);
        CGContextDrawPath(contextRef, kCGPathStroke);
    }
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
