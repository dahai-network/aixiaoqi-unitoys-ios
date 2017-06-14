//
//  MBProgressHUD+UNTip.h
//  unitoys
//
//  Created by 黄磊 on 2017/3/31.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>

@interface MBProgressHUD (UNTip)

/**
 *  加载成功提示信息
 *
 *  @param success 成功提示文字
 */
+ (void)showSuccess:(NSString *)success;
/**
 *  加载失败提示信息
 *
 *  @param success 失败提示文字
 */
+ (void)showError:(NSString *)error;
/**
 *  加载提示信息
 *
 *  @param success 提示文字
 */
+ (void)showMessage:(NSString *)message;
/**
 *  加载提示信息(长文本)
 *
 *  @param success 提示文字
 */
+ (void)showLongMessage:(NSString *)message;
/**
 *  加载提示信息
 *
 *  @param message 提示文字
 *  @param time    时间
 */
+ (void)showMessage:(NSString *)message DelayTime:(CGFloat)time;

/**
 *  加载提示信息
 *
 *  @param message 提示文字
 *  @param view    superView
 *  @param isLong  是否为长文字
 *  @param time    持续时间
 */
+ (void)showMessage:(NSString *)message toView:(UIView *)view isLongText:(BOOL)isLong DelayTime:(CGFloat)time;

/**
 *  加载提示信息
 *
 *  @param text 提示文字
 *  @param icon 提示图片
 *  @param view superView
 */
+ (void)show:(NSString *)text icon:(NSString *)icon view:(UIView *)view;


//正在加载不会自动隐藏
/**
 *  正在加载
 */
+ (void)showLoading;
/**
 *  正在加载
 *
 *  @param message 正在加载提示文字
 */
+ (void)showLoadingWithMessage:(NSString *)message;
/**
 *  加载警告信息
 *
 *  @param message 警告信息提示
 */
+ (void)showWarningWithMessage:(NSString *)message;



typedef NS_ENUM(NSUInteger, UNProgressType) {
    UNProgressTypeAnnularDeterminate = 1, //圆形外层填充
    UNProgressTypeDeterminate = 2,  //圆形内层填充
    UNProgressTypeDeterminateHorizontalBar = 3, //直线填充
};
/**
 加载进度条

 @param progress 进度
 @param type 类型
 */
+ (void)showLoadingWithProgress:(double)progress ProgressType:(UNProgressType)type;
+ (void)showLoadingWithProgress:(double)progress ProgressType:(UNProgressType)type toView:(UIView *)view;

/**
 *  隐藏提示
 */
+ (void)hideMBHUD;

@end
