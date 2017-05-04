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
    NSString *timeStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"LBEClose"];
    
}
//蓝牙断开连接通知
+ (void)createLBEDisConnectNoti
{

}
//网络断开或较差通知
+ (void)createNETDisConnectNoti
{
    
}

+ (void)creatErrorNoti:(NSString *)errorString
{
    NSDictionary *infoDic = [NSDictionary dictionaryWithObject:errorString forKey:@"DisConnect"];
    UILocalNotification *backgroudMsg = [[UILocalNotification alloc] init];
    if (backgroudMsg) {
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
