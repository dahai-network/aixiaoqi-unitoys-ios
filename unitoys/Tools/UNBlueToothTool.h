//
//  UNBlueToothTool.h
//  unitoys
//
//  Created by 黄磊 on 2017/3/20.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

//更新左上角状态
typedef void(^UpdateButtonImageAndTitleBlock)(NSString *title);
//弹出提示信息
typedef void(^ShowHudNormalBlock)(NSInteger hudType, NSString *string);
//关闭提示信息
typedef void(^EndHudBlock)();
//未检测到卡提示是否重置
typedef void(^CheckBLEAndResetBlock)();
//注册失败
typedef void(^RegistFailActionBlock)();
//支付成功
typedef void(^PaySuccessBlock)();


@interface UNBlueToothTool : NSObject<CBCentralManagerDelegate,CBPeripheralDelegate>
//是否初始化过
@property (nonatomic, assign) BOOL isInitInstance;

//sim卡类型
@property (nonatomic, copy) NSString *simtype;
/*蓝牙相关*/
@property (nonatomic, strong) CBCentralManager *mgr;
@property (nonatomic, strong) NSMutableArray *peripherals;
//外设
@property (nonatomic, strong) CBPeripheral *peripheral;
//信号最强的外设
@property (nonatomic, strong) CBPeripheral *strongestRssiPeripheral;
//写属性特征
@property (nonatomic, strong) CBCharacteristic *characteristic;
//通知属性特征
@property (nonatomic, strong) CBCharacteristic *notifyCharacteristic;
@property (nonatomic, strong) CBCharacteristic *notifyCharacteristic2;
@property (nonatomic, strong) CBCharacteristic *notifyCharacteristic3;
//存储uuid的数组
@property (nonatomic, strong) NSMutableArray *uuidArray;
//存放mac地址的字典
@property (nonatomic, strong) NSMutableDictionary *macAddressDict;
//存放RSSI的字典
@property (nonatomic, strong) NSMutableDictionary *RSSIDict;
//存放数据包的数组
@property (nonatomic, strong) NSMutableArray *dataPacketArray;
//存放最终总数据的字符串
@property (nonatomic, copy) NSString *totalString;
//存放绑定的设备的信息
@property (nonatomic, strong) NSDictionary *boundedDeviceInfo;
//记录需要激活的大王卡的序列号(空卡序列号)
@property (nonatomic, copy) NSString *bigKingCardNumber;
//激活的订单id
@property (nonatomic, copy) NSString *activityOrderId;
//计时器相关
@property (nonatomic, strong)NSTimer *timer;
@property (nonatomic, assign)int time;
//记录接收到包的类型
@property (nonatomic, assign) int dataPackegType;
//已连接的配对设备
@property (nonatomic, strong) NSArray *pairedArr;
//是否使能通知的数据数组
@property (nonatomic, strong) NSMutableArray *dataArr;

//是否已销毁
@property (nonatomic, assign) BOOL isKill;

+ (instancetype)shareBlueToothTool;
- (void)initBlueTooth;

@property (nonatomic, copy) UpdateButtonImageAndTitleBlock updateButtonImageAndTitleBlock;
@property (nonatomic, copy) ShowHudNormalBlock showHudNormalBlock;
@property (nonatomic, copy) EndHudBlock endHudBlock;
@property (nonatomic, copy) CheckBLEAndResetBlock checkBLEAndResetBlock;
@property (nonatomic, copy) RegistFailActionBlock registFailActionBlock;
@property (nonatomic, copy) PaySuccessBlock paySuccessBlock;

//查询绑定设备
- (void)checkBindedDeviceFromNet;
//对卡上电
- (void)phoneCardToUpeLectrifyWithType:(NSString *)type;
//对卡断电
- (void)downElectToCard;
//查找手环
- (void)searchBluetooth;
//停止扫描蓝牙
- (void)stopScanBluetooth;
//空中升级指令
- (void)oatUpdateCommand;
//发送卡数据
- (void)sendBLECardDataWithValidData:(NSString *)data;
//检查是否绑定
- (void)checkDeviceIsBound;
//设置是否PushKit
- (void)setPushKitStatu:(BOOL)isPushKit;
//正常加载
- (void)sendLBEMessageNoPushKit;
//解析鉴权数据
- (void)analysisAuthDataWithString:(NSString *)string;
//发送复位请求
- (void)sendBLESystemResetCommand;
//获取空卡序列号
- (void)checkEmptyCardSerialNumberFirstWithString:(NSString *)string;
//是否使能通知
- (void)sendDataToCheckIsAllowToNotificationWithPhoneCall:(BOOL)phoneCall Message:(BOOL)message WeiChart:(BOOL)weiChart QQ:(BOOL)QQ;
//检测到有电话
- (void)checkNitifiCall;
//检测到有短信
- (void)checkNotifiMessage;
//请求卡类型和ICCID
- (void)checkSystemInfo;
//请求系统基本信息
- (void)checkSystemBaseInfo;
//解绑
- (void)buttonToUnboundAction;
//取消绑定
- (void)cancelToBound;

//第一次进入前台
- (void)fristJumpForeground;

- (void)clearInstance;
@end
