//
//  HLTitlesView.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^TitlesButtonAction)(UIButton *);
@interface HLTitlesView : UIView

- (instancetype)initTitlesViewWithTitles:(NSArray *)titlesArray Margin:(CGFloat)margin;
+ (instancetype)titlesViewWithTitles:(NSArray *)titlesArray Margin:(CGFloat)margin;

- (void)topButtonClick:(UIButton *)button;
//- (void)topButtonSelect:(UIButton *)button;
- (void)topButtonSelect:(UIButton *)button isAnimate:(BOOL)animate;

@property (nonatomic, copy) TitlesButtonAction titlesButtonAction;

@end
