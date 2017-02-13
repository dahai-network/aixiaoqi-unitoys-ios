//
//  LineProgressLayer.m
//  Layer
//
//  Created by Carver Li on 14-12-1.
//
//

#import "LineProgressLayer.h"

@implementation LineProgressLayer

- (id)initWithLayer:(id)layer
{
    self = [super initWithLayer:layer];
    if (self)
    {
        if ([layer isKindOfClass:[LineProgressLayer class]])
        {
            LineProgressLayer *other = layer;
            self.total = other.total;
            self.color = other.color;
            self.completed = other.completed;
//            self.completedColor = other.completedColor;
            
            self.radius = other.radius;
            self.innerRadius = other.innerRadius;
            
            self.startAngle = other.startAngle;
            self.endAngle = other.endAngle;
            self.shouldRasterize = YES;
        }
    }
    
    return self;
}

+ (id)layer
{
    LineProgressLayer *result = [[LineProgressLayer alloc] init];
    
    return result;
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
    if ([key isEqualToString:@"completed"])
    {
        return YES;
    }
    
    return [super needsDisplayForKey:key];
}

- (void)drawInContext:(CGContextRef)contextRef
{
    CGFloat originalRadius = _radius;
    CGFloat totalAngle = _endAngle - _startAngle;
    
    CGRect rect = self.bounds;
    
    CGFloat x0 = (rect.size.width - 2*_radius)/2.0 + _radius;
    CGFloat y0 = (rect.size.height - 2*_radius)/2.0 + _radius;
    
    CGContextSetLineJoin(contextRef, kCGLineJoinRound);
    CGContextSetFlatness(contextRef, 2.0);
    CGContextSetAllowsAntialiasing(contextRef, true);
    CGContextSetShouldAntialias(contextRef, true);
    CGContextSetInterpolationQuality(contextRef, kCGInterpolationHigh);
    
    CGContextSetLineWidth(contextRef,2.0f);     //设置线条宽度
    
    
    for (int i = 0; i < _total; i++) {
//        CGContextMoveToPoint(contextRef, x0, y0);  //原始语句，下面做了修改
        
        CGContextMoveToPoint(contextRef, x0+cosf(_startAngle + totalAngle*i/_total)*_innerRadius, y0 + sinf(_startAngle + totalAngle*i/_total)*_innerRadius);
        
        
        
        CGFloat x = x0 + cosf(_startAngle + totalAngle*i/_total)*_radius;
        CGFloat y = y0 + sinf(_startAngle + totalAngle*i/_total)*_radius;
        
        
        
        
        CGContextAddLineToPoint(contextRef, x, y);
        CGContextSetStrokeColorWithColor(contextRef, _color.CGColor);   //设置颜色
        CGContextSetFillColorWithColor(contextRef, _color.CGColor);
        CGContextDrawPath(contextRef, kCGPathFillStroke);
    }
    
    for (int i = 0; i < _completed; i++) {
        
        UIColor *color = [UIColor colorWithRed:255/255.0 green:(1-i/(float)_total)*255/255.0 blue:(1-i/(float)_total)*255/255.0 alpha:1.0];
//        CGContextMoveToPoint(contextRef, x0, y0);    //原始语句，下面做了修改
        CGContextMoveToPoint(contextRef, x0+cosf(_startAngle + totalAngle*i/_total)*_innerRadius, y0 + sinf(_startAngle + totalAngle*i/_total)*_innerRadius);
        
        if (i + 1 == _completed) {
            _radius += 10;
        }
        else {
            _radius = originalRadius;
        }
        
        CGFloat x = x0 + cosf(_startAngle + totalAngle*i/_total)*_radius;
        CGFloat y = y0+ sinf(_startAngle + totalAngle*i/_total)*_radius;
        
        CGContextAddLineToPoint(contextRef, x, y);
        CGContextSetStrokeColorWithColor(contextRef, color.CGColor);  //设置完成颜色
        CGContextSetFillColorWithColor(contextRef, color.CGColor);
        CGContextDrawPath(contextRef, kCGPathFillStroke);
        
        if (i + 1 == _completed) {
            _radius = originalRadius;
            break;
        }
    }
    
    //画圆覆盖内部线条
    CGContextAddArc(contextRef, x0, y0, _innerRadius, 0, 2*M_PI, 0);
    CGContextSetFillColorWithColor(contextRef, CGColorCreateCopy(self.backgroundColor));
    CGContextSetStrokeColorWithColor(contextRef, [UIColor clearColor].CGColor);     //设置内圆无颜色
    CGContextDrawPath(contextRef, kCGPathFillStroke);
}

@end

// 版权属于原作者
// http://code4app.com (cn) http://code4app.net (en)
// 发布代码于最专业的源码分享网站: Code4App.com 
