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
    [self creatLocalNoti:dict];
}

+ (void)createLocalNotiMessageString:(NSString *)string
{
    [self creatLocalNoti:@{@"name" : string, @"phone" : @"123456789"}];
}

+ (void)creatLocalNoti:(NSDictionary *)dict
{
    NSDictionary *infoDic = [NSDictionary dictionaryWithObject:dict[@"phone"] forKey:@"phone"];
    //    NSArray *localnoti = [UIApplication sharedApplication].scheduledLocalNotifications;
    //    if (localnoti.count) {
    //        for (UILocalNotification *noti in localnoti) {
    //            NSDictionary *info = noti.userInfo;
    //            if (info) {
    //                if ([info[@"phone"] isEqualToString:info[@"phone"]]) {
    //                    [[UIApplication sharedApplication] cancelLocalNotification:noti];
    //                }
    //            }
    //        }
    //    }
    UILocalNotification *backgroudMsg = [[UILocalNotification alloc] init];
    if (backgroudMsg) {
        backgroudMsg.timeZone = [NSTimeZone defaultTimeZone];
        backgroudMsg.alertBody = [NSString stringWithFormat:@"%@来电", dict[@"name"]];
        backgroudMsg.alertAction = dict[@"phone"];
        backgroudMsg.repeatInterval = 0;
        backgroudMsg.applicationIconBadgeNumber = 1;
        //标记通知信息
        backgroudMsg.userInfo = infoDic;
        //        [[UIApplication sharedApplication] presentLocalNotificationNow:backgroudMsg];
        [[UIApplication sharedApplication] scheduleLocalNotification:backgroudMsg];
    }
}

@end
