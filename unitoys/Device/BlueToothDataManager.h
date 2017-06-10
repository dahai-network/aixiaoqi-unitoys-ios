//
//  BlueToothDataManager.h
//  unitoys
//
//  Created by 董杰 on 2016/11/29.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlueToothDataManager : NSObject

/**
 *  返回单例对象
 */
+(BlueToothDataManager *)shareManager;
@property (nonatomic, copy) NSString *currentStep;//当前步数
@property (nonatomic, copy) NSString *versionNumber;//固件版本
@property (nonatomic, copy) NSString *deviceMacAddress;//设备mac地址
@property (nonatomic, copy) NSString *electricQuantity;//设备电量
@property (nonatomic, assign) int chargingState;//充电状态 1:未充电 2:正在充电 3:充电完成
@property (nonatomic, copy) NSString *lastChargTime;//上次充电时间
@property (nonatomic, copy) NSString *movingTarget;//目标步数
@property (nonatomic, copy) NSString *distance;//距离
@property (nonatomic, copy) NSString *consume;//消耗
@property (nonatomic, copy) NSString *sportDays;//累计运动天数
@property (nonatomic, assign) BOOL isConnected;//是否连接成功
@property (nonatomic, assign) BOOL isBounded;//是否绑定成功
@property (nonatomic, assign) BOOL isReseted;//是否重置了
@property (nonatomic, assign) BOOL isOpened;//蓝牙是否打开
@property (nonatomic, assign) int executeNum;//执行查询蓝牙状态的次数
@property (nonatomic, assign) BOOL isRegisted;//是否已注册
@property (nonatomic, assign) BOOL isNeedToResert;//是否需要重置
@property (nonatomic, assign) BOOL isAccordBreak;//是否主动断开
@property (nonatomic, copy) NSString *operatorType;//运营商类型，0：上电失败 1：移动 2：联通 3：电信 4：爱小器卡 5：无卡
@property (nonatomic, assign) BOOL isTcpConnected;//tcp是否连接成功
@property (nonatomic, assign) BOOL isActivityCard;//是否点击激活大王卡操作
@property (nonatomic, assign) BOOL isHaveCard;//判断是否有卡
@property (nonatomic, copy) NSString *cardType;//卡类型，激活的时候用，0：无卡，1：爱小器卡，2：电话卡
@property (nonatomic, assign) BOOL isBeingRegisting;//是否正在注册
@property (nonatomic, copy) NSString *stepNumber;//记录注册的步数多少
@property (nonatomic, assign) BOOL isShowHud;//激活大王卡的时候是否显示hud
@property (nonatomic, assign) BOOL isShowAlert;//是否显示重试的提示，为1的时候不会显示首页的那个提示语而显示搜索页面的提示语
@property (nonatomic, assign) int bleStatueForCard;//蓝牙发送消息的状态，默认0：默认状态 1：激活大王卡状态 2：注册手机卡状态
@property (nonatomic, assign) BOOL isHavePackage;//是否含有制定套餐
@property (nonatomic, assign) BOOL isConnectedPairedDevice;//是否连接已配对的设备
@property (nonatomic, assign) BOOL isCheckAndRefreshBLEStatue;//是否正在查询卡的状态（包括tcp连接）
@property (nonatomic, copy) NSString *localServicePort;//本地服务器的端口号
@property (nonatomic, assign) BOOL isNeedToBoundDevice;//是否需要绑定
@property (nonatomic, assign) BOOL isAllowToBound;//是否同意绑定
@property (nonatomic, copy) NSString *deviceType;//需要绑定的设备类型
@property (nonatomic, copy) NSString *connectedDeviceName;//连接上的设备类型名称
@property (nonatomic, copy) NSString *boundedDeviceName;//已经绑定过的设备类型名称，手环解绑成功之后提示用
@property (nonatomic, assign) BOOL isChangeSimCard; //是否换过SIM卡
@property (nonatomic, assign) BOOL isBeingOTA;//是否正在进行空中升级
@property (nonatomic, copy) NSString *statuesTitleString;//记录当前状态
@property (nonatomic, assign) BOOL isNeedToCheckStatue;//是否需要查询注册状态
//@property (nonatomic, assign) BOOL isAccordTocheckCard;//是否主动查询是否有卡
//@property (nonatomic, assign) int blutoothStatue;//蓝牙状态 0:蓝牙未开 1:蓝牙已开启但未连接 2: 蓝牙已连接但未绑定 3:蓝牙已绑定设备但未插卡 4:设备已插卡

@property (nonatomic, copy) NSString *homeVCLeftTitle;

@property (nonatomic, assign) BOOL isLbeConnecting; //蓝牙是否正在连接(包括扫描连接操作)
@property (nonatomic, assign) BOOL isCanSendAuthData; //是否允许解析鉴权数据(只有蓝牙注册后才允许)
@property (nonatomic, copy) NSString *checkStr;//本次的加密文字
@property (nonatomic, assign) BOOL isSame;//密文是否一样
@property (nonatomic, assign) BOOL isFirstRegist;//判断是否第一次注册这张SIM卡
@property (nonatomic, assign) BOOL isBeingShowAlert;//是否正在显示卡的弹框
@property (nonatomic, copy) NSString *iccidFromTcp;//从tcp拿到的iccid
@property (nonatomic, copy) NSString *iccidFromBle;//从蓝牙拿到的iccid
@property (nonatomic, copy) NSString *commicateIDFromTcp;//从tcp拿到的会话id
@property (nonatomic, copy) NSString *portFromTcp;//从tcp拿到的电话端口号
@property (nonatomic, assign) BOOL isNeedToRegistAgain;//是否需要重新注册
@property (nonatomic, assign) BOOL isShowStatuesView;//是否显示状态栏(用于判断tcp连接的那段时间)
@property (nonatomic, assign) BOOL isAlreadyShowElectyAlert;//是否已经显示过低电量提示
@property (nonatomic, assign) BOOL isDoneRegist;//是否已经走了正常注册流程

//当前卡状态(PushKit下判断有无卡使用)(0未知,1无卡,2有卡)
@property (nonatomic, assign) NSInteger currentSimCardStatu;
@end
