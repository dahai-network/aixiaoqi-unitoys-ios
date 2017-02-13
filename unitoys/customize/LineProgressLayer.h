//
//  LineProgressLayer.h
//  GLSX
//
//  Created by Carver Li on 14-12-1.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LineProgressLayer : CALayer

@property (nonatomic,assign) int total;
@property (nonatomic,strong) UIColor *color;
@property (nonatomic,assign) int completed;
//@property (nonatomic,strong) UIColor *completedColor;

@property (nonatomic,assign) CGFloat radius;
@property (nonatomic,assign) CGFloat innerRadius;

@property CGFloat startAngle;
@property CGFloat endAngle;

@property (nonatomic, assign) CFTimeInterval animationDuration;

@end

// 版权属于原作者
// http://code4app.com (cn) http://code4app.net (en)
// 发布代码于最专业的源码分享网站: Code4App.com 
