//
//  UNMessageInputView.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/3.
//  Copyright © 2017年 sumars. All rights reserved.
//

#define kKeyboardView_Height 216.0
#define kMessageInputView_Height 50.0
#define kMessageInputView_HeightMax 120.0
#define kMessageInputView_PadingHeight 7.0
#define kMessageInputView_PaddingLeftWidth 15.0

#import "UNMessageInputView.h"
#import "UNPlaceHolderTextView.h"
#import <Masonry/Masonry.h>

@interface UNMessageInputView()<UNPlaceHolderTextViewDelegate>

@property (strong, nonatomic) UIScrollView *contentView;
@property (strong, nonatomic) UNPlaceHolderTextView *inputTextView;
@property (assign, nonatomic) CGFloat viewHeightOld;

@end

@implementation UNMessageInputView

- (void)setFrame:(CGRect)frame{
    CGFloat oldheightToBottom = kScreenHeightValue - CGRectGetMinY(self.frame);
    CGFloat newheightToBottom = kScreenHeightValue - CGRectGetMinY(frame);
    [super setFrame:frame];
    if (fabs(oldheightToBottom - newheightToBottom) > 0.1) {
        DebugUNLog(@"heightToBottom-----:%.2f", newheightToBottom);
        if (_delegate && [_delegate respondsToSelector:@selector(messageInputView:BottomViewHeightChanged:)]) {
            [self.delegate messageInputView:self BottomViewHeightChanged:newheightToBottom];
        }
    }
}

- (void)setPlaceHolder:(NSString *)placeHolder{
    _placeHolder = placeHolder;
    if (_inputTextView && ![_inputTextView.placeholder isEqualToString:placeHolder]) {
        _inputTextView.placeholder = placeHolder;
    }
}

+ (instancetype)messageInputViewWithPlaceHolder:(NSString *)placeHolder
{
    UNMessageInputView *messageInputView = [[UNMessageInputView alloc] initWithFrame:CGRectMake(0, kScreenHeightValue, kScreenWidthValue, kMessageInputView_Height)];
    
    return messageInputView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = DefualtBackgroundColor;
        _viewHeightOld = CGRectGetHeight(frame);
        [self customUI];
    }
    return self;
}

- (void)customUI
{
    CGFloat contentViewHeight = kMessageInputView_Height -2*kMessageInputView_PadingHeight;
    if (!_contentView) {
        _contentView = [[UIScrollView alloc] init];
        _contentView.backgroundColor = [UIColor whiteColor];
        _contentView.layer.borderWidth = 0.5;
        _contentView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        _contentView.layer.cornerRadius = contentViewHeight/2;
        _contentView.layer.masksToBounds = YES;
        _contentView.alwaysBounceVertical = YES;
        [self addSubview:_contentView];
        [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self).insets(UIEdgeInsetsMake(kMessageInputView_PadingHeight, kMessageInputView_PaddingLeftWidth, kMessageInputView_PadingHeight, kMessageInputView_PaddingLeftWidth));
        }];
    }
    
    if (!_inputTextView) {
        _inputTextView = [[UNPlaceHolderTextView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue - 2 * kMessageInputView_PaddingLeftWidth , contentViewHeight)];
        _inputTextView.font = [UIFont systemFontOfSize:16];
        _inputTextView.returnKeyType = UIReturnKeySend;
        _inputTextView.scrollsToTop = NO;
        _inputTextView.delegate = self;
        //输入框缩进
        UIEdgeInsets insets = _inputTextView.textContainerInset;
        insets.left += 8.0;
        insets.right += 8.0;
        _inputTextView.textContainerInset = insets;
        [self.contentView addSubview:_inputTextView];
    }
    
    if (_inputTextView) {
        _inputTextView.placeHolderTextViewDelegate = self;
    }
}

#pragma mark Public M
- (void)prepareToShow
{
    if ([self superview] == kKeyWindow) {
        return;
    }
    [self setUn_top:kScreenHeightValue];
    [kKeyWindow addSubview:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    if (![self isCustomFirstResponder]) {
        [UIView animateWithDuration:0.25 animations:^{
            [self setUn_top:kScreenHeightValue - CGRectGetHeight(self.frame)];
        }];
    }
}

- (void)prepareToDismiss
{
    if ([self superview] == nil) {
        return;
    }
    [self isAndResignFirstResponder];
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionTransitionFlipFromBottom animations:^{
        [self setUn_top:kScreenHeightValue];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)isAndResignFirstResponder
{
    if ([_inputTextView isFirstResponder]) {
        [_inputTextView resignFirstResponder];
        return YES;
    }else{
        return NO;
    }
}
- (BOOL)notAndBecomeFirstResponder{
    if ([_inputTextView isFirstResponder]) {
        return NO;
    }else{
        [_inputTextView becomeFirstResponder];
        return YES;
    }
}

- (BOOL)isCustomFirstResponder
{
    return [_inputTextView isFirstResponder];
}

- (void)sendMessageSuccess
{
    self.inputTextView.text = @"";
    [self isAndResignFirstResponder];
    //按钮可点击
}
- (void)sendMessageField
{
    //按钮可点击
}

- (void)placeHolderTextViewContentSizeChange:(CGSize)contentSize
{
    [self updateContentView];
}

- (void)updateContentView
{
    CGSize textSize = _inputTextView.contentSize;
    if (ABS(CGRectGetHeight(_inputTextView.frame) - textSize.height) > 0.5) {
        [_inputTextView setUn_height:textSize.height];
    }
    if (_contentView.isHidden) {
        textSize.height = kMessageInputView_Height - 2*kMessageInputView_PadingHeight;
    }
    CGSize contentSize = CGSizeMake(textSize.width, textSize.height);
    CGFloat selfHeight = MAX(kMessageInputView_Height, contentSize.height + 2*kMessageInputView_PadingHeight);
    CGFloat maxSelfHeight = kScreenHeightValue/5;
    if (kDevice_Is_iPhone5){
        maxSelfHeight = 140;
    }else if (kDevice_Is_iPhone6) {
        maxSelfHeight = 200;
    }else if (kDevice_Is_iPhone6Plus){
        maxSelfHeight = 250;
    }
    selfHeight = MIN(maxSelfHeight, selfHeight);
    
    CGFloat diffHeight = selfHeight - _viewHeightOld;
    if (ABS(diffHeight) > 0.5) {
        CGRect selfFrame = self.frame;
        selfFrame.size.height += diffHeight;
        selfFrame.origin.y -= diffHeight;
        [self setFrame:selfFrame];
        self.viewHeightOld = selfHeight;
    }
    [self.contentView setContentSize:contentSize];
    
    CGFloat bottomY = textSize.height;
    CGFloat offsetY = MAX(0, bottomY - (CGRectGetHeight(self.frame)- 2* kMessageInputView_PadingHeight));
    [self.contentView setContentOffset:CGPointMake(0, offsetY) animated:YES];
}

- (void)sendTextStr{
    NSMutableString *sendStr = [NSMutableString stringWithString:self.inputTextView.text];
    if (sendStr && ![sendStr isEqualToString:@""] && _delegate && [_delegate respondsToSelector:@selector(messageInputView:sendText:)]) {
        [self.delegate messageInputView:self sendText:sendStr];
    }
    _inputTextView.selectedRange = NSMakeRange(0, _inputTextView.text.length);
    [_inputTextView insertText:@""];
    [self updateContentView];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([text isEqualToString:@"\n"]) {
        [self sendTextStr];
        return NO;
    }
    return YES;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    return YES;
}
- (BOOL)textViewShouldEndEditing:(UITextView *)textView{

    [UIView animateWithDuration:0.25 delay:0.0f options:UIViewAnimationOptionTransitionFlipFromBottom animations:^{
        [self setUn_top:kScreenHeightValue- CGRectGetHeight(self.frame)];
    } completion:^(BOOL finished) {
    }];
    return YES;
}
#pragma mark - KeyBoard Notification Handlers
- (void)keyboardChange:(NSNotification*)aNotification{
    if ([aNotification name] == UIKeyboardDidChangeFrameNotification) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidChangeFrameNotification object:nil];
    }
    if ([self.inputTextView isFirstResponder]) {
        NSDictionary* userInfo = [aNotification userInfo];
        CGRect keyboardEndFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGFloat keyboardY =  keyboardEndFrame.origin.y;
        
        CGFloat selfOriginY = keyboardY == kScreenHeightValue? kScreenHeightValue - CGRectGetHeight(self.frame) : keyboardY - CGRectGetHeight(self.frame);
//        if (keyboardY == kScreenHeightValue) {
//            selfOriginY = kScreenHeightValue- CGRectGetHeight(self.frame);
//        }else{
//            selfOriginY = keyboardY-CGRectGetHeight(self.frame);
//        }
        if (selfOriginY == self.frame.origin.y) {
            return;
        }
        __weak typeof(self) weakSelf = self;
        void (^endFrameBlock)() = ^(){
            [weakSelf setUn_top:selfOriginY];
        };
        if ([aNotification name] == UIKeyboardWillChangeFrameNotification) {
            NSTimeInterval animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
            UIViewAnimationCurve animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
            [UIView animateWithDuration:animationDuration delay:0.0f options:[self animationOptionsForCurve:animationCurve] animations:^{
                endFrameBlock();
            } completion:nil];
        }else{
            endFrameBlock();
        }
    }
}


- (UIViewAnimationOptions)animationOptionsForCurve:(UIViewAnimationCurve)curve
{
    switch (curve) {
        case UIViewAnimationCurveEaseInOut:
            return UIViewAnimationOptionCurveEaseInOut;
            break;
        case UIViewAnimationCurveEaseIn:
            return UIViewAnimationOptionCurveEaseIn;
            break;
        case UIViewAnimationCurveEaseOut:
            return UIViewAnimationOptionCurveEaseOut;
            break;
        case UIViewAnimationCurveLinear:
            return UIViewAnimationOptionCurveLinear;
            break;
    }
    
    return kNilOptions;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
