//
//  LineProgressView.h
//  Layer
//
//  Created by Carver Li on 14-12-1.
//
//

#import <UIKit/UIKit.h>
#import "LineProgressLayer.h"

@class LineProgressViewDelegate;

@interface LineProgressView : UIView

@property (nonatomic,assign) int total;
@property (nonatomic,strong) UIColor *color;
@property (nonatomic,assign) int completed;
@property (nonatomic,strong) UIColor *completedColor;

@property (nonatomic,assign) CGFloat radius;
@property (nonatomic,assign) CGFloat innerRadius;

@property (nonatomic,assign) CGFloat startAngle;
@property (nonatomic,assign) CGFloat endAngle;

@property (nonatomic, assign) CFTimeInterval animationDuration;
@property (nonatomic) id delegate;

- (void)setCompleted:(int)completed animated:(BOOL)animated;

@end

@protocol LineProgressViewDelegate <NSObject>
@optional
- (void)LineProgressViewAnimationDidStart:(LineProgressView *)lineProgressView;
- (void)LineProgressViewAnimationDidStop:(LineProgressView *)lineProgressView;

@end
// 版权属于原作者
// http://code4app.com (cn) http://code4app.net (en)
// 发布代码于最专业的源码分享网站: Code4App.com 
