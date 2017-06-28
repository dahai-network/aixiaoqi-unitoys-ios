//
//  UNCheckPhoneAuth.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/28.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNCheckPhoneAuth.h"
#import <CoreLocation/CoreLocation.h>
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreTelephony/CTCellularData.h>
#import "BlueToothDataManager.h"

@interface UNCheckPhoneAuth()

@end

@implementation UNCheckPhoneAuth

+ (void)checkCurrentAuth
{
    //检查定位权限
    [self checkLocationAuth];
    //检查相册权限
    [self checkPhotoAuth];
    //检查麦克风权限
    [self checkMicPhoneAuth];
    //检查相机权限
    [self checkCameraAuth];
    //检查通知权限
    [self checkNotiAuth];
    //检查后台刷新权限
    [self checkBackgroundRefreshAuth];
    //检查网络权限
    [self checkNetworkAuth];
    //检测蓝牙权限
    [self checkLBEAuth];
}

//检查定位权限
+ (void)checkLocationAuth
{
    BOOL isLocation = [CLLocationManager locationServicesEnabled];
    if (!isLocation) {
        UNLogLBEProcess(@"定位权限 --> 定位功能未开启");
    }
    CLAuthorizationStatus CLstatus = [CLLocationManager authorizationStatus];
    switch (CLstatus) {
        case kCLAuthorizationStatusAuthorizedAlways:
            UNLogLBEProcess(@"定位权限 --> 始终开启 Always Authorized");
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            UNLogLBEProcess(@"定位权限 --> 使用时开启 AuthorizedWhenInUse");
            break;
        case kCLAuthorizationStatusDenied:
            UNLogLBEProcess(@"定位权限 --> 关闭 Denied");
            break;
        case kCLAuthorizationStatusNotDetermined:
            UNLogLBEProcess(@"定位权限 --> 未授权 not Determined");
            break;
        case kCLAuthorizationStatusRestricted:
            UNLogLBEProcess(@"定位权限 --> 无权限 Restricted");
            break;
        default:
            break;
    }
}

//检查相册权限
+ (void)checkPhotoAuth
{
    PHAuthorizationStatus photoAuthorStatus = [PHPhotoLibrary authorizationStatus];
    switch (photoAuthorStatus) {
        case PHAuthorizationStatusAuthorized:
            UNLogLBEProcess(@"相册权限 --> 开启 Authorized");
            break;
        case PHAuthorizationStatusDenied:
            UNLogLBEProcess(@"相册权限 --> 关闭 Denied");
            break;
        case PHAuthorizationStatusNotDetermined:
            UNLogLBEProcess(@"相册权限 --> 未授权 not Determined");
            break;
        case PHAuthorizationStatusRestricted:
            UNLogLBEProcess(@"相册权限 --> 无权限 Restricted");
            break;
        default:
            break;
    }
}

//检查麦克风权限
+ (void)checkMicPhoneAuth
{
    AVAuthorizationStatus AVMicrophonestatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (AVMicrophonestatus) {
        case AVAuthorizationStatusAuthorized:
            UNLogLBEProcess(@"麦克风权限 --> 开启 Authorized");
            break;
        case AVAuthorizationStatusDenied:
            UNLogLBEProcess(@"麦克风权限 --> 关闭 Denied");
            break;
        case AVAuthorizationStatusNotDetermined:
            UNLogLBEProcess(@"麦克风权限 --> 未授权 not Determined");
            break;
        case AVAuthorizationStatusRestricted:
            UNLogLBEProcess(@"麦克风权限 --> 无权限 Restricted");
            break;
        default:
            break;
    }
}

//检查相机权限
+ (void)checkCameraAuth
{
    AVAuthorizationStatus AVCamerastatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];//相机权限
    switch (AVCamerastatus) {
        case AVAuthorizationStatusAuthorized:
            UNLogLBEProcess(@"相机权限 --> 开启 Authorized");
            break;
        case AVAuthorizationStatusDenied:
            UNLogLBEProcess(@"相机权限 --> 关闭 Denied");
            break;
        case AVAuthorizationStatusNotDetermined:
            UNLogLBEProcess(@"相机权限 --> 未授权 not Determined");
            break;
        case AVAuthorizationStatusRestricted:
            UNLogLBEProcess(@"相机权限 --> 无权限 Restricted");
            break;
        default:
            break;
    }
}

//检查通知权限
+ (void)checkNotiAuth
{
    UIUserNotificationType notifiType = [[UIApplication sharedApplication] currentUserNotificationSettings].types;
    switch (notifiType) {
        case UIUserNotificationTypeNone:
            UNLogLBEProcess(@"通知权限 --> UIUserNotificationTypeNone");
            break;
        case UIUserNotificationTypeBadge:
            UNLogLBEProcess(@"通知权限 --> UIUserNotificationTypeBadge");
            break;
        case UIUserNotificationTypeSound:
            UNLogLBEProcess(@"通知权限 --> UIUserNotificationTypeSound");
            break;
        case UIUserNotificationTypeAlert:
            UNLogLBEProcess(@"通知权限 --> UIUserNotificationTypeAlert");
            break;
        default:
            UNLogLBEProcess(@"通知权限 --> 这是什么鬼类型 %lu", (unsigned long)notifiType);
            break;
    }
}

//检查后台刷新权限
+ (void)checkBackgroundRefreshAuth
{
    if ([UIApplication sharedApplication].backgroundRefreshStatus == UIBackgroundRefreshStatusDenied) {
        UNLogLBEProcess(@"后台应用刷新权限 --> 关闭 UIBackgroundRefreshStatusDenied");
    } else if ([UIApplication sharedApplication].backgroundRefreshStatus == UIBackgroundRefreshStatusRestricted) {
        UNLogLBEProcess(@"后台应用刷新权限 --> 无权限 UIBackgroundRefreshStatusRestricted");
    } else if ([UIApplication sharedApplication].backgroundRefreshStatus == UIBackgroundRefreshStatusAvailable) {
        UNLogLBEProcess(@"后台应用刷新权限 --> 开启 UIBackgroundRefreshStatusAvailable");
    } else {
        UNLogLBEProcess(@"后台应用刷新权限 --> 未知类型");
    }
}

//检查网络权限
+ (void)checkNetworkAuth
{
    CTCellularData *cellularData = [[CTCellularData alloc]init];
    cellularData.cellularDataRestrictionDidUpdateNotifier = ^(CTCellularDataRestrictedState state)
    { //获取联网状态
        switch (state)
        {
            case kCTCellularDataRestricted:
                UNLogLBEProcess(@"无线数据权限 --> 关闭 Restricrted");
                break;
            case kCTCellularDataNotRestricted:
                UNLogLBEProcess(@"无线数据权限 --> 开启 Not Restricted");
                break;
                //未知，第一次请求
            case kCTCellularDataRestrictedStateUnknown:
                UNLogLBEProcess(@"无线数据权限 --> 未授权 Unknown");
                break;
            default:
                break;
        };
    };
}

+ (void)checkLBEAuth
{
    if (![BlueToothDataManager shareManager].isOpened) {
        UNLogLBEProcess(@"蓝牙未开");
    }
    if (![BlueToothDataManager shareManager].isConnected) {
        UNLogLBEProcess(@"蓝牙未连接");
    }
}

@end
