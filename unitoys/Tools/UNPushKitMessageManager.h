//
//  UNPushKitMessageManager.h
//  unitoys
//
//  Created by 黄磊 on 2017/3/25.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>

//PushKit消息类型
typedef NS_ENUM(NSUInteger, PushKitMessageType) {
    PushKitMessageTypeNone = 0,//默认
    PushKitMessageTypePingPacket = 5,//心跳包
    PushKitMessageTypeNetCall = 6,//只需要开启网络电话,无需开启蓝牙(一般指联通卡)
    PushKitMessageTypeAuthSimData = 10,//正常鉴权数据
    PushKitMessageTypeSimDisconnect = 15,//SIM卡断开连接
};

@interface UNPushKitMessageManager : NSObject

+ (UNPushKitMessageManager *)shareManager;

/**
 *  当前是否为PushKit模式
 */
@property (nonatomic, assign) BOOL isPushKitFromAppDelegate;
/**
 *  是否需要注册
 */
@property (nonatomic, assign) BOOL isNeedRegister;
/**
 *  SIM数据
 */
@property (nonatomic, copy) NSDictionary *simDataDict;
/**
 *  PushKit消息类型
 */
@property (nonatomic, assign) PushKitMessageType pushKitMsgType;
/**
 *  PushKit鉴权数据消息类型
    type == 01(发送01数据)   type == 02(发送正常数据)
 */
@property (nonatomic, assign) NSInteger PushKitAuthDataType;
/**
 *  APP是否已加载(是否加载过HomeVC)
 */
@property (nonatomic, assign) BOOL isAppAlreadyLoad;

/**
 *  是否已经进入过前台
 */
@property (nonatomic, assign) BOOL isAlreadyInForeground;
/**
 *  TCP是否正在连接
 */
@property (nonatomic, assign) BOOL isTcpConnecting;
/**
 *  当前PushKit心跳包数据
 */
//@property (nonatomic, copy) NSDictionary *currentPushKitPingPackect;

/**
 *  PushKit消息队列
 */
@property (nonatomic, strong) NSMutableArray *pushKitMsgQueue;


/**
 *  Udp是否发送过第一次消息
 */
@property (nonatomic, assign) BOOL isUdpSendFristMsg;
/**
 *  ICCID的值,同时作为ICCID本地数据的key
 */
@property (nonatomic, copy) NSString *iccidString;
/**
 *  是否发送TCP消息,用来判断TCP连接成功后是否发送数据
 */
@property (nonatomic, assign) BOOL isSendTcpString;
/**
 *  当前PushKit消息,用作发送消息后从队列中删除
 */
@property (nonatomic, copy) NSDictionary *receivePushKitDataFormServices;
/**
 *  当前PushKitToken
 */
@property (nonatomic, copy) NSString *pushKitTokenString;
/**
 *  PushKit下蓝牙解析后的鉴权数据
 */
@property (nonatomic, copy) NSString *tcpStringWithPushKit;
/**
 *  PushKit下组合过的最终发送给TCP的数据
 */
@property (nonatomic, copy) NSString *tcpPacketStrWithPushKit;


/**
 *  鉴权数据卡类型是否存在
 */
@property (nonatomic, assign) BOOL isHasSimType;
/**
 *  鉴权数据卡类型数据
 */
@property (nonatomic, copy) NSString *simTypeData;
/**
 *  是否快速加载
 */
@property (nonatomic, assign) BOOL isQuickLoad;
/**
 *  ICCID命令数组
 */
@property (nonatomic, copy) NSArray *sendICCIDCommands;
/**
 *  当前发送ICCID序号
 */
@property (nonatomic, assign) NSInteger sendICCIDIndex;

/**
 *  tcp断线重连定时器时间间隔
 */
@property (nonatomic, assign) NSInteger tcpSocketTimerIndex;
/**
 *  tcp重连定时器
 */
@property (nonatomic, strong) NSTimer *tcpReconnectTimer;


/**
 *  是否为外部CallKit电话
 */
@property (nonatomic, assign) BOOL isSysCallKitPhone;
/**
 *  外部CallKit电话handle
 */
@property (nonatomic, copy) NSString *callKitHandleString;

@end
