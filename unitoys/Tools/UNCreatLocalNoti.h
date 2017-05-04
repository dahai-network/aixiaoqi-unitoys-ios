//
//  UNCreatLocalNoti.h
//  unitoys
//
//  Created by 黄磊 on 2017/3/3.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UNCreatLocalNoti : NSObject

+ (void)createLocalNotiMessage:(NSDictionary *)dict;

+ (void)createLocalNotiMessageString:(NSString *)string;

//蓝牙关闭通知
+ (void)createLBECloseNoti;
//蓝牙断开连接通知
+ (void)createLBEDisConnectNoti;
//网络断开或较差通知
+ (void)createNETDisConnectNoti;

@end
