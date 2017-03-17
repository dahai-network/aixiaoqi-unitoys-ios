//
//  UNSipEngineInitialize.m
//  unitoys
//
//  Created by 黄磊 on 2017/3/3.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNSipEngineInitialize.h"
#import "SipEngineManager.h"
#import "SipEngine.h"
#import "SSNetworkRequest.h"
#import "VSWManager.h"
#import <CommonCrypto/CommonDigest.h>
#import "UNDatabaseTools.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BlueToothDataManager.h"
#import "UNCreatLocalNoti.h"

//#import "GCDAsyncSocket.h"
#import "GCDAsyncUdpSocket.h"
#import "UNDataTransformation.h"
#import "VSWManager.h"


//app发送给蓝牙
typedef enum : NSUInteger {
    BLESystemReset,//系统复位
    BLETellBLEIsApple,//app发送手机系统给蓝牙
    BLEIsNotifi,//是否是能通知
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
} APPSENDTOBLE;

//蓝牙发送给app
typedef enum : NSUInteger {
    APPSystemBaseInfo,//系统基本信息
    APPElectricQuantity,//电量
    APPChargeElectricStatue,//充电状态
    APPAgreeToBind,//同意绑定
    APPRealTimeCountStep,//实时计步
    APPHistoryStep,//历史计步
    APPAnswerUpElectricToCard,//对卡上电回应
    APPAnswerDownElectricToCard,//对卡断电回应
    APPAnswerSIMData,//SIM数据回应
    APPAixiaoqiCardData,//爱小器国际卡数据
    APPLastChargeElectricTime,//上次充电时间
    APPAlarmClockSetSuccess,//闹钟设置成功
} BLESENDTOAPP;


@interface UNSipEngineInitialize()<SipEngineUICallDelegate,SipEngineUIRegistrationDelegate,CBCentralManagerDelegate,CBPeripheralDelegate,GCDAsyncUdpSocketDelegate>

@property (strong,nonatomic) NSMutableDictionary *headers;
@property (nonatomic, assign) BOOL checkToken;
//@property (nonatomic, copy) NSString *outIP;
//@property (nonatomic, strong)NSDictionary *userInfo;

//@property (nonatomic, assign) int maxPhoneCall;

@property (nonatomic, copy) NSDictionary *boundedDeviceInfo;
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

//已连接的配对设备
@property (nonatomic, strong) NSArray *pairedArr;

@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;
@property (nonatomic, assign)int prot;
@property (nonatomic, copy) NSString *currentPacketNumber;
//记录接收到包的类型
@property (nonatomic, assign) int dataPackegType;

@end

@implementation UNSipEngineInitialize

-(void)getBasicHeader
{
    //进行Header的构造，partner，Expries，Sign，TOKEN
    self.headers = [[NSMutableDictionary alloc] init];
    [self.headers setObject:@"2006808" forKey:@"partner"];
    
    NSString *timestemp = @"1471316792";
    
    [self.headers setObject:timestemp forKey:@"expires"];
    
    timestemp = [NSString stringWithFormat:@"2006808%@BAS123!@#FD1A56K",timestemp];
    
    [self.headers setObject:[self md5:timestemp] forKey:@"sign"];
    
    if (self.checkToken) {
        NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
        if (userdata) {
            [self.headers setObject:[userdata objectForKey:@"Token"] forKey:@"TOKEN"];
        }
    }
    
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



+ (UNSipEngineInitialize *)sharedInstance
{
    static UNSipEngineInitialize *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:nil] init];
    });
    return instance;
}

- (void)initEngine {
    [[SipEngineManager instance] Init];
    [[SipEngineManager instance] LoadConfig];
    if ([SipEngineManager instance].callDelegate == nil) {
        [[SipEngineManager instance] setCallDelegate:self];
    }
    if ([SipEngineManager instance].registrationDelegate == nil) {
        [[SipEngineManager instance] setRegistrationDelegate:self];
    }
    [self doRegister];

//    [self getMaxPhoneCall];
    //读取本地缓存的账号信息
//    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
//    self.userInfo = [[NSDictionary alloc] initWithDictionary:userdata];
    
    //添加通知
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAddressBook) name:@"addressBookChanged" object:@"addressBook"];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callingAction:) name:@"CallingAction" object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makeCallAction:) name:@"MakeCallAction" object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makeUnitysCallAction:) name:@"MakeUnitysCallAction" object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadMessage) name:@"sendMessageSuccess" object:@"sendMessageSuccess"];
}



-(void)doRegister{
    SipEngine *theSipEngine = [SipEngineManager getSipEngine];
    
    if(theSipEngine->AccountIsRegstered())
    {
        theSipEngine->DeRegisterSipAccount();
        __block SipEngine *callEngine = theSipEngine;
        
        self.checkToken = YES;
        [self getBasicHeader];
        [SSNetworkRequest getRequest:apiGetSecrityConfig params:nil success:^(id responseObj) {
            NSLog(@"有数据：%@",responseObj);
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                if (responseObj[@"data"][@"VswServer"]) {
                    [VSWManager shareManager].vswIp = responseObj[@"data"][@"VswServer"][@"Ip"];
                    [VSWManager shareManager].vswPort = [responseObj[@"data"][@"VswServer"][@"Port"] intValue];
                    [[NSUserDefaults standardUserDefaults] setObject:responseObj[@"data"][@"VswServer"][@"Ip"] forKey:@"VSWServerIp"];
                    [[NSUserDefaults standardUserDefaults] setObject:responseObj[@"data"][@"VswServer"][@"Port"] forKey:@"VSWServerPort"];
                }
                
                NSString *secpwd = [self md5:[[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"PublicPassword"] stringByAppendingString:@"voipcc2015"]];
                
                NSString *thirdpwd = [self md5:secpwd];
                
                NSString *userName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"userData"] objectForKey:@"Tel"];
                
                
//                self.outIP = [[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"];
                
                callEngine->SetEnCrypt(NO, NO);
                //IP地址
                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String], "", [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"] UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue]);
                //域名
                //                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String], "", [@"asterisk.unitoys.com" UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue]);
                
                
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
            }
            
            
        } failure:^(id dataObj, NSError *error) {
            NSLog(@"有异常：%@",[error description]);
        } headers:self.headers];
        
    }else{
        
        __block SipEngine *callEngine = theSipEngine;
        
        self.checkToken = YES;
        [self getBasicHeader];
        [SSNetworkRequest getRequest:apiGetSecrityConfig params:nil success:^(id responseObj) {
            NSLog(@"有数据：%@",responseObj);
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                if (responseObj[@"data"][@"VswServer"]) {
                    [VSWManager shareManager].vswIp = responseObj[@"data"][@"VswServer"][@"Ip"];
                    [VSWManager shareManager].vswPort = [responseObj[@"data"][@"VswServer"][@"Port"] intValue];
                    [[NSUserDefaults standardUserDefaults] setObject:responseObj[@"data"][@"VswServer"][@"Ip"] forKey:@"VSWServerIp"];
                    [[NSUserDefaults standardUserDefaults] setObject:responseObj[@"data"][@"VswServer"][@"Port"] forKey:@"VSWServerPort"];
                }
                
                NSString *secpwd = [self md5:[[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"PublicPassword"] stringByAppendingString:@"voipcc2015"]];
                /*
                 secpwd = [super md5:@"e38632c0f035e45efe57125bd0ebe8cevoipcc2015"];*/
                //去年替换方案
                
                NSString *thirdpwd = [self md5:secpwd];
                
                NSString *userName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"userData"] objectForKey:@"Tel"];
                //[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"PublicPassword"]
                
                //callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String],"", "121.46.3.20", 65061,1800);
                
//                self.outIP = [[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"];
                
                //                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String],"", [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"] UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue],1800);
                callEngine->SetEnCrypt(NO, NO);
                //IP地址
                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String], "", [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"] UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue]);
                
                
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
            }
            
            
            
        } failure:^(id dataObj, NSError *error) {
            NSLog(@"有异常：%@",[error description]);
        } headers:self.headers];
    }
}


#pragma mark --- SipEngineUIDelegate
-(void) OnNetworkQuality:(int)ms {
    //网络质量提示？
}

-(void)OnSipEngineState:(SipEngineState)code {
    if (code==0) {
        //
    } else {
        //
    }
}

-(void) OnNewCall:(CallDir)dir
 withPeerCallerID:(NSString*)cid
        withVideo:(BOOL)video_call{
}
-(void) OnCallProcessing{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"正在呼叫...")];
}

/*对方振铃*/
-(void) OnCallRinging{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"对方振铃...")];
}

/*呼叫接通*/
-(void) OnCallStreamsRunning:(bool)is_video_call{
    NSLog(@"接通...");
    //在接通时更新扩音状态
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"正在通话")];
}

-(void) OnCallMediaStreamsConnected:(MediaTransMode)mode{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"正在呼叫...")];
}

-(void) OnCallResume {
    NSLog(@"继续通话");
}

-(void) onCallResumeByRemote {
    //远程
    NSLog(@"对方继续通话");
}

-(void) OnCallPaused {
    NSLog(@"暂停通话");
}

-(void) onCallPausedByRemote {
    NSLog(@"对方暂停通话");
}

-(void) OnCallRemotePaused {
    NSLog(@"暂停通话");
}

/*呼叫接通知识*/
-(void) OnCallConnected{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"正在通话")];
}

/*话单*/
-(void) OnCallReport:(void*)report{
    
}

/*呼叫结束*/
-(void) OnCallEnded{
    NSLog(@"结束通话");
    
//    [self loadPhoneRecord];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"通话结束")];
//    self.speakerStatus = NO;
}

/*呼叫失败，并返回错误代码，代码对应的含义，请参考common_types.h*/
-(void) OnCallFailed:(CallErrorCode) error_code{
    NSLog([NSString stringWithFormat:@"呼叫错误, 代码 %d",error_code],nil);
    [[[UIAlertView alloc] initWithTitle:@"错误提示" message:[NSString stringWithFormat:@"呼叫异常,请确认网络或账号正常"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
    
}

/*帐号注册状态反馈, 失败返回错误代码 代码对应的含义，请参考common_types.h*/
-(void) OnRegistrationState:(RegistrationState) code
              withErrorCode:(RegistrationErrorCode) e_errno{
    
    NSString *msg=@"";
    
    if(code == 1){
        msg = @"正在注册...";
        [SipEngineManager instance].resignStatue = 0;
        //        [mBtnRegister setTitle:@"注册中" forState:UIControlStateNormal];
    }else if(code == 2){
        msg = @"注册成功！";
        [SipEngineManager instance].resignStatue = 1;
        //        [mBtnRegister setTitle:@"注销" forState:UIControlStateNormal];
    }else if(code == 3){
        msg = @"您的账号已注销";
        [SipEngineManager instance].resignStatue = 0;
        //        [mBtnRegister setTitle:@"注册" forState:UIControlStateNormal];
    }else if(code == 4){
        msg = [NSString stringWithFormat:@"注册失败，错误代码 %d",e_errno];
        [SipEngineManager instance].resignStatue = 0;
        //        [mBtnRegister setTitle:@"注册" forState:UIControlStateNormal];
    }
    
    //    [mStatus setText:msg];
    NSLog(@"注册状态：%@",msg);
}



- (void)scanLBEDevice
{
    NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:@"apiDeviceBracelet"];
    if (responseObj) {
        self.boundedDeviceInfo = [[NSDictionary alloc] initWithDictionary:responseObj[@"data"]];
        //扫描蓝牙设备
        [self scanAndConnectDevice];
    }
}



- (NSMutableArray *)peripherals
{
    if (!_peripherals) {
        _peripherals = [NSMutableArray array];
    }
    return _peripherals;
}

- (CBCentralManager *)mgr
{
    if (!_mgr) {
        // 创建中心设备管理者，用来管理中心设备
        _mgr = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    return _mgr;
}

#pragma mark 扫描连接外设
- (void)scanAndConnectDevice {
    if (self.peripherals.count) {
        [self.peripherals removeAllObjects];
    }
    if (self.macAddressDict.allKeys.count) {
        [self.macAddressDict removeAllObjects];
    }
    
    [UNCreatLocalNoti createLocalNotiMessageString:@"扫描外设"];
    // 扫描外设
    [self centralManagerDidUpdateState:self.mgr];
    //自动连接,延时1秒
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CBPeripheral *temPer;
        NSNumber *tempRssi;
        switch (self.peripherals.count) {
            case 0:
                NSLog(@"没有搜索到可连接的设备");
                [UNCreatLocalNoti createLocalNotiMessageString:@"没有搜索到可连接的设备"];
                //未连接
                if ([BlueToothDataManager shareManager].isOpened) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(BLESCANTIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (![BlueToothDataManager shareManager].isConnected) {
                            [self.mgr stopScan];
                        }
                    });
                } else {
//                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_BLNOTOPEN];
                }
                break;
                return;
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
                //                self.strongestRssiPeripheral = self.peripherals[0];
                for (CBPeripheral *per in self.peripherals) {
                    NSNumber *perRssi = [self.RSSIDict objectForKey:per.identifier];
                    NSNumber *strongRssi = [self.RSSIDict objectForKey:self.strongestRssiPeripheral.identifier];
                    if ([strongRssi intValue]< [perRssi intValue] && [perRssi intValue] <= 0 && self.strongestRssiPeripheral) {
                        self.strongestRssiPeripheral = per;
                        NSLog(@"strongest -- %@", self.strongestRssiPeripheral);
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
        if (!self.boundedDeviceInfo[@"IMEI"]) {
            //调用绑定设备接口
            [self bindBoundDevice];
        } else {
            NSLog(@"已经绑定过了%@", self.boundedDeviceInfo[@"IMEI"]);
            //已经绑定过
        }
    });
}


#pragma mark 获取设备的mac地址
- (NSString *)checkDerviceMacAddress {
    NSString *str;
    if (!self.boundedDeviceInfo[@"IMEI"]) {
        str = [self.macAddressDict objectForKey:self.strongestRssiPeripheral.identifier];
    } else {
        NSLog(@"mac地址有问题");
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
            NSLog(@"mac地址：%@", string.lowercaseString);
            return string.lowercaseString;
        } else {
            NSLog(@"mac地址为空");
            return nil;
        }
    } else {
        if (str && ![str isEqualToString:@"(null)"]) {
            NSLog(@"mac地址：%@", str.lowercaseString);
            return str.lowercaseString;
        } else {
            NSLog(@"mac地址为空");
            return nil;
        }
    }
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
        NSLog(@"mac地址：%@", lowStr);
        return lowStr;
    } else {
        NSLog(@"mac地址有问题,未连接");
        return nil;
    }
}

#pragma mark 调用绑定手环接口
- (void)bindBoundDevice {
    if ([BlueToothDataManager shareManager].deviceMacAddress&&![[BlueToothDataManager shareManager].deviceMacAddress isEqualToString:@"(null):(null):(null):(null):(null):(null)"]) {
        if (![BlueToothDataManager shareManager].isConnectedPairedDevice) {
            self.checkToken = YES;
            NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:[BlueToothDataManager shareManager].deviceMacAddress,@"IMEI", [BlueToothDataManager shareManager].versionNumber, @"Version", nil];
            
            [self getBasicHeader];
            NSLog(@"表演头：%@",self.headers);
            
            [SSNetworkRequest postRequest:apiBind params:info success:^(id responseObj) {
                if ([[responseObj objectForKey:@"status"] intValue]==1) {
                    NSLog(@"绑定结果：%@", responseObj);
                    [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:@"apiBind" dictData:responseObj];
                    
                    //绑定成功之后再绑定蓝牙
                    if (self.strongestRssiPeripheral) {
                        self.peripheral = self.strongestRssiPeripheral;
                        [self.mgr connectPeripheral:self.peripheral options:nil];
                    }
                    [BlueToothDataManager shareManager].isBounded = YES;
                }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
                }else{
                    //数据请求失败
                    NSLog(@"请求失败：%@", responseObj[@"msg"]);
                }
            } failure:^(id dataObj, NSError *error) {
                NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:@"apiBind"];
                if (responseObj) {
                    if (self.strongestRssiPeripheral) {
                        self.peripheral = self.strongestRssiPeripheral;
                        [self.mgr connectPeripheral:self.peripheral options:nil];
                    }
                    [BlueToothDataManager shareManager].isBounded = YES;
                }
                NSLog(@"啥都没：%@",[error description]);
            } headers:self.headers];
        }
    } else {
        NSLog(@"绑定蓝牙接口出问题 -- %s:%d", __func__, __LINE__);
    }
}


#pragma mark - CBCentralManagerDelegate
#pragma mark 发现外围设备的时候调用,RSSI为负值，越接近0，信号越强
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // 添加外围设备
//    [UNCreatLocalNoti createLocalNotiMessageString:@"发现外围设备"];
    if (![self.peripherals containsObject:peripheral]) {
        // 设置外设的代理
        //        peripheral.delegate = self;
        if (peripheral.name) {
            NSLog(@"设备名称：%@", peripheral.name);
            NSString *imeiStr = self.boundedDeviceInfo[@"IMEI"];
            NSString *imeiLowStr = imeiStr.lowercaseString;
            NSString *nameStr;
            if (peripheral.name.length > 7) {
                nameStr = [peripheral.name substringWithRange:NSMakeRange(0, 7)];
            } else {
                nameStr = peripheral.name;
            }
            if (imeiLowStr&&[MYDEVICENAME containsString:nameStr.lowercaseString]) {
                //新版本带mac地址的
                if (peripheral.name.length > 8) {
                    NSString *macStr = [self conventMACAddressFromNetWithStr:[peripheral.name substringFromIndex:8]];
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
                    NSLog(@"mac地址没有广播");
                }
            } else {
                //新版本带mac地址的
                if (peripheral.name.length > 8 && [MYDEVICENAME containsString:nameStr.lowercaseString]) {
                    NSString *macStr = [self conventMACAddressFromNetWithStr:[peripheral.name substringFromIndex:8]];
                    
                    [self.peripherals addObject:peripheral];
                    NSLog(@"带mac地址 -- uuid = %@ name = %@ 信号强度是：%@ mac地址是：%@", peripheral.identifier, peripheral.name, RSSI, macStr.lowercaseString);
                    [self.macAddressDict setObject:macStr.lowercaseString forKey:peripheral.identifier];
                    [self.RSSIDict setObject:RSSI forKey:peripheral.identifier];
                }
                //mac地址没有广播
                if (!advertisementData[@"kCBAdvDataManufacturerData"]) {
                    NSLog(@"mac地址没有广播");
                }
            }
        }
    }
}

#pragma mark 蓝牙状态发生变化
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    [UNCreatLocalNoti createLocalNotiMessageString:@"蓝牙状态变化"];
    
    [BlueToothDataManager shareManager].executeNum++;
    //第一次打开或者每次蓝牙状态改变都会调用这个函数
    if(central.state == CBManagerStatePoweredOn) {
        
        [UNCreatLocalNoti createLocalNotiMessageString:@"CBManagerStatePoweredOn"];
        NSLog(@"蓝牙设备开着");
        [BlueToothDataManager shareManager].isOpened = YES;
        //连接中
//        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_CONNECTING];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //已经被系统或者其他APP连接上的设备数组
            if (!self.pairedArr) {
                self.pairedArr = [[NSArray alloc] initWithArray:[self.mgr retrieveConnectedPeripheralsWithServices:@[[CBUUID UUIDWithString:UUIDFORSERVICE1SERVICE]]]];
            } else {
                self.pairedArr = [self.mgr retrieveConnectedPeripheralsWithServices:@[[CBUUID UUIDWithString:UUIDFORSERVICE1SERVICE]]];
            }
            if(self.pairedArr.count>0) {
                NSLog(@"连接的配对设备 - %@", self.pairedArr);
                [UNCreatLocalNoti createLocalNotiMessageString:@"有配对设备"];
                for (CBPeripheral* peripheral in self.pairedArr) {
                    NSString *nameStr = [peripheral.name substringWithRange:NSMakeRange(0, 7)];
                    if (peripheral != nil && [MYDEVICENAME containsString:nameStr.lowercaseString]) {
                        
                        //获取mac地址
                        if (!self.boundedDeviceInfo[@"IMEI"] && peripheral.name.length > 8) {
                            [BlueToothDataManager shareManager].deviceMacAddress = [self conventMACAddressFromNetWithStr:[peripheral.name substringFromIndex:8].lowercaseString];
                        }
                        if (self.boundedDeviceInfo[@"IMEI"]) {
                            NSString *boundStr = self.boundedDeviceInfo[@"IMEI"];
                            [BlueToothDataManager shareManager].deviceMacAddress = boundStr.lowercaseString;
                        }
                        //绑定设备
                        if (!self.boundedDeviceInfo[@"IMEI"]) {
                            //调用绑定设备接口
                            self.strongestRssiPeripheral = peripheral;
                            [self.macAddressDict setObject:[BlueToothDataManager shareManager].deviceMacAddress forKey:peripheral.identifier];
                            [self bindBoundDevice];
                            [BlueToothDataManager shareManager].isConnectedPairedDevice = YES;
                        } else {
                            NSLog(@"已经绑定过了%@", self.boundedDeviceInfo[@"IMEI"]);
                            //已经绑定过
                            NSString *boundMac = self.boundedDeviceInfo[@"IMEI"];
                            if ([boundMac.lowercaseString isEqualToString:[BlueToothDataManager shareManager].deviceMacAddress]) {
                                peripheral.delegate = self;
                                self.peripheral = peripheral;
                                [self.mgr connectPeripheral:self.peripheral options:nil];
                            } else {
//                                HUDNormal(@"请先忽略您之前的设备")
                            }
                        }
                    }
                }
            } else {
                [UNCreatLocalNoti createLocalNotiMessageString:@"没有有配对设备"];
                [self.mgr scanForPeripheralsWithServices:nil options:nil];
            }
        });
    } else {
        [UNCreatLocalNoti createLocalNotiMessageString:@"蓝牙设备关着"];
        
        NSLog(@"蓝牙设备关着");
        //        [self.mgr stopScan];
        //蓝牙未开
//        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_BLNOTOPEN];
        if (![BlueToothDataManager shareManager].isOpened) {
            if ([BlueToothDataManager shareManager].executeNum < 3) {
                //第一次什么都不执行
            } else {
//                HUDNormal(@"连接蓝牙设备才能正常使用")
            }
        }
        [BlueToothDataManager shareManager].isOpened = NO;
    }
    
    //        [self showTheAlertViewWithMassage:@"手机蓝牙处于可用状态"];
    NSLog(@"中心设备：%ld，%@", central.state, central);
}



#pragma mark 连接到某个外设的时候调用
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [UNCreatLocalNoti createLocalNotiMessageString:@"didConnectPeripheral"];
    
    [self.mgr stopScan];
//    [self.timer setFireDate:[NSDate distantFuture]];
    peripheral.delegate = self;
    // 查找外设中的所有服务
    NSLog(@"连接成功，开始查找外设重所有服务%@",peripheral.name);
    
    [BlueToothDataManager shareManager].isBounded = YES;
    //发送绑定成功通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"boundSuccess" object:@"boundSuccess"];
    
#warning 通过传入一个存放服务UUID的数组进去，过滤掉一些不要的服务
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [peripheral discoverServices:nil];
    });
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [UNCreatLocalNoti createLocalNotiMessageString:@"didFailToConnectPeripheral"];
    NSLog(@"连接失败 - %@", error);
}

#pragma mark 跟某个外设失去连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    //    [BlueToothDataManager shareManager].isRegisted = NO;
    [BlueToothDataManager shareManager].isBounded = NO;
    [BlueToothDataManager shareManager].isConnected = NO;
    [BlueToothDataManager shareManager].isConnectedPairedDevice = NO;
    [BlueToothDataManager shareManager].deviceMacAddress = nil;
    [BlueToothDataManager shareManager].electricQuantity = nil;
    [BlueToothDataManager shareManager].versionNumber = nil;
    [BlueToothDataManager shareManager].currentStep = @"0";
    [BlueToothDataManager shareManager].bleStatueForCard = 0;
    [BlueToothDataManager shareManager].isBeingRegisting = NO;
//    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"deviceIsDisconnect" object:@"deviceIsDisconnect"];
    if (![BlueToothDataManager shareManager].isAccordBreak) {
//        [self checkBindedDeviceFromNet];
        [self scanLBEDevice];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (![BlueToothDataManager shareManager].isConnected) {
//                [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
                [self.mgr stopScan];
                //开始计时
//                [self startTimer];
            }
        });
    }
}

#pragma mark - CBPeripheralDelegate
#pragma mark 外设已经查找到服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    // 遍历所有的服务
    for (CBService *service in peripheral.services) {
        // 过滤掉不想要的服务
        if ([[service.UUID UUIDString] isEqual:UUIDFORSERVICE1SERVICE]) {
            // 扫描服务下面的特征
#warning 通过传入一个存放特征UUID的数组进去，过滤掉一些不要的特征
            [peripheral discoverCharacteristics:nil forService:service];
        }
        NSLog(@"蓝牙设备的服务：%@", service);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // 遍历所有的特征
    for (CBCharacteristic *characteristic in service.characteristics) {
        // 过滤掉不想要的特征
        if ([[characteristic.UUID UUIDString] isEqual:UUIDFORSERVICE1CHARACTERISTICTOWRITE]) {
            // 找到想要的特征
            NSLog(@"这是写特属性特征");
            self.characteristic = characteristic;
            [self.peripheral setNotifyValue:YES forCharacteristic:characteristic];
        } else if ([[characteristic.UUID UUIDString] isEqual:UUIDFORSERVICE1CHARACTERISTICTONOTIF]) {
            NSLog(@"这是第一个通知属性的特征");
            self.notifyCharacteristic = characteristic;
            [self.peripheral setNotifyValue:YES forCharacteristic:self.notifyCharacteristic];
        } else if ([[characteristic.UUID UUIDString] isEqual:UUIDFORSERVICE1CHARACTERISTICTONOTIF2]) {
            NSLog(@"这是第一个通知属性的特征2");
            self.notifyCharacteristic2 = characteristic;
            [self.peripheral setNotifyValue:YES forCharacteristic:self.notifyCharacteristic2];
        }else if ([[characteristic.UUID UUIDString] isEqual:UUIDFORSERVICE1CHARACTERISTICTONOTIF3]) {
            NSLog(@"这是第一个通知属性的特征3");
            self.notifyCharacteristic3 = characteristic;
            [self.peripheral setNotifyValue:YES forCharacteristic:self.notifyCharacteristic3];
        }
        NSLog(@"characteristic:%@", characteristic);
    }
    [BlueToothDataManager shareManager].isConnected = YES;
    //告诉蓝牙是苹果设备
//    [self sendMessageToBLEWithType:BLETellBLEIsApple validData:@"01"];
    //同步时间
//    [self checkNowTime];
    //请求基本信息
//    [self sendMessageToBLEWithType:BLESystemBaseInfo validData:nil];
    //请求电量
//    [self sendMessageToBLEWithType:BLECheckElectricQuantity validData:nil];
    //对卡上电
    [self phoneCardToUpeLectrify:@"03"];
//    [self sendMessageToBLEWithType:BLECardData validData:nil];
//    [self refreshBLEStatue];
}

#pragma mark 更新蓝牙状态
- (void)refreshBLEStatue {
    if ([BlueToothDataManager shareManager].isConnected) {
        if (![BlueToothDataManager shareManager].isHaveCard) {
//            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTINSERTCARD];
        } else {
//            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_CONNECTING];
        }
    } else {
//        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
    }
}

#pragma mark 发送指令
- (void)sendConnectingInstructWithData:(NSData *)data {
    self.peripheral.delegate = self;
    if((self.characteristic.properties & CBCharacteristicWriteWithoutResponse) != 0) {
        [self.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithoutResponse];
    } else if ((self.characteristic.properties & CBCharacteristicPropertyWrite) != 0) {
        [self.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
    } else {
        NSLog(@"No write property on TX characteristic, %ld.",self.characteristic.properties);
    }
    NSLog(@"连接蓝牙并发送给蓝牙数据 -- %@", data);
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"发送指令成功");
    if (!error) {
        NSLog(@"其他操作");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    NSLog(@"接收到数据什么鬼？");
    
}

#pragma mark 注册失败
- (void)registFailAction {
    [UNCreatLocalNoti createLocalNotiMessageString:@"注册失败"];
    
//    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
//    if ([BlueToothDataManager shareManager].isNeedToResert) {
//        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:@"注册失败，是否复位？" preferredStyle:UIAlertControllerStyleAlert];
//        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//            [BlueToothDataManager shareManager].isNeedToResert = NO;
//        }];
//    }
}

#pragma mark 当接收到蓝牙设备发送来的数据包时就会调用此方法
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    NSLog(@"接收到蓝牙发送过来的数据value --> %@",characteristic.value);
    
//    [UNCreatLocalNoti createLocalNotiMessageString:@"接收蓝牙数据"];
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
                NSLog(@"接收到的有效data -- %@", contentStr);
            }
        } else {
            if (str.length > 6) {
                contentStr = [str substringFromIndex:6];
                NSLog(@"接收到的有效data -- %@", contentStr);
            }
        }
//        [UNCreatLocalNoti createLocalNotiMessageString:[NSString stringWithFormat:@"数据类型---%zd", self.dataPackegType]];
        switch (self.dataPackegType) {
//            case 1:
//                //系统基本信息
//                NSLog(@"接收到系统基本信息数据");
//                //版本号
//                int versionNumber1 = [self convertRangeStringToIntWithString:contentStr rangeLoc:0 rangeLen:2];
//                int versionNumber2 = [self convertRangeStringToIntWithString:contentStr rangeLoc:2 rangeLen:2];
//                versionNumber = [NSString stringWithFormat:@"%d.%d", versionNumber1, versionNumber2];
//                NSLog(@"版本号:%@", versionNumber);
//                [BlueToothDataManager shareManager].versionNumber = versionNumber;
//                //电量
//                int electricQuantity = [self convertRangeStringToIntWithString:contentStr rangeLoc:4 rangeLen:2];
//                NSLog(@"当前电量为：%d%%", electricQuantity);
//                [BlueToothDataManager shareManager].electricQuantity = [NSString stringWithFormat:@"%d", electricQuantity];
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"boundSuccess" object:@"boundSuccess"];
//                break;
//            case 2:
//                //电量
//                NSLog(@"接收到电量数据");
//                int electricQuantityNew = [self convertRangeStringToIntWithString:contentStr rangeLoc:0 rangeLen:2];
//                NSLog(@"当前电量为：%d%%", electricQuantityNew);
//                [BlueToothDataManager shareManager].electricQuantity = [NSString stringWithFormat:@"%d", electricQuantityNew];
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"boundSuccess" object:@"boundSuccess"];
//                break;
//            case 3:
//                //充电状态
//                NSLog(@"接收到充电状态数据");
//                int chargeStatue = [self convertRangeStringToIntWithString:contentStr rangeLoc:0 rangeLen:2];
//                NSLog(@"充电状态 --> %d", chargeStatue);
//                switch (chargeStatue) {
//                    case 1:
//                        NSLog(@"未充电");
//                        break;
//                    case 2:
//                        NSLog(@"正在充电");
//                        break;
//                    case 3:
//                        NSLog(@"充电完成");
//                        break;
//                    default:
//                        NSLog(@"充电状态有问题");
//                        break;
//                }
//                break;
//            case 4:
//                //同意绑定
//                NSLog(@"接收到同意绑定数据");
//                break;
//            case 5:
//                //实时计步
//                NSLog(@"接收到实时计步数据");
//                break;
//            case 6:
//                //历史步数
//                NSLog(@"接收到历史计步数据");
//                break;
            case 7:
                //回应上电
                if ([contentStr isEqualToString:@"01"]) {
                    NSLog(@"对卡上电1成功，有卡");
//                    [UNCreatLocalNoti createLocalNotiMessageString:@"对卡上电1成功，有卡"];
                    [BlueToothDataManager shareManager].isHaveCard = YES;
                    //更新蓝牙状态
//                    [self refreshBLEStatue];
                    //判断卡类型
                    [self checkCardType];
                } else if ([contentStr isEqualToString:@"11"]) {
                    NSLog(@"对卡上电1失败,没有卡");
//                    [UNCreatLocalNoti createLocalNotiMessageString:@"对卡上电1失败,没有卡"];
                    if ([BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue) {
                        [BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue = NO;
                    }
//                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTINSERTCARD];
                } else if ([contentStr isEqualToString:@"02"]) {
//                    [UNCreatLocalNoti createLocalNotiMessageString:@"对卡上电2成功"];
                    NSLog(@"对卡上电2成功");
                } else if ([contentStr isEqualToString:@"12"]) {
//                    [UNCreatLocalNoti createLocalNotiMessageString:@"对卡上电2失败"];
                    NSLog(@"对卡上电2失败");
                    [self registFailAction];
                } else if ([contentStr isEqualToString:@"03"]) {
//                    [UNCreatLocalNoti createLocalNotiMessageString:@"对卡上电3成功"];
                    NSLog(@"对卡上电3成功");
                    [[VSWManager shareManager] sendMessageToDev:[NSString stringWithFormat:@"%d", 33] pdata:@"0006050c000200003f007f206f740000a01400000c810301250082028281830100"];
                }else if ([contentStr isEqualToString:@"13"]) {
                    [UNCreatLocalNoti createLocalNotiMessageString:@"对卡上电3失败"];
                    NSLog(@"对卡上电3失败");
                    [self registFailAction];
                }
                break;
            case 8:
                //回应断电
                NSLog(@"对卡断电成功");
                break;
            case 9:
                //回应SIM数据
                NSLog(@"sim卡相关数据");
                if ([BlueToothDataManager shareManager].bleStatueForCard == 0) {
                    //默认状态，查询卡类型
                    [UNCreatLocalNoti createLocalNotiMessageString:[NSString stringWithFormat:@"蓝牙发送的数据--%@", contentStr]];
                    NSString *totalString = contentStr;
                    NSLog(@"totalString -- %@", totalString);
                    if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"9f17"]) {
                        [UNCreatLocalNoti createLocalNotiMessageString:[NSString stringWithFormat:@"蓝牙发送的数据--%@", @"9f17"]];
                        [self sendMessageToBLEWithType:BLECardData validData:@"a0a40000022f02"];
                    } else if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"9f0f"]) {
                        [UNCreatLocalNoti createLocalNotiMessageString:[NSString stringWithFormat:@"蓝牙发送的数据--%@", @"9f0f"]];
                        //A0B000000A
                        [self sendMessageToBLEWithType:BLECardData validData:@"a0b000000a"];
                    } else if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"0344"]) {
                        [UNCreatLocalNoti createLocalNotiMessageString:[NSString stringWithFormat:@"蓝牙发送的数据--%@", @"0344"]];
                        //对卡断电
                        [self phoneCardToOutageNew];
                        //是大王卡
                        NSLog(@"是大王卡");
                        [BlueToothDataManager shareManager].isActivityCard = YES;
                        [BlueToothDataManager shareManager].bleStatueForCard = 1;
                        [BlueToothDataManager shareManager].operatorType = @"2";
//                        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_AIXIAOQICARD];
                        [BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue = NO;
                    } else {
                        //对卡断电
                        [self phoneCardToOutageNew];
                        [UNCreatLocalNoti createLocalNotiMessageString:[NSString stringWithFormat:@"蓝牙发送的数据--%@", @"不是大王卡"]];
                        NSLog(@"不是大王卡");
                        //判断是否有指定套餐，并创建连接
                        [BlueToothDataManager shareManager].bleStatueForCard = 2;
                        if ([BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue) {
                            //查询tcp连接状态
//                            [self checkRegistStatue];
                            [BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue = NO;
                        } else {
                            //注册卡
                            if (![BlueToothDataManager shareManager].isTcpConnected && ![BlueToothDataManager shareManager].isRegisted) {
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                                    [self checkUserIsExistAppointPackage];
                                });
                            } else {
//                                [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_SIGNALSTRONG];
                            }
                        }
                    }
                }
//                else if ([BlueToothDataManager shareManager].bleStatueForCard == 1) {
//                    if ([BlueToothDataManager shareManager].isActivityCard) {
//                        //激活大王卡的步骤
//                        NSLog(@"接收到激活大王卡的数据 -- %@", str);
//                        NSString *totalString = contentStr;
//                        NSLog(@"totalString -- %@", totalString);
//                        if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"9f17"]) {
//                            [self sendMessageToBLEWithType:BLECardData validData:@"a0a40000022f02"];
//                        } else if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"9f0f"]) {
//                            //A0B000000A
//                            [self sendMessageToBLEWithType:BLECardData validData:@"a0b000000a"];
//                        } else if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"0344"]) {
//                            //对卡断电
//                            [self phoneCardToOutageNew];
//                            self.bigKingCardNumber = [totalString substringWithRange:NSMakeRange(4, 16)];
//                            [self checkQueueOrderData];
//                        } else if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"9000"]) {
//                            //对卡断电
//                            [self phoneCardToOutageNew];
//                            [self activitySuccess];
//                        } else {
//                            //对卡断电
//                            [self phoneCardToOutageNew];
//                            NSLog(@"返回数据有问题");
//                            HUDStop;
//                            HUDNormal(@"激活失败")
//                            [self paySuccess];
//                        }
//                    }else {
//                        NSLog(@"激活大王卡状态有问题");
//                    }
//                }
                else if ([BlueToothDataManager shareManager].bleStatueForCard == 2) {
//                    [UNCreatLocalNoti createLocalNotiMessageString:@"注册手机卡"];
//                    //注册手机卡状态
//                    //注册电话卡的步骤
//                    NSString *totalString = contentStr;
//                    if (totalString) {
//                        [self.dataPacketArray addObject:totalString];
//                    }
//                    //总包数
//                    NSString *totalDataNumber;
//                    //数据当前包数
//                    NSString *dataCurrentNumber = [NSString stringWithFormat:@"%lu", strtoul([[str substringWithRange:NSMakeRange(2, 2)] UTF8String], 0, 16)+1];
//                    if ([dataCurrentNumber intValue] >= 128) {
//                        totalDataNumber = [NSString stringWithFormat:@"%d", [dataCurrentNumber intValue] - 128];
//                        NSString *tempStr;
//                        if (self.dataPacketArray.count) {
//                            if (self.dataPacketArray.count == 1) {
//                                self.totalString = self.dataPacketArray[0];
//                            } else {
//                                for (int i = 0; i < self.dataPacketArray.count; i++) {
//                                    if (i == 0) {
//                                        tempStr = self.dataPacketArray[0];
//                                    } else {
//                                        self.totalString = [NSString stringWithFormat:@"%@%@", tempStr, self.dataPacketArray[i]];
//                                        tempStr = self.totalString;
//                                    }
//                                }
//                            }
//                            NSLog(@"最终发送的数据包字符为：%@", self.totalString);
//                            [[NSNotificationCenter defaultCenter] postNotificationName:@"receiveNewDtaaPacket" object:self.totalString];
//                            [self.dataPacketArray removeAllObjects];
//                            self.totalString = nil;
//                        }
//                    }
                } else {
                    //状态有问题
                    NSLog(@"状态有问题");
                }
                break;
            case 10:
                //上一次充电时间
                break;
            default:
                NSLog(@"不能识别的类别");
                break;
        }
    }
}


#pragma mark 判断用户是否存在指定套餐
//- (void)checkUserIsExistAppointPackage {
//    NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:@"apiCheckUsedExistByPageCategory"];
//    if (responseObj) {
//        if ([responseObj[@"data"][@"Used"] intValue]/*0：不存在，1：存在*/) {
//            dispatch_queue_t global = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//            dispatch_async(global, ^{
//                if ([self.simtype isEqualToString:@"1"] || [self.simtype isEqualToString:@"2"]) {
//                    if ([BlueToothDataManager shareManager].isTcpConnected) {
//                        [[NSNotificationCenter defaultCenter] postNotificationName:@"connectingBLE" object:@"connectingBLE"];
//                    } else {
//                        [[VSWManager shareManager] simActionWithSimType:self.simtype];
//                    }
//                } else {
//                    HUDNormal(@"电话卡运营商不属于三大运营商")
//                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOSIGNAL];
//                }
//            });
//        }
//    }
//}


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
            
        default:
            break;
    }
    if (validData) {
        //有有效data
        if (firstStr.length/2 <= 15) {
            validStrLength = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)(firstStr.length+typeStr.length)/2]];
            totalStr = [NSString stringWithFormat:@"8880%@%@%@", validStrLength, typeStr, firstStr];
            NSLog(@"只有一个包，最终发送的包内容 -> %@", totalStr);
            [self sendConnectingInstructWithData:[UNDataTransformation checkNewMessageReuseWithString:totalStr]];
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
                    NSLog(@"多包第一个，最终发送的包内容 -> %@", totalStr);
                    [self sendConnectingInstructWithData:[UNDataTransformation checkNewMessageReuseWithString:totalStr]];
                } else if (i == [totalNumber integerValue] - 1) {
                    //最后一个
                    currentStrLength = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)((firstStr.length-15*2)-(i-1)*(17*2))/2]];
                    currentNumStr = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)i + 128]];//加上0x80
                    tempStr = [firstStr substringFromIndex:15*2 + 17*2*(i - 1)];
                    totalStr = [NSString stringWithFormat:@"88%@%@%@", currentNumStr, currentStrLength, tempStr];
                    NSLog(@"多包最后一个，最终发送的包内容 -> %@", totalStr);
                    [self sendConnectingInstructWithData:[UNDataTransformation checkNewMessageReuseWithString:totalStr]];
                } else {
                    //中间的
                    currentStrLength = [self hexStringFromString:@"17"];
                    tempStr = [firstStr substringWithRange:NSMakeRange(15*2+17*2*(i-1), 17*2)];
                    currentNumStr = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)i]];
                    totalStr = [NSString stringWithFormat:@"88%@%@%@", currentNumStr, currentStrLength, tempStr];
                    NSLog(@"多包中间的，最终发送的包内容 -> %@", totalStr);
                    [self sendConnectingInstructWithData:[UNDataTransformation checkNewMessageReuseWithString:totalStr]];
                }
            }
        }
        
    } else {
        //无有效data
        validStrLength = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)(typeStr.length)/2]];
        totalStr = [NSString stringWithFormat:@"8880%@%@", validStrLength, typeStr];
        NSLog(@"无有效data，最终发送的包内容 -> %@", totalStr);
        [self sendConnectingInstructWithData:[UNDataTransformation checkNewMessageReuseWithString:totalStr]];
    }
}

#pragma mark token转换成十六进制，换算文本
- (NSString *)hexStringFromString:(NSString *)string {
    NSData *myD = [string dataUsingEncoding:NSUTF8StringEncoding];
    Byte *bytes = (Byte *)[myD bytes]; //下面是Byte 转换为16进制。
    NSString *hexStr=@"";
    for ( int i=0 ;i<[myD length];i++) {
        NSString *newHexStr = [NSString stringWithFormat:@ "%x" ,bytes[i]& 0xff ]; ///16进制数
        if ([newHexStr length]== 1)
            hexStr = [NSString stringWithFormat:@ "%@0%@" ,hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@ "%@%@" ,hexStr,newHexStr];
    }
    return hexStr;
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
    NSLog(@"十进制：%@ %d %d %@ %d %d %d", yearString, month, day, weekString, hour, min, sec);
    NSString *hexYear = [self hexStringFromString:yearString];
    NSString *hexMonth = [self hexStringFromString:monthString];
    NSString *hexDay = [self hexStringFromString:dayString];
    NSString *hexWeek = [self hexStringFromString:weekString];
    NSString *hexHour = [self hexStringFromString:hourString];
    NSString *hexMin = [self hexStringFromString:minString];
    NSString *hexSec = [self hexStringFromString:secString];
    
    [self sendMessageToBLEWithType:BLETurnoverTime validData:[NSString stringWithFormat:@"%@%@%@%@%@%@%@", hexYear, hexMonth, hexDay, hexHour, hexMin, hexSec, hexWeek]];
}

#pragma mark 复位请求指令
- (NSData *)resettingInstruct {
    Byte reg[6];
    //    0xAA 0x11 0x22 0x33 0xAA
    reg[0]=0xAA;
    reg[1]=0x11;
    reg[2]=0x22;
    reg[3]=0x33;
    reg[4]=0xAA;
    reg[5]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]^reg[4]);
    NSData *data=[NSData dataWithBytes:reg length:6];
    return data;
}

#pragma mark 对卡上电指令（新协议）
- (void)phoneCardToUpeLectrify:(NSString *)type {
    [UNCreatLocalNoti createLocalNotiMessageString:@"请求上电"];
    [self sendMessageToBLEWithType:BLEUpElectricToCard validData:type];
}

#pragma mark 数据包截取字符串转换为int型
- (int)convertRangeStringToIntWithString:(NSString *)dataString rangeLoc:(NSUInteger)rangeLoc rangeLen:(NSUInteger)rangeLen {
    NSString *subString = [dataString substringWithRange:NSMakeRange(rangeLoc, rangeLen)];
    int result = strtoul([subString UTF8String], 0, 16);
    //    NSLog(@"返回的结果为：%d", result);
    return result;
}

#pragma mark 判断卡类型第一步
- (void)checkCardType {
    [self sendMessageToBLEWithType:BLECardData validData:@"a0a40000023f00"];
}
#pragma mark 对卡断电指令
- (void)phoneCardToOutageNew {
    [self sendMessageToBLEWithType:BLEDownElectricToCard validData:nil];
}


#pragma mark ------------其他------------
#pragma mark 转换十六进制

#pragma mark 异或校验
- (NSString *)check_sum:(NSArray*)date {
    
    NSInteger checksum = 0;
    int tempData = 0;
    
    for (NSInteger i = 0; i < date.count; i++) {
        //先将十六进制转换成十进制
        tempData = strtoul([date[i] UTF8String], 0, 16);
        //        NSLog(@"date[i] = %ld",(long)tempData);
        checksum ^= tempData;
        //        NSLog(@"checksum = %ld",(long)checksum);
        
    }
    //再将十进制转换为十六进制
    NSString *hexChecksum = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)checksum]];
    NSLog(@"校验位：%@", hexChecksum);
    //    return hexChecksum;
    NSString *checkSum = [NSString stringWithFormat:@"%ld", (long)checksum];
    return checkSum;
    
}

#pragma mark 获取手环注册状态
//- (void)checkRegistStatue {
//    self.checkToken = YES;
//    [self getBasicHeader];
//    NSLog(@"表头：%@",self.headers);
//    [SSNetworkRequest getRequest:apiGetRegStatus params:nil success:^(id responseObj) {
//        if ([[responseObj objectForKey:@"status"] intValue]==1) {
//            NSLog(@"手环注册状态 -- %@", responseObj[@"data"][@"RegStatus"]);
//            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:@"apiGetRegStatus" dictData:responseObj];
//            
//            if ([responseObj[@"data"][@"RegStatus"] intValue] == 1) {
//                //注册成功
//                [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_SIGNALSTRONG];
//            } else if ([responseObj[@"data"][@"RegStatus"] intValue] == 0) {
//                //未注册成功
//                [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOSIGNAL];
//                //注册卡
//                if (![BlueToothDataManager shareManager].isTcpConnected && ![BlueToothDataManager shareManager].isRegisted) {
//                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                        [self checkUserIsExistAppointPackage];
//                    });
//                } else {
//                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_SIGNALSTRONG];
//                }
//            } else {
//                NSLog(@"注册状态有问题");
//            }
//        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
//        }else{
//            //数据请求失败
//            HUDNormal(responseObj[@"msg"])
//        }
//    } failure:^(id dataObj, NSError *error) {
//        HUDNormal(@"网络貌似有问题")
//        
//        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:@"apiGetRegStatus"];
//        if (responseObj) {
//            if ([responseObj[@"data"][@"RegStatus"] intValue] == 1) {
//                //注册成功
//                [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_SIGNALSTRONG];
//            } else if ([responseObj[@"data"][@"RegStatus"] intValue] == 0) {
//                //未注册成功
//                [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOSIGNAL];
//                //注册卡
//                if (![BlueToothDataManager shareManager].isTcpConnected && ![BlueToothDataManager shareManager].isRegisted) {
//                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                        [self checkUserIsExistAppointPackage];
//                    });
//                } else {
//                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_SIGNALSTRONG];
//                }
//            } else {
//                NSLog(@"注册状态有问题");
//            }
//        }
//        
//        NSLog(@"啥都没：%@",[error description]);
//    } headers:self.headers];
//}











- (void)setUpUdpSocket
{
    _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_udpSocket receiveOnce:nil];
    //监听接口和接收数据
    NSError * error = nil;
    [_udpSocket bindToPort:PORT error:&error];
    if (error) {//监听错误打印错误信息
        NSLog(@"error:%@",error);
        NSString *errorStr= [NSString stringWithFormat:@"socket-error:%@",error];
        [UNCreatLocalNoti createLocalNotiMessageString:errorStr];
    }else {//监听成功则开始接收信息
        [_udpSocket beginReceiving:&error];
        [UNCreatLocalNoti createLocalNotiMessageString:@"socket成功"];
    }
}


#pragma mark udp协议
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
//    [UNCreatLocalNoti createLocalNotiMessageString:@"udp---didReceiveData"];
    
    self.prot = [GCDAsyncUdpSocket portFromAddress:address];
    NSLog(@"接收到%@的消息:%@",address,data);//自行转换格式吧
    NSString *receivedMessage = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    //    NSLog(@"获取的端口号 -> %d", self.prot);
    self.currentPacketNumber = [receivedMessage substringWithRange:NSMakeRange(0, 6)];
    NSString *str = [self.currentPacketNumber substringWithRange:NSMakeRange(3, 3)];
    //发送当前编号
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeStatue" object:str];
    [BlueToothDataManager shareManager].isBeingRegisting = YES;
    [BlueToothDataManager shareManager].stepNumber = str;
//    if (![BlueToothDataManager shareManager].isRegisted) {
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:HOMESTATUETITLE_CONNECTING];
//    }
    NSLog(@"转换之后的内容：%@", receivedMessage);
    if ([receivedMessage isEqualToString:@"200001:0x0000"]) {
        [UNCreatLocalNoti createLocalNotiMessageString:@"需要upLoadToCard"];
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"upLoadToCard" object:@"upLoadToCard"];
//        if ([BlueToothDataManager shareManager].isNeedToResert) {
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:HOMESTATUETITLE_CONNECTING];
//        }
    } else {
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"receiveNewMessageFromBLE" object:[receivedMessage substringFromIndex:7]];
        [UNCreatLocalNoti createLocalNotiMessageString:@"senderNewMessageToBLE"];
        [self senderNewMessageToBLE:[receivedMessage substringFromIndex:7]];
    }
}

- (void)senderNewMessageToBLE:(NSString *)tempStr {
    [self sendMessageToBLEWithType:BLECardData validData:tempStr];
}


- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    [UNCreatLocalNoti createLocalNotiMessageString:@"udp---didSendDataWithTag"];
    NSLog(@"发送信息成功");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    [UNCreatLocalNoti createLocalNotiMessageString:@"udp---didNotSendDataWithTag"];
    NSLog(@"发送信息失败");
}

















@end
