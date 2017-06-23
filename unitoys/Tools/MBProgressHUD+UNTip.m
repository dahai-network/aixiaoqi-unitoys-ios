//
//  MBProgressHUD+UNTip.m
//  unitoys
//
//  Created by 黄磊 on 2017/3/31.
//  Copyright © 2017年 sumars. All rights reserved.
//

#define ShowTime 1.0
#define MessageTime 1.5

#define hudBackgroundColor [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]

#import "MBProgressHUD+UNTip.h"

@implementation MBProgressHUD (UNTip)

+ (void)show:(NSString *)text icon:(NSString *)icon view:(UIView *)view
{
    if (view == nil) view = [[UIApplication sharedApplication].windows lastObject];
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *iconHud = [MBProgressHUD HUDForView:view];
        if (!iconHud) {
            iconHud = [MBProgressHUD showHUDAddedTo:view animated:YES];
        }
        iconHud.mode = MBProgressHUDModeCustomView;
        iconHud.minSize = CGSizeMake(100, 100);
        iconHud.label.text = text;
        iconHud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"MBProgressHUD.bundle/%@", icon]]];
        iconHud.removeFromSuperViewOnHide = YES;
        [iconHud hideAnimated:YES afterDelay:ShowTime];
    });
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
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD HUDForView:view];
        if (!hud) {
            hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
        }
        hud.mode = MBProgressHUDModeText;
        if (isLong) {
            hud.detailsLabel.text = message;
            hud.detailsLabel.font = [UIFont systemFontOfSize:14];
        }else{
            hud.label.text = message;
        }
        hud.removeFromSuperViewOnHide = YES;
        if (time != 0) {
            [hud hideAnimated:YES afterDelay:time];
        }else{
            [hud hideAnimated:YES afterDelay:MessageTime];
        }
    });
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
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD HUDForView:view];
        if (!hud) {
            hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
        }
        hud.mode = MBProgressHUDModeIndeterminate;
        if (message) {
            hud.label.text = message;
        }
        // 隐藏时候从父控件中移除
        hud.removeFromSuperViewOnHide = YES;
    });

}

+ (void)showWarningWithMessage:(NSString *)message
{
    [self show:message icon:@"info.png" view:nil];
}

+ (void)showLoadingWithProgress:(double)progress ProgressType:(UNProgressType)type
{
    [self showLoadingWithProgress:progress ProgressType:type toView:nil];
}

+ (void)showLoadingWithProgress:(double)progress ProgressType:(UNProgressType)type toView:(UIView *)view
{
    if (view == nil) view = [[UIApplication sharedApplication].windows lastObject];
    MBProgressHUD *hud = [MBProgressHUD HUDForView:view];
    if (!hud) {
        hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    }
    MBProgressHUDMode modetype;
    switch (type) {
        case UNProgressTypeAnnularDeterminate:
            modetype = MBProgressHUDModeAnnularDeterminate;
            break;
        case UNProgressTypeDeterminate:
            modetype = MBProgressHUDModeDeterminate;
            break;
        case UNProgressTypeDeterminateHorizontalBar:
            modetype = MBProgressHUDModeDeterminateHorizontalBar;
            break;
        default:
            modetype = MBProgressHUDModeAnnularDeterminate;
            break;
    }
    hud.mode = modetype;
    hud.progress = progress == 1.0 ? 0.99 : progress;
    hud.removeFromSuperViewOnHide = YES;
}

+ (void)hideMBHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideHUDForView:nil];
    });
}

+ (void)hideHUDForView:(UIView *)view
{
    if (view == nil) view = [[UIApplication sharedApplication].windows lastObject];
    MBProgressHUD *hiddenHud = [MBProgressHUD HUDForView:view];
    if (hiddenHud) {
        [hiddenHud hideAnimated:NO];
//        [MBProgressHUD hideHUDForView:view animated:YES];
    }
}

@end
