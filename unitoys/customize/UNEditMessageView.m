//
//  UNEditMessageView.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/12.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNEditMessageView.h"
#import "UIView+Utils.h"

@interface UNEditMessageView()

@property (nonatomic, weak) UIButton *cancelButtn;
@property (nonatomic, weak) UIButton *deleteButtn;

@end

@implementation UNEditMessageView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews
{
    
    UIButton *deleteButtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.deleteButtn = deleteButtn;
    [deleteButtn setImage:[UIImage imageNamed:@"delete_msg_nor"] forState:UIControlStateNormal];
    [deleteButtn setImage:[UIImage imageNamed:@"delete_msg_pre"] forState:UIControlStateHighlighted];
    [deleteButtn addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];
    [deleteButtn sizeToFit];
    [self addSubview:deleteButtn];
    
    UIButton *cancelButtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cancelButtn = cancelButtn;
    [cancelButtn setImage:[UIImage imageNamed:@"exit_msg_nor"] forState:UIControlStateNormal];
    [cancelButtn setImage:[UIImage imageNamed:@"exit_msg_pre"] forState:UIControlStateHighlighted];
    [cancelButtn addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [cancelButtn sizeToFit];
    [self addSubview:cancelButtn];
}

- (void)cancelAction:(UIButton *)button
{
    if (self.editMessageActionBlock) {
        self.editMessageActionBlock(1);
    }
}

- (void)deleteAction:(UIButton *)button
{
    if (self.editMessageActionBlock) {
        self.editMessageActionBlock(0);
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.deleteButtn.centerY = self.height * 0.5;
    self.deleteButtn.right = self.width * 0.5 - 20;
    
    self.cancelButtn.centerY = self.height * 0.5;
    self.cancelButtn.left = self.width * 0.5 + 20;
}

@end
