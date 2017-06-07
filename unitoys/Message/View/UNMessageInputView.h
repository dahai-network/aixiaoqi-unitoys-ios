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

+ (instancetype)messageInputViewWithPlaceHolder:(NSString *)placeHolder;
- (void)prepareToShow;
- (void)prepareToDismiss;
- (BOOL)isAndResignFirstResponder;

- (void)sendMessageSuccess;
- (void)sendMessageField;
@end


@protocol UIMessageInputViewDelegate <NSObject>
@optional
//发送文字
- (void)messageInputView:(UNMessageInputView *)inputView sendText:(NSString *)text;
//底部高度改变
- (void)messageInputView:(UNMessageInputView *)inputView BottomViewHeightChanged:(CGFloat)BottomViewHeight;
@end
