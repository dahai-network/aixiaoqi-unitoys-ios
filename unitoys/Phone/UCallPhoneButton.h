//
//  UCallPhoneButton.h
//  unitoys
//
//  Created by 黄磊 on 2017/2/16.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^PhoneButtonLongPressAction)(NSString *topTitle, NSString *bottomTitle);

@interface UCallPhoneButton : UIControl

+ (instancetype)callPhoneButtonWithTopTitle:(NSString *)topTitle BottomTitle:(NSString *)bottomTitle IsCanLongPress:(BOOL)isCanLongPress;

- (instancetype)initWithCallPhoneButtonWithTopTitle:(NSString *)topTitle BottomTitle:(NSString *)bottomTitle IsCanLongPress:(BOOL)isCanLongPress;

@property (nonatomic, copy) PhoneButtonLongPressAction phoneButtonLongPressAction;

@property (nonatomic, readonly) NSString *topTitle;
@property (nonatomic, readonly) NSString *bottomTitle;

@property (nonatomic, assign) BOOL isTransparent;

@end
