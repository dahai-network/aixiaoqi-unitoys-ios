//
//  ThroughLineLabel.m
//  unitoys
//
//  Created by 董杰 on 2017/6/21.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "ThroughLineLabel.h"

@implementation ThroughLineLabel

//- (void)drawRect:(CGRect)rect
//{
//    // 调用super的drawRect:方法,会按照父类绘制label的文字
//    [super drawRect:rect];
////
////    // 取文字的颜色作为删除线的颜色
////    [self.textColor set];
////    CGFloat w = rect.size.width;
////    CGFloat h = rect.size.height;
////    // 绘制(这个数字是为了找到label的中间位置,0.35这个数字是试出来的,如果不在中间可以自己调整)
////    UIRectFill(CGRectMake(0, h * 0.5, w, 1));
//    // 1 获取上下文
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    // 2 设置线条颜色
//    [self.textColor setStroke];
//    // 3 线的起点
//    NSRange textRang;
//    if ([self.text containsString:@"原价"]) {
//        textRang = [self.text rangeOfString:@"原价"];
//    }
//    CGFloat y = rect.size.height * 0.5;
//    CGContextMoveToPoint(context, textRang.location, y);
//    // 4 短标题,根据字体确定宽度
//    CGSize size = [self.text sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:self.font,NSFontAttributeName, nil]];
//    // 5 线的终点 所以换行出问题了
//    CGContextAddLineToPoint(context, size.width, y);
//    // 6 最后渲染上去
//    CGContextStrokePath(context);
//}

- (void)drawTextInRect:(CGRect)rect
{
    [super drawTextInRect:rect];
    self.strikeThroughColor = self.textColor;
    
    CGSize textSize = [[self text] sizeWithFont:[self font]];
    
    NSLog(@"______textSize = %@ , ______rect = %@",NSStringFromCGSize(textSize),NSStringFromCGRect(rect));
    
    CGFloat strikeWidth = textSize.width;
    
    CGRect lineRect;
    
    if ([self textAlignment] == NSTextAlignmentRight)
    {
        // 画线居中
        lineRect = CGRectMake(rect.size.width - strikeWidth, rect.size.height/2, strikeWidth, 1);
        
        // 画线居下
        //lineRect = CGRectMake(rect.size.width - strikeWidth, rect.size.height/2 + textSize.height/2, strikeWidth, 1);
    }
    else if ([self textAlignment] == NSTextAlignmentCenter)
    {
        // 画线居中
        lineRect = CGRectMake(rect.size.width/2 - strikeWidth/2, rect.size.height/2, strikeWidth, 1);
        
        // 画线居下
        //lineRect = CGRectMake(rect.size.width/2 - strikeWidth/2, rect.size.height/2 + textSize.height/2, strikeWidth, 1);
    }
    else
    {
        // 画线居中
        lineRect = CGRectMake(0, rect.size.height/2, strikeWidth, 1);
        
        // 画线居下
        //lineRect = CGRectMake(0, rect.size.height/2 + textSize.height/2, strikeWidth, 1);
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [self strikeThroughColor].CGColor);
    
    CGContextFillRect(context, lineRect);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
