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
    [self hideMBHUD];
    if (view == nil) view = [[UIApplication sharedApplication].windows lastObject];
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *iconHud = [MBProgressHUD showHUDAddedTo:view animated:YES];
        iconHud.label.text = text;
        iconHud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"MBProgressHUD.bundle/%@", icon]]];
        iconHud.mode = MBProgressHUDModeCustomView;
        iconHud.removeFromSuperViewOnHide = YES;
//        iconHud.color = hudBackgroundColor;
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
    [self hideMBHUD];
    if (view == nil) view = [[UIApplication sharedApplication].windows lastObject];
    // 快速显示一个提示信息
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
        hud.mode = MBProgressHUDModeText;
        if (isLong) {
            hud.detailsLabel.text = message;
            hud.detailsLabel.font = [UIFont systemFontOfSize:14];
        }else{
            hud.label.text = message;
        }
//        hud.color = hudBackgroundColor;
        hud.removeFromSuperViewOnHide = YES;
        // YES代表需要蒙版效果
        //    hud.dimBackground = YES;
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
    [self hideMBHUD];
    if (view == nil) view = [[UIApplication sharedApplication].windows lastObject];
    // 快速显示一个提示信息
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
        if (message) {
            hud.label.text = message;
        }
//        hud.bezelView.color = hudBackgroundColor;
        // 隐藏时候从父控件中移除
        hud.removeFromSuperViewOnHide = YES;
        // YES代表需要蒙版效果
//        hud.dimBackground = YES;
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
    if (hud && hud.mode == modetype) {
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.progress = progress;
        });
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
//            [self hideMBHUD]
            [hud hideAnimated:NO];
            MBProgressHUD *progressHud = [MBProgressHUD showHUDAddedTo:view animated:YES];
            progressHud.mode = modetype;
            progressHud.progress = progress == 1.0 ? 0.99 : progress;
            progressHud.removeFromSuperViewOnHide = YES;
//            progressHud.color = hudBackgroundColor;
        });
    }
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
