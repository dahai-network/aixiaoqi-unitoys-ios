//
//  UNBlueToothTool.m
//  unitoys
//
//  Created by 黄磊 on 2017/3/20.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNBlueToothTool.h"
#import "BlueToothDataManager.h"
#import "UNDatabaseTools.h"
#import "global.h"
#import "SSNetworkRequest.h"
#import <CommonCrypto/CommonDigest.h>
#import "UNSimCardAuthenticationModel.h"
#import "UNBLEDataManager.h"
#import "UNGetSimData.h"
#import "UNPushKitMessageManager.h"
#import "NSString+Extension.h"
#import "UNDataTools.h"

#import "UNCreatLocalNoti.h"

//app发送给蓝牙
typedef enum : NSUInteger {
    BLESystemReset,//系统复位
    BLETellBLEIsApple,//app发送手机系统给蓝牙
    BLEIsNotifi,//是否使能通知
    BLENotifiCall,//检测到有电话
    BLETurnoverTime,//更新时间
    BLESystemBaseInfo,//系统基本信息请求
    BLECkeckToBound,//请求绑定
    BLEIsBoundSuccess,//是否绑定成功
    BLERemoveBound,//解除绑定
    BLEUpdataFromOTA,//空中升级
    BLECheckElectricQuantity,//请求电量
    BLESearchDevice,//查找手环
    BLEIsUpHands,//是否是能抬手功能
    BLECheckHistoryStep,//请求历史步数
    BLESetAlarmClock,//设置闹钟
    BLEUpElectricToCard,//对卡上电
    BLEDownElectricToCard,//对卡断电
    BLECardData,//卡数据
    BLEAixiaoqiCardData,//爱小器国外卡数据
    BLEJUSTBOXCANCONNECT,//仅钥匙扣能连
    BLECardTypeAndICCID,//获取卡类型和ICCID
} APPSENDTOBLE;

@interface UNBlueToothTool()
@property (nonatomic, assign) BOOL checkToken;
@property (nonatomic, strong) NSMutableDictionary *headers;

@property (nonatomic, strong) UNSimCardAuthenticationModel *authenticationModel;
@property (nonatomic, assign) NSInteger maxSendCount;
@property (nonatomic, assign) NSInteger currentSendIndex;
@property (nonatomic, strong) NSMutableArray *needSendDatas;

@property (nonatomic, strong)NSString *connectedDeviceName;//连接的设备名称（用于区分连接的是什么设备）

@property (nonatomic, assign) BOOL isPushKitStatu;//是否为PushKit

@property (nonatomic, copy) NSString *normalAuthSimString;

@property (nonatomic, assign) BOOL isClickButton;//是否点击了解绑按钮

@property (nonatomic, assign) BOOL isNewCard;//是否是新的爱小器卡

@property (nonatomic, copy) NSString *lastDataStr;//激活卡的时候记录上一条发送的指令

@property (nonatomic, copy)NSString *activityCardData;

//绑定计时器
@property (nonatomic, strong) NSTimer *boundTimer;
@property (nonatomic, assign) int boundTimeValue;

//扫描计时器
@property (nonatomic, strong) NSTimer *scanAndConnectingTimer;
@property (nonatomic, assign) int scanAndConnectingTimeValue;

//加密计时器
@property (nonatomic, strong) NSTimer *encryptionTimer;
@property (nonatomic, assign) int encryptionTimeValue;

@property (nonatomic, copy)NSString *activityCardDataStr;//激活爱小器卡时记录多包的数据
@property (nonatomic, copy) NSString *appdenStr;//加密数据

@end

static UNBlueToothTool *instance = nil;
@implementation UNBlueToothTool

- (void)setPushKitStatu:(BOOL)isPushKit
{
    _isPushKitStatu = isPushKit;
}



- (NSMutableArray *)needSendDatas
{
    if (!_needSendDatas) {
        _needSendDatas = [NSMutableArray array];
    }
    return _needSendDatas;
}

- (NSMutableArray *)dataPacketArray {
    if (!_dataPacketArray) {
        _dataPacketArray = [NSMutableArray array];
    }
    return _dataPacketArray;
}

- (NSMutableArray *)peripherals
{
    if (!_peripherals) {
        self.peripherals = [NSMutableArray array];
    }
    return _peripherals;
}
- (CBCentralManager *)mgr
{
    if (!_mgr) {
        // 创建中心设备管理者，用来管理中心设备
        self.mgr = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    return _mgr;
}

+ (UNBlueToothTool *)shareBlueToothTool
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[UNBlueToothTool alloc] init];
    });
    return instance;
}

- (void)clearInstance
{
    UNDebugLogVerbose(@"clearInstance");
    self.isKill = YES;
    [[UNDatabaseTools sharedFMDBTools] deleteTableWithAPIName:@"apiDeviceBracelet"];
    if ([BlueToothDataManager shareManager].isConnected) {
        UNDebugLogVerbose(@"断开蓝牙1");
        if (_peripheral) {
            UNDebugLogVerbose(@"断开蓝牙2");
            [_mgr cancelPeripheralConnection:_peripheral];
        }
    }
    if (_mgr) {
        [_mgr stopScan];
        _mgr = nil;
    }
    _peripheral = nil;
    _peripherals = nil;
    _strongestRssiPeripheral = nil;
    
    _macAddressDict = nil;
    _RSSIDict = nil;
    _simtype = nil;
    
    self.isInitInstance = NO;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self initObserverAction];
    }
    return self;
}

- (void)initBlueTooth
{
    UNLogLBEProcess(@"走了初始化蓝牙的方法");
    if (![UNDataTools sharedInstance].isLogout) {
        UNDebugLogVerbose(@"在线：%s,%d", __FUNCTION__, __LINE__);
        if (self.isInitInstance) {
            UNLogLBEProcess(@"不初始化蓝牙")
            return;
        }
        UNLogLBEProcess(@"初始化蓝牙")
        UNLogLBEProcess(@"当前初始化线程======%@", [NSThread currentThread]);
        
        self.isKill = NO;
        self.isInitInstance = YES;
        self.isPushKitStatu = [UNPushKitMessageManager shareManager].isPushKitFromAppDelegate;
        
        [BlueToothDataManager shareManager].bleStatueForCard = 0;
        self.macAddressDict = [NSMutableDictionary new];
        self.RSSIDict = [NSMutableDictionary new];
        if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
            [BlueToothDataManager shareManager].operatorType = [[NSUserDefaults standardUserDefaults] objectForKey:@"operatorType"];
        }
        self.simtype = [self checkSimType];
        UNLogLBEProcess(@"卡类型--%@", self.simtype);
        
        [BlueToothDataManager shareManager].isNeedToResert = YES;
        [BlueToothDataManager shareManager].currentStep = @"0";
        
        //    [self initObserverAction];
        [self checkBindedDeviceFromNet];
    } else {
        UNLogLBEProcess(@"不在线：%s,%d", __FUNCTION__, __LINE__)
    }
}

- (void)initObserverAction
{
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
    UNLogLBEProcess(@"initObserverAction==注册监听");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downElectToCard) name:@"downElectic" object:@"downElectic"];//对卡断电
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivePushKitMessage) name:@"ReceivePushKitMessage" object:nil];//接收PushKit消息
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(analysisAuthData:) name:@"AnalysisAuthData" object:nil];//解析鉴权数据
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveIMEIToConnecting:) name:@"clickAndConnectingPer" object:nil];//接收到消息之后连接指定外设
}

- (void)receiveIMEIToConnecting:(NSNotification *)sender {
    int index = [sender.object intValue];
    self.strongestRssiPeripheral = self.peripherals[index];
    if (self.strongestRssiPeripheral) {
        self.peripheral = self.strongestRssiPeripheral;
        [self.mgr connectPeripheral:self.peripheral options:nil];
    }
}

- (void)receivePushKitMessage
{
    if (self.isKill || !self.isInitInstance) {
        UNLogLBEProcess(@"是否已销毁====%d=====是否已初始化======%d",self.isKill,self.isInitInstance);
        return;
    }
    UNLogLBEProcess(@"receivePushKitMessage");
    if ([BlueToothDataManager shareManager].isConnected) {
        if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
            UNLogLBEProcess(@"发送pushkit消息到蓝牙");
            if ([UNPushKitMessageManager shareManager].pushKitMsgType == PushKitMessageTypeSimDisconnect) {
                UNLogLBEProcess(@"SIM断开连接消息类型");
                [self sendLBEMessageSIMDisConnect];
            }else{
                if ([UNPushKitMessageManager shareManager].simDataDict) {
                    [self sendLBEMessageWithPushKit];
                }else{
//                    [self sendLBEConnectData];
                    UNLogLBEProcess(@"必须有simDataDict");
                }
            }
        }else{
            UNLogLBEProcess(@"数据错误,必须为PushKit模式");
        }
        
    }else{
        UNLogLBEProcess(@"蓝牙未连接");
        if (![BlueToothDataManager shareManager].isLbeConnecting) {
            UNLogLBEProcess(@"蓝牙未连接,重连设备");
            [self checkBindedDeviceFromNet];
        }
    }
}

//解析鉴权数据
- (void)analysisAuthData:(NSNotification *)noti
{
    if (self.isKill || !self.isInitInstance) {
        return;
    }
    UNDebugLogVerbose(@"analysisAuthData---%@", noti.object);
    [self analysisAuthDataWithString:noti.object];
}

//对卡上电
- (void)phoneCardToUpeLectrifyWithType:(NSString *)type
{
    [self phoneCardToUpeLectrify:type];
}

#pragma mark 对卡断电
- (void)downElectToCard {
    if (self.isKill || !self.isInitInstance) {
        return;
    }
    
    if ([BlueToothDataManager shareManager].isConnected) {
        UNDebugLogVerbose(@"对卡断电");
        [self phoneCardToOutageNew];
    }else{
        UNDebugLogVerbose(@"蓝牙未连接");
        [self showHudNormalString:INTERNATIONALSTRING(@"蓝牙未连接")];
    }
}

#pragma mark 对卡上电
- (void)updataToCard {
    if ([BlueToothDataManager shareManager].isConnected) {
        [self phoneCardToUpeLectrify:@"03"];
    }else{
        UNLogLBEProcess(@"蓝牙未连接");
        [self showHudNormalString:INTERNATIONALSTRING(@"蓝牙未连接")];
    }
}

//查找手环
- (void)searchBluetooth
{
    [self sendMessageToBLEWithType:BLESearchDevice validData:nil];
}

//停止扫描手环
- (void)stopScanBluetooth
{
    [self.mgr stopScan];
    [self.scanAndConnectingTimer setFireDate:[NSDate distantFuture]];
}

//空中升级
- (void)oatUpdateCommand
{
    [self sendMessageToBLEWithType:BLEUpdataFromOTA validData:@"b1"];
}

//发送卡数据
- (void)sendBLECardDataWithValidData:(NSString *)data
{
    [self sendMessageToBLEWithType:BLECardData validData:data];
}

//发送复位请求
- (void)sendBLESystemResetCommand
{
    [self sendMessageToBLEWithType:BLESystemReset validData:nil];
}

//第一次进入前台
- (void)fristJumpForeground
{
    if (self.needSendDatas.count) {
        [self.needSendDatas removeAllObjects];
    }
    self.currentSendIndex = 0;
}

#pragma mark 对卡断电指令
- (void)phoneCardToOutageNew {
    [self sendMessageToBLEWithType:BLEDownElectricToCard validData:nil];
}

#pragma mark 对卡上电指令（新协议）
- (void)phoneCardToUpeLectrify:(NSString *)type {
    [self sendMessageToBLEWithType:BLEUpElectricToCard validData:type];
}

#pragma mark 检测到有电话
- (void)checkNitifiCall {
    [self sendMessageToBLEWithType:BLENotifiCall validData:@"01"];
}

#pragma mark 检测到有短信
- (void)checkNotifiMessage {
    [self sendMessageToBLEWithType:BLENotifiCall validData:@"02"];
}

#pragma mark 新协议发送数据包的方法
- (void)sendMessageToBLEWithType:(APPSENDTOBLE)type validData:(NSString *)validData {
    NSString *firstStr;
    NSString *typeStr;
    NSString *validStrLength;
    NSString *totalStr;
    if (validData) {
        firstStr = validData;
    }
    switch (type) {
        case BLESystemReset:
            //系统复位
            typeStr = @"0100";
            break;
        case BLETellBLEIsApple:
            //app发送手机系统给蓝牙
            typeStr = @"0200";
            break;
        case BLEIsNotifi:
            //是否是能通知
            typeStr = @"0300";
            break;
        case BLENotifiCall:
            //检测到有电话
            typeStr = @"0400";
            break;
        case BLETurnoverTime:
            //更新时间
            typeStr = @"0500";
            break;
        case BLESystemBaseInfo:
            //系统基本信息请求
            typeStr = @"0600";
            break;
        case BLECkeckToBound:
            //请求绑定
            typeStr = @"0700";
            break;
        case BLEIsBoundSuccess:
            //是否绑定成功
            typeStr = @"0800";
            break;
        case BLERemoveBound:
            //解除绑定
            typeStr = @"0900";
            break;
        case BLEUpdataFromOTA:
            //空中升级
            typeStr = @"0a00";
            break;
        case BLECheckElectricQuantity:
            //请求电量
            typeStr = @"0b00";
            break;
        case BLESearchDevice:
            //查找手环
            typeStr = @"0c00";
            break;
        case BLEIsUpHands:
            //是否是能抬手功能
            typeStr = @"0d00";
            break;
        case BLECheckHistoryStep:
            //请求历史步数
            typeStr = @"0e00";
            break;
        case BLESetAlarmClock:
            //设置闹钟
            typeStr = @"0f00";
            break;
        case BLEUpElectricToCard:
            //对卡上电
            typeStr = @"1000";
            break;
        case BLEDownElectricToCard:
            //对卡断电
            typeStr = @"1100";
            break;
        case BLECardData:
            //卡数据
            typeStr = @"1200";
            break;
        case BLEAixiaoqiCardData:
            //卡数据
            typeStr = @"1300";
            break;
        case BLEJUSTBOXCANCONNECT:
            //仅钥匙扣能连
            typeStr = @"1400";
            break;
        case BLECardTypeAndICCID:
            //卡类型和iccid
            typeStr = @"1600";
            break;
        default:
            break;
    }
    if (validData) {
        //有有效data
        if (firstStr.length/2 <= 15) {
            validStrLength = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)(firstStr.length+typeStr.length)/2]];
            totalStr = [NSString stringWithFormat:@"8880%@%@%@", validStrLength, typeStr, firstStr];
            UNLogLBEProcess(@"只有一个包，最终发送的包内容 -> %@", totalStr);
            [self sendConnectingInstructWithData:[self checkNewMessageReuseWithString:totalStr]];
        } else {
            NSString *totalNumber = [NSString stringWithFormat:@"%lu", ((firstStr.length - 15*2)/2)/17 + 2];
            for (int i = 0; i < [totalNumber integerValue]; i++) {
                NSString *tempStr;//后面拼接的字节
                NSString *currentNumStr;//数据包编号
                NSString *currentStrLength;//当前数据长度
                if (i == 0) {
                    //第一个
                    currentStrLength = [self hexStringFromString:@"17"];
                    tempStr = [firstStr substringWithRange:NSMakeRange(0, 34 - 4)];//减去类型的两个字节
                    totalStr = [NSString stringWithFormat:@"8800%@%@%@", currentStrLength, typeStr, tempStr];
                    UNLogLBEProcess(@"多包第一个，最终发送的包内容 -> %@", totalStr);
                    [self sendConnectingInstructWithData:[self checkNewMessageReuseWithString:totalStr]];
                } else if (i == [totalNumber integerValue] - 1) {
                    //最后一个
                    currentStrLength = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)((firstStr.length-15*2)-(i-1)*(17*2))/2]];
                    currentNumStr = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)i + 128]];//加上0x80
                    tempStr = [firstStr substringFromIndex:15*2 + 17*2*(i - 1)];
                    totalStr = [NSString stringWithFormat:@"88%@%@%@", currentNumStr, currentStrLength, tempStr];
                    UNLogLBEProcess(@"多包最后一个，最终发送的包内容 -> %@", totalStr);
                    [self sendConnectingInstructWithData:[self checkNewMessageReuseWithString:totalStr]];
                } else {
                    //中间的
                    currentStrLength = [self hexStringFromString:@"17"];
                    tempStr = [firstStr substringWithRange:NSMakeRange(15*2+17*2*(i-1), 17*2)];
                    currentNumStr = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)i]];
                    totalStr = [NSString stringWithFormat:@"88%@%@%@", currentNumStr, currentStrLength, tempStr];
                    UNLogLBEProcess(@"多包中间的，最终发送的包内容 -> %@", totalStr);
                    [self sendConnectingInstructWithData:[self checkNewMessageReuseWithString:totalStr]];
                }
            }
        }
        
    } else {
        //无有效data
        validStrLength = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)(typeStr.length)/2]];
        totalStr = [NSString stringWithFormat:@"8880%@%@", validStrLength, typeStr];
        UNDebugLogVerbose(@"无有效data，最终发送的包内容 -> %@", totalStr);
        [self sendConnectingInstructWithData:[self checkNewMessageReuseWithString:totalStr]];
    }
}


#pragma mark 发送指令
- (void)sendConnectingInstructWithData:(NSData *)data {
    if ([BlueToothDataManager shareManager].isConnected) {
        if (![BlueToothDataManager shareManager].isBeingOTA) {
            self.peripheral.delegate = self;
            if((self.characteristic.properties & CBCharacteristicWriteWithoutResponse) != 0) {
                [self.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithoutResponse];
            } else if ((self.characteristic.properties & CBCharacteristicPropertyWrite) != 0) {
                [self.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
            } else {
                UNLogLBEProcess(@"No write property on TX characteristic, %ld.",(unsigned long)self.characteristic.properties);
            }
            UNLogLBEProcess(@"连接蓝牙并发送给蓝牙数据 -- %@", data);
        }
    } else {
        UNLogLBEProcess(@"蓝牙未连接");
    }
}


#pragma mark - CBCentralManagerDelegate
#pragma mark 发现外围设备的时候调用,RSSI为负值，越接近0，信号越强
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    UNDebugLogVerbose(@"发现设备");
    // 添加外围设备
    if (![self.peripherals containsObject:peripheral]) {
        // 设置外设的代理
        //        peripheral.delegate = self;
        if (peripheral.name) {
            UNDebugLogVerbose(@"发现设备名称：%@", peripheral.name);
            NSString *imeiStr = self.boundedDeviceInfo[@"IMEI"];
            NSString *imeiLowStr = imeiStr.lowercaseString;
            NSString *nameStr = peripheral.name;
            NSString *allDeviceStr = MYDEVICENAME;
            if ([peripheral.name containsString:MYDEVICENAMEUNITOYS]) {
                nameStr = MYDEVICENAMEUNITOYS;
            }
            if ([peripheral.name containsString:MYDEVICENAMEUNIBOX]) {
                nameStr = MYDEVICENAMEUNIBOX;
            }
            if ([BlueToothDataManager shareManager].deviceType) {
                if ([[BlueToothDataManager shareManager].deviceType isEqualToString:MYDEVICENAMEUNITOYS]) {
                    //手环
                    allDeviceStr = MYDEVICENAMEUNITOYS;
                } else if ([[BlueToothDataManager shareManager].deviceType isEqualToString:MYDEVICENAMEUNIBOX]) {
                    //钥匙扣
                    allDeviceStr = MYDEVICENAMEUNIBOX;
                } else {
                    UNDebugLogVerbose(@"类型错了");
                }
            }
            if (imeiLowStr&&[allDeviceStr containsString:nameStr.lowercaseString]) {
                //新版本带mac地址的
                if (peripheral.name.length > nameStr.length+1) {
                    NSString *macStr = [self conventMACAddressFromNetWithStr:[peripheral.name substringFromIndex:nameStr.length+1]];
                    if ([macStr.lowercaseString isEqualToString:imeiLowStr]) {
                        self.peripheral = peripheral;
                        [self.mgr connectPeripheral:self.peripheral options:nil];
                        [self.macAddressDict setObject:macStr.lowercaseString forKey:peripheral.identifier];
                        [self.RSSIDict setObject:RSSI forKey:peripheral.identifier];
                        [BlueToothDataManager shareManager].deviceMacAddress = imeiLowStr;
                    }
                }
                //mac地址没有广播
                if (!advertisementData[@"kCBAdvDataManufacturerData"]) {
                    UNDebugLogVerbose(@"mac地址没有广播");
                }
            } else {
                //新版本带mac地址的
                if (peripheral.name.length > nameStr.length+1 && [allDeviceStr containsString:nameStr.lowercaseString]) {
                    NSString *macStr = [self conventMACAddressFromNetWithStr:[peripheral.name substringFromIndex:nameStr.length+1]];
                    if ([RSSI intValue] < 0) {
                        [self.peripherals addObject:peripheral];
                        UNDebugLogVerbose(@"带mac地址 -- uuid = %@ name = %@ 信号强度是：%@ mac地址是：%@", peripheral.identifier, peripheral.name, RSSI, macStr.lowercaseString);
                        [self.macAddressDict setObject:macStr.lowercaseString forKey:peripheral.identifier];
                        [self.RSSIDict setObject:RSSI forKey:peripheral.identifier];
                    } else {
                        UNDebugLogVerbose(@"rssi大于0");
                    }
                }
                //mac地址没有广播
                if (!advertisementData[@"kCBAdvDataManufacturerData"]) {
                    UNDebugLogVerbose(@"mac地址没有广播");
                }
            }
        }
    }
}

#pragma mark 蓝牙状态发生变化
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    [BlueToothDataManager shareManager].executeNum++;
    //第一次打开或者每次蓝牙状态改变都会调用这个函数
    switch (central.state) {
        case CBManagerStateUnknown:
            UNLogLBEProcess(@"当前蓝牙状态CBManagerStateUnknown")
            break;
        case CBManagerStateResetting:
            UNLogLBEProcess(@"当前蓝牙状态CBManagerStateResetting")
            break;
        case CBManagerStateUnsupported:
            UNLogLBEProcess(@"当前蓝牙状态CBManagerStateUnsupported")
            break;
        case CBManagerStateUnauthorized:
            UNLogLBEProcess(@"当前蓝牙状态CBManagerStateUnauthorized")
            break;
        case CBManagerStatePoweredOff:
            UNLogLBEProcess(@"当前蓝牙状态CBManagerStatePoweredOff")
            //清空鉴权数据
            self.normalAuthSimString = nil;
            [BlueToothDataManager shareManager].isConnected = NO;
            [BlueToothDataManager shareManager].isCanSendAuthData = NO;
            [self.peripherals removeAllObjects];
            [self.mgr stopScan];
            [BlueToothDataManager shareManager].isShowStatuesView = YES;
            //蓝牙未开
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_BLNOTOPEN];
            if (![BlueToothDataManager shareManager].isOpened) {
                if ([BlueToothDataManager shareManager].executeNum < 3) {
                    //第一次什么都不执行
                } else {
                    //                HUDNormal(INTERNATIONALSTRING(@"连接蓝牙设备才能正常使用"))
                    [self showHudNormalString:INTERNATIONALSTRING(@"连接蓝牙设备才能正常使用")];
                }
            }
            [BlueToothDataManager shareManager].isOpened = NO;
            if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (self.mgr.state == CBManagerStatePoweredOff) {
                        [UNCreatLocalNoti createLBECloseNoti];
                    }
                });
            }
            break;
        case CBManagerStatePoweredOn:
        {
            UNLogLBEProcess(@"当前蓝牙状态CBManagerStatePoweredOn")
            UNDebugLogVerbose(@"蓝牙设备开着");
            [BlueToothDataManager shareManager].bleStatueForCard = 0;
            [self.peripherals removeAllObjects];
            [BlueToothDataManager shareManager].isOpened = YES;
            //连接中
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_CONNECTING];
            if (!self.boundedDeviceInfo[@"IMEI"]) {
                [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTBOUND];
            }
            [BlueToothDataManager shareManager].isLbeConnecting = YES;
#warning 为了提高连接时间，此处去掉延时，可能对手环连接有影响
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //已经被系统或者其他APP连接上的设备数组
                if (!self.pairedArr){
                    self.pairedArr = [[NSArray alloc] initWithArray:[self.mgr retrieveConnectedPeripheralsWithServices:@[[CBUUID UUIDWithString:UUIDFORSERVICE1SERVICE]]]];
                }else{
                    self.pairedArr = nil;
                    self.pairedArr = [[NSArray alloc] initWithArray:[self.mgr retrieveConnectedPeripheralsWithServices:@[[CBUUID UUIDWithString:UUIDFORSERVICE1SERVICE]]]];
                }
                if(self.pairedArr.count>0) {
                    UNDebugLogVerbose(@"连接的配对设备 - %@", self.pairedArr);
                    for (CBPeripheral* peripheral in self.pairedArr) {
                        NSString *nameStr = peripheral.name;
                        NSString *allDeviceStr = MYDEVICENAME;
                        if ([peripheral.name containsString:MYDEVICENAMEUNITOYS]) {
                            nameStr = MYDEVICENAMEUNITOYS;
                        }
                        if ([peripheral.name containsString:MYDEVICENAMEUNIBOX]) {
                            nameStr = MYDEVICENAMEUNIBOX;
                        }
                        if ([BlueToothDataManager shareManager].deviceType) {
                            if ([[BlueToothDataManager shareManager].deviceType isEqualToString:MYDEVICENAMEUNITOYS]) {
                                //手环
                                allDeviceStr = MYDEVICENAMEUNITOYS;
                            } else if ([[BlueToothDataManager shareManager].deviceType isEqualToString:MYDEVICENAMEUNIBOX]) {
                                //钥匙扣
                                allDeviceStr = MYDEVICENAMEUNIBOX;
                            } else {
                                UNLogLBEProcess(@"类型错了")
                            }
                        }
                        if (peripheral != nil && [allDeviceStr containsString:nameStr.lowercaseString]) {
                            //获取mac地址
                            if (!self.boundedDeviceInfo[@"IMEI"] && peripheral.name.length > nameStr.length+1) {
                                [BlueToothDataManager shareManager].deviceMacAddress = [self conventMACAddressFromNetWithStr:[peripheral.name substringFromIndex:nameStr.length+1].lowercaseString];
                            }
                            if (self.boundedDeviceInfo[@"IMEI"]) {
                                NSString *boundStr = self.boundedDeviceInfo[@"IMEI"];
                                [BlueToothDataManager shareManager].deviceMacAddress = boundStr.lowercaseString;
                            }
                            //绑定设备
                            if (!self.boundedDeviceInfo[@"IMEI"]) {
                                if ([BlueToothDataManager shareManager].isNeedToBoundDevice) {
                                    //调用绑定设备接口
                                    self.strongestRssiPeripheral = peripheral;
                                    [self.macAddressDict setObject:[BlueToothDataManager shareManager].deviceMacAddress forKey:peripheral.identifier];
                                    [self checkDeviceIsBound];
                                    [BlueToothDataManager shareManager].isNeedToBoundDevice = NO;
                                    [BlueToothDataManager shareManager].isConnectedPairedDevice = NO;
                                } else {
                                    UNLogLBEProcess(@"啥都不做")
                                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTBOUND];
                                }
                            } else {
                                UNLogLBEProcess(@"已经绑定过了%@", self.boundedDeviceInfo[@"IMEI"]);
                                //已经绑定过
                                NSString *boundMac = self.boundedDeviceInfo[@"IMEI"];
                                if ([boundMac.lowercaseString isEqualToString:[BlueToothDataManager shareManager].deviceMacAddress]) {
                                    peripheral.delegate = self;
                                    self.peripheral = peripheral;
                                    [self.mgr connectPeripheral:self.peripheral options:nil];
                                } else {
                                    //                                HUDNormal(INTERNATIONALSTRING(@"请忽略您之前的设备"))
                                    [self showHudNormalString:INTERNATIONALSTRING(@"请忽略您之前的设备")];
                                }
                            }
                        }
                    }
                } else {
                    UNLogLBEProcess(@"没有配对设备")
                    
                    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
                    NSMutableDictionary *boundedDeviceInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"boundedDeviceInfo"]];
                    if ([boundedDeviceInfo objectForKey:userdata[@"Tel"]]) {
                        NSArray *arr = [self.mgr retrievePeripheralsWithIdentifiers:@[[[NSUUID alloc] initWithUUIDString:[boundedDeviceInfo objectForKey:userdata[@"Tel"]]]]];
                        UNDebugLogVerbose(@"本地存储的设备信息 -- %@", arr);
                        if (arr.count) {
                            self.peripheral = arr[0];
                            UNDebugLogVerbose(@"获取到了存储的peripheral - %@", self.peripheral);
                            if (self.peripheral) {
                                UNDebugLogVerbose(@"存在连接过的外围设备");
                                [self.mgr connectPeripheral:self.peripheral options:nil];
                                if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
                                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                            if (![BlueToothDataManager shareManager].isConnected) {
                                                [UNCreatLocalNoti createLBEDisConnectNoti];
                                            }
                                    });
                                }
                            } else {
                                UNDebugLogVerbose(@"不存在连接过的外围设备");
                                [self.mgr scanForPeripheralsWithServices:nil options:nil];
                            }
                        } else {
                            UNDebugLogVerbose(@"本地有存储其他设备信息，不存在连接过的外围设备");
                            [self.mgr scanForPeripheralsWithServices:nil options:nil];
                        }
                    } else {
                        UNDebugLogVerbose(@"本地未存储其他设备信息,不存在连接过的外围设备");
                        [self.mgr scanForPeripheralsWithServices:nil options:nil];
                    }
                }
            });
            //-------------------------------------------------------------------------------
                //已经被系统或者其他APP连接上的设备数组
            /*
            if (!self.pairedArr) {
                self.pairedArr = [[NSArray alloc] initWithArray:[self.mgr retrieveConnectedPeripheralsWithServices:@[[CBUUID UUIDWithString:UUIDFORSERVICE1SERVICE]]]];
            } else {
                self.pairedArr = nil;
                self.pairedArr = [[NSArray alloc] initWithArray:[self.mgr retrieveConnectedPeripheralsWithServices:@[[CBUUID UUIDWithString:UUIDFORSERVICE1SERVICE]]]];
            }
            if(self.pairedArr.count>0) {
                UNDebugLogVerbose(@"连接的配对设备 - %@", self.pairedArr);
                for (CBPeripheral* peripheral in self.pairedArr) {
                    NSString *nameStr = peripheral.name;
                    NSString *allDeviceStr = MYDEVICENAME;
                    if ([peripheral.name containsString:MYDEVICENAMEUNITOYS]) {
                        nameStr = MYDEVICENAMEUNITOYS;
                    }
                    if ([peripheral.name containsString:MYDEVICENAMEUNIBOX]) {
                        nameStr = MYDEVICENAMEUNIBOX;
                    }
                    if ([BlueToothDataManager shareManager].deviceType) {
                        if ([[BlueToothDataManager shareManager].deviceType isEqualToString:MYDEVICENAMEUNITOYS]) {
                            //手环
                            allDeviceStr = MYDEVICENAMEUNITOYS;
                        } else if ([[BlueToothDataManager shareManager].deviceType isEqualToString:MYDEVICENAMEUNIBOX]) {
                            //钥匙扣
                            allDeviceStr = MYDEVICENAMEUNIBOX;
                        } else {
                            UNDebugLogVerbose(@"类型错了");
                        }
                    }
                    if (peripheral != nil && [allDeviceStr containsString:nameStr.lowercaseString]) {
                        
                        //获取mac地址
                        if (!self.boundedDeviceInfo[@"IMEI"] && peripheral.name.length > nameStr.length+1) {
                            [BlueToothDataManager shareManager].deviceMacAddress = [self conventMACAddressFromNetWithStr:[peripheral.name substringFromIndex:nameStr.length+1].lowercaseString];
                        }
                        if (self.boundedDeviceInfo[@"IMEI"]) {
                            NSString *boundStr = self.boundedDeviceInfo[@"IMEI"];
                            [BlueToothDataManager shareManager].deviceMacAddress = boundStr.lowercaseString;
                        }
                        //绑定设备
                        if (!self.boundedDeviceInfo[@"IMEI"]) {
                            if ([BlueToothDataManager shareManager].isNeedToBoundDevice) {
                                //调用绑定设备接口
                                self.strongestRssiPeripheral = peripheral;
                                [self.macAddressDict setObject:[BlueToothDataManager shareManager].deviceMacAddress forKey:peripheral.identifier];
                                [self checkDeviceIsBound];
                                [BlueToothDataManager shareManager].isNeedToBoundDevice = NO;
                                [BlueToothDataManager shareManager].isConnectedPairedDevice = NO;
                            } else {
                                UNDebugLogVerbose(@"啥都不做");
                                [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTBOUND];
                            }
                        } else {
                            UNDebugLogVerbose(@"已经绑定过了%@", self.boundedDeviceInfo[@"IMEI"]);
                            //已经绑定过
                            NSString *boundMac = self.boundedDeviceInfo[@"IMEI"];
                            if ([boundMac.lowercaseString isEqualToString:[BlueToothDataManager shareManager].deviceMacAddress]) {
                                peripheral.delegate = self;
                                self.peripheral = peripheral;
                                [self.mgr connectPeripheral:self.peripheral options:nil];
                            } else {
                                //                                HUDNormal(INTERNATIONALSTRING(@"请忽略您之前的设备"))
                                [self showHudNormalString:INTERNATIONALSTRING(@"请忽略您之前的设备")];
                            }
                        }
                    }
                }
            } else {
                UNDebugLogVerbose(@"没有配对设备");
                
                NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
                NSMutableDictionary *boundedDeviceInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"boundedDeviceInfo"]];
                if ([boundedDeviceInfo objectForKey:userdata[@"Tel"]]) {
                    NSArray *arr = [self.mgr retrievePeripheralsWithIdentifiers:@[[[NSUUID alloc] initWithUUIDString:[boundedDeviceInfo objectForKey:userdata[@"Tel"]]]]];
                    UNDebugLogVerbose(@"本地存储的设备信息 -- %@", arr);
                    if (arr.count) {
                        self.peripheral = arr[0];
                        UNDebugLogVerbose(@"获取到了存储的peripheral - %@", self.peripheral);
                        if (self.peripheral) {
                            UNDebugLogVerbose(@"存在连接过的外围设备");
                            [self.mgr connectPeripheral:self.peripheral options:nil];
                        } else {
                            UNDebugLogVerbose(@"不存在连接过的外围设备");
                            [self.mgr scanForPeripheralsWithServices:nil options:nil];
                        }
                    } else {
                        UNDebugLogVerbose(@"本地有存储其他设备信息，不存在连接过的外围设备");
                        [self.mgr scanForPeripheralsWithServices:nil options:nil];
                    }
                } else {
                    UNDebugLogVerbose(@"本地未存储其他设备信息,不存在连接过的外围设备");
                    [self.mgr scanForPeripheralsWithServices:nil options:nil];
                }
            }
             */
            //-----------------------------------------------------------------------------------------
        }
            break;
        default:
            break;
    }
    UNDebugLogVerbose(@"中心设备：%ld，%@ %@", (long)central.state, central, self.mgr);
}

#pragma mark 连接到某个外设的时候调用
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [BlueToothDataManager shareManager].isConnected = YES;
    [BlueToothDataManager shareManager].isLbeConnecting = NO;
    [self.mgr stopScan];
    [self.timer setFireDate:[NSDate distantFuture]];
    [self.scanAndConnectingTimer setFireDate:[NSDate distantFuture]];
    peripheral.delegate = self;
    NSString *nameStr = peripheral.name;
    NSString *allDeviceStr = MYDEVICENAME;
    if ([peripheral.name containsString:MYDEVICENAMEUNITOYS]) {
        nameStr = MYDEVICENAMEUNITOYS;
    }
    if ([peripheral.name containsString:MYDEVICENAMEUNIBOX]) {
        nameStr = MYDEVICENAMEUNIBOX;
    }
    if ([BlueToothDataManager shareManager].deviceType) {
        if ([[BlueToothDataManager shareManager].deviceType isEqualToString:MYDEVICENAMEUNITOYS]) {
            //手环
            allDeviceStr = MYDEVICENAMEUNITOYS;
        } else if ([[BlueToothDataManager shareManager].deviceType isEqualToString:MYDEVICENAMEUNIBOX]) {
            //钥匙扣
            allDeviceStr = MYDEVICENAMEUNIBOX;
        } else {
            UNLogLBEProcess(@"类型错了")
        }
    }
    if (peripheral != nil && [allDeviceStr containsString:nameStr.lowercaseString]) {
        
        //获取mac地址
        [BlueToothDataManager shareManager].deviceMacAddress = [self conventMACAddressFromNetWithStr:[peripheral.name substringFromIndex:nameStr.length+1].lowercaseString];
    }
    
    // 查找外设中的所有服务
    UNLogLBEProcess(@"连接成功，开始查找外设重所有服务%@",peripheral.name)
    if ([peripheral.name containsString:MYDEVICENAMEUNITOYS]) {
        self.connectedDeviceName = MYDEVICENAMEUNITOYS;
        [BlueToothDataManager shareManager].connectedDeviceName = MYDEVICENAMEUNITOYS;
    } else if ([peripheral.name containsString:MYDEVICENAMEUNIBOX]) {
        self.connectedDeviceName = MYDEVICENAMEUNIBOX;
        [BlueToothDataManager shareManager].connectedDeviceName = MYDEVICENAMEUNIBOX;
    } else {
        UNLogLBEProcess(@"连接的是什么设备")
    }
    
//    [BlueToothDataManager shareManager].isBounded = YES;
    //发送绑定成功通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"boundSuccess" object:@"boundSuccess"];
    
#warning 通过传入一个存放服务UUID的数组进去，过滤掉一些不要的服务
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [peripheral discoverServices:nil];
    });
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [BlueToothDataManager shareManager].isLbeConnecting = NO;
    UNLogLBEProcess(@"连接失败 - %@", error)
}

#pragma mark 跟某个外设失去连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    UNLogLBEProcess(@"跟外设失去连接")
    [BlueToothDataManager shareManager].isCanSendAuthData = NO;
    [UNPushKitMessageManager shareManager].isNeedRegister = NO;
    [BlueToothDataManager shareManager].isLbeConnecting = NO;
    [BlueToothDataManager shareManager].isAlreadyShowElectyAlert = NO;
    //    [BlueToothDataManager shareManager].isRegisted = NO;
    [BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue = NO;
//    [BlueToothDataManager shareManager].isBounded = NO;
    [BlueToothDataManager shareManager].isConnected = NO;
    [BlueToothDataManager shareManager].isConnectedPairedDevice = NO;
    [BlueToothDataManager shareManager].deviceMacAddress = nil;
    [BlueToothDataManager shareManager].electricQuantity = nil;
    [BlueToothDataManager shareManager].versionNumber = nil;
    [BlueToothDataManager shareManager].currentStep = @"0";
    [BlueToothDataManager shareManager].bleStatueForCard = 0;
    [BlueToothDataManager shareManager].isBeingRegisting = NO;
    [BlueToothDataManager shareManager].stepNumber = @"000";
    [BlueToothDataManager shareManager].boundedDeviceName = [BlueToothDataManager shareManager].connectedDeviceName;
    [BlueToothDataManager shareManager].connectedDeviceName = nil;
    [BlueToothDataManager shareManager].chargingState = 1;
    [BlueToothDataManager shareManager].iccidFromTcp = nil;
    [BlueToothDataManager shareManager].iccidFromBle = nil;
    [BlueToothDataManager shareManager].isDoneRegist = NO;
    [BlueToothDataManager shareManager].operatorType = nil;
    [BlueToothDataManager shareManager].currentSimCardStatu = 0;
    [BlueToothDataManager shareManager].isHaveCard = NO;
    self.appdenStr = nil;
    
    if (self.isKill) {
        return;
    }
    
    if ([self.connectedDeviceName isEqualToString:MYDEVICENAMEUNIBOX]) {
        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTBOUND];
    } else if ([self.connectedDeviceName isEqualToString:MYDEVICENAMEUNITOYS]) {
        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
    } else {
        UNLogLBEProcess(@"这是什么鬼类型")
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"deviceIsDisconnect" object:@"deviceIsDisconnect"];
    if (![BlueToothDataManager shareManager].isAccordBreak) {
        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
        [self checkBindedDeviceFromNet];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (![BlueToothDataManager shareManager].isConnected && [BlueToothDataManager shareManager].isOpened) {
                [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
                [self.mgr stopScan];
                //开始计时
                [self startTimer];
            }
        });
    }
    if (![BlueToothDataManager shareManager].isSame) {
        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
    }
}



#pragma mark 开始计时
- (void)startTimer {
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
    } else {
        [self.timer setFireDate:[NSDate distantPast]];
    }
}

- (void)timerAction {
    if (self.time == 60) {
        [self.timer setFireDate:[NSDate distantFuture]];
        self.time = 0;
        if (![BlueToothDataManager shareManager].isConnected && [BlueToothDataManager shareManager].isOpened && ![BlueToothDataManager shareManager].isLbeConnecting) {
            //重新连接
            [self checkBindedDeviceFromNet];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (![BlueToothDataManager shareManager].isConnected && [BlueToothDataManager shareManager].isOpened) {
                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
                    [self.mgr stopScan];
                    //开始计时
                    [self startTimer];
                }
            });
        }
    }
    self.time++;
}


#pragma mark - CBPeripheralDelegate
#pragma mark 外设已经查找到服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        UNLogLBEProcess(@"Error didDiscoverServices: %@", [error localizedDescription])
        return;
    }
    // 遍历所有的服务
    for (CBService *service in peripheral.services) {
        // 过滤掉不想要的服务
        if ([[service.UUID UUIDString] isEqual:UUIDFORSERVICE1SERVICE]) {
            // 扫描服务下面的特征
#warning 通过传入一个存放特征UUID的数组进去，过滤掉一些不要的特征
            [peripheral discoverCharacteristics:nil forService:service];
        }
        UNDebugLogVerbose(@"蓝牙设备的服务：%@", service);
    }
}

#pragma mark 获取到外设特征
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // 遍历所有的特征
    for (CBCharacteristic *characteristic in service.characteristics) {
        // 过滤掉不想要的特征
        if ([[characteristic.UUID UUIDString] isEqual:UUIDFORSERVICE1CHARACTERISTICTOWRITE]) {
            // 找到想要的特征
            UNDebugLogVerbose(@"这是写特属性特征");
            self.characteristic = characteristic;
            [self.peripheral setNotifyValue:YES forCharacteristic:characteristic];
        } else if ([[characteristic.UUID UUIDString] isEqual:UUIDFORSERVICE1CHARACTERISTICTONOTIF]) {
            UNDebugLogVerbose(@"这是第一个通知属性的特征");
            self.notifyCharacteristic = characteristic;
            [self.peripheral setNotifyValue:YES forCharacteristic:self.notifyCharacteristic];
        } else if ([[characteristic.UUID UUIDString] isEqual:UUIDFORSERVICE1CHARACTERISTICTONOTIF2]) {
            UNDebugLogVerbose(@"这是第一个通知属性的特征2");
            self.notifyCharacteristic2 = characteristic;
            [self.peripheral setNotifyValue:YES forCharacteristic:self.notifyCharacteristic2];
        }else if ([[characteristic.UUID UUIDString] isEqual:UUIDFORSERVICE1CHARACTERISTICTONOTIF3]) {
            UNDebugLogVerbose(@"这是第一个通知属性的特征3");
            self.notifyCharacteristic3 = characteristic;
            [self.peripheral setNotifyValue:YES forCharacteristic:self.notifyCharacteristic3];
        }
        UNDebugLogVerbose(@"characteristic:%@", characteristic);
    }
    if (![BlueToothDataManager shareManager].isBeingOTA && self.boundedDeviceInfo[@"IMEI"]) {
        //将连接的信息存储到本地
        UNLogLBEProcess(@"没有进行空中升级的时候连接 %@", [peripheral.identifier UUIDString])
        NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
        NSMutableDictionary *boundedDeviceInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"boundedDeviceInfo"]];
        [boundedDeviceInfo setObject:[peripheral.identifier UUIDString] forKey:userdata[@"Tel"]];
        [[NSUserDefaults standardUserDefaults] setObject:boundedDeviceInfo forKey:@"boundedDeviceInfo"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
//    [BlueToothDataManager shareManager].isConnected = YES;
    [BlueToothDataManager shareManager].isLbeConnecting = NO;
    if (self.normalAuthSimString) {
        [self sendLBEConnectData];
        [UNPushKitMessageManager shareManager].isQuickLoad = NO;
        [self updataToCard];
        [BlueToothDataManager shareManager].isRegisted = NO;
        [BlueToothDataManager shareManager].isBeingRegisting = YES;
        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_REGISTING];
        [self sendDataToVSW:self.normalAuthSimString];
        self.normalAuthSimString = nil;
    }else{
        [self sendInitMessageToBLE];
    }
    
}

//第一次发送蓝牙消息
- (void)sendInitMessageToBLE
{
    if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
            UNLogLBEProcess(@"发送pushkit消息到蓝牙")
        if ([UNPushKitMessageManager shareManager].pushKitMsgType == PushKitMessageTypeSimDisconnect) {
            UNLogLBEProcess(@"SIM断开连接消息类型")
            [self sendLBEMessageNoPushKit];
        }else{
            if ([UNPushKitMessageManager shareManager].simDataDict) {
//                [BlueToothDataManager shareManager].isBeingRegisting = YES;
                [self sendLBEMessageWithPushKit];
            }else{
                [self sendLBEConnectData];
            }
        }
    }else{
        [self sendLBEMessageNoPushKit];
    }
}

- (void)sendLBEConnectData
{
    UNLogLBEProcess(@"sendLBEConnectData")
    //告诉蓝牙是苹果设备
    [self sendMessageToBLEWithType:BLETellBLEIsApple validData:@"01"];
    //同步时间
    [self checkNowTime];
    //请求基本信息
    [self sendMessageToBLEWithType:BLESystemBaseInfo validData:nil];
    if (self.boundedDeviceInfo[@"IMEI"]) {
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] isEqualToString:@"on"]) {
            //请求卡类型和ICCID
            if (![UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
                UNLogLBEProcess(@"获取卡类型")
                if (![[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] isEqualToString:@"on"]) {
                    [self sendMessageToBLEWithType:BLECardTypeAndICCID validData:nil];
                } else {
                    DebugUNLog(@"服务未开");
                    [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NOTSERVICE;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeStatueAll" object:HOMESTATUETITLE_NOTSERVICE];
                }
            }
        } else {
            [BlueToothDataManager shareManager].isShowStatuesView = YES;
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTSERVICE];
        }
    }
    //请求电量
    [self sendMessageToBLEWithType:BLECheckElectricQuantity validData:nil];
    //仅钥匙扣能连接
    [BlueToothDataManager shareManager].isSame = NO;
    if (!self.appdenStr) {
        for (int i = 0; i < 8; i++) {
            int a = arc4random() % 255;
            NSString *randomNumStr = [self hexStringFromString:[NSString stringWithFormat:@"%d", a]];
            if (!self.appdenStr.length) {
                self.appdenStr = randomNumStr;
            } else {
                self.appdenStr = [self.appdenStr stringByAppendingString:randomNumStr];
            }
        }
    }
//    appdenStr  = @"0102030405060708";
//    appdenStr  = @"e2ebbcecc1cc9f7a";
    NSString *encryptStr = [NSString doEncryptBuffer:[self convenStrToCharWithString:self.appdenStr]];
    UNLogLBEProcess(@"转换之后的文字 -- %@", self.appdenStr)
    UNLogLBEProcess(@"加密之后的文字 -- %@", encryptStr)
    [BlueToothDataManager shareManager].checkStr = encryptStr;
    [self sendMessageToBLEWithType:BLEJUSTBOXCANCONNECT validData:self.appdenStr];
    [self startEncryptionTimer];
}

- (void)startEncryptionTimer {
    self.encryptionTimeValue = 0;
    if (!self.encryptionTimer) {
        self.encryptionTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(actionToEncryption) userInfo:nil repeats:YES];
        //如果不添加下面这条语句，在UITableView拖动的时候，会阻塞定时器的调用
        [[NSRunLoop currentRunLoop] addTimer:self.encryptionTimer forMode:UITrackingRunLoopMode];
    } else {
        [self.encryptionTimer setFireDate:[NSDate distantPast]];
    }
}

- (void)actionToEncryption {
    if (self.encryptionTimeValue == 4) {
        if (![BlueToothDataManager shareManager].isSame) {
            [self closeConnecting];
        }
        [self.encryptionTimer setFireDate:[NSDate distantFuture]];
    }
    self.encryptionTimeValue++;
    UNDebugLogVerbose(@"加密正在计时 -- %d", self.encryptionTimeValue);
}

- (void)checkSystemInfo {
    //请求基本信息
//    [self sendMessageToBLEWithType:BLESystemBaseInfo validData:nil];
    //请求卡类型和ICCID
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] isEqualToString:@"on"]) {
        [self sendMessageToBLEWithType:BLECardTypeAndICCID validData:nil];
    } else {
        DebugUNLog(@"服务未开");
        [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NOTSERVICE;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"changeStatueAll" object:HOMESTATUETITLE_NOTSERVICE];
    }
}

//请求系统基本信息
- (void)checkSystemBaseInfo
{
    if ([BlueToothDataManager shareManager].isConnected) {
        if (![BlueToothDataManager shareManager].isHaveCard) {
            [self sendMessageToBLEWithType:BLESystemBaseInfo validData:nil];
        }
    }else{
        if (![BlueToothDataManager shareManager].isLbeConnecting) {
            [self checkBindedDeviceFromNet];
        }
    }
}

- (void)sendLBEMessageWithPushKit
{
    UNLogLBEProcess(@"sendLBEMessageWithPushKit")
    if ([BlueToothDataManager shareManager].isConnected) {
        UNLogLBEProcess(@"蓝牙连接正常")
        [self sendMessageToBLEWithType:BLETellBLEIsApple validData:@"01"];
        [self sendMessageToBLEWithType:BLESystemBaseInfo validData:nil];
        [self sendMessageToBLEWithType:BLEJUSTBOXCANCONNECT validData:nil];
        
        
        [BlueToothDataManager shareManager].isRegisted = NO;
        [BlueToothDataManager shareManager].isBeingRegisting = YES;
        [UNPushKitMessageManager shareManager].isQuickLoad = YES;
        
        //对卡上电
        UNDebugLogVerbose(@"对卡上电03");
        [self updataToCard];
        
        if ([UNPushKitMessageManager shareManager].simDataDict[@"time"]) {
            NSString *timeString = [UNPushKitMessageManager shareManager].simDataDict[@"time"];
            CGFloat dataTime = [timeString doubleValue];
            NSDate *dataDate = [NSDate dateWithTimeIntervalSince1970:dataTime];
            NSTimeInterval timeValue = [dataDate timeIntervalSinceNow];
            UNLogLBEProcess(@"时间差为---%f", timeValue);
            if (timeValue > 150.0) {
                UNLogLBEProcess(@"时间太久,丢弃当前数据")
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PushKitMessageDataTimeout" object:nil];
            }else{
                UNLogLBEProcess(@"在规定时间内发送数据")
                [self sendDataToVSW:[UNPushKitMessageManager shareManager].simDataDict[@"dataString"]];
            }
        }
        
    }else{
        UNLogLBEProcess(@"蓝牙未连接")
        if (![BlueToothDataManager shareManager].isLbeConnecting) {
            [self checkBindedDeviceFromNet];
        }
    }
}

//解析鉴权数据
- (void)analysisAuthDataWithString:(NSString *)string
{
    if ([BlueToothDataManager shareManager].isConnected) {
        UNLogLBEProcess(@"解析鉴权数据")
//        if ([BlueToothDataManager shareManager].isCanSendAuthData) {
            [UNPushKitMessageManager shareManager].isQuickLoad = NO;
            [self updataToCard];
            [self sendDataToVSW:string];
//        }
    }else{
        UNLogLBEProcess(@"蓝牙未连接")
        if (![BlueToothDataManager shareManager].isLbeConnecting) {
            self.normalAuthSimString = string;
            [self checkBindedDeviceFromNet];
        }
    }
}

- (void)sendLBEMessageSIMDisConnect
{
    UNLogLBEProcess(@"sendLBEMessageSIMDisConnect")
    if ([BlueToothDataManager shareManager].isConnected) {
        [UNPushKitMessageManager shareManager].isQuickLoad = NO;
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] isEqualToString:@"on"]) {
            [self sendMessageToBLEWithType:BLECardTypeAndICCID validData:nil];
        } else {
            DebugUNLog(@"服务未开");
            [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NOTSERVICE;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"changeStatueAll" object:HOMESTATUETITLE_NOTSERVICE];
        }
    }
}

- (void)sendLBEMessageNoPushKit
{
    UNLogLBEProcess(@"sendLBEMessageNoPushKit")
    if ([BlueToothDataManager shareManager].isConnected) {
        [UNPushKitMessageManager shareManager].isQuickLoad = NO;
        
        [self sendLBEConnectData];
        
        if ([[BlueToothDataManager shareManager].deviceType isEqualToString:MYDEVICENAMEUNITOYS]) {
            //连接的是手环
            //对卡上电
//            [self phoneCardToUpeLectrify:@"01"];
            [self bindBoundDevice];
        } else if ([[BlueToothDataManager shareManager].deviceType isEqualToString:MYDEVICENAMEUNIBOX]) {
            //连接的是钥匙扣
            if (!self.boundedDeviceInfo[@"IMEI"]) {
                
                //发送绑定请求
                [self sendMessageToBLEWithType:BLECkeckToBound validData:nil];
                [self startBoundTimer];
            } else {
                //对卡上电
//                [self phoneCardToUpeLectrify:@"01"];
            }
        } else {
//            UNDebugLogVerbose(@"已绑定过之后上电");
            //对卡上电
//            [self phoneCardToUpeLectrify:@"01"];
        }
        //是否是能通知
        if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNITOYS]) {
            [self checkUserConfig];
        }
//        [self refreshBLEStatue];
        [self initBLEStatue];
    }else{
        UNLogLBEProcess(@"蓝牙未连接重连蓝牙")
        if (![BlueToothDataManager shareManager].isLbeConnecting) {
            [self checkBindedDeviceFromNet];
        }
    }
}

- (void)startScanAndConnectingTimer {
    self.scanAndConnectingTimeValue = 0;
    if (!self.scanAndConnectingTimer) {
        self.scanAndConnectingTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(actionToScanAndConnecting) userInfo:nil repeats:YES];
        //如果不添加下面这条语句，在UITableView拖动的时候，会阻塞定时器的调用
        [[NSRunLoop currentRunLoop] addTimer:self.scanAndConnectingTimer forMode:UITrackingRunLoopMode];
    } else {
        [self.scanAndConnectingTimer setFireDate:[NSDate distantPast]];
    }
}

//旧方法，没有列表
/*
- (void)actionToScanAndConnecting {
    if (self.scanAndConnectingTimeValue == 4) {
        CBPeripheral *temPer;
        NSNumber *tempRssi;
        switch (self.peripherals.count) {
            case 0:
                UNDebugLogVerbose(@"没有搜索到可连接的设备");
                //未连接
                if ([BlueToothDataManager shareManager].isOpened) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [BlueToothDataManager shareManager].isShowStatuesView = YES;
                    });
                    if (!self.boundedDeviceInfo) {
                        //更新状态
                        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
                    }
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(BLESCANTIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (![BlueToothDataManager shareManager].isConnected) {
                            //更新状态
                            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
                            [self.mgr stopScan];
                        }
                    });
                } else {
                    //更新状态
                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_BLNOTOPEN];
                }
                break;
            case 1:
                temPer = self.peripherals[0];
                tempRssi = [self.RSSIDict objectForKey:temPer.identifier];
                if ([tempRssi intValue]<= 0) {
                    self.strongestRssiPeripheral = self.peripherals[0];
                }
                break;
            default:
                for (CBPeripheral *per in self.peripherals) {
                    NSNumber *perRssi = [self.RSSIDict objectForKey:per.identifier];
                    if ([perRssi intValue] <= 0) {
                        self.strongestRssiPeripheral = per;
                        break;
                    }
                }
                for (CBPeripheral *per in self.peripherals) {
                    NSNumber *perRssi = [self.RSSIDict objectForKey:per.identifier];
                    NSNumber *strongRssi = [self.RSSIDict objectForKey:self.strongestRssiPeripheral.identifier];
                    if ([strongRssi intValue]< [perRssi intValue] && [perRssi intValue] <= 0 && self.strongestRssiPeripheral) {
                        self.strongestRssiPeripheral = per;
                        UNDebugLogVerbose(@"strongest -- %@", self.strongestRssiPeripheral);
                    }
                }
                break;
        }
        //获取mac地址
        if (!self.boundedDeviceInfo[@"IMEI"]) {
            [BlueToothDataManager shareManager].deviceMacAddress = [self checkDerviceMacAddress];
        }
        [BlueToothDataManager shareManager].isAccordBreak = NO;
        //绑定设备
        if ([BlueToothDataManager shareManager].isOpened) {
            if (!self.boundedDeviceInfo[@"IMEI"]) {
                //扫描蓝牙设备
                if ([BlueToothDataManager shareManager].isNeedToBoundDevice) {
                    //更新状态
                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTBOUND];
                    //调用绑定设备接口
                    [self checkDeviceIsBound];
                    [BlueToothDataManager shareManager].isNeedToBoundDevice = NO;
                }
            } else {
                UNDebugLogVerbose(@"已经绑定过了%@", self.boundedDeviceInfo[@"IMEI"]);
                //已经绑定过
            }
        } else {
            UNDebugLogVerbose(@"蓝牙未开");
        }
        [self stopScanBluetooth];
    }
    UNDebugLogVerbose(@"扫描计时器 -- %d", self.scanAndConnectingTimeValue);
    self.scanAndConnectingTimeValue++;
}
 */

- (void)actionToScanAndConnecting {
    if (self.scanAndConnectingTimeValue == 4) {
        switch (self.peripherals.count) {
            case 0:
                UNLogLBEProcess(@"没有搜索到可连接的设备")
                //未连接
                if ([BlueToothDataManager shareManager].isOpened) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [BlueToothDataManager shareManager].isShowStatuesView = YES;
                    });
                    if (!self.boundedDeviceInfo) {
                        //更新状态
                        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
                    }
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(BLESCANTIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (![BlueToothDataManager shareManager].isConnected) {
                            //更新状态
                            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
                            [self.mgr stopScan];
                        }
                    });
                } else {
                    //更新状态
                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_BLNOTOPEN];
                }
                break;
            default:
                
                for (int i = 0; i < self.peripherals.count; i++) {
                    for (int j = 0; j < self.peripherals.count-i-1; j++) {
                        CBPeripheral *perj = self.peripherals[j];
                        CBPeripheral *perjj = self.peripherals[j+1];
                        NSNumber *rssij = [self.RSSIDict objectForKey:perj.identifier];
                        NSNumber *rssijj = [self.RSSIDict objectForKey:perjj.identifier];
                        if ([rssij intValue] < [rssijj intValue]) {
                            //降序排列
                            [self.peripherals exchangeObjectAtIndex:j withObjectAtIndex:j+1];
                        }
                    }
                }
                break;
        }
        
        //获取mac地址
        if (!self.boundedDeviceInfo[@"IMEI"]) {
            [BlueToothDataManager shareManager].deviceMacAddress = [self checkDerviceMacAddress];
        }
        [BlueToothDataManager shareManager].isAccordBreak = NO;
        //绑定设备
        if ([BlueToothDataManager shareManager].isOpened) {
            if (!self.boundedDeviceInfo[@"IMEI"]) {
                //扫描蓝牙设备
                if ([BlueToothDataManager shareManager].isNeedToBoundDevice) {
                    //更新状态
                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTBOUND];
                    //调用绑定设备接口
//                    [self checkDeviceIsBound];
                    [self cehckDeviceBound];
                    [BlueToothDataManager shareManager].isNeedToBoundDevice = NO;
                }
            } else {
                UNLogLBEProcess(@"已经绑定过了%@", self.boundedDeviceInfo[@"IMEI"])
                //已经绑定过
            }
        } else {
            UNLogLBEProcess(@"蓝牙未开")
        }
        [self stopScanBluetooth];
    }
    UNDebugLogVerbose(@"扫描计时器 -- %d", self.scanAndConnectingTimeValue);
    self.scanAndConnectingTimeValue++;
}

#pragma mark 查询绑定的设备imei
- (void)cehckDeviceBound {
    if (self.peripherals.count) {
        NSMutableArray *imeiArr = [NSMutableArray array];
        if (self.peripherals.count <= 20) {
            UNDebugLogVerbose(@"外设不足20个,%s,%d", __FUNCTION__, __LINE__);
            for (CBPeripheral *per in self.peripherals) {
                NSString *imeiStr = [self.macAddressDict objectForKey:per.identifier];
                if (imeiStr) {
                    [imeiArr addObject:imeiStr];
                } else {
                    UNDebugLogVerbose(@"没有对应的IMEI %s,%d", __FUNCTION__, __LINE__);
                }
            }
        } else {
            UNDebugLogVerbose(@"外设多于20个,%s,%d", __FUNCTION__, __LINE__);
            for (int i = 0; i < 20; i++) {
                CBPeripheral *per = self.peripherals[i];
                NSString *imeiStr = [self.macAddressDict objectForKey:per.identifier];
                if (imeiStr) {
                    [imeiArr addObject:imeiStr];
                } else {
                    UNDebugLogVerbose(@"没有对应的IMEI %s,%d", __FUNCTION__, __LINE__);
                }
            }
        }
        
        //从服务器更新
        self.checkToken = YES;
        [self getBasicHeader];
        NSDictionary *params = @{@"IMEIs" : imeiArr};
        [SSNetworkRequest getJsonRequest:apiGetBindsIMEI params:params success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                NSMutableArray *deviceInfoArr = [NSMutableArray array];
                for (NSString *imei in imeiArr) {
                    NSMutableDictionary *deviceDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:imei.lowercaseString, @"mac", @"0", @"isAlreadyBind", nil];
                    [deviceInfoArr addObject:deviceDict];
                }
                NSArray *listArr = responseObj[@"data"][@"list"];
                if (listArr.count) {
                    for (NSString *imeiReturn in listArr) {
                        for (int i = 0; i < imeiArr.count; i++) {
                            NSString *imerStr = imeiArr[i];
                            if ([imeiReturn.lowercaseString isEqualToString:imerStr.lowercaseString]) {
                                NSMutableDictionary *deviceDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:imerStr.lowercaseString, @"mac", @"1", @"isAlreadyBind", nil];
                                [deviceInfoArr replaceObjectAtIndex:i withObject:deviceDict];
                            }
                        }
                    }
                }
                UNDebugLogVerbose(@"处理之后的绑定信息：%@", deviceInfoArr);
                [[NSNotificationCenter defaultCenter] postNotificationName:@"checkBoundDeviceInfo" object:deviceInfoArr];
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                UNDebugLogVerbose(@"返回的状态码异常,%s,%d", __FUNCTION__, __LINE__);
            }
            UNDebugLogVerbose(@"返回的绑定的设备的结果：%@",responseObj);
        } failure:^(id dataObj, NSError *error) {
            UNDebugLogVerbose(@"啥都没：%@",[error description]);
            [self showHudNormalString:@"网络貌似有问题"];
        } headers:self.headers];
    } else {
        UNLogLBEProcess(@"没有搜索到适配的设备,%s%d", __FUNCTION__, __LINE__)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"checkBoundDeviceInfo" object:nil];
    }
}

- (void)startBoundTimer {
    self.boundTimeValue = 0;
    if (!self.boundTimer) {
        self.boundTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(actionToBound) userInfo:nil repeats:YES];
        //如果不添加下面这条语句，在UITableView拖动的时候，会阻塞定时器的调用
        [[NSRunLoop currentRunLoop] addTimer:self.boundTimer forMode:UITrackingRunLoopMode];
    } else {
        [self.boundTimer setFireDate:[NSDate distantPast]];
    }
}

- (void)actionToBound {
    if (self.boundTimeValue == 20) {
        if (![BlueToothDataManager shareManager].isAllowToBound) {
            [self hideHud];
            [BlueToothDataManager shareManager].isAccordBreak = YES;
            [self sendMessageToBLEWithType:BLEIsBoundSuccess validData:@"00"];
            [self.mgr cancelPeripheralConnection:self.peripheral];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"boundDeviceFailNotifi" object:@"boundDeviceFailNotifi"];
            //                        [self sendDataToUnBoundDevice];
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTBOUND];
            [self showHudNormalString:INTERNATIONALSTRING(@"绑定失败")];
            [BlueToothDataManager shareManager].isBounded = NO;
            [self.boundTimer setFireDate:[NSDate distantFuture]];
        }
    }
    self.boundTimeValue++;
    UNDebugLogVerbose(@"正在计时 -- %d", self.boundTimeValue);
}

- (void)cancelToBound {
    [BlueToothDataManager shareManager].isAccordBreak = YES;
    [BlueToothDataManager shareManager].isBounded = NO;
    [self sendMessageToBLEWithType:BLEIsBoundSuccess validData:@"00"];
    [self.mgr cancelPeripheralConnection:self.peripheral];
    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTBOUND];
    [self.boundTimer setFireDate:[NSDate distantFuture]];
    [self.encryptionTimer setFireDate:[NSDate distantFuture]];
}

//初始化ICCID指令
- (void)sendICCIDMessage
{
    [BlueToothDataManager shareManager].isRegisted = NO;
    [BlueToothDataManager shareManager].isBeingRegisting = YES;
    [BlueToothDataManager shareManager].bleStatueForCard = 2;
    [UNPushKitMessageManager shareManager].sendICCIDCommands = @[@"a0a40000023f00",@"a0a40000022fe2",@"a0c000000f",@"a0b000000a"];
    [UNPushKitMessageManager shareManager].sendICCIDIndex = 0;
    [self sendICCIDCommand:[UNPushKitMessageManager shareManager].sendICCIDIndex];
}

//发送ICCID指令
- (void)sendICCIDCommand:(NSInteger)index
{
    if (index < [UNPushKitMessageManager shareManager].sendICCIDCommands.count) {
        [self sendMessageToBLEWithType:BLECardData validData:[UNPushKitMessageManager shareManager].sendICCIDCommands[index]];
    }
}

#pragma mark 初始化蓝牙状态
- (void)initBLEStatue
{
    if ([BlueToothDataManager shareManager].isConnected) {
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] isEqualToString:@"on"]) {
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_REGISTING];
        } else {
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTSERVICE];
        }
    } else {
        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
    }
}

#pragma mark 更新蓝牙状态
- (void)refreshBLEStatue {
    if ([BlueToothDataManager shareManager].isConnected) {
        if (![BlueToothDataManager shareManager].isHaveCard) {
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTINSERTCARD];
        } else {
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_REGISTING];
        }
    } else {
        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    UNDebugLogVerbose(@"发送指令成功")
    if (!error) {
        UNLogLBEProcess(@"发送指令成功无错误");
    }else{
        UNLogLBEProcess(@"发送指令错误%@",error)
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    UNDebugLogVerbose(@"接收到数据什么鬼？");
}


#pragma mark 当接收到蓝牙设备发送来的数据包时就会调用此方法
#pragma mark ---- peripheral: didUpdateValueForCharacteristic
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        UNLogLBEProcess(@"Error discovering characteristics: %@", [error localizedDescription])
        return;
    }
    UNLogLBEProcess(@"接收到蓝牙发送过来的数据value --> %@",characteristic.value)
    
#pragma mark 把接收到的数据进行截取
    NSString *str = [NSString stringWithFormat:@"%@",characteristic.value];
    if ([str containsString:@"<"]) {
        str = [str stringByReplacingOccurrencesOfString:@"<" withString:@""];
    }
    if ([str containsString:@">"]) {
        str = [str stringByReplacingOccurrencesOfString:@">" withString:@""];
    }
    if ([str containsString:@" "]) {
        str = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
    NSString *contentStr;
    NSString *versionNumber;
    if ([[str substringWithRange:NSMakeRange(0, 2)] isEqualToString:@"55"]) {
        //新协议的标志
        NSString *typeStr = [str substringWithRange:NSMakeRange(2, 2)];
        if ([typeStr isEqualToString:@"00"] || [typeStr isEqualToString:@"80"]) {
            self.dataPackegType = [self convertRangeStringToIntWithString:str rangeLoc:6 rangeLen:2];
            if (str.length > 10) {
                contentStr = [str substringFromIndex:10];
                UNDebugLogVerbose(@"接收到的有效data -- %@", contentStr);
            }
        } else {
            if (self.dataPackegType == 9 || self.dataPackegType == 10) {
                if (str.length > 6) {
                    contentStr = [str substringFromIndex:6];
                    UNDebugLogVerbose(@"接收到的有效data -- %@", contentStr);
                }
            } else {
                UNDebugLogVerbose(@"接收到的数据不应该为多包%@",str);
                return;
            }
        }
        switch (self.dataPackegType) {
            case 1:
                //系统基本信息
                UNLogLBEProcess(@"接收到系统基本信息数据")
                //版本号
                int versionNumber1 = [self convertRangeStringToIntWithString:contentStr rangeLoc:0 rangeLen:2];
                int versionNumber2 = [self convertRangeStringToIntWithString:contentStr rangeLoc:2 rangeLen:2];
                if (versionNumber2 < 10) {
                    versionNumber = [NSString stringWithFormat:@"%d.0%d", versionNumber1, versionNumber2];
                } else {
                    versionNumber = [NSString stringWithFormat:@"%d.%d", versionNumber1, versionNumber2];
                }
                UNDebugLogVerbose(@"版本号:%@", versionNumber);
                [BlueToothDataManager shareManager].versionNumber = versionNumber;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshVersionNumber" object:@"refreshVersionNumber"];
                //电量
                int electricQuantity = [self convertRangeStringToIntWithString:contentStr rangeLoc:4 rangeLen:2];
                if (electricQuantity <= LOWELECTYNUM && ![BlueToothDataManager shareManager].isAlreadyShowElectyAlert && [BlueToothDataManager shareManager].chargingState != 2) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"showLowElectyAlert" object:@"showLowElectyAlert"];
                }
                UNDebugLogVerbose(@"当前电量为：%d%%", electricQuantity);
                [BlueToothDataManager shareManager].electricQuantity = [NSString stringWithFormat:@"%d", electricQuantity];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"boundSuccessAndAddElecty" object:@"boundSuccessAndAddElecty"];
                if (![UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
                    [self refreshBLEInfo];
                }
                //是否有卡
                if (contentStr.length >= 8) {
                    NSString *isHaveCardStr = [contentStr substringWithRange:NSMakeRange(6, 2)];
                    if ([isHaveCardStr isEqualToString:@"00"]) {
                        UNLogLBEProcess(@"系统基本信息 -- 无卡")
                        [BlueToothDataManager shareManager].isDoneRegist = NO;
                        [BlueToothDataManager shareManager].isHaveCard = NO;
                        [BlueToothDataManager shareManager].currentSimCardStatu = 1;
                    } else if ([isHaveCardStr isEqualToString:@"01"]) {
                        UNLogLBEProcess(@"系统基本信息 -- 有卡")
                        [BlueToothDataManager shareManager].isHaveCard = YES;
                        [BlueToothDataManager shareManager].currentSimCardStatu = 2;
                    } else {
                        UNLogLBEProcess(@"系统基本信息 -- 状态有问题")
                        [BlueToothDataManager shareManager].currentSimCardStatu = 0;
                    }
                }
                if (![UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
                    [self otaDownload];
                }
                break;
            case 2:
                //电量
                UNLogLBEProcess(@"接收到电量数据")
                int electricQuantityNew = [self convertRangeStringToIntWithString:contentStr rangeLoc:0 rangeLen:2];
                if (electricQuantityNew <= LOWELECTYNUM && ![BlueToothDataManager shareManager].isAlreadyShowElectyAlert && [BlueToothDataManager shareManager].chargingState != 2) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"showLowElectyAlert" object:@"showLowElectyAlert"];
                }
                UNDebugLogVerbose(@"当前电量为：%d%%", electricQuantityNew);
                [BlueToothDataManager shareManager].electricQuantity = [NSString stringWithFormat:@"%d", electricQuantityNew];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"boundSuccessAndAddElecty" object:@"boundSuccessAndAddElecty"];
                break;
            case 3:
                //充电状态
                UNDebugLogVerbose(@"接收到充电状态数据")
                int chargeStatue = [self convertRangeStringToIntWithString:contentStr rangeLoc:0 rangeLen:2];
                UNLogLBEProcess(@"充电状态 --> %d", chargeStatue)
                [BlueToothDataManager shareManager].chargingState = chargeStatue;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"chargeStatuChanged" object:@"chargeStatuChanged"];
                switch (chargeStatue) {
                    case 1:
                        UNDebugLogVerbose(@"未充电");
                        break;
                    case 2:
                        UNDebugLogVerbose(@"正在充电");
                        break;
                    case 3:
                        UNDebugLogVerbose(@"充电完成");
                        break;
                    default:
                        UNDebugLogVerbose(@"充电状态有问题");
                        break;
                }
                break;
            case 4:
                //同意绑定
                UNLogLBEProcess(@"接收到同意绑定数据")
                [self.boundTimer setFireDate:[NSDate distantFuture]];
                [BlueToothDataManager shareManager].isAllowToBound = YES;
                [self sendMessageToBLEWithType:BLEIsBoundSuccess validData:@"01"];
                //请求卡类型和ICCID
                if (![[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] isEqualToString:@"on"]) {
                    [self sendMessageToBLEWithType:BLECardTypeAndICCID validData:nil];
                } else {
                    DebugUNLog(@"服务未开");
                    [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NOTSERVICE;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeStatueAll" object:HOMESTATUETITLE_NOTSERVICE];
                }
                [self bindBoundDevice];
                //对卡上电
//                [self phoneCardToUpeLectrify:@"01"];
                break;
            case 5:
                //实时计步
                UNLogLBEProcess(@"接收到实时计步数据")
                break;
            case 6:
                //历史步数
                UNLogLBEProcess(@"接收到历史计步数据")
                break;
            case 7:
                //回应上电
                if ([contentStr isEqualToString:@"01"]) {
                    UNLogLBEProcess(@"对卡上电1成功，有卡")
                    [BlueToothDataManager shareManager].isHaveCard = YES;
                    [BlueToothDataManager shareManager].currentSimCardStatu = 2;
                    //更新蓝牙状态
                    [self refreshBLEStatue];
                    //判断卡类型
                    [self checkCardType];
                } else if ([contentStr isEqualToString:@"11"]) {
                    [BlueToothDataManager shareManager].isRegisted = NO;
                    [BlueToothDataManager shareManager].currentSimCardStatu = 1;
                    UNLogLBEProcess(@"对卡上电1失败,没有卡")
                    if ([BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue) {
                        [self checkBLEAndReset];
                        [BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue = NO;
                    }
                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTINSERTCARD];
                } else if ([contentStr isEqualToString:@"02"]) {
                    UNLogLBEProcess(@"对卡上电2成功")
                } else if ([contentStr isEqualToString:@"12"]) {
                    UNLogLBEProcess(@"对卡上电2失败")
                    [BlueToothDataManager shareManager].isRegisted = NO;
                    [BlueToothDataManager shareManager].isBeingRegisting = NO;
                    [self registFailAction];
                    
                } else if ([contentStr isEqualToString:@"03"]) {
                    [BlueToothDataManager shareManager].isCanSendAuthData = YES;
                    UNLogLBEProcess(@"对卡上电3成功")
                }else if ([contentStr isEqualToString:@"13"]) {
                    UNLogLBEProcess(@"对卡上电3失败")
                    [BlueToothDataManager shareManager].isRegisted = NO;
                    [BlueToothDataManager shareManager].isBeingRegisting = NO;
                    [self registFailAction];
                }
                break;
            case 8:
                //回应断电
                UNLogLBEProcess(@"对卡断电成功")
                break;
            case 9:
                //回应SIM数据
                UNLogLBEProcess(@"sim卡相关数据")
                if ([BlueToothDataManager shareManager].bleStatueForCard == 0) {
                    UNLogLBEProcess(@"错误的数据状态,这是sim卡的数据1")
                } else if ([BlueToothDataManager shareManager].bleStatueForCard == 1) {
                    UNLogLBEProcess(@"错误的数据状态,这是sim卡的数据2")
                } else if ([BlueToothDataManager shareManager].bleStatueForCard == 2) {
                    UNLogLBEProcess(@"接收到sim注册数据")
                    //注册手机卡状态
                    //注册电话卡的步骤
                    NSString *totalString = contentStr;
                    if (totalString) {
                        [self.dataPacketArray addObject:totalString];
                    }
                    //总包数
                    NSString *totalDataNumber;
                    //数据当前包数
                    NSString *dataCurrentNumber = [NSString stringWithFormat:@"%lu", strtoul([[str substringWithRange:NSMakeRange(2, 2)] UTF8String], 0, 16)+1];
                    if ([dataCurrentNumber intValue] >= 128) {
                        totalDataNumber = [NSString stringWithFormat:@"%d", [dataCurrentNumber intValue] - 128];
                        NSString *tempStr;
                        if (self.dataPacketArray.count) {
                            if (self.dataPacketArray.count == 1) {
                                self.totalString = self.dataPacketArray[0];
                            } else {
                                for (int i = 0; i < self.dataPacketArray.count; i++) {
                                    if (i == 0) {
                                        tempStr = self.dataPacketArray[0];
                                    } else {
                                        self.totalString = [NSString stringWithFormat:@"%@%@", tempStr, self.dataPacketArray[i]];
                                        tempStr = self.totalString;
                                    }
                                }
                            }
                            UNDebugLogVerbose(@"最终发送的数据包字符为：%@", self.totalString);
                            if ([UNPushKitMessageManager shareManager].sendICCIDIndex < [UNPushKitMessageManager shareManager].sendICCIDCommands.count) {
                                [UNPushKitMessageManager shareManager].sendICCIDIndex++;
                                if ([UNPushKitMessageManager shareManager].sendICCIDIndex == [UNPushKitMessageManager shareManager].sendICCIDCommands.count) {
                                    //判断本地是否存在ICCID
                                    [UNPushKitMessageManager shareManager].iccidString = [self getIccidWithString:self.totalString];
                                    
                                    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:[[UNPushKitMessageManager shareManager].iccidString lowercaseString]];
                                    UNDebugLogVerbose(@"iccid======%@", [UNPushKitMessageManager shareManager].iccidString);
                                    if (dict) {
                                        //创建tcp,建立连接
                                        [BlueToothDataManager shareManager].isFirstRegist = NO;
                                        [[NSNotificationCenter defaultCenter] postNotificationName:@"CreateTCPSocketToBLE" object:[UNPushKitMessageManager shareManager].iccidString];
                                    }else{
                                        //创建udp,初始化操作
                                        [BlueToothDataManager shareManager].isFirstRegist = YES;
                                        [UNPushKitMessageManager shareManager].isNeedRegister = YES;
                                        [[NSNotificationCenter defaultCenter] postNotificationName:@"CreateUDPSocketToBLE" object:self.simtype];
                                    }
                                    [UNPushKitMessageManager shareManager].sendICCIDCommands = nil;
                                    [UNPushKitMessageManager shareManager].sendICCIDIndex = 0;
                                    //对卡断电
                                    [self downElectToCard];
                                }else{
                                    [self sendICCIDCommand:[UNPushKitMessageManager shareManager].sendICCIDIndex];
                                }
                            }else{
                                if ([UNPushKitMessageManager shareManager].isNeedRegister) {
                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"receiveNewDtaaPacket" object:self.totalString];
                                }else{
                                    if (self.needSendDatas.count > self.currentSendIndex) {
                                        NSString *currentSendStr = self.needSendDatas[self.currentSendIndex];
                                        UNLogLBEProcess(@"currentSendStr-%@",currentSendStr)
                                        if (self.authenticationModel.isAddSendData) {
                                            if ([currentSendStr isEqualToString:@"a0c0000003"] || [currentSendStr isEqualToString:@"a0c000000c"]) {
                                                //最后一条额外数据
                                                UNDebugLogVerbose(@"====1111111====");
                                                UNDebugLogVerbose(@"最后一条额外数据");
                                                [[UNBLEDataManager sharedInstance] receiveDataFromBLE:self.totalString WithType:2];
                                                NSString *sendTcpStr = [self getStringToTcp];
                                                [self sendTcpString:sendTcpStr];
                                                UNDebugLogVerbose(@"sendTcpStr====%@", sendTcpStr);
                                            }else if([currentSendStr isEqualToString:self.authenticationModel.simData]){
                                                UNDebugLogVerbose(@"====2222222====");
                                                [[UNBLEDataManager sharedInstance] receiveDataFromBLE:self.totalString WithType:1];
                                                self.currentSendIndex += 1;
                                                [self sendDataToLBEWithIndex:self.currentSendIndex];
                                            }else{
                                                UNDebugLogVerbose(@"====3333333====");
                                                self.currentSendIndex += 1;
                                                [self sendDataToLBEWithIndex:self.currentSendIndex];
                                            }
                                        }else{
                                            //如果不是a088,到这里结束
                                            if ([currentSendStr isEqualToString:self.authenticationModel.simData]) {
                                                [[UNBLEDataManager sharedInstance] receiveDataFromBLE:self.totalString WithType:1];
                                                NSString *sendTcpStr = [self getStringToTcp];
                                                [self sendTcpString:sendTcpStr];
                                                UNLogLBEProcess(@"sendTcpStr====%@", sendTcpStr)
                                            }else{
                                                self.currentSendIndex += 1;
                                                [self sendDataToLBEWithIndex:self.currentSendIndex];
                                            }
                                        }
                                    }
                                    
                                }
                            }
                            [self.dataPacketArray removeAllObjects];
                            self.totalString = nil;
                        }
                    }
                } else {
                    //状态有问题
                    UNLogLBEProcess(@"状态有问题")
                }
                break;
            case 10:
                //爱小器国际卡数据
                UNLogLBEProcess(@"爱小器国际卡相关数据")
                if ([BlueToothDataManager shareManager].bleStatueForCard == 0) {
                    //默认状态，查询卡类型
                    NSString *totalString = contentStr;
                    UNLogLBEProcess(@"totalString -- %@", totalString)
                    if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"9f17"]) {
                        [self sendMessageToBLEWithType:BLEAixiaoqiCardData validData:@"a0a40000022f02"];
                    } else if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"9f0f"]) {
                        //A0B000000A
                        [self sendMessageToBLEWithType:BLEAixiaoqiCardData validData:@"a0b000000a"];
                    } else if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"0344"]) {
                        //对卡断电
                        UNDebugLogVerbose(@"对卡断电");
                        [self phoneCardToOutageNew];
                        //是大王卡
                        UNLogLBEProcess(@"是大王卡")
                        [BlueToothDataManager shareManager].cardType = @"1";
                        [BlueToothDataManager shareManager].isRegisted = NO;
                        [BlueToothDataManager shareManager].isActivityCard = YES;
                        [BlueToothDataManager shareManager].bleStatueForCard = 1;
                        [BlueToothDataManager shareManager].operatorType = @"2";
                        [[NSUserDefaults standardUserDefaults] setObject:[BlueToothDataManager shareManager].operatorType forKey:@"operatorType"];
                        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_AIXIAOQICARD];
                        [BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue = NO;
                    } else {
                        //对卡断电
                        UNDebugLogVerbose(@"对卡断电");
                        [self phoneCardToOutageNew];
                        UNLogLBEProcess(@"不是大王卡")
                        [BlueToothDataManager shareManager].cardType = @"2";
                        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_REGISTING];
                        //判断是否有指定套餐，并创建连接
                        [BlueToothDataManager shareManager].bleStatueForCard = 2;
                        [BlueToothDataManager shareManager].isCanSendAuthData = YES;
                        if ([BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue && ![BlueToothDataManager shareManager].isNeedToCheckStatue) {
                            //查询tcp连接状态
                            [self checkRegistStatue];
                            [BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue = NO;
                        } else {
                            //注册卡
                            [BlueToothDataManager shareManager].isNeedToCheckStatue = NO;
                            if ([BlueToothDataManager shareManager].isChangeSimCard || (![BlueToothDataManager shareManager].isTcpConnected && ![BlueToothDataManager shareManager].isRegisted)) {
                                
// ---取消延时查询套餐
//                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                    [BlueToothDataManager shareManager].isRegisted = NO;
                                    [BlueToothDataManager shareManager].isBeingRegisting = YES;
//                                    [BlueToothDataManager shareManager].isChangeSimCard = NO;
                                    UNLogLBEProcess(@"判断用户是否存在指定套餐")
                                    [self checkUserIsExistAppointPackage];
//                                });
                                
                            } else {
                                UNLogLBEProcess(@"注册卡---信号强")
                                [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_SIGNALSTRONG];
                            }
                        }
                    }
                } else if ([BlueToothDataManager shareManager].bleStatueForCard == 1) {
                    if ([BlueToothDataManager shareManager].isActivityCard) {
                        //激活大王卡的步骤
                        UNLogLBEProcess(@"接收到激活大王卡的数据 -- %@", str)
                        NSString *totalString;
                        if ([[str substringWithRange:NSMakeRange(2, 1)] isEqualToString:@"8"]) {
                            //是最后一个包
                            if ([[str substringWithRange:NSMakeRange(3, 1)] isEqualToString:@"0"]) {
                                //只有一个包
                                totalString = contentStr;
                            } else {
                                self.activityCardDataStr = [self.activityCardDataStr stringByAppendingString:contentStr];
                                totalString = self.activityCardDataStr;
                            }
                            self.activityCardDataStr = nil;
                            
                            UNDebugLogVerbose(@"totalString -- %@", totalString);
                            if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"9f17"]) {
                                if (!self.isNewCard) {
                                    [self sendMessageToBLEWithType:BLEAixiaoqiCardData validData:@"a0a40000022f02"];
                                } else {
                                    [self sendMessageToBLEWithType:BLEAixiaoqiCardData validData:@"a01000001dffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"];
                                    self.lastDataStr = @"a01000001dffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
                                }
                            } else if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"9f0f"]) {
                                //A0B000000A
                                [self sendMessageToBLEWithType:BLEAixiaoqiCardData validData:@"a0b000000a"];
                            } else if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"0344"] || [[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"0345"]) {
                                //对卡断电
                                UNDebugLogVerbose(@"对卡断电");
                                [self phoneCardToOutageNew];
                                self.bigKingCardNumber = [totalString substringWithRange:NSMakeRange(4, 16)];
                                
                                NSString *checkTypeStr = [self.bigKingCardNumber substringFromIndex:self.bigKingCardNumber.length-8];
                                if ([checkTypeStr intValue] > 300) {
                                    UNLogLBEProcess(@"是新版爱小器卡")
                                    self.isNewCard = YES;
                                } else {
                                    UNLogLBEProcess(@"是旧版爱小器卡")
                                }
                                [self checkQueueOrderData];
                            } else if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"9000"]) {
                                if (!self.isNewCard) {
                                    //对卡断电
                                    UNDebugLogVerbose(@"对卡断电");
                                    [self phoneCardToOutageNew];
                                    [self activitySuccess];
                                } else {
                                    if ([self.lastDataStr isEqualToString:@"a01400000c810301250082028281830100"]) {
                                        [self sendMessageToBLEWithType:BLEAixiaoqiCardData validData:@"a0c2000009d30782020181900101"];
                                        self.lastDataStr = @"a0c2000009d30782020181900101";
                                    } else {
                                        UNLogLBEProcess(@"激活卡有问题")
                                        [self phoneCardToOutageNew];
                                        UNDebugLogVerbose(@"返回数据有问题");
                                        [self hideHud];
                                        [self showHudNormalString:INTERNATIONALSTRING(@"激活失败")];
                                        [BlueToothDataManager shareManager].isShowHud = NO;
                                        self.isNewCard = NO;
                                        
                                        [self paySuccess];
                                    }
                                }
                            } else if ([[totalString substringWithRange:NSMakeRange(0, 2)] isEqualToString:@"91"]) {
                                
                                NSString *str = [NSString stringWithFormat:@"a0120000%@", [totalString substringWithRange:NSMakeRange(2, 2)]];
                                [self sendMessageToBLEWithType:BLEAixiaoqiCardData validData:str];
                                self.lastDataStr = @"a0120000";
                            } else if ([[totalString substringFromIndex:totalString.length - 10] isEqualToString:@"c06d3b9000"]) {
                                [self sendMessageToBLEWithType:BLEAixiaoqiCardData validData:@"a01400000c810301250082028281830100"];
                                self.lastDataStr = @"a01400000c810301250082028281830100";
                            } else if ([[totalString substringFromIndex:totalString.length - 10] isEqualToString:@"0201e69000"]) {
                                [self sendMessageToBLEWithType:BLEAixiaoqiCardData validData:self.activityCardData];
                            } else if ([[totalString substringFromIndex:totalString.length - 10] isEqualToString:@"6500649000"]) {
                                //激活成功
                                //对卡断电
                                UNLogLBEProcess(@"激活成功")
                                UNDebugLogVerbose(@"对卡断电");
                                [self phoneCardToOutageNew];
                                [self activitySuccess];
                                self.isNewCard = NO;
                            } else {
                                //对卡断电
                                UNDebugLogVerbose(@"对卡断电");
                                [self phoneCardToOutageNew];
                                UNLogLBEProcess(@"返回数据有问题")
                                [self hideHud];
                                [self showHudNormalString:INTERNATIONALSTRING(@"激活失败")];
                                [BlueToothDataManager shareManager].isShowHud = NO;
                                self.isNewCard = NO;
                                
                                [self paySuccess];
                            }
                            
                        } else {
                            //不是最后一个包
                            if (!self.activityCardDataStr.length) {
                                self.activityCardDataStr = contentStr;
                            } else {
                                self.activityCardDataStr = [self.activityCardDataStr stringByAppendingString:contentStr];
                            }
                        }
                    } else {
                        UNLogLBEProcess(@"激活大王卡状态有问题")
                    }
                } else if ([BlueToothDataManager shareManager].bleStatueForCard == 2) {
                    UNLogLBEProcess(@"错误的数据状态,这是爱小器卡的数据")
                } else {
                    //状态有问题
                    UNLogLBEProcess(@"状态有问题")
                }
                break;
            case 11:
                //回应收到空中升级指令
                UNLogLBEProcess(@"回应收到空中升级指令 -- %@", contentStr)
                break;
            case 12:
                //卡状态改变(热插拔)
                UNLogLBEProcess(@"蓝牙发送卡状态改变 -- %@", contentStr)
                if (contentStr.length == 4) {
                    int isHaveCardStatue = [self convertRangeStringToIntWithString:contentStr rangeLoc:0 rangeLen:2];
                    switch (isHaveCardStatue) {
                        case 0:
                        {
                            UNLogLBEProcess(@"卡状态改变 -- 无卡")
                            [BlueToothDataManager shareManager].isDoneRegist = NO;
                            [BlueToothDataManager shareManager].isShowStatuesView = YES;
                            if (![BlueToothDataManager shareManager].isBeingShowAlert && [BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue) {
                                [BlueToothDataManager shareManager].isBeingShowAlert = YES;
                                [self checkBLEAndReset];
                            }
                            if ([BlueToothDataManager shareManager].isConnected && [BlueToothDataManager shareManager].isTcpConnected) {
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"closeServiceNotifi" object:@"closeServiceNotifi"];
                            }
                            [BlueToothDataManager shareManager].stepNumber = @"0";
                            [BlueToothDataManager shareManager].operatorType = @"5";
                            [[NSUserDefaults standardUserDefaults] setObject:[BlueToothDataManager shareManager].operatorType forKey:@"operatorType"];
                            [UNPushKitMessageManager shareManager].isNeedRegister = NO;
                            [BlueToothDataManager shareManager].isHaveCard = NO;
                            [BlueToothDataManager shareManager].currentSimCardStatu = 1;
                            [BlueToothDataManager shareManager].isBeingRegisting = NO;
                            [BlueToothDataManager shareManager].isChangeSimCard = YES;
                            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTINSERTCARD];
                        }
                            break;
                        case 1:
                            UNLogLBEProcess(@"卡状态改变 -- 有卡")
//                            if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
//                                return;
//                            }
                            
                            int cardType = [self convertRangeStringToIntWithString:contentStr rangeLoc:2 rangeLen:2];
                            switch (cardType) {
                                case 0:
                                {
                                    UNLogLBEProcess(@"插卡，上电失败")
                                    [BlueToothDataManager shareManager].isShowStatuesView = YES;
                                    if (![BlueToothDataManager shareManager].isBeingShowAlert && [BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue) {
                                        [BlueToothDataManager shareManager].isBeingShowAlert = YES;
                                        [self checkBLEAndReset];
                                    }
                                }
                                    break;
                                case 1:
                                    UNLogLBEProcess(@"插卡，移动")
                                    break;
                                case 2:
                                    UNLogLBEProcess(@"插卡，联通")
                                    break;
                                case 3:
                                    UNLogLBEProcess(@"插卡，电信")
                                    break;
                                case 4:
                                    UNLogLBEProcess(@"插卡，爱小器")
                                    [BlueToothDataManager shareManager].isShowStatuesView = YES;
                                    if ([BlueToothDataManager shareManager].isConnected && [BlueToothDataManager shareManager].isTcpConnected) {
                                        [[NSNotificationCenter defaultCenter] postNotificationName:@"closeServiceNotifi" object:@"closeServiceNotifi"];
                                    }
                                    break;
                                default:
                                    [BlueToothDataManager shareManager].isShowStatuesView = YES;
                                    UNLogLBEProcess(@"插卡，无法识别")
                                    break;
                            }
                            [BlueToothDataManager shareManager].operatorType = [NSString stringWithFormat:@"%d", cardType];
                            [[NSUserDefaults standardUserDefaults] setObject:[BlueToothDataManager shareManager].operatorType forKey:@"operatorType"];
                            self.simtype = [self checkSimType];
                            if ([[BlueToothDataManager shareManager].operatorType isEqualToString:@"1"] || [[BlueToothDataManager shareManager].operatorType isEqualToString:@"2"] || [[BlueToothDataManager shareManager].operatorType isEqualToString:@"3"]) {
                                //有电话卡
                                [BlueToothDataManager shareManager].isHaveCard = YES;
                                [BlueToothDataManager shareManager].currentSimCardStatu = 2;
                                [BlueToothDataManager shareManager].cardType = @"2";
                            } else if ([[BlueToothDataManager shareManager].operatorType isEqualToString:@"4"]) {
                                //爱小器卡
                                [BlueToothDataManager shareManager].isHaveCard = YES;
                                [BlueToothDataManager shareManager].currentSimCardStatu = 2;
                                [BlueToothDataManager shareManager].cardType = @"1";
                                [BlueToothDataManager shareManager].isRegisted = NO;
                                [BlueToothDataManager shareManager].isActivityCard = YES;
                                [BlueToothDataManager shareManager].bleStatueForCard = 1;
                                [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_AIXIAOQICARD];
                                [BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue = NO;
                            } else if ([[BlueToothDataManager shareManager].operatorType isEqualToString:@"5"] || [[BlueToothDataManager shareManager].operatorType isEqualToString:@"0"]) {
                                [BlueToothDataManager shareManager].cardType = @"0";
                                [UNPushKitMessageManager shareManager].isNeedRegister = NO;
                                [BlueToothDataManager shareManager].isHaveCard = NO;
                                [BlueToothDataManager shareManager].currentSimCardStatu = 1;
                                [BlueToothDataManager shareManager].isBeingRegisting = NO;
                                [BlueToothDataManager shareManager].isChangeSimCard = YES;
                                if (cardType == 0) {
                                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_READCARDFAIL];
                                } else {
                                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTINSERTCARD];
                                }
                            } else {
                                UNLogLBEProcess(@"卡类型有问题 - %s,%d", __FUNCTION__, __LINE__)
                                [BlueToothDataManager shareManager].cardType = @"0";
                                [UNPushKitMessageManager shareManager].isNeedRegister = NO;
                                [BlueToothDataManager shareManager].isHaveCard = NO;
                                [BlueToothDataManager shareManager].currentSimCardStatu = 1;
                                [BlueToothDataManager shareManager].isBeingRegisting = NO;
                                [BlueToothDataManager shareManager].isChangeSimCard = YES;
                                [self showHudNormalString:@"您插入的卡不是常规卡，请更换"];
                                [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_READCARDFAIL];
                            }
                            break;
                        default:
                            UNLogLBEProcess(@"卡状态改变 -- 状态有问题")
                            break;
                    }
                    [BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue = NO;
                } else {
                    UNLogLBEProcess(@"这是旧版本的设备，需要强制空中升级")
                    [self showHudNormalString:@"您的蓝牙需要进行固件升级"];
                    [BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue = NO;
                    return;
                }
                break;
            case 13:
                UNLogLBEProcess(@"接收到SIM卡ICCID -- %@", contentStr)
                if (contentStr) {
//                    [[NSUserDefaults standardUserDefaults] setObject:contentStr forKey:@"SIMICCIDString"];
                    [self getboundPhoneWithIccid:contentStr];
                }
                
                if (![UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
                    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] isEqualToString:@"on"]) {
                        if (contentStr && [[BlueToothDataManager shareManager].cardType isEqualToString:@"2"]) {
                            [BlueToothDataManager shareManager].isShowStatuesView = YES;
                            [UNPushKitMessageManager shareManager].iccidString = contentStr.lowercaseString;
                            [BlueToothDataManager shareManager].iccidFromBle = contentStr.lowercaseString;
                            if ([BlueToothDataManager shareManager].iccidFromTcp) {
                                NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:[[UNPushKitMessageManager shareManager].iccidString lowercaseString]];
                                if ([[BlueToothDataManager shareManager].iccidFromTcp isEqualToString:[BlueToothDataManager shareManager].iccidFromBle] && dict) {
                                    //在线
                                    UNLogLBEProcess(@"同一张卡在线%s,%d", __FUNCTION__, __LINE__)
                                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_SIGNALSTRONG];
                                    [BlueToothDataManager shareManager].isRegisted = YES;
                                    [UNPushKitMessageManager shareManager].iccidString = [BlueToothDataManager shareManager].iccidFromTcp;
                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"isAlreadOnlineAndSendJumpDataNotifi" object:@"isAlreadOnlineAndSendJumpDataNotifi"];
                                } else {
                                    //不是同一张卡，需要重新注册
                                    UNLogLBEProcess(@"不是同一张卡在线，需要重新注册 - tcpiccid:%@ bleiccid:%@,%s,%d", [BlueToothDataManager shareManager].iccidFromTcp, [BlueToothDataManager shareManager].iccidFromBle, __FUNCTION__, __LINE__)
                                    [BlueToothDataManager shareManager].isChangeSimCard = YES;
                                    [self registSimCardStep];
                                }
                            } else {
                                //原先注册程序在这里
                                UNLogLBEProcess(@"不在线，正常注册 - %s,%d", __FUNCTION__, __LINE__)
                                [BlueToothDataManager shareManager].isDoneRegist = YES;
                                [self registSimCardStep];
                            }
                        }
                    } else {
                        UNLogLBEProcess(@"服务未开");
                        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTSERVICE];
                    }
                }else{
                    if ([UNPushKitMessageManager shareManager].pushKitMsgType == PushKitMessageTypeSimDisconnect) {
                        //判断本地是否存在ICCID
                        [UNPushKitMessageManager shareManager].iccidString = contentStr;
                        
                        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:[[UNPushKitMessageManager shareManager].iccidString lowercaseString]];
                        UNLogLBEProcess(@"iccid对应的数据======%@", dict);
                        if (dict) {
                            //创建tcp,建立连接
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"CreateTCPSocketToBLE" object:[UNPushKitMessageManager shareManager].iccidString];
                        }
                    }
                }
                break;
            case 14:
                //设置闹钟成功
                break;
            case 20:
                //接收到app返回的加密数据
                UNLogLBEProcess(@"接收到app返回的加密数据 -- %@", contentStr)
                if (![contentStr isEqualToString:[BlueToothDataManager shareManager].checkStr]) {
                    [BlueToothDataManager shareManager].isSame = NO;
                    [self closeConnecting];
                } else {
                    [BlueToothDataManager shareManager].isSame = YES;
                }
                [self.encryptionTimer setFireDate:[NSDate distantFuture]];
                break;
            default:
                UNLogLBEProcess(@"不能识别的类别")
                break;
        }
    }
}

- (void)registSimCardStep {
    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_REGISTING];
    //判断是否有指定套餐，并创建连接
    [BlueToothDataManager shareManager].bleStatueForCard = 2;
    [BlueToothDataManager shareManager].isCanSendAuthData = YES;
    if ([BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue && ![BlueToothDataManager shareManager].isNeedToCheckStatue) {
        //查询tcp连接状态
        [self checkRegistStatue];
        [BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue = NO;
    } else {
        //注册卡
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] isEqualToString:@"on"]) {
            [BlueToothDataManager shareManager].isNeedToCheckStatue = NO;
            if ([BlueToothDataManager shareManager].isChangeSimCard || (![BlueToothDataManager shareManager].isTcpConnected && ![BlueToothDataManager shareManager].isRegisted)) {
                
                // ---取消延时查询套餐
                //                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [BlueToothDataManager shareManager].isRegisted = NO;
                [BlueToothDataManager shareManager].isBeingRegisting = YES;
                //                                    [BlueToothDataManager shareManager].isChangeSimCard = NO;
                UNDebugLogVerbose(@"判断用户是否存在指定套餐");
                [self checkUserIsExistAppointPackage];
                //                                });
                
            } else {
                if ([BlueToothDataManager shareManager].isTcpConnected) {
                    if ([BlueToothDataManager shareManager].isRegisted) {
                        UNLogLBEProcess(@"注册卡---信号强")
                        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_SIGNALSTRONG];
                    } else {
                        UNLogLBEProcess(@"注册卡---需要重新注册")
                        UNLogLBEProcess(@"判断用户是否存在指定套餐")
                        [BlueToothDataManager shareManager].isBeingRegisting = YES;
                        [self checkUserIsExistAppointPackage];
                    }
                }else{
                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOSIGNAL];
                }
                
            }
        } else {
            UNLogLBEProcess(@"不注册")
            [self showHudNormalString:@"不注册"];
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTSERVICE];
            [BlueToothDataManager shareManager].isBeingRegisting = NO;
            [BlueToothDataManager shareManager].isRegisted = NO;
        }
    }
}

- (void)getboundPhoneWithIccid:(NSString *)iccidString
{
//    NSString *iccidKey = [NSString stringWithFormat:@"ValidateICCID%@", iccidString];
    NSString *iccidKey = [NSString stringWithFormat:@"ValidateICCID"];
    NSDictionary *iccidData = [[NSUserDefaults standardUserDefaults] objectForKey:iccidKey];
    if (!iccidData || ![iccidData[@"ICCID"] isEqualToString:iccidString]) {
        self.checkToken = YES;
        NSDictionary *params = @{@"ICCID" : iccidString};
        [self getBasicHeader];
        [SSNetworkRequest getRequest:apiUserDeviceTelCheckConfirmed params:params success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                if ([responseObj[@"data"][@"IsConfirmed"] boolValue]) {
                    if (responseObj[@"data"][@"Tel"] && [responseObj[@"data"][@"Tel"] length]) {
                        [[NSUserDefaults standardUserDefaults] setObject:@{@"ICCID" : iccidString, @"TEL" : responseObj[@"data"][@"Tel"]} forKey:iccidKey];
                        //重新注册网络电话
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"RegisterNetWorkCallPhone" object:nil];
                    }
                }else{
                    if (iccidData) {
                        [[NSUserDefaults standardUserDefaults] removeObjectForKey:iccidKey];
                    }
                }
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
                UNLogLBEProcess(@"请求失败：%@", responseObj[@"msg"])
            }
        } failure:^(id dataObj, NSError *error) {
            UNLogLBEProcess(@"请求失败：%@", error)
        } headers:self.headers];
    }
}

- (void)closeConnecting {
    if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
        return;
    }
    UNLogLBEProcess(@"关闭连接--closeConnecting")
//    if ([BlueToothDataManager shareManager].isBounded) {
//        [self u];
//    }
    [BlueToothDataManager shareManager].isAccordBreak = YES;
//    [BlueToothDataManager shareManager].isBounded = NO;
//    [self sendMessageToBLEWithType:BLEIsBoundSuccess validData:@"00"];
    [self.mgr cancelPeripheralConnection:self.peripheral];
//    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTBOUND];
//    [self.boundTimer setFireDate:[NSDate distantFuture]];
}

#pragma mark 查询订单卡数据
- (void)checkQueueOrderData {
    UNLogLBEProcess(@"查询订单卡")
    self.checkToken = YES;
    NSDictionary *params;
    if (!self.isNewCard) {
        params = [[NSDictionary alloc] initWithObjectsAndKeys:self.bigKingCardNumber,@"EmptyCardSerialNumber", self.activityOrderId, @"OrderID", nil];
    } else {
        params = [[NSDictionary alloc] initWithObjectsAndKeys:@"",@"EmptyCardSerialNumber", self.activityOrderId, @"OrderID", nil];
    }
    
    [self getBasicHeader];
//    UNDebugLogVerbose(@"表演头：%@",self.headers);
    
    [SSNetworkRequest postRequest:apiQueryOrderData params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            UNDebugLogVerbose(@"%@", responseObj);
            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:@"apiQueryOrderData" dictData:responseObj];
            //上电
            //对卡上电
            [self phoneCardToUpeLectrify:@"03"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (!self.isNewCard) {
                    [self sendMessageToBLEWithType:BLEAixiaoqiCardData validData:responseObj[@"data"][@"Data"]];
                } else {
                    [self sendMessageToBLEWithType:BLEAixiaoqiCardData validData:@"a0a40000023f00"];
                    self.activityCardData = [NSString stringWithFormat:@"a0140000738103012301820282818301008d6504%@", responseObj[@"data"][@"Data"]];
                }
            });
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            UNDebugLogVerbose(@"请求失败：%@", responseObj[@"msg"]);
        }
    } failure:^(id dataObj, NSError *error) {
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:@"apiQueryOrderData"];
        if (responseObj) {
            [self phoneCardToUpeLectrify:@"03"];
            [self sendMessageToBLEWithType:BLEAixiaoqiCardData validData:responseObj[@"data"][@"Data"]];
        }else{
            [self showHudNormalString:INTERNATIONALSTRING(@"网络貌似有问题")];
        }
        UNDebugLogVerbose(@"啥都没：%@",[error description]);
    } headers:self.headers];
}


#pragma mark 激活成功
- (void)activitySuccess {
    UNLogLBEProcess(@"激活成功activitySuccess")
    self.checkToken = YES;
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.activityOrderId, @"OrderID", nil];
    
    [self getBasicHeader];
//    UNDebugLogVerbose(@"表演头：%@",self.headers);
    
    [SSNetworkRequest postRequest:apiActivationLocalCompleted params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            UNDebugLogVerbose(@"%@", responseObj);
            [self hideHud];
            [BlueToothDataManager shareManager].isShowHud = NO;
            [self showHudNormalString:INTERNATIONALSTRING(@"激活成功")];
            [self paySuccess];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"actionOrderSuccess" object:@"actionOrderSuccess"];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [BlueToothDataManager shareManager].isShowHud = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"actionOrderStatueFail" object:@"actionOrderStatueFail"];
        }else{
            //数据请求失败
            [BlueToothDataManager shareManager].isShowHud = NO;
            UNDebugLogVerbose(@"请求失败：%@", responseObj[@"msg"]);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"actionOrderStatueFail" object:@"actionOrderStatueFail"];
        }
    } failure:^(id dataObj, NSError *error) {
        [BlueToothDataManager shareManager].isShowHud = NO;
        UNDebugLogVerbose(@"啥都没：%@",[error description]);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"actionOrderStatueFail" object:@"actionOrderStatueFail"];
    } headers:self.headers];
}

//获取Iccid
- (NSString *)getIccidWithString:(NSString *)string
{
    NSString *tempStr = [string substringToIndex:(string.length - 4)];
    return [self getReverseString:tempStr];
}

- (NSString *)getReverseString:(NSString *)string
{
    NSMutableString *mutaleString = [NSMutableString string];
    for (int i = 0; i < (string.length /2); i++) {
        [mutaleString appendString:[string substringWithRange:NSMakeRange(i*2+1, 1)]];
        [mutaleString appendString:[string substringWithRange:NSMakeRange(i*2, 1)]];
    }
    return mutaleString;
}

#pragma mark --解析鉴权数据并发送蓝牙数据
- (void)sendDataToVSW:(NSString *)string
{
    UNLogLBEProcess(@"sendDataToVSW--%@", string)
    if (!string) {
        return;
    }
    if (self.needSendDatas.count) {
        [self.needSendDatas removeAllObjects];
    }
    self.currentSendIndex = 0;
    [BlueToothDataManager shareManager].bleStatueForCard = 2;
    
    UNSimCardAuthenticationModel *model = [UNGetSimData getModelWithAuthenticationString:string];
    self.authenticationModel = model;
    if (model.simTypePrefix.length == 4) {
        NSString *simType = [model.simTypePrefix substringFromIndex:2];
        if ([simType isEqualToString:@"88"]) {
            [UNPushKitMessageManager shareManager].isHasSimType = YES;
            [UNPushKitMessageManager shareManager].simTypeData = @"C0";
        }else{
            NSArray *simArray = @[@"C0",@"B0",@"B2",@"F2",@"12"];
            if ([simArray containsObject:simType.uppercaseString]) {
                [UNPushKitMessageManager shareManager].isHasSimType = YES;
                [UNPushKitMessageManager shareManager].simTypeData = simType;
            }else{
                [UNPushKitMessageManager shareManager].isHasSimType = NO;
                [UNPushKitMessageManager shareManager].simTypeData = nil;
            }
        }
    }
    if (model.simdirectory && model.simdirectory.count) {
        for (NSString *simString in model.simdirectory) {
            NSString *sendData = [NSString stringWithFormat:@"a0a4000002%@", simString];
            [self.needSendDatas addObject:sendData];
        }
    }
    [self.needSendDatas addObject:model.simData];
    if (model.isAddSendData) {
        if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
            if ([self.simtype isEqualToString:@"0"]) {
                [BlueToothDataManager shareManager].operatorType = [[NSUserDefaults standardUserDefaults] objectForKey:@"operatorType"];
                self.simtype = [self checkSimType];
            }
        }
        
        if ([self.simtype isEqualToString:@"2"]) {
            //电信
            [self.needSendDatas addObject:@"a0c0000003"];
        }else if ([self.simtype isEqualToString:@"1"]){
            //移动联通
            [self.needSendDatas addObject:@"a0c000000c"];
        }else{
            return;
        }
    }
    UNLogLBEProcess(@"model===%@", model)
    UNLogLBEProcess(@"needSendDatas===%@",self.needSendDatas)
    [self sendDataToLBEWithIndex:self.currentSendIndex];
}

- (void)sendDataToLBEWithIndex:(NSInteger)index
{
    if (self.needSendDatas.count > index) {
        [self sendNewMessageToBLEWithPushKit:self.needSendDatas[index]];
    }else{
        UNLogLBEProcess(@"发送蓝牙数据错误====needSendDatas=====%@", self.needSendDatas)
    }
}

- (void)sendNewMessageToBLEWithPushKit:(NSString *)sendString
{
    if ([BlueToothDataManager shareManager].isConnected) {
        UNLogLBEProcess(@"获取卡数据sendNewMessageToBLEWithPushKit---%@", sendString)
        [self sendMessageToBLEWithType:BLECardData validData:sendString];
    }else{
        UNLogLBEProcess(@"蓝牙未连接")
        [self showHudNormalString:INTERNATIONALSTRING(@"蓝牙未连接")];
    }
}

//接受蓝牙的数据并根据规律组合
//- (NSString *)getStringToTcpWithShortString:(NSString *)shortStr LongString:(NSString *)longStr
- (NSString *)getStringToTcp
{
    //   收到的需要发送的数据 0003 0011 0F A0C000000C 9F0C C0 A9316DD53556EEAADB5C1F0F9000
    // 原始数据   00 34 05 11 000200 02 3f00 7f25 6f3a 0000 a08800001100000000640000000000639b9980000000
    // SDK传过来的数据  0034 0008 06 A0C0000003 9F03 C0 03AFC19000
    //    0008（总长度） 06（后面有效长度） a0c0000003（最后需要发送的命令） 9f03（a088返回的数据） c0（当前位置） 03AFC19000（加密返回的数据）
    
    NSString *shortStr = [UNBLEDataManager sharedInstance].shortString;
    NSString *longStr = [UNBLEDataManager sharedInstance].longString;
    NSMutableString *tempStr = [NSMutableString string];
    [tempStr appendString:self.authenticationModel.chn];
    [tempStr appendString:self.authenticationModel.cmdIndex];
    
    //加密返回的数据
    NSString *lastData;
    if (longStr) {
        lastData = longStr;
    }
    //卡类型
    NSString *simtTypeStr;
    if ([UNPushKitMessageManager shareManager].isHasSimType && [UNPushKitMessageManager shareManager].simTypeData) {
        simtTypeStr = [UNPushKitMessageManager shareManager].simTypeData;
    }
    //卡类型返回的数据(短数据,只有a088时才有)
    NSString *simTypeGetData = shortStr;
    //最后发送的命令
    NSString *lastStr = @"0000000000";
    if (self.authenticationModel.isAddSendData) {
        if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
            if ([self.simtype isEqualToString:@"0"]) {
                [BlueToothDataManager shareManager].operatorType = [[NSUserDefaults standardUserDefaults] objectForKey:@"operatorType"];
                self.simtype = [self checkSimType];
            }
        }
        if ([self.simtype isEqualToString:@"2"]) {
            //电信
            lastStr = @"a0c0000003";
        }else if ([self.simtype isEqualToString:@"1"]){
            //移动联通
            lastStr = @"a0c000000c";
        }
    }
    
    //后面有效长度
    NSInteger validStrLength = 0;
    NSString *laterLength;
    if (longStr) {
        if (lastData) {
            validStrLength += lastData.length;
        }
        if (simtTypeStr) {
            validStrLength += simtTypeStr.length;
        }
        validStrLength = validStrLength/2;
        laterLength = [self hexStringFromString:[NSString stringWithFormat:@"%zd", validStrLength]];
    }else{
        if (simtTypeStr) {
            validStrLength += simtTypeStr.length /2;
        }
        laterLength = @"00";
    }
    
    //总长度
    if (simTypeGetData) {
        validStrLength += (simTypeGetData.length/2);
    }
    NSString *totalLenth = [self hexStringFromString:[NSString stringWithFormat:@"%zd", validStrLength]];
    if (totalLenth.length == 2) {
        totalLenth = [NSString stringWithFormat:@"00%@", totalLenth];
    }else if (totalLenth.length == 3){
        totalLenth = [NSString stringWithFormat:@"0%@", totalLenth];
    }
    
    //总长度
    [tempStr appendString:totalLenth];
    //后面有效长度
    [tempStr appendString:laterLength];
    //最后发送的命令(a088才需要,移动联通电信才需要)
    if (lastStr) {
        [tempStr appendString:lastStr];
    }
    //卡类型返回的数据(如9f0c)
    if (lastData) {
        if (simTypeGetData) {
            [tempStr appendString:simTypeGetData];
        }
        //卡类型(如C0)
        if (simtTypeStr) {
            [tempStr appendString:simtTypeStr];
        }
        
        //加密返回的数据(a088时发送移动联通指令返回的数据)
        [tempStr appendString:lastData];
    }else{
        if (simtTypeStr) {
            [tempStr appendString:simtTypeStr];
        }
        if (simTypeGetData) {
            [tempStr appendString:simTypeGetData];
        }
    }
    
    //重置数据
    [[UNBLEDataManager sharedInstance] clearData];
    self.currentSendIndex = 0;
    [self.needSendDatas removeAllObjects];
    UNLogLBEProcess(@"发送给TCP的数据%@",[tempStr uppercaseString])
    return [tempStr uppercaseString];
}

//将组合的数据发送到tcp服务器
- (void)sendTcpString:(NSString *)string
{
    if ([UNPushKitMessageManager shareManager].isQuickLoad) {
        UNDebugLogVerbose(@"SendTcpDataFromPushKit");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SendTcpDataFromPushKit" object:nil userInfo:@{@"tcpString" : string}];
    }else{
        UNDebugLogVerbose(@"receiveNewDataStr");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"receiveNewDataStr" object:string];
    }
    self.authenticationModel = nil;
    [UNPushKitMessageManager shareManager].simDataDict = nil;
    [self.needSendDatas removeAllObjects];
    self.currentSendIndex = 0;
}

#pragma mark 判断用户是否存在指定套餐
- (void)checkUserIsExistAppointPackage {
    self.checkToken = YES;
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"PackageCategory", nil];
    
    [self getBasicHeader];
//    UNDebugLogVerbose(@"表演头：%@",self.headers);
    
    [SSNetworkRequest postRequest:apiCheckUsedExistByPageCategory params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            UNDebugLogVerbose(@"是否存在制定套餐:%@", responseObj);
            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:@"apiCheckUsedExistByPageCategory" dictData:responseObj];
            
            if ([responseObj[@"data"][@"Used"] intValue]/*0：不存在，1：存在*/) {
                [BlueToothDataManager shareManager].isHavePackage = YES;
                dispatch_queue_t global = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_async(global, ^{
                    if ([[BlueToothDataManager shareManager].cardType isEqualToString:@"2"]) {
                        if ([BlueToothDataManager shareManager].isTcpConnected && ![BlueToothDataManager shareManager].isChangeSimCard && ![BlueToothDataManager shareManager].isNeedToRegistAgain) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"connectingBLE" object:@"connectingBLE"];
                            UNLogLBEProcess(@"又走重新连接tcp的地方了")
                        } else {
                            //                            [[VSWManager shareManager] simActionWithSimType:self.simtype];
                            [BlueToothDataManager shareManager].isNeedToRegistAgain = NO;
                            [BlueToothDataManager shareManager].isChangeSimCard = NO;
                            
                            UNLogLBEProcess(@"iccid======%@", [UNPushKitMessageManager shareManager].iccidString)
                            if ([UNPushKitMessageManager shareManager].iccidString) {
                                NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:[[UNPushKitMessageManager shareManager].iccidString lowercaseString]];
                                if (dict) {
                                    //创建tcp,建立连接
                                    DebugUNLog(@"创建tcp,建立连接");
                                    [BlueToothDataManager shareManager].isFirstRegist = NO;
                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"CreateTCPSocketToBLE" object:[UNPushKitMessageManager shareManager].iccidString];
                                }else{
                                    //创建udp,初始化操作
                                    DebugUNLog(@"创建udp,初始化操作");
                                    [BlueToothDataManager shareManager].isFirstRegist = YES;
                                    [UNPushKitMessageManager shareManager].isNeedRegister = YES;
                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"CreateUDPSocketToBLE" object:self.simtype];
                                }
                            }
                        }
                    } else {
                        [self showHudNormalString:INTERNATIONALSTRING(@"电话卡运营商不属于三大运营商")];
                        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOSIGNAL];
                    }
                });
            } else {
                [self showHudNormalString:INTERNATIONALSTRING(@"您还没有购买通话套餐")];
                [BlueToothDataManager shareManager].isHavePackage = NO;
                [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOPACKAGE];
            }
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            UNDebugLogVerbose(@"请求失败：%@", responseObj[@"msg"]);
        }
    } failure:^(id dataObj, NSError *error) {
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:@"apiCheckUsedExistByPageCategory"];
        if (responseObj) {
            if ([responseObj[@"data"][@"Used"] intValue]/*0：不存在，1：存在*/) {
                dispatch_queue_t global = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_async(global, ^{
                    if ([[BlueToothDataManager shareManager].cardType isEqualToString:@"2"]) {
                        if ([BlueToothDataManager shareManager].isTcpConnected) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"connectingBLE" object:@"connectingBLE"];
                        } else {
                            //                            [[VSWManager shareManager] simActionWithSimType:self.simtype];
                            //取消手动发送ICCID命令
//                            [self updataToCard];
//                            [self sendICCIDMessage];
                        }
                    } else {
                        [self showHudNormalString:INTERNATIONALSTRING(@"电话卡运营商不属于三大运营商")];
                        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOSIGNAL];
                    }
                });
            } else {
                [self showHudNormalString:INTERNATIONALSTRING(@"您还没有购买通话套餐")];
                [BlueToothDataManager shareManager].isHavePackage = NO;
                [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOPACKAGE];
            }
        }else{
            [self showHudNormalString:INTERNATIONALSTRING(@"网络貌似有问题")];
        }
        UNDebugLogVerbose(@"啥都没：%@",[error description]);
    } headers:self.headers];
}


#pragma mark 查询绑定设备
- (void)checkBindedDeviceFromNet {
    if (self.boundedDeviceInfo) {
        self.boundedDeviceInfo = nil;
    }
    NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:@"apiDeviceBracelet"];
    if (responseObj[@"data"][@"IMEI"]) {
        self.boundedDeviceInfo = [[NSDictionary alloc] initWithDictionary:responseObj[@"data"]];
        if (!responseObj[@"data"]) {
            [BlueToothDataManager shareManager].isShowStatuesView = YES;
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTBOUND];
            [BlueToothDataManager shareManager].isBounded = NO;
        } else {
            [BlueToothDataManager shareManager].isBounded = YES;
        }
        UNLogLBEProcess(@"本地存储了的，直接扫描蓝牙设备")
        UNDebugLogVerbose(@"当前本地绑定设备----%@",self.boundedDeviceInfo);
        //扫描蓝牙设备
        [self scanAndConnectDevice];
    } else {
        UNLogLBEProcess(@"本地没有存储，进行网络请求")
            self.checkToken = YES;
            [self getBasicHeader];
//            UNDebugLogVerbose(@"表头：%@",self.headers);
            NSDictionary *info = [[NSDictionary alloc] init];
            [SSNetworkRequest getRequest:apiDeviceBracelet params:info success:^(id responseObj) {
                if ([[responseObj objectForKey:@"status"] intValue]==1) {
                    UNDebugLogVerbose(@"查询绑定设备 -- %@", responseObj);
                    self.boundedDeviceInfo = [[NSDictionary alloc] initWithDictionary:responseObj[@"data"]];
                    if (!responseObj[@"data"][@"IMEI"]) {
                        [BlueToothDataManager shareManager].isShowStatuesView = YES;
                        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTBOUND];
                        [BlueToothDataManager shareManager].isBounded = NO;
                    } else {
                        [BlueToothDataManager shareManager].isBounded = YES;
                        [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:@"apiDeviceBracelet" dictData:responseObj];
                    }
                    //扫描蓝牙设备
                    [self scanAndConnectDevice];
                }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                    UNDebugLogVerbose(@"reloginNotify");
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
                    [self scanAndConnectDevice];
                }else if ([[responseObj objectForKey:@"status"] intValue]==0){
                    //数据请求失败
                    UNDebugLogVerbose(@"没有设备");
                    [BlueToothDataManager shareManager].isShowStatuesView = YES;
                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTBOUND];
                    //扫描蓝牙设备
                    [self scanAndConnectDevice];
                }
            } failure:^(id dataObj, NSError *error) {
                [self showHudNormalString:INTERNATIONALSTRING(@"网络貌似有问题")];
                NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:@"apiDeviceBracelet"];
                if (responseObj) {
                    self.boundedDeviceInfo = [[NSDictionary alloc] initWithDictionary:responseObj[@"data"]];
                }
                //扫描蓝牙设备
                [self scanAndConnectDevice];
                UNDebugLogVerbose(@"啥都没：%@",[error description]);
            } headers:self.headers];
    }
}


#pragma mark 查询手环设备是否已被绑定
- (void)checkDeviceIsBound {
    self.checkToken = YES;
    [self getBasicHeader];
//    UNDebugLogVerbose(@"表头：%@",self.headers);
    NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:[BlueToothDataManager shareManager].deviceMacAddress,@"IMEI", nil];
    if (!info[@"IMEI"]) {
        [self showAlertViewWithMessage:@"没有搜索到可连接的设备"];
        return;
    }
    [SSNetworkRequest getRequest:apiIsBind params:info success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            UNDebugLogVerbose(@"手环是否已被绑定 -- %@", responseObj[@"data"][@"BindStatus"]);
            if ([responseObj[@"data"][@"BindStatus"] isEqualToString:@"0"]) {
                //未绑定
//                [self bindBoundDevice];
                //先绑定蓝牙再走绑定接口
                if (self.strongestRssiPeripheral) {
                    self.peripheral = self.strongestRssiPeripheral;
                    [self.mgr connectPeripheral:self.peripheral options:nil];
                }
            } else if ([responseObj[@"data"][@"BindStatus"] isEqualToString:@"1"]) {
                //已绑定
                [self showHudNormalString:INTERNATIONALSTRING(@"此设备已被其他用户绑定")];
                [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTBOUND];
            } else {
                UNDebugLogVerbose(@"无法识别的判断");
            }
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            [self showHudNormalString:responseObj[@"msg"]];
        }
    } failure:^(id dataObj, NSError *error) {
        [self showHudNormalString:INTERNATIONALSTRING(@"网络貌似有问题")];
        UNDebugLogVerbose(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

#pragma mark 调用绑定手环接口
- (void)bindBoundDevice {
    if ([BlueToothDataManager shareManager].deviceMacAddress&&![[BlueToothDataManager shareManager].deviceMacAddress isEqualToString:@"(null):(null):(null):(null):(null):(null)"]) {
        if (![BlueToothDataManager shareManager].isConnectedPairedDevice) {
            self.checkToken = YES;
            NSDictionary *info;
            if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNIBOX]) {
                info = [[NSDictionary alloc] initWithObjectsAndKeys:[BlueToothDataManager shareManager].deviceMacAddress,@"IMEI", @"1", @"DeviceType", nil];
            } else if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNITOYS]) {
                info = [[NSDictionary alloc] initWithObjectsAndKeys:[BlueToothDataManager shareManager].deviceMacAddress,@"IMEI", @"0", @"DeviceType", nil];
            } else {
                UNDebugLogVerbose(@"设备类型有问题");
                info = [[NSDictionary alloc] initWithObjectsAndKeys:[BlueToothDataManager shareManager].deviceMacAddress,@"IMEI", @"1", @"DeviceType", nil];
            }
            
            [self getBasicHeader];
//            UNDebugLogVerbose(@"表演头：%@",self.headers);
            
            NSDictionary *saveData = @{@"data":info, @"status" : @1};
            [SSNetworkRequest postRequest:apiBind params:info success:^(id responseObj) {
                if ([[responseObj objectForKey:@"status"] intValue]==1) {
                    UNDebugLogVerbose(@"绑定结果：%@", responseObj);
                    //发送绑定成功通知
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"secondCkeckBoundSuccess" object:@"secondCkeckBoundSuccess"];
                    [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:@"apiDeviceBracelet" dictData:saveData];
                    //绑定成功之后再绑定蓝牙
//                    if (self.strongestRssiPeripheral) {
//                        self.peripheral = self.strongestRssiPeripheral;
//                        [self.mgr connectPeripheral:self.peripheral options:nil];
//                    }
                    [BlueToothDataManager shareManager].isBounded = YES;
                    if ([[BlueToothDataManager shareManager].deviceType isEqualToString:MYDEVICENAMEUNITOYS]) {
                        [self showHudNormalString:responseObj[@"msg"]];
                    }
                    
                    if ([BlueToothDataManager shareManager].isConnected) {
                        NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
                        NSMutableDictionary *boundedDeviceInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"boundedDeviceInfo"]];
                        UNDebugLogVerbose(@"绑定之后存储 %@", [self.peripheral.identifier UUIDString]);
                        [boundedDeviceInfo setObject:[self.peripheral.identifier UUIDString] forKey:userdata[@"Tel"]];
                        [[NSUserDefaults standardUserDefaults] setObject:boundedDeviceInfo forKey:@"boundedDeviceInfo"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                    
                }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
                }else{
                    //数据请求失败
                    UNDebugLogVerbose(@"请求失败：%@", responseObj[@"msg"]);
                    [self showHudNormalString:responseObj[@"msg"]];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"connectFail" object:@"connectFail"];
                }
            } failure:^(id dataObj, NSError *error) {
                NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:@"apiDeviceBracelet"];
                if (responseObj) {
                    if (self.strongestRssiPeripheral) {
                        self.peripheral = self.strongestRssiPeripheral;
                        [self.mgr connectPeripheral:self.peripheral options:nil];
                    }
                    [BlueToothDataManager shareManager].isBounded = YES;
                }
                UNDebugLogVerbose(@"啥都没：%@",[error description]);
            } headers:self.headers];
        } else {
            [self showHudNormalString:INTERNATIONALSTRING(@"请先在设置->蓝牙中忽略已配对的设备")];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"needToIgnore" object:@"needToIgnore"];
            return;
        }
    } else {
        UNLogLBEProcess(@"绑定蓝牙接口出问题 -- %s:%d", __func__, __LINE__)
    }
}

#pragma mark 更新蓝牙连接信息
- (void)refreshBLEInfo {
    self.checkToken = YES;
    NSDictionary *info;
    if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNIBOX]) {
        info = [[NSDictionary alloc] initWithObjectsAndKeys:[BlueToothDataManager shareManager].versionNumber,@"Version", [BlueToothDataManager shareManager].electricQuantity, @"Power", @"1", @"DeviceType", nil];
    } else if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNITOYS]) {
        info = [[NSDictionary alloc] initWithObjectsAndKeys:[BlueToothDataManager shareManager].versionNumber,@"Version", [BlueToothDataManager shareManager].electricQuantity, @"Power", @"0", @"DeviceType", nil];
    } else {
        UNDebugLogVerbose(@"设备类型有问题");
        info = [[NSDictionary alloc] initWithObjectsAndKeys:[BlueToothDataManager shareManager].versionNumber,@"Version", [BlueToothDataManager shareManager].electricQuantity, @"Power", @"1", @"DeviceType", nil];
    }
    
    [self getBasicHeader];
    //            UNDebugLogVerbose(@"表演头：%@",self.headers);
    [SSNetworkRequest postRequest:apiUpdateConnectInfo params:info success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            UNDebugLogVerbose(@"更新结果：%@", responseObj);
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            UNDebugLogVerbose(@"请求失败：%@", responseObj[@"msg"]);
        }
    } failure:^(id dataObj, NSError *error) {
        UNDebugLogVerbose(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

#pragma mark 解绑
- (void)buttonToUnboundAction {
//    [self hideHud];
    self.isClickButton = YES;
    [BlueToothDataManager shareManager].isAccordBreak = YES;
    [self sendMessageToBLEWithType:BLEIsBoundSuccess validData:@"00"];
    [self.mgr cancelPeripheralConnection:self.peripheral];
    [self sendDataToUnBoundDevice];
    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTBOUND];
}


- (void)sendDataToUnBoundDevice {
    if (self.isClickButton) {
        [self showHudNormalTop1String:@"正在解绑"];
    }
    self.checkToken = YES;
    [self getBasicHeader];
//    UNDebugLogVerbose(@"表头：%@",self.headers);
    [SSNetworkRequest getRequest:apiUnBind params:nil success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            UNDebugLogVerbose(@"解除绑定结果：%@", responseObj);
            //将连接的信息存储到本地
            NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
            NSMutableDictionary *boundedDeviceInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"boundedDeviceInfo"]];
            if ([boundedDeviceInfo objectForKey:userdata[@"Tel"]]) {
                [boundedDeviceInfo removeObjectForKey:userdata[@"Tel"]];
            }
            [[NSUserDefaults standardUserDefaults] setObject:boundedDeviceInfo forKey:@"boundedDeviceInfo"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"]) {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"offsetStatue"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            //删除存储的绑定信息
            [[UNDatabaseTools sharedFMDBTools] deleteTableWithAPIName:@"apiDeviceBracelet"];
            if ([BlueToothDataManager shareManager].isConnected) {
                [self.mgr cancelPeripheralConnection:self.peripheral];
            }
            if (!self.isClickButton) {
                [self showHudNormalString:INTERNATIONALSTRING(@"绑定失败")];
            } else {
                [self showHudNormalString:INTERNATIONALSTRING(@"已解除绑定")];
            }
            [BlueToothDataManager shareManager].isBounded = NO;
            [BlueToothDataManager shareManager].isConnected = NO;
            [BlueToothDataManager shareManager].isRegisted = NO;
            [BlueToothDataManager shareManager].deviceMacAddress = nil;
            [BlueToothDataManager shareManager].electricQuantity = nil;
            [BlueToothDataManager shareManager].versionNumber = nil;
            [BlueToothDataManager shareManager].stepNumber = nil;
            [BlueToothDataManager shareManager].bleStatueForCard = 0;
            [BlueToothDataManager shareManager].isBeingRegisting = NO;
            if (!self.isClickButton) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"boundDeviceFailNotifi" object:@"boundDeviceFailNotifi"];
            }
            self.isClickButton = NO;
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            self.isClickButton = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            [self showHudNormalString:responseObj[@"msg"]];
            self.isClickButton = NO;
        }
    } failure:^(id dataObj, NSError *error) {
        UNDebugLogVerbose(@"啥都没：%@",[error description]);
        self.isClickButton = NO;
    } headers:self.headers];
}

#pragma mark 获取手环注册状态
- (void)checkRegistStatue {
    self.checkToken = YES;
    [self getBasicHeader];
//    UNDebugLogVerbose(@"表头：%@",self.headers);
    [SSNetworkRequest getRequest:apiGetRegStatus params:nil success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            UNLogLBEProcess(@"手环注册状态 -- %@", responseObj[@"data"][@"RegStatus"])
//            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:@"apiGetRegStatus" dictData:responseObj];
            
            if ([responseObj[@"data"][@"RegStatus"] intValue] == 1) {
                if ([BlueToothDataManager shareManager].isTcpConnected) {
                    //注册成功
                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_SIGNALSTRONG];
                    [BlueToothDataManager shareManager].isRegisted = YES;
                }else{
                    //未注册成功
                    [BlueToothDataManager shareManager].isBeingRegisting = YES;
                    [BlueToothDataManager shareManager].isRegisted = NO;
                    [self checkUserIsExistAppointPackage];
                }
            } else if ([responseObj[@"data"][@"RegStatus"] intValue] == 0) {
                //未注册成功
                [BlueToothDataManager shareManager].isBeingRegisting = YES;
                [BlueToothDataManager shareManager].isRegisted = NO;
                [self checkUserIsExistAppointPackage];
            } else {
                UNLogLBEProcess(@"注册状态有问题")
            }
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            [self showHudNormalString:responseObj[@"msg"]];
        }
    } failure:^(id dataObj, NSError *error) {
        [self showHudNormalString:INTERNATIONALSTRING(@"网络貌似有问题")];
        
        UNDebugLogVerbose(@"啥都没：%@",[error description]);
    } headers:self.headers];
}



#pragma mark 扫描连接外设
- (void)scanAndConnectDevice {
    UNLogLBEProcess(@"扫描连接外设===scanAndConnectDevice")
    if (self.peripherals.count) {
        [self.peripherals removeAllObjects];
    }
    if (self.macAddressDict.allKeys.count) {
        [self.macAddressDict removeAllObjects];
    }
    // 扫描外设
    [self centralManagerDidUpdateState:self.mgr];
    if (!self.isPushKitStatu) {
        [self startScanAndConnectingTimer];
    }
}




#pragma mark 获取当前时间
- (void)checkNowTime {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit |
    NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    
    //    NSDate *now=[NSDate date];
    NSDateComponents *comps = [calendar components:unitFlags fromDate:[NSDate date]];
    int year=[comps year];
    int week = [comps weekday];
    int month = [comps month];
    int day = [comps day];
    int hour = [comps hour];
    int min = [comps minute];
    int sec = [comps second];
    
    NSArray * arrWeek=[NSArray arrayWithObjects:@"07",@"01",@"02",@"03",@"04",@"05",@"06", nil];
    NSString *weekString = [NSString stringWithFormat:@"%@",[arrWeek objectAtIndex:[comps weekday] - 1]];
    NSString *yearString = [[NSString stringWithFormat:@"%d", year] substringFromIndex:2];
    NSString *monthString = [NSString stringWithFormat:@"%d", month];
    NSString *dayString = [NSString stringWithFormat:@"%d", day];
    NSString *hourString = [NSString stringWithFormat:@"%d", hour];
    NSString *minString = [NSString stringWithFormat:@"%d", min];
    NSString *secString = [NSString stringWithFormat:@"%d", sec];
    UNDebugLogVerbose(@"十进制：%@ %d %d %@ %d %d %d", yearString, month, day, weekString, hour, min, sec);
    NSString *hexYear = [self hexStringFromString:yearString];
    NSString *hexMonth = [self hexStringFromString:monthString];
    NSString *hexDay = [self hexStringFromString:dayString];
    NSString *hexWeek = [self hexStringFromString:weekString];
    NSString *hexHour = [self hexStringFromString:hourString];
    NSString *hexMin = [self hexStringFromString:minString];
    NSString *hexSec = [self hexStringFromString:secString];
    
    [self sendMessageToBLEWithType:BLETurnoverTime validData:[NSString stringWithFormat:@"%@%@%@%@%@%@%@", hexYear, hexMonth, hexDay, hexHour, hexMin, hexSec, hexWeek]];
}

#pragma mark 获取闹钟的设置
- (void)checkClockAlarmSetWithNumber:(NSString *)number open:(NSString *)open reuse:(NSString *)reuse monday:(NSString *)monday tuesday:(NSString *)tuesday wednesday:(NSString *)wednesday thursday:(NSString *)thursday friday:(NSString *)friday saturday:(NSString *)saturday sunday:(NSString *)sunday hour:(NSString *)hour min:(NSString *)min {
    NSString *hexNumber = [self hexStringFromString:number];
    NSString *hexOpen = [self hexStringFromString:open];
    NSString *hexReuse = [self hexStringFromString:reuse];
    NSString *hexMonday = [self hexStringFromString:monday];
    NSString *hexTuesday = [self hexStringFromString:tuesday];
    NSString *hexWednesday = [self hexStringFromString:wednesday];
    NSString *hexThursday = [self hexStringFromString:thursday];
    NSString *hexFriday = [self hexStringFromString:friday];
    NSString *hexSaturday = [self hexStringFromString:saturday];
    NSString *hexSunday = [self hexStringFromString:sunday];
    NSString *hexHour = [self hexStringFromString:hour];
    NSString *hexMin = [self hexStringFromString:min];
    //0xAA 0x07 0x0F
    NSMutableArray *array = [NSMutableArray arrayWithObjects:@"AA", @"07", @"0F", hexNumber, hexOpen, hexReuse, hexMonday, hexTuesday, hexWednesday, hexThursday, hexFriday, hexSaturday, hexSunday, hexHour, hexMin, nil];
    //获取校验位
    NSString *checkString = [self check_sum:array];
    //发送设置闹钟指令
    [self sendConnectingInstructWithData:[self settingClockAlarmWithNumber:number open:open reuse:reuse monday:monday tuesday:tuesday wednesday:wednesday thursday:thursday friday:friday saturday:saturday sunday:sunday hour:hour min:min cehck:checkString]];
}

#pragma mark ------------发送的数据包------------
#pragma mark 获取空卡序列号第一步
- (void)checkEmptyCardSerialNumberFirstWithString:(NSString *)string
{
    self.activityOrderId = [NSString stringWithFormat:@"%@", string];
    if ([BlueToothDataManager shareManager].bleStatueForCard == 1) {
        [BlueToothDataManager shareManager].isActivityCard = YES;
    }
    [self phoneCardToUpeLectrify:@"03"];
    //    A0A4000002 3F00
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sendMessageToBLEWithType:BLEAixiaoqiCardData validData:@"a0a40000023f00"];
    });
}


#pragma mark 判断卡类型第一步
- (void)checkCardType {
    [self sendMessageToBLEWithType:BLEAixiaoqiCardData validData:@"a0a40000023f00"];
}

#pragma mark 请求是否使能通知
- (void)checkUserConfig {
    NSMutableDictionary *dict1 = [NSMutableDictionary dictionaryWithDictionary:@{@"img":@"pro_call", @"lblName":@"来电通知", @"status":@"0"}];
    NSMutableDictionary *dict2 = [NSMutableDictionary dictionaryWithDictionary:@{@"img":@"pro_message", @"lblName":@"短信通知", @"status":@"0"}];
    NSMutableDictionary *dict3 = [NSMutableDictionary dictionaryWithDictionary:@{@"img":@"pro_weichart", @"lblName":@"微信通知", @"status":@"0"}];
    NSMutableDictionary *dict4 = [NSMutableDictionary dictionaryWithDictionary:@{@"img":@"pro_qq", @"lblName":@"QQ通知", @"status":@"0"}];
    self.dataArr = [NSMutableArray arrayWithObjects:dict1, dict2, dict3, dict4, nil];
    self.checkToken = YES;
    [self getBasicHeader];
//    UNDebugLogVerbose(@"表头：%@",self.headers);
    [SSNetworkRequest getRequest:apiCheckUserConfig params:nil success:^(id responseObj) {
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            UNDebugLogVerbose(@"获取到的用户配置信息 --> %@", responseObj);
            NSArray *arr = responseObj[@"data"];
            if (arr.count) {
                for (NSDictionary *dict in arr) {
                    if ([dict[@"Name"] isEqualToString:@"NotificaCall"]) {
                        //来电
                        [self.dataArr[0] setObject:[dict[@"Status"] intValue]?@"1":@"0" forKey:@"status"];
                    } else if ([dict[@"Name"] isEqualToString:@"NotificaSMS"]) {
                        //短信
                        [self.dataArr[1] setObject:[dict[@"Status"] intValue]?@"1":@"0" forKey:@"status"];
                    } else if ([dict[@"Name"] isEqualToString:@"NotificaWeChat"]) {
                        //微信
                        [self.dataArr[2] setObject:[dict[@"Status"] intValue]?@"1":@"0" forKey:@"status"];
                    }else if ([dict[@"Name"] isEqualToString:@"NotificaQQ"]) {
                        //QQ消息
                        [self.dataArr[3] setObject:[dict[@"Status"] intValue]?@"1":@"0" forKey:@"status"];
                    } else {
                        UNDebugLogVerbose(@"这是什么消息？");
                    }
                }
            }
            [self sendDataToCheckIsAllowToNotificationWithPhoneCall:[self.dataArr[0][@"status"] boolValue] Message:[self.dataArr[1][@"status"] boolValue] WeiChart:[self.dataArr[2][@"status"] boolValue] QQ:[self.dataArr[3][@"status"] boolValue]];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
    } failure:^(id dataObj, NSError *error) {
        //
        UNDebugLogVerbose(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

#pragma mark 是否使能通知
- (void)sendDataToCheckIsAllowToNotificationWithPhoneCall:(BOOL)phoneCall Message:(BOOL)message WeiChart:(BOOL)weiChart QQ:(BOOL)QQ {
    int dataNum = 0;
    NSString *dataStr;
    if (phoneCall) {
        dataNum+=8;
    }
    if (message) {
        dataNum+=4;
    }
    if (weiChart) {
        dataNum+=2;
    }
    if (QQ) {
        dataNum+=1;
    }
    dataStr = [NSString stringWithFormat:@"%d", dataNum];
    NSString *dataHexStr = [self hexStringFromString:dataStr];
    [self sendMessageToBLEWithType:BLEIsNotifi validData:dataHexStr];
}

#pragma mark 设置闹钟指令
- (NSData *)settingClockAlarmWithNumber:(NSString *)number open:(NSString *)open reuse:(NSString *)reuse monday:(NSString *)monday tuesday:(NSString *)tuesday wednesday:(NSString *)wednesday thursday:(NSString *)thursday friday:(NSString *)friday saturday:(NSString *)saturday sunday:(NSString *)sunday hour:(NSString *)hour min:(NSString *)min cehck:(NSString *)check {
    Byte reg[17];
    //    0xAA 0x07 0x0F 0x**(闹钟编号) 0x**(是否开启该闹钟) 0x**(自定义是否周重复)....
    reg[0]=0xAA;
    reg[1]=0x07;
    reg[2]=0x0F;
    reg[3]=[self strEndMinute:number];
    reg[4]=[self strEndMinute:open];
    reg[5]=[self strEndMinute:reuse];
    reg[6]=[self strEndMinute:monday];
    reg[7]=[self strEndMinute:tuesday];
    reg[8]=[self strEndMinute:wednesday];
    reg[9]=[self strEndMinute:thursday];
    reg[10]=[self strEndMinute:friday];
    reg[11]=[self strEndMinute:saturday];
    reg[12]=[self strEndMinute:sunday];
    reg[13]=[self strEndMinute:hour];
    reg[14]=[self strEndMinute:min];
    reg[15]=[self strEndMinute:check];
    reg[16]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]^reg[4]^reg[5]^reg[6]^reg[7]^reg[8]^reg[9]^reg[10]^reg[11]^reg[12]^reg[13]^reg[14]^reg[15]);
    NSData *data=[NSData dataWithBytes:reg length:17];
    return data;
}


#pragma mark 获取设备的mac地址
- (NSString *)checkDerviceMacAddress {
    NSString *str;
    if (!self.boundedDeviceInfo[@"IMEI"]) {
        str = [self.macAddressDict objectForKey:self.strongestRssiPeripheral.identifier];
    } else {
        UNDebugLogVerbose(@"mac地址有问题");
    }
    if ([str containsString:@"<"] && [str containsString:@">"]) {
        if (str && ![str isEqualToString:@"(null)"]) {
            NSString *string1 = [str substringWithRange:NSMakeRange(5, 2)];
            NSString *string2 = [str substringWithRange:NSMakeRange(7, 2)];
            NSString *string3 = [str substringWithRange:NSMakeRange(10, 2)];
            NSString *string4 = [str substringWithRange:NSMakeRange(12, 2)];
            NSString *string5 = [str substringWithRange:NSMakeRange(14, 2)];
            NSString *string6 = [str substringWithRange:NSMakeRange(16, 2)];
            NSString *string = [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@", string1, string2, string3, string4, string5, string6];
            UNDebugLogVerbose(@"mac地址：%@", string.lowercaseString);
            return string.lowercaseString;
        } else {
            UNDebugLogVerbose(@"mac地址为空");
            return nil;
        }
    } else {
        if (str && ![str isEqualToString:@"(null)"]) {
            UNDebugLogVerbose(@"mac地址：%@", str.lowercaseString);
            return str.lowercaseString;
        } else {
            UNDebugLogVerbose(@"mac地址为空");
            return nil;
        }
    }
}



-(void)getBasicHeader
{
    //进行Header的构造，partner，Expries，Sign，TOKEN
    self.headers = [[NSMutableDictionary alloc] init];
    [self.headers setObject:@"2006808" forKey:@"partner"];
    
    NSString *timestemp = @"1471316792";
    [self.headers setObject:timestemp forKey:@"expires"];
    
    timestemp = [NSString stringWithFormat:@"2006808%@BAS123!@#FD1A56K",timestemp];
    [self.headers setObject:[self md5:timestemp] forKey:@"sign"];
    
    // 当前软件的版本号（从Info.plist中获得）
    NSString *key = @"CFBundleShortVersionString";
    NSString *versionNumberStr = [NSBundle mainBundle].infoDictionary[key];
    [self.headers setObject:versionNumberStr forKey:@"Version"];
    
    //附加信息
    NSString *terminalStr = @"iOS";
    [self.headers setObject:terminalStr forKey:@"Terminal"];
    
    if (self.checkToken) {
        NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
        if (userdata) {
            [self.headers setObject:[userdata objectForKey:@"Token"] forKey:@"TOKEN"];
        }
    }
    
}

- (void)showAlertViewWithMessage:(NSString *)message {
    //弹出提醒消息
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:INTERNATIONALSTRING(message) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *certailAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(@"确定") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"searchNoDevice" object:@"searchNoDevice"];
    }];
    [alertVC addAction:certailAction];
//    [self presentViewController:alertVC animated:YES completion:nil];
}


- (NSString *)md5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

#pragma mark - VSW相关
#pragma mark 判断网络运营商 1:移动或者联通 2:电信 0:网络运营商或号码有问题
- (NSString *)checkSimType {
    NSString *type = @"0";
    switch ([[BlueToothDataManager shareManager].operatorType intValue]) {
        case 0:
            UNDebugLogVerbose(@"运营商类型有问题,上电失败");
            break;
        case 1:
            type = @"1";
            break;
        case 2:
            type = @"1";
            break;
        case 3:
            type = @"2";
            break;
        case 4:
            UNDebugLogVerbose(@"爱小器卡");
            break;
        default:
            break;
    }
    return type;
}

#pragma mark ------------其他------------
#pragma mark 转换十六进制
- (NSString *)hexStringFromString:(NSString *)string {
    NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1x",[string intValue]]];
    if (hexString.length == 1) {
        NSString *hexString1 = [NSString stringWithFormat:@"0%@", hexString];
        return hexString1;
    }
    return hexString;
}

#pragma mark 异或校验
- (NSString *)check_sum:(NSArray*)date {
    
    NSInteger checksum = 0;
    unsigned long int tempData = 0;
    for (NSInteger i = 0; i < date.count; i++) {
        //先将十六进制转换成十进制
        tempData = strtoul([date[i] UTF8String], 0, 16);
        //        UNDebugLogVerbose(@"date[i] = %ld",(long)tempData);
        checksum ^= tempData;
        //        UNDebugLogVerbose(@"checksum = %ld",(long)checksum);
        
    }
    //再将十进制转换为十六进制
    NSString *hexChecksum = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)checksum]];
    UNDebugLogVerbose(@"校验位：%@", hexChecksum);
    //    return hexChecksum;
    NSString *checkSum = [NSString stringWithFormat:@"%ld", (long)checksum];
    return checkSum;
    
}

#pragma mark 字符串类型转换成bytes类型
- (Byte)strEndMinute:(NSString *)string {
    // 转成 int  类型
    int endMinutes = [string intValue];
    Byte endMinuteByte = (Byte)0xff&endMinutes;
    return endMinuteByte;
}

#pragma mark 数据包截取字符串转换为int型
- (int)convertRangeStringToIntWithString:(NSString *)dataString rangeLoc:(NSUInteger)rangeLoc rangeLen:(NSUInteger)rangeLen {
    NSString *subString = [dataString substringWithRange:NSMakeRange(rangeLoc, rangeLen)];
    int result = strtoul([subString UTF8String], 0, 16);
    //    UNDebugLogVerbose(@"返回的结果为：%d", result);
    return result;
}

#pragma mark 将十六进制的数据包转换成byte数组
- (unsigned char *)convenStrToCharWithString:(NSString *)hexString {
    
    int len = (int)[hexString length] /2;// Target length
    
    unsigned char *buf =malloc(len);
    
    unsigned char *whole_byte = buf;
    
    char byte_chars[3] = {'\0','\0','\0'};
    
    int i;
    
    for (i=0; i < [hexString length] /2; i++) {
        
        byte_chars[0] = [hexString characterAtIndex:i*2];
        
        byte_chars[1] = [hexString characterAtIndex:i*2+1];
        
        *whole_byte = strtol(byte_chars, NULL, 16);
//        *whole_byte = strtoul(byte_chars, NULL, 16);
        
        whole_byte++;
        
    }
    return buf;
}

#pragma mark 将十六进制的数据包转换成byte数组
- (NSData *)checkNewMessageReuseWithString:(NSString *)hexString {
    
    int len = (int)[hexString length] /2;// Target length
    
    unsigned char *buf =malloc(len);
    
    unsigned char *whole_byte = buf;
    
    char byte_chars[3] = {'\0','\0','\0'};
    
    int i;
    
    for (i=0; i < [hexString length] /2; i++) {
        
        byte_chars[0] = [hexString characterAtIndex:i*2];
        
        byte_chars[1] = [hexString characterAtIndex:i*2+1];
        
        *whole_byte = strtol(byte_chars, NULL, 16);
        
        whole_byte++;
        
    }
    
    NSData *data = [NSData dataWithBytes:buf length:len];
    
    free( buf );
    UNLogLBEProcess(@"最终发送的包 -> %@", data)
    return data;
}

#pragma mark 转换蓝牙设备（未连接）的mac地址
- (NSString *)conventMACAddressFromNetWithStr:(NSString *)str {
    if (str.length >= 12) {
        NSString *string1 = [str substringWithRange:NSMakeRange(0, 2)];
        NSString *string2 = [str substringWithRange:NSMakeRange(2, 2)];
        NSString *string3 = [str substringWithRange:NSMakeRange(4, 2)];
        NSString *string4 = [str substringWithRange:NSMakeRange(6, 2)];
        NSString *string5 = [str substringWithRange:NSMakeRange(8, 2)];
        NSString *string6 = [str substringWithRange:NSMakeRange(10, 2)];
        NSString *string = [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@", string1, string2, string3, string4, string5, string6];
        NSString *lowStr = string.lowercaseString;
        UNDebugLogVerbose(@"mac地址：%@", lowStr);
        return lowStr;
    } else {
        UNDebugLogVerbose(@"mac地址有问题,未连接");
        return nil;
    }
}

//左上角状态刷新
- (void)setButtonImageAndTitleWithTitle:(NSString *)title
{
    UNDebugLogVerbose(@"%@", title);
    if (_updateButtonImageAndTitleBlock) {
        _updateButtonImageAndTitleBlock([title copy]);
    }
}

//显示提示信息
- (void)showHudNormalString:(NSString *)title
{
    UNDebugLogVerbose(@"%@", title);
    if (self.showHudNormalBlock) {
        self.showHudNormalBlock(1, title);
    }
}

//显示提示信息
- (void)showHudNormalTop1String:(NSString *)title
{
    UNDebugLogVerbose(@"%@", title);
    if (self.showHudNormalBlock) {
        self.showHudNormalBlock(2, title);
    }
}


//停止提示信息
- (void)hideHud
{
    if (self.endHudBlock) {
        self.endHudBlock();
    }
}

//检测并且提示是否重启蓝牙
- (void)checkBLEAndReset
{
    if (self.checkBLEAndResetBlock) {
        self.checkBLEAndResetBlock();
    }
}

//注册失败
- (void)registFailAction
{
    if (self.registFailActionBlock) {
        self.registFailActionBlock();
    }
}

//支付成功
- (void)paySuccess
{
    if (self.paySuccessBlock) {
        self.paySuccessBlock();
    }
}

#pragma mark 调用空中升级接口
- (void)otaDownload {
    UNLogLBEProcess(@"otaDownload")
    self.checkToken = YES;
    [self getBasicHeader];
    //    UNDebugLogVerbose(@"表头：%@",self.headers);
    NSString *versionStr;
    NSString *typeStr;
    if ([BlueToothDataManager shareManager].versionNumber) {
        versionStr= [BlueToothDataManager shareManager].versionNumber;
    } else {
        versionStr = @"1.00";
    }
    if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNITOYS]) {
        typeStr = @"0";
    } else if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNIBOX]) {
        typeStr = @"1";
    } else {
        typeStr = @"0";
        UNDebugLogVerbose(@"连接的类型有问题");
    }
    NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:versionStr, @"Version", typeStr, @"DeviceType", nil];
    [SSNetworkRequest getRequest:apiDeviceBraceletOTA params:info success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            UNDebugLogVerbose(@"空中升级的请求结果 -- %@", responseObj);
            if (responseObj[@"data"][@"Descr"]) {
//                NSString *infoStr = [NSString stringWithFormat:@"新版本：%@\n%@", responseObj[@"data"][@"Version"], responseObj[@"data"][@"Descr"]];
                [UNDataTools sharedInstance].isHasFirmwareUpdateTip = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"TipMessageStatuChange" object:nil];
                NSString *versionStr = [BlueToothDataManager shareManager].versionNumber;
                NSRange pointLocation = [versionStr rangeOfString:@"."];
                NSString *firstStr = [versionStr substringToIndex:pointLocation.location];
                NSString *secondStr = [versionStr substringFromIndex:pointLocation.location+1];
//                UNDebugLogVerbose(@"拆分之后的固件版本号:%@,%@", firstStr, secondStr);
                if ([firstStr isEqualToString:@"1"] && [secondStr intValue] < 18) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"showAlertToOta" object:responseObj[@"data"][@"Url"]];
                }
            }
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else if ([[responseObj objectForKey:@"status"] intValue]==0){
            //数据请求失败
            UNDebugLogVerbose(@"请求失败");
        }
    } failure:^(id dataObj, NSError *error) {
        //
        UNDebugLogVerbose(@"啥都没：%@",[error description]);
    } headers:self.headers];
}


- (void)dealloc
{
    UNDebugLogVerbose(@"UNBlueToothTool---dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
