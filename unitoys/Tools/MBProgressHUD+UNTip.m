//
//  MBProgressHUD+UNTip.m
//  unitoys
//
//  Created by 黄磊 on 2017/3/31.
//  Copyright © 2017年 sumars. All rights reserved.
//

#define ShowTime 1.0
#define MessageTime 1.5

#import "MBProgressHUD+UNTip.h"

@implementation MBProgressHUD (UNTip)

+ (void)show:(NSString *)text icon:(NSString *)icon view:(UIView *)view
{
//    [self hideHUD];
    if (view == nil) view = [[UIApplication sharedApplication].windows lastObject];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.labelText = text;
    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"MBProgressHUD.bundle/%@", icon]]];
    hud.mode = MBProgressHUDModeCustomView;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:ShowTime];
}

+ (void)showSuccess:(NSString *)success
{
    [self showSuccess:success toView:nil];
}

+ (void)showSuccess:(NSString *)success toView:(UIView *)view
{
    [self show:success icon:@"success.png" view:view];
}

+ (void)showError:(NSString *)error
{
    [self showError:error toView:nil];
}

+ (void)showError:(NSString *)error toView:(UIView *)view{
    [self show:error icon:@"error.png" view:view];
}

+ (void)showMessage:(NSString *)message
{
    if (message.length > 8) {
        [self showMessage:message toView:nil isLongText:YES DelayTime:0];
    }else{
        [self showMessage:message toView:nil isLongText:NO DelayTime:0];
    }
}

+ (void)showLongMessage:(NSString *)message
{
    [self showMessage:message toView:nil isLongText:YES DelayTime:0];
}

+ (void)showMessage:(NSString *)message DelayTime:(CGFloat)time
{
    [self showMessage:message toView:nil isLongText:NO DelayTime:time];
}

+ (void)showMessage:(NSString *)message toView:(UIView *)view isLongText:(BOOL)isLong DelayTime:(CGFloat)time{
    if (view == nil) view = [[UIApplication sharedApplication].windows lastObject];
    // 快速显示一个提示信息
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = MBProgressHUDModeText;
    if (isLong) {
        hud.detailsLabelText = message;
        hud.detailsLabelFont = [UIFont systemFontOfSize:14];
    }else{
        hud.labelText = message;
    }
    hud.removeFromSuperViewOnHide = YES;
    // YES代表需要蒙版效果
//    hud.dimBackground = YES;
    if (time != 0) {
        [hud hide:YES afterDelay:time];
    }else{
        [hud hide:YES afterDelay:MessageTime];
    }
}

+ (void)showLoading
{
    [self showLoadingMessage:nil toView:nil];
}

+ (void)showLoadingWithMessage:(NSString *)message;
{
    [self showLoadingMessage:message toView:nil];
}

+ (void)showLoadingMessage:(NSString *)message toView:(UIView *)view
{
    if (view == nil) view = [[UIApplication sharedApplication].windows lastObject];
    // 快速显示一个提示信息
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    if (message) {
       hud.labelText = message;
    }
    // 隐藏时候从父控件中移除
    hud.removeFromSuperViewOnHide = YES;
    // YES代表需要蒙版效果
    hud.dimBackground = YES;
}

+ (void)showWarningWithMessage:(NSString *)message
{
    [self show:message icon:@"info.png" view:nil];
}

+ (void)hideHUD
{
    [self hideHUDForView:nil];
}

+ (void)hideHUDForView:(UIView *)view
{
    if (view == nil) view = [[UIApplication sharedApplication].windows lastObject];
    [self hideHUDForView:view animated:YES];
}

@end
