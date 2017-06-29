//
//  HLTitlesView.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AddTouchAreaButton;
typedef void(^TitlesButtonAction)(UIButton *);
@interface HLTitlesView : UIView

@property (nonatomic, weak) UIImageView *titleBottomView;
@property (nonatomic, weak) AddTouchAreaButton *selectButton;
@property (nonatomic, assign) NSInteger titleCount;

- (instancetype)initTitlesViewWithTitles:(NSArray *)titlesArray Margin:(CGFloat)margin;
+ (instancetype)titlesViewWithTitles:(NSArray *)titlesArray Margin:(CGFloat)margin;

//指定点击按钮
- (void)topButtonClick:(UIButton *)button;
//指定选择按钮
- (void)topButtonSelect:(UIButton *)button isAnimate:(BOOL)animate;

//改变挡墙选中Button
- (void)changeCurrentSelectButton;

//手动选择选中Button
- (void)setSelectButtonWithTag:(NSInteger)tag;

//显示标题栏小红点
- (void)showRedTipWithIndex:(NSInteger)buttonIndex;
//隐藏标题栏小红点
- (void)hiddenRedTipWithIndex:(NSInteger)buttonIndex;

@property (nonatomic, copy) TitlesButtonAction titlesButtonAction;

@end
