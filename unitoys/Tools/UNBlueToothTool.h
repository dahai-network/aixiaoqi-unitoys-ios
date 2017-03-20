//
//  UNBlueToothTool.h
//  unitoys
//
//  Created by 黄磊 on 2017/3/20.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface UNBlueToothTool : NSObject<CBCentralManagerDelegate,CBPeripheralDelegate>

//存放mac地址的字典
@property (nonatomic, strong) NSMutableDictionary *macAddressDict;
//存放RSSI的字典
@property (nonatomic, strong) NSMutableDictionary *RSSIDict;
//存放绑定的设备的信息
@property (nonatomic, strong) NSDictionary *boundedDeviceInfo;
//存放数据包的数组
@property (nonatomic, strong) NSMutableArray *dataPacketArray;
//存放最终总数据的字符串
@property (nonatomic, copy) NSString *totalString;
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
//已连接的配对设备
@property (nonatomic, strong) NSArray *pairedArr;
//计时器相关
@property (nonatomic, strong)NSTimer *timer;
@property (nonatomic, assign)int time;
//激活的订单id
@property (nonatomic, copy) NSString *activityOrderId;
//记录接收到包的类型
@property (nonatomic, assign) int dataPackegType;
//记录需要激活的大王卡的序列号(空卡序列号)
@property (nonatomic, copy) NSString *bigKingCardNumber;

@property (nonatomic, assign) BOOL isInitInstance;
@property (nonatomic, assign) BOOL isPushKitStatu;

+ (instancetype)shareBlueToothTool;
- (void)initBlueTooth;

//发送卡数据
- (void)sendBLECardDataWithValidData:(NSString *)data;

//空中升级指令
- (void)oatUpdateCommand;

//对卡上电
- (void)phoneCardToUpeLectrifyWithType:(NSString *)type;

//对卡断电
- (void)phoneCardToOutageNew;

//查找手环
- (void)searchBluetooth;

//停止扫描蓝牙
- (void)stopScanBluetooth;

//获取ICCID消息
- (void)sendICCIDMessage;

//发送爱小器国际卡卡数据
- (void)sendBLEAixiaoqiCardDataWithValidData:(NSString *)data;


@end
