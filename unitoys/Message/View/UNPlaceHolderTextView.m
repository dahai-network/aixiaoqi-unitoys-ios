//
//  UNPlaceHolderTextView.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/3.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNPlaceHolderTextView.h"

@implementation UNPlaceHolderTextView

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self initSubViews];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews
{
    self.placeholderColor = [UIColor lightGrayColor];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextViewTextDidChangeNotification object:self];
}

- (void)textDidChange:(NSNotification *)note
{
    [self setNeedsDisplay];
}

- (void)setPlaceholder:(NSString *)placeholder
{
    _placeholder = [placeholder copy];
    [self setNeedsDisplay];
}
- (void)setPlaceholderColor:(UIColor *)placeholderColor
{
    _placeholderColor = placeholderColor;
    [self setNeedsDisplay];
}
- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    [self setNeedsDisplay];
}
- (void)setText:(NSString *)text
{
    [super setText:text];
    [self setNeedsDisplay];
}
- (void)setAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    if (self.hasText) return;
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    attrs[NSFontAttributeName] = self.font;
    attrs[NSForegroundColorAttributeName] = self.placeholderColor;
    
    if (CGPointEqualToPoint(self.placeholderOrigin, CGPointZero)) {
        rect.origin.x = 5;
        rect.origin.y = 8;
    }else{
        rect.origin.x = self.placeholderOrigin.x + 5;
        rect.origin.y = self.placeholderOrigin.y;
    }
    rect.size.width -= 2 * rect.origin.x;
    [self.placeholder drawInRect:rect withAttributes:attrs];
}
- (void)layoutSubviews
{
    [super layoutSubviews];
    [self setNeedsDisplay];
}

- (void)setContentSize:(CGSize)contentSize
{
//    NSLog(@"selfContentSize:%@======contentSize:%@", NSStringFromCGSize(self.contentSize), NSStringFromCGSize(contentSize));
    [super setContentSize:contentSize];
    if (_placeHolderTextViewDelegate && [_placeHolderTextViewDelegate respondsToSelector:@selector(placeHolderTextViewContentSizeChange:)]) {
        [self.placeHolderTextViewDelegate placeHolderTextViewContentSizeChange:contentSize];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
