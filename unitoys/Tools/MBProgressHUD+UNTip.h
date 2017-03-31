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

/**
 *  隐藏提示
 */
+ (void)hideHUD;

@end
