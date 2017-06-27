//
//  UCallPhonePadView.h
//  unitoys
//
//  Created by 黄磊 on 2017/2/16.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UCallPhoneNumLabel.h"

@interface UCallPhonePadView : UIView

+ (instancetype)callPhonePadViewWithFrame:(CGRect)frame IsTransparentBackground:(BOOL)isTransparent;

- (instancetype)initWithFrame:(CGRect)frame IsTransparentBackground:(BOOL)isTransparent;

@property (nonatomic, strong) UCallPhoneNumLabel *phoneNumLabel;

@property (nonatomic, copy) NSString *currentInputNum;

@property (copy,nonatomic) NSString *inputedPhoneNumber;

@property (nonatomic, assign) BOOL isHideDelLabel;

//是否能够点击(弹出复制粘贴功能)
@property (nonatomic, assign) BOOL isCanTouch;

//typedef void (^UCallInputCompletedBlock)(NSString *btnText,NSInteger btnTag);
typedef void (^UCallInputCompletedBlock)(NSString *btnText, NSString *currentNum);
@property (nonatomic,copy)UCallInputCompletedBlock completeBlock;

- (void)showCallView;
- (void)hideCallView;

- (void)showCallViewNoDelLabel;
- (void)hideCallViewNoDelLabel;

@end
