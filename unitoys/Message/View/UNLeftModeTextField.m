//
//  UNLeftModeTextField.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/3.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNLeftModeTextField.h"

@implementation UNLeftModeTextField

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initSubViews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews
{
    self.leftViewWidth = 5;
    [self setUpLeftViewWithTextFrame:self.frame];
}

- (void)setUpLeftViewWithTextFrame:(CGRect)frame
{
    CGRect leftFrame = frame;
    leftFrame.size.width = self.leftViewWidth;
    UIView *leftView = [[UIView alloc] initWithFrame:leftFrame];
    self.leftViewMode = UITextFieldViewModeAlways;
    self.leftView = leftView;
}

- (void)setLeftViewWidth:(CGFloat)leftViewWidth
{
    _leftViewWidth = leftViewWidth;
    [self setUpLeftViewWithTextFrame:self.frame];
}


@end
