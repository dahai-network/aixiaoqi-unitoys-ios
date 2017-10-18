//
//  HLTitlesView.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "HLTitlesView.h"
#import "UIView+Utils.h"
#import "AddTouchAreaButton.h"

#import "UIView+UNRedTip.h"


#define UIColorFromHex_hl(hexValue) [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16))/255.0 green:((float)((hexValue & 0xFF00) >> 8))/255.0 blue:((float)(hexValue & 0xFF))/255.0 alpha:1]

@interface HLTitlesView ()

@property (nonatomic, assign) CGFloat margin;
@end


@implementation HLTitlesView

- (instancetype)initTitlesViewWithTitles:(NSArray *)titlesArray Margin:(CGFloat)margin
{
    if (self = [super init]) {
        [self initSubViewsWithTitlesArray:titlesArray Margin:margin];
    }
    return self;
}

+ (instancetype)titlesViewWithTitles:(NSArray *)titlesArray Margin:(CGFloat)margin
{
    HLTitlesView *titlesView = [[HLTitlesView alloc] initTitlesViewWithTitles:titlesArray Margin:margin];
    return titlesView;
}

- (void)initSubViewsWithTitlesArray:(NSArray *)titlesArray Margin:(CGFloat)margin
{
    if (margin == 0) {
        margin = 10;
    }
    self.margin = margin;
    self.titleCount = titlesArray.count;
    UIImageView *titleBottomView = [[UIImageView alloc] init];
//    titleBottomView.backgroundColor = UIColorFromHex_hl(0x42a5f5);
//    titleBottomView.layer.cornerRadius = 1;
//    titleBottomView.layer.masksToBounds = YES;
    titleBottomView.image = [UIImage imageNamed:@"title_icon"];
    [titleBottomView sizeToFit];
    _titleBottomView = titleBottomView;
    [self addSubview:titleBottomView];
    
    CGFloat titlesViewW = 0;
    for (int i = 0; i < titlesArray.count; i++) {
        NSString *currentStr = INTERNATIONALSTRING(titlesArray[i]);
        CGFloat titleW = [currentStr boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:17]} context:nil].size.width;
        
        AddTouchAreaButton *button = [AddTouchAreaButton buttonWithType:UIButtonTypeCustom];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:17];
        [button setTitle:currentStr forState:UIControlStateNormal];
//        [button setTitleColor:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1] forState:UIControlStateNormal];
//        [button setTitleColor:UIColorFromHex_hl(0x42a5f5) forState:UIControlStateSelected];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.frame = CGRectMake(titlesViewW, 10, titleW + margin, 20);
        button.touchEdgeInset = UIEdgeInsetsMake(15, 10, 15, 10);
        button.tag = i;
        [button addTarget:self action:@selector(topButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        if (i == 0) {
            [self topButtonSelect:button isAnimate:NO];
        }
        titlesViewW += (titleW + margin);
    }
    
    self.frame = CGRectMake(0, 0, titlesViewW, 45);
    
    NSString *fristStr = titlesArray[0];
    CGFloat fristStrW = [fristStr boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:17]} context:nil].size.width;

    titleBottomView.un_bottom = self.frame.size.height;
    
    CGPoint titleBottomCenter = titleBottomView.center;
    titleBottomCenter.x = (fristStrW + margin) * 0.5;
    titleBottomView.center = titleBottomCenter;
}

- (void)topButtonSelect:(AddTouchAreaButton *)button isAnimate:(BOOL)animate
{
    if (button.isSelected) return;
    self.selectButton.selected = NO;
    self.selectButton= button;
    button.selected = YES;
    if (animate) {
        [UIView animateWithDuration:0.3 animations:^{
            CGPoint titleBottomCenter = self.titleBottomView.center;
            titleBottomCenter = CGPointMake(button.center.x, titleBottomCenter.y);
            self.titleBottomView.center = titleBottomCenter;
        }];
    }else{
        CGPoint titleBottomCenter = self.titleBottomView.center;
        titleBottomCenter = CGPointMake(button.center.x, titleBottomCenter.y);
        self.titleBottomView.center = titleBottomCenter;
    }
}

- (void)topButtonClick:(AddTouchAreaButton *)button
{
    if (button.isSelected) return;
    [self topButtonSelect:button isAnimate:YES];
    if (_titlesButtonAction) {
        _titlesButtonAction(button);
    }
}

- (void)changeCurrentSelectButton
{
    if (self.selectButton) {
        NSInteger nextTag;
        if (self.selectButton.tag == self.titleCount - 1) {
            nextTag = 0;
        }else{
            nextTag = self.selectButton.tag + 1;
        }
        [self setSelectButtonWithTag:nextTag];
    }else{
        [self setSelectButtonWithTag:0];
    }
}

- (void)setSelectButtonWithTag:(NSInteger)tag
{
    AddTouchAreaButton *button;
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[AddTouchAreaButton class]] && view.tag == tag) {
            button = (AddTouchAreaButton *)view;
            break;
        }
    }
    if (button) {
        [self topButtonClick:button];
    }
}

- (void)showRedTipWithIndex:(NSInteger)buttonIndex
{
    AddTouchAreaButton *button;
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[AddTouchAreaButton class]] && view.tag == buttonIndex) {
            button = (AddTouchAreaButton *)view;
            break;
        }
    }
    if (button) {
        [button showBadgeWithRightMargin:self.margin * 0.5 TopMargin:0];
    }
}
- (void)hiddenRedTipWithIndex:(NSInteger)buttonIndex
{
    AddTouchAreaButton *button;
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[AddTouchAreaButton class]] && view.tag == buttonIndex) {
            button = (AddTouchAreaButton *)view;
            break;
        }
    }
    if (button) {
        [button hideBadge];
    }
}

@end
