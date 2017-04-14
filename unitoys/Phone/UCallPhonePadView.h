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

//typedef void (^UCallInputCompletedBlock)(NSString *btnText,NSInteger btnTag);
typedef void (^UCallInputCompletedBlock)(NSString *btnText, NSString *currentNum);
@property (nonatomic,copy)UCallInputCompletedBlock completeBlock;

- (void)showCallView;
- (void)hideCallView;

- (void)showCallViewNoDelLabel;
- (void)hideCallViewNoDelLabel;

@end
