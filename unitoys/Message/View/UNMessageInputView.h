//
//  UNMessageInputView.h
//  unitoys
//
//  Created by 黄磊 on 2017/6/3.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UIMessageInputViewDelegate;

@interface UNMessageInputView : UIView<UITextViewDelegate>
@property (nonatomic, copy) NSString *placeHolder;
@property (nonatomic, weak) id<UIMessageInputViewDelegate> delegate;
@property (nonatomic, assign) CGFloat bottomHeight;

+ (instancetype)messageInputViewWithPlaceHolder:(NSString *)placeHolder;
- (void)prepareToShowWithAnimate:(BOOL)isAnimate;
- (void)prepareToDismissWithAnimate:(BOOL)isAnimate;
- (BOOL)isAndResignFirstResponder;
- (BOOL)notAndBecomeFirstResponder;
- (BOOL)isCustomFirstResponder;

- (void)sendMessageSuccess;
- (void)sendMessageField;

- (void)showInputView:(void (^ __nullable)(BOOL finished))completion;
- (void)hideInputView:(void (^ __nullable)(BOOL finished))completion;
@end


@protocol UIMessageInputViewDelegate <NSObject>
@optional
//发送文字
- (BOOL)messageInputView:(UNMessageInputView *)inputView sendText:(NSString *)text;
//底部高度改变
- (void)messageInputView:(UNMessageInputView *)inputView BottomViewHeightChanged:(CGFloat)BottomViewHeight;
@end
