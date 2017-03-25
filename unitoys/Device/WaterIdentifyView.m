//
//
//  WaterIdentifyView.m
//
//  modifyed by mars on 16/12/2.
//

#import "WaterIdentifyView.h"

@implementation WaterIdentifyView
{
    CGRect fullRect;
    CGRect scaleRect;
    CGRect waveRect;
    
    CGFloat currentLinePointY;
    CGFloat targetLinePointY;
    CGFloat amplitude;//振幅
    
    CGFloat currentPercent;//但前百分比，用于保存第一次显示时的动画效果
    
    CGFloat a;
    CGFloat b;
    
    BOOL increase;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        fullRect = frame;
        
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    _scaleDivisionsLength = 10;
    _scaleDivisionsWidth = 2;
    _scaleCount = 100;
    
    a = 1.5;
    b = 0;
    increase = NO;
    
    _frontWaterColor = [UIColor colorWithRed:33/255.0 green:181/255.0 blue:33/255.0 alpha:1.00];
    _backWaterColor = [UIColor colorWithRed:21/255.0 green:135/255.0 blue:20/255.0 alpha:1.00];
    
    
    _waterBgColor = [UIColor colorWithRed:63/255.0 green:70/255.0 blue:85/255.0 alpha:1.00];
    _circleBgColor = [UIColor colorWithRed:42/255.0 green:48/255.0 blue:59/255.0 alpha:1.00];

    
    _percent = 0.45;
    
    _scaleMargin = -10;
    _waveMargin = 18;
    _showBgLineView = NO;
    self.labelStr = INTERNATIONALSTRING(@"剩余电量");
    
    [self initDrawingRects];
    
    [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(animateWave) userInfo:nil repeats:YES];
}

- (void)initDrawingRects
{
    CGFloat offset = _scaleMargin;
    scaleRect = CGRectMake(offset,
                           offset,
                           fullRect.size.width - 2 * offset,
                           fullRect.size.height - 2 * offset);
    
    offset = _scaleMargin + _waveMargin + _scaleDivisionsWidth;
    waveRect = CGRectMake(offset,
                          offset,
                          fullRect.size.width - 2 * offset,
                          fullRect.size.height - 2 * offset);
    
    currentLinePointY = waveRect.size.height;
    targetLinePointY = waveRect.size.height * (1 - _percent);
    amplitude = (waveRect.size.height / 320.0) * 10;
    
    [self setNeedsDisplay];
}

// 覆盖drawRect方法，你可以在此自定义绘画和动画
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self drawBackground:context];
    [self drawWave:context];
    [self drawLabel:context];
    
}



/**
 *  画波浪
 *
 *  @param context 全局context
 */
- (void)drawWave:(CGContextRef)context {
    
    CGMutablePathRef frontPath = CGPathCreateMutable();
    CGMutablePathRef backPath = CGPathCreateMutable();
    
    //画水
    CGContextSetLineWidth(context, 1);
    CGContextSetFillColorWithColor(context, [_frontWaterColor CGColor]);
    
    CGFloat offset = _scaleMargin + _waveMargin + _scaleDivisionsWidth;
    
    float frontY = currentLinePointY;
    float backY = currentLinePointY;
    
    CGFloat radius = waveRect.size.width / 2;
    
    CGPoint frontStartPoint = CGPointMake(offset, currentLinePointY + offset);
    CGPoint frontEndPoint = CGPointMake(offset, currentLinePointY + offset);
    
    CGPoint backStartPoint = CGPointMake(offset, currentLinePointY + offset);
    CGPoint backEndPoint = CGPointMake(offset, currentLinePointY + offset);
    
    for(float x = 0; x <= waveRect.size.width; x++){
        
        //前浪绘制
        frontY = a * sin( x / 180 * M_PI + 4 * b / M_PI ) * amplitude + currentLinePointY;
        
        CGFloat frontCircleY;
        if (currentLinePointY < radius) {
            frontCircleY = radius - sqrt(pow(radius, 2) - pow((radius - x), 2));
            if (frontY < frontCircleY) {
                frontY = frontCircleY;
            }
        } else if (currentLinePointY > radius) {
            frontCircleY = radius + sqrt(pow(radius, 2) - pow((radius - x), 2));
            if (frontY > frontCircleY) {
                frontY = frontCircleY;
            }
        }
        
        if (fabs(0 - x) < 0.001) {
            frontStartPoint = CGPointMake(x + offset, frontY + offset);
            CGPathMoveToPoint(frontPath, NULL, frontStartPoint.x, frontStartPoint.y);
        }
        
        frontEndPoint = CGPointMake(x + offset, frontY + offset);
        CGPathAddLineToPoint(frontPath, nil, frontEndPoint.x, frontEndPoint.y);
        
        //后波浪绘制
        backY = a * cos( x / 180 * M_PI + 3 * b / M_PI ) * amplitude + currentLinePointY;
        CGFloat backCircleY;
        if (currentLinePointY < radius) {
            backCircleY = radius - sqrt(pow(radius, 2) - pow((radius - x), 2));
            if (backY < backCircleY) {
                backY = backCircleY;
            }
        } else if (currentLinePointY > radius) {
            backCircleY = radius + sqrt(pow(radius, 2) - pow((radius - x), 2));
            if (backY > backCircleY) {
                backY = backCircleY;
            }
        }
        
        if (fabs(0 - x) < 0.001) {
            backStartPoint = CGPointMake(x + offset, backY + offset);
            CGPathMoveToPoint(backPath, NULL, backStartPoint.x, backStartPoint.y);
        }
        
        backEndPoint = CGPointMake(x + offset, backY + offset);
        CGPathAddLineToPoint(backPath, nil, backEndPoint.x, backEndPoint.y);
    }
    
    CGPoint centerPoint = CGPointMake(fullRect.size.width / 2, fullRect.size.height / 2);
    
    //绘制前浪圆弧
    CGFloat frontStart = [self calculateRotateDegree:centerPoint point:frontStartPoint];
    CGFloat frontEnd = [self calculateRotateDegree:centerPoint point:frontEndPoint];
    
    CGPathAddArc(frontPath, nil, centerPoint.x, centerPoint.y, waveRect.size.width / 2, frontEnd, frontStart, 0);
    CGContextAddPath(context, frontPath);
    CGContextFillPath(context);
    //推入
    CGContextSaveGState(context);
    CGContextDrawPath(context, kCGPathStroke);
    CGPathRelease(frontPath);
    
    
    //绘制后浪圆弧
    CGFloat backStart = [self calculateRotateDegree:centerPoint point:backStartPoint];
    CGFloat backEnd = [self calculateRotateDegree:centerPoint point:backEndPoint];
    
    CGPathAddArc(backPath, nil, centerPoint.x, centerPoint.y, waveRect.size.width / 2, backEnd, backStart, 0);
    
    CGContextSetFillColorWithColor(context, [_backWaterColor CGColor]);
    CGContextAddPath(context, backPath);
    CGContextFillPath(context);
    //推入
    CGContextSaveGState(context);
    CGContextDrawPath(context, kCGPathStroke);
    CGPathRelease(backPath);
    
}

/**
 *  画背景界面
 *
 *  @param context 全局context
 */
- (void)drawBackground:(CGContextRef)context {
    
    CGPoint centerPoint = CGPointMake(fullRect.size.width / 2, fullRect.size.height / 2);
    //画背景圆
    CGMutablePathRef outpath = CGPathCreateMutable();
    CGContextSetLineWidth(context, 1);
    CGContextSetFillColorWithColor(context, [_circleBgColor CGColor]);
    
    CGPathAddArc(outpath, nil, centerPoint.x, centerPoint.y, waveRect.size.width / 2+10, 0, 2 * M_PI, 0);
    
    CGContextAddPath(context, outpath);
    CGContextFillPath(context);
    CGContextDrawPath(context, kCGPathStroke);
    CGPathRelease(outpath);
    
    //画背景圆
    CGMutablePathRef path = CGPathCreateMutable();
    CGContextSetLineWidth(context, 1);
    CGContextSetFillColorWithColor(context, [_waterBgColor CGColor]);
    

    CGPathAddArc(path, nil, centerPoint.x, centerPoint.y, waveRect.size.width / 2, 0, 2 * M_PI, 0);
    
    CGContextAddPath(context, path);
    CGContextFillPath(context);
    CGContextDrawPath(context, kCGPathStroke);
    CGPathRelease(path);
    
    
}


- (void)drawLabel:(CGContextRef)context {
    
    NSMutableAttributedString *attriButedText = [self formatBatteryLevel:_percent * 100];
    CGRect textSize = [attriButedText boundingRectWithSize:CGSizeMake(400, 10000) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
    NSMutableAttributedString *attriLabelText = [self formatLabel:self.labelStr];
    CGRect labelSize = [attriLabelText boundingRectWithSize:CGSizeMake(400, 10000) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
    
    CGPoint textPoint = CGPointMake(fullRect.size.width / 2 - textSize.size.width / 2, fullRect.size.height / 2 - textSize.size.height / 2 - labelSize.size.height / 2);
    CGPoint labelPoint = CGPointMake(fullRect.size.width / 2 - labelSize.size.width / 2, textPoint.y + textSize.size.height);
    
    [attriButedText drawAtPoint:textPoint];
    [attriLabelText drawAtPoint:labelPoint];
    
    //推入
    CGContextSaveGState(context);
}

/**
 *  实时调用产生波浪的动画效果
 */
-(void)animateWave
{
    if (targetLinePointY == self.frame.size.height ||
        currentLinePointY == 0) {
        return;
    }
    
    if (targetLinePointY < currentLinePointY) {
        currentLinePointY -= 1;
        currentPercent = (waveRect.size.height - currentLinePointY) / waveRect.size.height;
    }
    
    if (targetLinePointY > currentLinePointY) {
        currentLinePointY += 1;
        currentPercent = (waveRect.size.height - currentLinePointY) / waveRect.size.height;
    }
    
    if (increase) {
        a += 0.01;
    } else {
        a -= 0.01;
    }
    
    
    if (a <= 1) {
        increase = YES;
    }
    
    if (a >= 1.5) {
        increase = NO;
    }
    
    b += 0.1;
    
    [self setNeedsDisplay];
}

/**
 * Core Graphics rotation in context
 */
- (void)rotateContext:(CGContextRef)context fromCenter:(CGPoint)center_ withAngle:(CGFloat)angle
{
    CGContextTranslateCTM(context, center_.x, center_.y);
    CGContextRotateCTM(context, angle);
    CGContextTranslateCTM(context, -center_.x, -center_.y);
}

/**
 *  根据圆心点和圆上一个点计算角度
 *
 *  @param centerPoint 圆心点
 *  @param point       圆上的一个点
 *
 *  @return 角度
 */
- (CGFloat)calculateRotateDegree:(CGPoint)centerPoint point:(CGPoint)point {
    
    CGFloat rotateDegree = asin(fabs(point.y - centerPoint.y) / (sqrt(pow(point.x - centerPoint.x, 2) + pow(point.y - centerPoint.y, 2))));
    
    //如果point纵坐标大于原点centerPoint纵坐标(在第一和第二象限)
    if (point.y > centerPoint.y) {
        //第一象限
        if (point.x >= centerPoint.x) {
            rotateDegree = rotateDegree;
        }
        //第二象限
        else {
            rotateDegree = M_PI - rotateDegree;
        }
    } else //第三和第四象限
    {
        if (point.x <= centerPoint.x) //第三象限，不做任何处理
        {
            rotateDegree = M_PI + rotateDegree;
        }
        else //第四象限
        {
            rotateDegree = 2 * M_PI - rotateDegree;
        }
    }
    return rotateDegree;
}

/**
 *  格式化电量的Label的字体
 *
 *  @param percent 百分比
 *
 *  @return 电量百分比文字参数
 */
-(NSMutableAttributedString *) formatBatteryLevel:(NSInteger)percent
{
    UIColor *textColor = [UIColor whiteColor];
    NSMutableAttributedString *attrText;
    
    NSString *percentText=[NSString stringWithFormat:@"%ld%%",(long)percent];
    
    NSMutableParagraphStyle *paragrahStyle = [[NSMutableParagraphStyle alloc] init];
    [paragrahStyle setAlignment:NSTextAlignmentCenter];
    if (percent<10) {
        attrText=[[NSMutableAttributedString alloc] initWithString:percentText];
        UIFont *capacityNumberFont=[UIFont fontWithName:@"HelveticaNeue-Bold" size:25];
        UIFont *capacityPercentFont=[UIFont fontWithName:@"HelveticaNeue-Bold" size:25];
        [attrText addAttribute:NSFontAttributeName value:capacityNumberFont range:NSMakeRange(0, 1)];
        [attrText addAttribute:NSFontAttributeName value:capacityPercentFont range:NSMakeRange(1, 1)];
        [attrText addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0, 2)];
        [attrText  addAttribute:NSParagraphStyleAttributeName value:paragrahStyle range:NSMakeRange(0, 2)];
        
    } else {
        attrText=[[NSMutableAttributedString alloc] initWithString:percentText];
        UIFont *capacityNumberFont=[UIFont fontWithName:@"HelveticaNeue-Bold" size:25];
        UIFont *capacityPercentFont=[UIFont fontWithName:@"HelveticaNeue-Bold" size:25];
        
        
        if (percent>=100) {
            
            [attrText addAttribute:NSFontAttributeName value:capacityNumberFont range:NSMakeRange(0, 3)];
            [attrText addAttribute:NSFontAttributeName value:capacityPercentFont range:NSMakeRange(3, 1)];
            [attrText addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0, 4)];
            [attrText addAttribute:NSParagraphStyleAttributeName value:paragrahStyle range:NSMakeRange(0, 4)];
        } else {
            [attrText addAttribute:NSFontAttributeName value:capacityNumberFont range:NSMakeRange(0, 2)];
            [attrText addAttribute:NSFontAttributeName value:capacityPercentFont range:NSMakeRange(2, 1)];
            [attrText addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0, 3)];
            [attrText  addAttribute:NSParagraphStyleAttributeName value:paragrahStyle range:NSMakeRange(0, 3)];
        }
        
    }
    
    
    return attrText;
}

/**
 *  显示信息Label参数
 *
 *  @param text 显示的文字
 *
 *  @return 相关参数
 */
-(NSMutableAttributedString *) formatLabel:(NSString*)text
{
    UIColor *textColor = [UIColor whiteColor];
    NSMutableAttributedString *attrText;
    NSMutableParagraphStyle *paragrahStyle = [[NSMutableParagraphStyle alloc] init];
    [paragrahStyle setAlignment:NSTextAlignmentCenter];
 
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];
    
    attrText=[[NSMutableAttributedString alloc] initWithString:text];
    [attrText addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, text.length)];
    [attrText addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0, text.length)];
    [attrText  addAttribute:NSParagraphStyleAttributeName value:paragrahStyle range:NSMakeRange(0, text.length)];
    
    return attrText;
}

#pragma mark - Setter

- (void)setPercent:(CGFloat)percent {
    _percent = percent;
    currentPercent = percent;
    targetLinePointY = waveRect.size.height * (1 - _percent);
    [self initDrawingRects];
}

- (void)setWaterBgColor:(UIColor *)waterBgColor {
    _waterBgColor = waterBgColor;
    [self initDrawingRects];
}

- (void)setFrontWaterColor:(UIColor *)frontWaterColor {
    _frontWaterColor = frontWaterColor;
    [self initDrawingRects];
}

- (void)setBackWaterColor:(UIColor *)backWaterColor {
    _backWaterColor = backWaterColor;
    [self initDrawingRects];
}

- (void)setShowBgLineView:(BOOL)showBgLineView {
    _showBgLineView = showBgLineView;
    [self initDrawingRects];
}

@end
