//
//  UNCreatLocalNoti.m
//  unitoys
//
//  Created by 黄磊 on 2017/3/3.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNCreatLocalNoti.h"
#import <UIKit/UIKit.h>

@implementation UNCreatLocalNoti

+ (void)createLocalNotiMessage:(NSDictionary *)dict
{
#if DEBUG
    [self creatLocalNoti:dict];
#endif
}

+ (void)createLocalNotiMessageString:(NSString *)string
{
#if DEBUG
    NSLog(@"Noti---%@", string);
    [self creatLocalNoti:@{@"name" : string, @"phone" : @"123456789"}];
#endif
}

+ (void)creatLocalNoti:(NSDictionary *)dict
{
    NSDictionary *infoDic = [NSDictionary dictionaryWithObject:dict[@"phone"] forKey:@"phone"];
    UILocalNotification *backgroudMsg = [[UILocalNotification alloc] init];
    if (backgroudMsg) {
        backgroudMsg.timeZone = [NSTimeZone defaultTimeZone];
        backgroudMsg.alertBody = [NSString stringWithFormat:@"%@来电", dict[@"name"]];
        backgroudMsg.alertAction = dict[@"phone"];
        backgroudMsg.repeatInterval = 0;
        backgroudMsg.applicationIconBadgeNumber = 0;
        //标记通知信息
        backgroudMsg.userInfo = infoDic;
        //        [[UIApplication sharedApplication] presentLocalNotificationNow:backgroudMsg];
        [[UIApplication sharedApplication] scheduleLocalNotification:backgroudMsg];
    }
}

//蓝牙关闭通知
+ (void)createLBECloseNoti
{
    [self createNotiWithNoteString:@"蓝牙未开,将可能无法接收到电话和短信" NotiTypeString:@"LBECloseTime"];
}
//蓝牙断开连接通知
+ (void)createLBEDisConnectNoti
{
    [self createNotiWithNoteString:@"无法搜索到蓝牙,将可能无法接收到电话和短信" NotiTypeString:@"LBEDisConnectTime"];
}
//网络断开或较差通知
+ (void)createNETDisConnectNoti
{
    [self createNotiWithNoteString:@"网络不稳定,将可能无法接收到电话和短信" NotiTypeString:@"NETDisConnectTime"];
}

+ (void)createNotiWithNoteString:(NSString *)noteString NotiTypeString:(NSString *)typeString
{
    NSLog(@"noteString--%@,typeString--%@", noteString, typeString);
    NSString *timeStr = [[NSUserDefaults standardUserDefaults] objectForKey:typeString];
    NSTimeInterval timeValue = 0.0;
    if (timeStr != nil) {
        CGFloat dataTime = [timeStr doubleValue];
        NSDate *dataDate = [NSDate dateWithTimeIntervalSince1970:dataTime];
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSinceNow];
        timeValue = currentTime - [dataDate timeIntervalSinceNow];
    }else{
        timeValue = 700;
    }

    NSLog(@"时间差为---%f", timeValue);
    //判断时间限制
    if (timeValue > 600) {
        //存储新的时间数据
        NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
        NSString *timeString = [NSString stringWithFormat:@"%f", time];
        [[NSUserDefaults standardUserDefaults] setObject:timeString forKey:typeString];
        //发送通知
        [self creatErrorNoti:noteString];
    }
}

+ (void)creatErrorNoti:(NSString *)errorString
{
    NSDictionary *infoDic = [NSDictionary dictionaryWithObject:errorString forKey:@"DisConnect"];
    UILocalNotification *backgroudMsg = [[UILocalNotification alloc] init];
    if (backgroudMsg) {
        NSLog(@"发送通知");
        backgroudMsg.timeZone = [NSTimeZone defaultTimeZone];
        backgroudMsg.alertBody = errorString;
//        backgroudMsg.alertAction = dict[@"phone"];
        backgroudMsg.repeatInterval = 0;
        backgroudMsg.applicationIconBadgeNumber = 0;
        //标记通知信息
        backgroudMsg.userInfo = infoDic;
        [[UIApplication sharedApplication] scheduleLocalNotification:backgroudMsg];
    }
}

@end
