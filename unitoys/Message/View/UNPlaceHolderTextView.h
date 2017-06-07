//
//  UNPlaceHolderTextView.h
//  unitoys
//
//  Created by 黄磊 on 2017/6/3.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UNPlaceHolderTextViewDelegate <NSObject>

- (void)placeHolderTextViewContentSizeChange:(CGSize)contentSize;

@end

@interface UNPlaceHolderTextView : UITextView
//占位文字颜色
@property (nonatomic, strong) UIColor *placeholderColor;
//占位文字
@property (nonatomic, copy) NSString *placeholder;
//占位文字位置
@property(nonatomic, assign) CGPoint placeholderOrigin;

@property (nonatomic, weak) id<UNPlaceHolderTextViewDelegate> placeHolderTextViewDelegate;

@end
