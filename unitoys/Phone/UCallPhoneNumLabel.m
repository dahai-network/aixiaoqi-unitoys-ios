//
//  UCallPhoneNumLabel.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UCallPhoneNumLabel.h"
#import "UIView+Utils.h"
#import "AddTouchAreaButton.h"
#import "global.h"
#import "UNConvertFormatTool.h"

@implementation UCallPhoneNumLabel

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initSubViews];
    }
    return self;
}

- (void)setIsCanTouch:(BOOL)isCanTouch
{
    _isCanTouch = isCanTouch;
    if (isCanTouch) {
        _phonelabel.userInteractionEnabled = YES;
        UILongPressGestureRecognizer *pressRe = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(pressAction:)];
        [_phonelabel addGestureRecognizer:pressRe];
    }
}

- (BOOL)canBecomeFirstResponder{
    return _isCanTouch;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender{
    
    if (action ==@selector(copy:)){
        return YES;
    }
    else if (action ==@selector(paste:)){
        return YES;
    }
    return NO;
}

- (void)pressAction:(UILongPressGestureRecognizer *)press
{
    [self becomeFirstResponder];
    UIMenuController *menu = [UIMenuController sharedMenuController];
    [menu setTargetRect:self.frame inView:self.superview];
    [menu setMenuVisible:YES animated:YES];
}

-(void)copy:(id)sender{
    if (_phonelabel.text && ![_phonelabel.text isEqualToString:@""]) {
        UIPasteboard *pboard = [UIPasteboard generalPasteboard];
        pboard.string = _phonelabel.text;
    }
}


- (void)paste:(id)sender{
    UIPasteboard *pboard = [UIPasteboard generalPasteboard];
    NSString *pasteString = [UNConvertFormatTool getNumStringWithString:pboard.string];
    [self updatePhoneLabel:pasteString currentNum:pasteString];
}

- (void)initSubViews
{
    self.backgroundColor = [UIColor whiteColor];
    UIView *topLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, 1)];
    topLineView.backgroundColor = UIColorFromRGB(0xf2f2f2);
    [self addSubview:topLineView];
    
    _phonelabel = [[UILabel alloc] init];
    _phonelabel.numberOfLines = 1;
    _phonelabel.font = [UIFont systemFontOfSize:24];
    _phonelabel.textColor = UIColorFromRGB(0x333333);
    _phonelabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_phonelabel];
    
    _deleteButton = [AddTouchAreaButton buttonWithType:UIButtonTypeCustom];
    _deleteButton.touchEdgeInset = UIEdgeInsetsMake(10, 10, 10, 10);
    [_deleteButton setImage:[UIImage imageNamed:@"icon_del_nor"] forState:UIControlStateNormal];
    _deleteButton.un_width = 60;
    _deleteButton.un_height = self.un_height;
    [_deleteButton addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_deleteButton];
}

- (void)updatePhoneLabel:(NSString *)phone currentNum:(NSString *)number
{
    if ([self isFirstResponder]) {
        [self resignFirstResponder];
    }
    if (phone) {
        _phonelabel.text = [phone copy];
    }else{
        _phonelabel.text = @"";
    }
    [self currentLabelText:_phonelabel.text currentNum:number];
}

- (void)deleteAction:(UIButton *)button
{
    if ([self isFirstResponder]) {
        UNDebugLogVerbose(@"当前为第一响应者")
        [self resignFirstResponder];
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    }
    if (_phonelabel.text.length > 1) {
        _phonelabel.text = [_phonelabel.text substringToIndex:_phonelabel.text.length - 1];
    }else{
        _phonelabel.text = @"";
    }
    [self currentLabelText:_phonelabel.text currentNum:@"DEL"];
}

- (void)currentLabelText:(NSString *)text currentNum:(NSString *)number
{
    UNDebugLogVerbose(@"当前输入文字---%@",text)
    if (_phoneLabelChangeBlock) {
        _phoneLabelChangeBlock(text,number);
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _deleteButton.un_right = self.un_width;
    _deleteButton.un_centerY = self.un_height * 0.5;
    
    _phonelabel.frame = CGRectMake(0, 0, _deleteButton.un_left, self.un_height);
}

@end
