//
//  AppDelegate.h
//  unitoys
//
//  Created by sumars on 16/9/11.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WXApi.h"
#import <Bugly/Bugly.h>

//PushKit消息类型
typedef NS_ENUM(NSUInteger, PushKitMessageType) {
//    PushKitMessageTypeNone = 0,//默认
//    PushKitMessageType05 = 5,//心跳包
//    PushKitMessageType06 = 6,//只需要开启网络电话,无需开启蓝牙(一般指联通卡)
    PushKitMessageTypeNone = 0,//默认
    PushKitMessageTypePingPacket = 5,//心跳包
    PushKitMessageTypeNetCall = 6,//只需要开启网络电话,无需开启蓝牙(一般指联通卡)
    PushKitMessageTypeAuthSimData = 10,//正常鉴权数据
    PushKitMessageTypeSimDisconnect = 15,//SIM卡断开连接

};

@interface AppDelegate : UIResponder <UIApplicationDelegate,WXApiDelegate, BuglyDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, assign) int currentNumber;//记录心跳包次数，从08开始

@property (nonatomic, readonly) BOOL isPushKit;
@property (nonatomic, readonly) BOOL isNeedRegister;
@property (nonatomic, readonly) NSString *simDataString;

@property (nonatomic, readonly) PushKitMessageType pushKitMsgType;
@end

