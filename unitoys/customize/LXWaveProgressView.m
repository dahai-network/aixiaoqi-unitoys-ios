//
//  LXWaveProgressView.m
//  LXWaveProgressDemo
//
//  Created by liuxin on 16/8/1.
//  Copyright © 2016年 liuxin. All rights reserved.
//
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define LXDefaultFirstWaveColor [UIColor colorWithRed:29/255.0 green:156/255.0 blue:254/255.0 alpha:0.4]
//#define LXDefaultSecondWaveColor [UIColor colorWithRed:34/255.0 green:116/255.0 blue:210/255.0 alpha:0.3]
//#define LXDefaultSecondWaveColor [UIColor colorWithRed:207/255.0 green:237/255.0 blue:255/255.0 alpha:1]

#import "LXWaveProgressView.h"
#import "YYWeakProxy.h"

@interface LXWaveProgressView ()
@property (nonatomic,assign)CGFloat yHeight;
@property (nonatomic,assign)CGFloat offset;
@property (nonatomic,strong)CADisplayLink * timer;
@property (nonatomic,strong)CAShapeLayer * firstWaveLayer;
@property (nonatomic,strong)CAShapeLayer * secondWaveLayer;
@property (nonatomic,strong)CAShapeLayer * thirdWaveLayer;

@end

@implementation LXWaveProgressView

- (instancetype)initWithFrame:(CGRect)frame
{
    self.waveNum = 3;
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColorFromRGB(0x98d4ff);
        self.bounds = CGRectMake(0, 0, MIN(frame.size.width, frame.size.height), MIN(frame.size.width, frame.size.height));
        self.layer.cornerRadius = MIN(frame.size.width, frame.size.height) * 0.5;
        self.layer.masksToBounds = YES;
        self.layer.borderColor = [UIColor whiteColor].CGColor;
        self.layer.borderWidth = 3.0f;
        
        self.waveHeight = 5.0;
        self.firstWaveColor = LXDefaultFirstWaveColor;
        self.secondWaveColor = LXDefaultFirstWaveColor;
        self.thirdWaveColor = LXDefaultFirstWaveColor;
        self.yHeight = self.bounds.size.height;
        self.speed=1.0;
        
        [self.layer addSublayer:self.firstWaveLayer];
        switch (self.waveNum) {
            case 2:
                [self.layer addSublayer:self.secondWaveLayer];
                break;
            case 3:
                [self.layer addSublayer:self.secondWaveLayer];
                [self.layer addSublayer:self.thirdWaveLayer];
                break;
            default:
                break;
        }
        
        [self addSubview:self.progressLabel];
        [self addSubview:self.subTitleLabel];
        [self addSubview:self.batteryView];
        
        
       
    }
    return self;
}



-(void)setProgress:(CGFloat)progress
{
    _progress = progress;
    _progressLabel.text = [NSString stringWithFormat:@"%ld%%",[[NSNumber numberWithFloat:progress * 100] integerValue]];
//    _progressLabel.textColor=[UIColor colorWithWhite:progress*1.8 alpha:1];
    _progressLabel.textColor=[UIColor whiteColor];
    self.yHeight = self.bounds.size.height * (1 - progress);
    
    if (progress <= 0.5) {
        self.waveHeight=5+progress;
        self.speed=progress+0.5;
    } else {
        self.waveHeight=5+(1-progress);
        self.speed=(1-progress)+0.5;
    }


    [self stopWaveAnimation];
    [self startWaveAnimation];
}

#pragma mark -- 开始波动动画
- (void)startWaveAnimation
{
    self.timer = [CADisplayLink displayLinkWithTarget:[YYWeakProxy proxyWithTarget:self] selector:@selector(waveAnimation)];
    [self.timer addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
   
}


#pragma mark -- 停止波动动画
- (void)stopWaveAnimation
{
    
    [self.timer invalidate];
    self.timer = nil;
}

#pragma mark -- 波动动画实现
- (void)waveAnimation
{
    CGFloat waveHeight = self.waveHeight;
    if (self.progress == 0.0f || self.progress == 1.0f) {
        waveHeight = 0.f;
    }

    self.offset += self.speed;
    //第一个波纹
    CGMutablePathRef pathRef = CGPathCreateMutable();
    CGFloat startOffY = waveHeight * sinf(self.offset * M_PI * 2 / self.bounds.size.width);
    CGFloat orignOffY = 0.0;
    CGPathMoveToPoint(pathRef, NULL, 0, startOffY);
    for (CGFloat i = 0.f; i <= self.bounds.size.width; i++) {
        orignOffY = waveHeight * sinf(2 * M_PI / self.bounds.size.width * i + self.offset * M_PI * 2 / self.bounds.size.width) + self.yHeight;
        CGPathAddLineToPoint(pathRef, NULL, i, orignOffY);
    }
    
    CGPathAddLineToPoint(pathRef, NULL, self.bounds.size.width, orignOffY);
    CGPathAddLineToPoint(pathRef, NULL, self.bounds.size.width, self.bounds.size.height);
    CGPathAddLineToPoint(pathRef, NULL, 0, self.bounds.size.height);
    CGPathAddLineToPoint(pathRef, NULL, 0, startOffY);
    CGPathCloseSubpath(pathRef);
    self.firstWaveLayer.path = pathRef;
    self.firstWaveLayer.fillColor = self.firstWaveColor.CGColor;
    CGPathRelease(pathRef);
    
    switch (self.waveNum) {
        case 2:
        {
            CGMutablePathRef pathRef1 = CGPathCreateMutable();
            CGFloat startOffY1 = waveHeight * sinf(self.offset * M_PI * 2 / self.bounds.size.width);
            CGFloat orignOffY1 = 0.0;
            CGPathMoveToPoint(pathRef1, NULL, 0, startOffY1);
            for (CGFloat i = 0.f; i <= self.bounds.size.width; i++) {
                orignOffY1 = waveHeight * cosf(2 * M_PI / self.bounds.size.width * i + self.offset * M_PI * 2 / self.bounds.size.width) + self.yHeight;
                CGPathAddLineToPoint(pathRef1, NULL, i, orignOffY1);
            }
            
            CGPathAddLineToPoint(pathRef1, NULL, self.bounds.size.width, orignOffY1);
            CGPathAddLineToPoint(pathRef1, NULL, self.bounds.size.width, self.bounds.size.height);
            CGPathAddLineToPoint(pathRef1, NULL, 0, self.bounds.size.height);
            CGPathAddLineToPoint(pathRef1, NULL, 0, startOffY1);
            CGPathCloseSubpath(pathRef1);
            self.secondWaveLayer.path = pathRef1;
            self.secondWaveLayer.fillColor = self.secondWaveColor.CGColor;
            
            CGPathRelease(pathRef1);
        }
            break;
        case 3:
        {
            //第二个
            CGMutablePathRef pathRef1 = CGPathCreateMutable();
            CGFloat startOffY1 = waveHeight * sinf(self.offset * M_PI * 2 / self.bounds.size.width);
            CGFloat orignOffY1 = 0.0;
            CGPathMoveToPoint(pathRef1, NULL, 0, startOffY1);
            for (CGFloat i = 0.f; i <= self.bounds.size.width; i++) {
                orignOffY1 = waveHeight * cosf(2 * M_PI / self.bounds.size.width * i + self.offset * M_PI * 2 / self.bounds.size.width) + self.yHeight;
                CGPathAddLineToPoint(pathRef1, NULL, i, orignOffY1);
            }
            
            CGPathAddLineToPoint(pathRef1, NULL, self.bounds.size.width, orignOffY1);
            CGPathAddLineToPoint(pathRef1, NULL, self.bounds.size.width, self.bounds.size.height);
            CGPathAddLineToPoint(pathRef1, NULL, 0, self.bounds.size.height);
            CGPathAddLineToPoint(pathRef1, NULL, 0, startOffY1);
            CGPathCloseSubpath(pathRef1);
            self.secondWaveLayer.path = pathRef1;
            self.secondWaveLayer.fillColor = self.secondWaveColor.CGColor;
            
            CGPathRelease(pathRef1);
            
            //第三个
            CGMutablePathRef pathRef2 = CGPathCreateMutable();
            CGFloat startOffY2 = waveHeight * sinf(self.offset * M_PI * 2 / self.bounds.size.width);
            CGFloat orignOffY2 = 0.0;
            CGPathMoveToPoint(pathRef2, NULL, 0, startOffY2);
            for (CGFloat i = 0.f; i <= self.bounds.size.width; i++) {
                orignOffY2 = waveHeight * cosf(3 * M_PI / self.bounds.size.width * i + self.offset * M_PI * 2 / self.bounds.size.width) + self.yHeight;
                CGPathAddLineToPoint(pathRef2, NULL, i, orignOffY2);
            }
            
            CGPathAddLineToPoint(pathRef2, NULL, self.bounds.size.width, orignOffY2);
            CGPathAddLineToPoint(pathRef2, NULL, self.bounds.size.width, self.bounds.size.height);
            CGPathAddLineToPoint(pathRef2, NULL, 0, self.bounds.size.height);
            CGPathAddLineToPoint(pathRef2, NULL, 0, startOffY2);
            CGPathCloseSubpath(pathRef2);
            self.thirdWaveLayer.path = pathRef2;
            self.thirdWaveLayer.fillColor = self.thirdWaveColor.CGColor;
            
            CGPathRelease(pathRef2);
        }
            break;
        default:
            break;
    }
    
}

#pragma mark ----- INITUI ----
-(CAShapeLayer *)firstWaveLayer{
    if (!_firstWaveLayer) {
        _firstWaveLayer = [CAShapeLayer layer];
        _firstWaveLayer.frame = self.bounds;
        _firstWaveLayer.fillColor = _firstWaveColor.CGColor;
    }
    return _firstWaveLayer;
}

-(CAShapeLayer *)secondWaveLayer{
    if (!_secondWaveLayer) {
        _secondWaveLayer = [CAShapeLayer layer];
        _secondWaveLayer.frame = self.bounds;
        _secondWaveLayer.fillColor = _secondWaveColor.CGColor;
    }
    return _secondWaveLayer;
}

-(CAShapeLayer *)thirdWaveLayer{
    if (!_thirdWaveLayer) {
        _thirdWaveLayer = [CAShapeLayer layer];
        _thirdWaveLayer.frame = self.bounds;
        _thirdWaveLayer.fillColor = _thirdWaveColor.CGColor;
    }
    return _thirdWaveLayer;
}

-(UILabel *)progressLabel{
    if (!_progressLabel) {
        _progressLabel=[[UILabel alloc] init];
        _progressLabel.text=@"0%";
        _progressLabel.frame=CGRectMake(0, 0, self.bounds.size.width, 30);
        _progressLabel.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)+10);
        _progressLabel.font=[UIFont systemFontOfSize:26];
        _progressLabel.textColor=[UIColor whiteColor];
        _progressLabel.textAlignment=1;
    }
    return _progressLabel;
}

- (UIImageView *)batteryView {
    if (!_batteryView) {
        _batteryView = [[UIImageView alloc] init];
        float height = self.progressLabel.un_height-10;
        _batteryView.frame = CGRectMake(0, 0, height*2, height);
        _batteryView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)+10);
        _batteryView.image = [UIImage imageNamed:@"battery"];
        _batteryView.hidden = YES;
    }
    return _batteryView;
}

-(UILabel *)subTitleLabel{
    if (!_subTitleLabel) {
        _subTitleLabel=[[UILabel alloc] init];
        _subTitleLabel.text=@"剩余电量";
        _subTitleLabel.frame=CGRectMake(0, 0, self.bounds.size.width, 30);
        _subTitleLabel.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)-15);
        _subTitleLabel.font=[UIFont systemFontOfSize:14];
        _subTitleLabel.textColor=[UIColor whiteColor];
        _subTitleLabel.textAlignment=1;
    }
    return _subTitleLabel;
}



-(void)dealloc{
    
    [self.timer invalidate];
    self.timer = nil;
    
    if (_firstWaveLayer) {
        [_firstWaveLayer removeFromSuperlayer];
        _firstWaveLayer = nil;
    }
    
    if (_secondWaveLayer) {
        [_secondWaveLayer removeFromSuperlayer];
        _secondWaveLayer = nil;
    }
    
    if (_thirdWaveLayer) {
        [_thirdWaveLayer removeFromSuperlayer];
        _thirdWaveLayer = nil;
    }
}


@end
