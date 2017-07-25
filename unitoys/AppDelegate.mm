//
//  AppDelegate.m
//  unitoys
//
//  Created by sumars on 16/9/11.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "AppDelegate.h"
#import "global.h"
#import <AlipaySDK/AlipaySDK.h>
#import "ContactModel.h"
#import "AddressBookManager.h"
#import <AddressBook/AddressBook.h>

#import "SSNetworkRequest.h"           //网络请求
#import <CommonCrypto/CommonDigest.h>  //MD5算法所需
#import "SipEngineManager.h"
#import "BGTask.h"
#import "BGLogation.h"

#import "GCDAsyncUdpSocket.h"
#import "GCDAsyncSocket.h"
#import "VSWManager.h"
#import "BlueToothDataManager.h"
#import "NSString+Extension.h"

#import "PhoneViewController.h"

//CallKit相关
#import <CallKit/CallKit.h>
#import "UNCallKitCenter.h"
#import "NSUserActivity+UnExtension.h"
#import <FMDB/FMDB.h>

// 引 JPush功能所需头 件
#import "JPUSHService.h"
// iOS10注册APNs所需头 件
#ifdef NSFoundationVersionNumber_iOS_9_x_Max 
#import <UserNotifications/UserNotifications.h> 

#import "UNDatabaseTools.h"
//#import <Reachability/Reachability.h>
#import <PushKit/PushKit.h>
#import "UNSipEngineInitialize.h"

#import "UNCreatLocalNoti.h"
#import "HWNewfeatureViewController.h"
#import "UNBlueToothTool.h"
#import "UNPushKitMessageManager.h"
#import "UNNetWorkStatuManager.h"

#import "MBProgressHUD+UNTip.h"

#import "UNLoginViewController.h"
#import "UNDataTools.h"

#import "UNCheckPhoneAuth.h"

#endif
// 如果需要使 idfa功能所需要引 的头 件(可选) #import <AdSupport/AdSupport.h>

@interface AppDelegate ()<JPUSHRegisterDelegate, GCDAsyncUdpSocketDelegate, GCDAsyncSocketDelegate, PKPushRegistryDelegate>
@property (strong , nonatomic) BGTask *task;
@property (strong , nonatomic) NSTimer *bgTimer;
@property (strong , nonatomic) BGLogation *bgLocation;
@property (strong , nonatomic) CLLocationManager *location;
@property (strong, nonatomic)GCDAsyncUdpSocket * udpSocket;
@property (nonatomic, strong)GCDAsyncSocket *sendTcpSocket;
@property (nonatomic, copy) NSString *currentPacketNumber;
@property (nonatomic, assign)int prot;
@property (nonatomic, copy)NSString *iccidTotalHex;
@property (nonatomic, copy)NSString *imsiTotalHex;
@property (nonatomic, copy)NSString *packetTotalLengthHex;
@property (nonatomic, copy)NSString *packetFinalHex;
@property (nonatomic, copy)NSString *tcpPacketStr;
@property (nonatomic, copy)NSString *tlvFirstStr;
@property (nonatomic, copy)NSString *communicateID;
@property (nonatomic, strong)NSTimer *timer;
@property (nonatomic, assign)int sec;
@property (nonatomic, assign) int lessStep;
@property (nonatomic, assign) BOOL isNeedToCheckSIMStatue;

//重连定时器,收到0f数据后,每过几秒检查条件是否符合,符合才重连,并关闭定时器
@property (nonatomic, strong) NSTimer *reconnectTimer;
@property (nonatomic, assign) NSInteger reconnectTimeCount;
@property (nonatomic, strong)NSMutableDictionary *headers;
@property (nonatomic, assign) BOOL checkToken;
@end

@implementation AppDelegate



- (void)redirectNSLogToDocumentFolder
{
#if DEBUG
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    
    NSString *fileName = [NSString stringWithFormat:@"%@.log",[[NSDate alloc] initWithTimeIntervalSinceNow:8*3600]]; // 注意不是NSData!
    NSString *logFilePath = [documentDirectory stringByAppendingPathComponent:fileName];
    
    // 将log输入到文件
//    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+", stdout);
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
#endif
}



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //制定真机调试保存日志文件
//    [self redirectNSLogToDocumentFolder];
    
    [[UNDDLogManager sharedInstance] enabelUNLog];
    
    UNLogLBEProcess(@"============================================didFinishLaunchingWithOptions============================================\n")
    [UNPushKitMessageManager shareManager].pushKitMsgType = PushKitMessageTypeNone;
    [BlueToothDataManager shareManager].isOpened = YES;
    [BlueToothDataManager shareManager].isShowStatuesView = NO;
    self.lessStep = 0;
    [[UNNetWorkStatuManager shareManager] initNetWorkStatuManager];
    
    [UNNetWorkStatuManager shareManager].netWorkStatuChangeBlock = ^(NetworkStatus currentStatu){
        if (currentStatu != NotReachable) {
            //清除网络断开连接通知
            [UNCreatLocalNoti clearNETDisConnectNoti];
            
            UNLogLBEProcess(@"有网络")
//            [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_REGISTING;
            [self changeBleStatue];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"netWorkNotToUse" object:@"1"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"NetStatusIsWell" object:nil];
            });
            
            if (self.tcpPacketStr) {
                UNLogLBEProcess(@"注册Tcp")
                [self closeTCP];
                if ([UNPushKitMessageManager shareManager].pushKitMsgType == PushKitMessageTypeNone) {
                    [UNPushKitMessageManager shareManager].isSendTcpString = NO;
                }
                if (![[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] isEqualToString:@"on"]) {
                    UNDebugLogVerbose(@"服务开关是开的：%s,%d", __FUNCTION__, __LINE__);
                    [self creatAsocketTcp];
                } else {
                    UNDebugLogVerbose(@"服务开关关闭：%s,%d", __FUNCTION__, __LINE__);
                }
            }
        } else {
            UNLogLBEProcess(@"无网络")
            [BlueToothDataManager shareManager].isShowStatuesView = YES;
//            [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NETWORKCANNOTUSE;
            [self changeBleStatue];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"netWorkNotToUse" object:@"0"];
            });
        }
    };
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([UNNetWorkStatuManager shareManager].currentStatu == NotReachable) {
            UNLogLBEProcess(@"主程序无网络")
            [BlueToothDataManager shareManager].isShowStatuesView = YES;
//            [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NETWORKCANNOTUSE;
            [self changeBleStatue];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"netWorkNotToUse" object:@"0"];
        }else{
            UNLogLBEProcess(@"主程序有网络")
//            [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_REGISTING;
            [self changeBleStatue];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"netWorkNotToUse" object:@"1"];
        }
    });
    
    if (kSystemVersionValue >= 10.0) {
        [[UNCallKitCenter sharedInstance] configurationCallProvider];
    }
    
    if (kSystemVersionValue >= 8.0) {
        PKPushRegistry *pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
        pushRegistry.delegate = self;
        pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    }
    
    //获取基本配置
    [self loadBasicConfig];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    // 2.设置根控制器
    NSString *key = @"CFBundleVersion";
    NSString *key1 = @"CFBundleShortVersionString";
    // 上一次的使用版本（存储在沙盒中的版本号）
    NSString *lastVersion = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    NSString *lastShortVersion = [[NSUserDefaults standardUserDefaults] objectForKey:key1];
    // 当前软件的版本号（从Info.plist中获得）
    NSString *currentVersion = [NSBundle mainBundle].infoDictionary[key];
    NSString *currentShortVersion = [NSBundle mainBundle].infoDictionary[key1];
    
    if ([currentVersion isEqualToString:lastVersion] && [currentShortVersion isEqualToString:lastShortVersion]) { // 版本号相同：这次打开和上次打开的是同一个版本
        [self showLaunchView];
        [self checkLogin];
    } else { // 这次打开的版本和上一次不一样，显示新特性
        self.window.rootViewController = [[HWNewfeatureViewController alloc] init];
        [self.window makeKeyAndVisible];
        
        // 将当前的版本号存进沙盒
        [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:key];
        [[NSUserDefaults standardUserDefaults] setObject:currentShortVersion forKey:key1];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self checkDatabase];
    }
    
    [WXApi registerApp:@"wxff7e7ee82cd9afc4" withDescription:@"爱小器微信支付"];
    
    [Bugly startWithAppId:@"1eca39e3ae"];
    
    //极光推送
    [self resignJPushWithOptions:launchOptions];
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(networkDidReceiveMessage:) name:kJPFNetworkDidReceiveMessageNotification object:nil];
    
    //友盟
    [self initUMeng];
    
    BuglyConfig *config = [[BuglyConfig alloc] init];  //初始化
    config.delegate = self;
    self.window.backgroundColor = [UIColor colorWithRed:234/255.0 green:236/255.0 blue:240/255.0 alpha:1.0];
    
    if ([[UIDevice currentDevice].systemVersion floatValue] < 9.0) {
        ABAddressBookRef addresBook = ABAddressBookCreateWithOptions(NULL, NULL);
        ABAddressBookRegisterExternalChangeCallback(addresBook, addressBookChanged, (__bridge void *)(self));
    }
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    //定位相关
    _task = [BGTask shareBGTask];
    UIAlertView *alert;
    //判断定位权限
    if([UIApplication sharedApplication].backgroundRefreshStatus == UIBackgroundRefreshStatusDenied)
    {
        if (!alert) {
            alert = [[UIAlertView alloc]initWithTitle:INTERNATIONALSTRING(@"提示") message:INTERNATIONALSTRING(@"应用没有开启后台定位功能，需要在设置->通用->后台应用刷新开启") delegate:nil cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil];
            [alert show];
        }
    }
    else if ([UIApplication sharedApplication].backgroundRefreshStatus == UIBackgroundRefreshStatusRestricted)
    {
        if (!alert) {
            alert = [[UIAlertView alloc]initWithTitle:INTERNATIONALSTRING(@"提示") message:INTERNATIONALSTRING(@"设备不可以定位") delegate:nil cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil];
            [alert show];
        }
    }
    else
    {
        self.bgLocation = [[BGLogation alloc]init];
        [self.bgLocation startLocation];
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(log) userInfo:nil repeats:YES];
    }
    
#warning 先不创建udp,获取imsi
//    [self setUpUdpSocket];
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"iosSystemBit"]) {
        if ([self is32bit]) {
            [[NSUserDefaults standardUserDefaults] setObject:@"32" forKey:@"iosSystemBit"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendNewMessage:) name:@"receiveNewDtaaPacket" object:nil];//udp发包
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTcpPacket:) name:@"tcppacket" object:nil];//收到tcp部分数据包
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTcpIccidAndImsi:) name:@"iccidAndImsi" object:nil];//收到tcp的iccid和imsi
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTcpLength:) name:@"packetLength" object:nil];//收到tcp的数据包压缩前长度
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNewDataStr:) name:@"receiveNewDataStr" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectingBLEAction) name:@"connectingBLE" object:@"connectingBLE"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeTCPAndService) name:@"noConnectedAndUnbind" object:@"noConnectedAndUnbind"];//解绑之后关闭tcp
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dicConnectedBLE) name:@"deviceIsDisconnect" object:@"deviceIsDisconnect"];//蓝牙断开连接
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeTCPAndService) name:@"disconnectTCP" object:@"disconnectTCP"];//关闭tcp
    // Override point for customization after application launch.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTcpDataFromPushKit:) name:@"SendTcpDataFromPushKit" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createUDPSocketToBLE:) name:@"CreateUDPSocketToBLE" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createTCPSocketToBLE:) name:@"CreateTCPSocketToBLE" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearTimeoutPushKitMessage) name:@"PushKitMessageDataTimeout" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendDataToCloseService) name:@"closeServiceNotifi" object:@"closeServiceNotifi"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSuccessAndCreatTCP) name:@"loginSuccessAndCreatTcpNotif" object:@"loginSuccessAndCreatTcpNotif"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(isAlreadOnlineAndSendJumpData) name:@"isAlreadOnlineAndSendJumpDataNotifi" object:@"isAlreadOnlineAndSendJumpDataNotifi"];
    //接收重新登入通知，清除缓存的数据包
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanPackageData) name:@"reloginNotify" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaSuccessAndReConnected) name:@"OTASuccessAndReConnectedNotif" object:@"OTASuccessAndReConnectedNotif"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UNCheckPhoneAuth checkCurrentAuth];
    });
    
    return YES;
}

- (void)otaSuccessAndReConnected {
    if (![UNDataTools sharedInstance].isLogout) {
        UNDebugLogVerbose(@"在线：%s,%d", __FUNCTION__, __LINE__);
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] isEqualToString:@"on"]) {
            if ([BlueToothDataManager shareManager].isOpened) {
                if ([UNNetWorkStatuManager shareManager].currentStatu != 0) {
                    self.isNeedToCheckSIMStatue = YES;
                    if ([BlueToothDataManager shareManager].isTcpConnected) {
                        [self sendDataToCheckRegistStatue];
                    } else {
                        [self creatAsocketTcp];
                    }
                } else {
                    UNLogLBEProcess(@"进入前台--没网络")
                }
            } else {
                UNLogLBEProcess(@"进入前台--蓝牙未开")
            }
        } else {
            UNLogLBEProcess(@"进入前台--服务未开")
        }
    } else {
        UNDebugLogVerbose(@"不在线：%s,%d", __FUNCTION__, __LINE__);
    }
}


- (void)cleanPackageData {
    self.tcpPacketStr = nil;
    [UNPushKitMessageManager shareManager].iccidString = nil;
}

- (void)initUMeng {
#if DEBUG
    //打印登录信息
    [MobClick setLogEnabled:YES];
    UMConfigInstance.appKey = @"5940f2581c5dd06a9f0011ad";
#else
    UMConfigInstance.appKey = @"5938f75075ca357657001149";
#endif
    UMConfigInstance.channelId = @"App Store";
    //设置登录账号
//    [MobClick profileSignInWithPUID:@"playerID"];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [MobClick setAppVersion:version];
    [MobClick startWithConfigure:UMConfigInstance];//配置以上参数后调用此方法初始化SDK！
}

- (void)sendDataToCloseService {
    if (![self.communicateID isEqualToString:@"00000000"]) {
        //发送关闭服务的数据
        NSString *sendStr = [NSString stringWithFormat:@"108a0d00%@00010003020100", self.communicateID];
        UNLogLBEProcess(@"发送关闭服务的数据 -- %@", sendStr)
        [self sendMsgWithMessage:sendStr];
        [self.timer setFireDate:[NSDate distantFuture]];
        self.tcpPacketStr = nil;
    }
}

- (void)sendDataToCheckRegistStatue {
    //发送检查是否在线的数据
    if (self.isNeedToCheckSIMStatue) {
        // 等待数据来啊
        [self.sendTcpSocket readDataWithTimeout:-1 tag:200];
        
        NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
        NSString *token;
        if (userdata) {
            token = userdata[@"Token"];
        }
        UNLogLBEProcess(@"判断tcp是否在线的时候的token - %@", token)
        NSString *ascHex = [self hexStringFromString:token];
        //    UNDebugLogVerbose(@"转换前：%@\n 转换后：%@\n 转换后的长度：%lu", token, ascHex, (unsigned long)ascHex.length/2);
        NSString *lengthHex = [self hexNewStringFromString:[NSString stringWithFormat:@"%zd", ascHex.length/2]];
        //    UNDebugLogVerbose(@"长度为 -- %@", lengthHex);
        NSString *tokenHex = [NSString stringWithFormat:@"78%@%@", lengthHex, ascHex];
        //正常状态TCP包
        NSString *tempHex = [self hexFinalTLVLength:[NSString stringWithFormat:@"%zd", tokenHex.length/2]];
        
        NSString *sendStr = [NSString stringWithFormat:@"108a0900000000000001%@%@", tempHex, tokenHex];
        UNLogLBEProcess(@"发送检查是否在线的数据 -- %@", sendStr)
        [self sendMsgWithMessage:sendStr];
        self.isNeedToCheckSIMStatue = NO;
    } else {
        UNDebugLogVerbose(@"状态不对 - 位置：%s%d", __func__, __LINE__);
    }
}

- (void)isAlreadOnlineAndSendJumpData {
    if (!self.tcpPacketStr) {
        self.tcpPacketStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"TCPPacketStr"];
    }
    self.communicateID = [BlueToothDataManager shareManager].commicateIDFromTcp;
    [VSWManager shareManager].callPort = [BlueToothDataManager shareManager].portFromTcp;
    [[NSUserDefaults standardUserDefaults] setObject:[BlueToothDataManager shareManager].portFromTcp forKey:@"VSWCallPort"];
    [self startJumpDataTimer];
    
    [self callPhoneFromCallKit];
}

- (void)loadBasicConfig {
    [SSNetworkRequest getRequest:apiGetBasicConfig params:nil success:^(id responseObj){
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:@"apiGetBasicConfig" dictData:responseObj];
            [[NSUserDefaults standardUserDefaults] setObject:[[responseObj objectForKey:@"data"] objectForKey:@"paymentOfTerms"] forKey:@"paymentOfTerms"];
            [[NSUserDefaults standardUserDefaults] setObject:[[responseObj objectForKey:@"data"] objectForKey:@"howToUse"]  forKey:@"howToUse"];
            [[NSUserDefaults standardUserDefaults] setObject:[[responseObj objectForKey:@"data"] objectForKey:@"userAgreementUrl"] forKey:@"userAgreementUrl"];
            //双卡双待教程
            [[NSUserDefaults standardUserDefaults] setObject:[[responseObj objectForKey:@"data"] objectForKey:@"dualSimStandbyTutorialUrl"] forKey:@"dualSimStandbyTutorialUrl"];
            //出国前教程
            [[NSUserDefaults standardUserDefaults] setObject:[[responseObj objectForKey:@"data"] objectForKey:@"beforeGoingAbroadTutorialUrl"] forKey:@"beforeGoingAbroadTutorialUrl"];
            //什么是爱小器卡
            [[NSUserDefaults standardUserDefaults] setObject:[[responseObj objectForKey:@"data"] objectForKey:@"aixiaoqiDescrUrl"] forKey:@"aixiaoqiDescrUrl"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
    }failure:^(id dataObj, NSError *error) {
        UNDebugLogVerbose(@"数据错误：%@",[error description]);
    } headers:nil];
}


- (void)showLaunchView {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LaunchScreen" bundle:nil];
    if (storyboard) {
        UIViewController *launchScreen = [storyboard instantiateViewControllerWithIdentifier:@"launchScreen"];
        if (launchScreen) {
            self.window.rootViewController = launchScreen;
            [self.window makeKeyAndVisible];
            self.currentNumber = 8;
            self.communicateID = @"00000000";
        }
    }
}

- (void)createUDPSocketToBLE:(NSNotification *)noti
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[VSWManager shareManager] simActionWithSimType:noti.object];
//        [[VSWManager shareManager] registAndInit];
    });
    UNLogLBEProcess(@"创建udp")
    [self setUpUdpSocket];
}

//收到蓝牙通知创建TCP
- (void)createTCPSocketToBLE:(NSNotification *)noti
{
    if (![UNPushKitMessageManager shareManager].iccidString) {
        UNLogLBEProcess(@"ICCID没有了：%s,%d", __FUNCTION__, __LINE__)
        return;
    }
    UNLogLBEProcess(@"获取ICCID数据")
    [UNPushKitMessageManager shareManager].pushKitMsgType = PushKitMessageTypeNone;
    [BlueToothDataManager shareManager].isReseted = NO;
    [UNPushKitMessageManager shareManager].iccidString = [noti.object lowercaseString];
    NSDictionary *simData = [[NSUserDefaults standardUserDefaults] objectForKey:[UNPushKitMessageManager shareManager].iccidString];
    if (simData) {
        self.iccidTotalHex = simData[@"iccidTotalHex"];
        self.imsiTotalHex = simData[@"imsiTotalHex"];
        self.packetTotalLengthHex = simData[@"packetTotalLengthHex"];
        self.packetFinalHex = simData[@"packetFinalHex"];
    }
    UNLogLBEProcess(@"simData====%@", simData)
    [self groupPacket];
}

//创建UDP
- (void)setUpUdpSocket
{
    _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_udpSocket receiveOnce:nil];
    //监听接口和接收数据
    NSError * error = nil;
    [_udpSocket bindToPort:PORT error:&error];
    if (error) {//监听错误打印错误信息
        UNLogLBEProcess(@"setUpUdpSocket==error:%@",error)
    }else {//监听成功则开始接收信息
        [_udpSocket beginReceiving:&error];
    }
}

- (void)dicConnectedBLE {
    self.currentPacketNumber = @"001";
}

- (void)checkDatabase
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    path = [path stringByAppendingPathComponent:@"callrecord2.db"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // delete the old db.
    if (![fileManager fileExistsAtPath:path])
    {
        FMDatabase *db = [FMDatabase databaseWithPath:path];
        if ([db open]) {
            NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", @"CallRecord"];
            FMResultSet *rs = [db executeQuery:existsSql];
            if ([rs next]) {
                NSInteger count = [rs intForColumn:@"countNum"];
                UNDebugLogVerbose(@"The table count: %zd", count);
                if (count == 0) {
                    [db executeUpdate:@"CREATE TABLE CallRecord (datas Text, calltime TimeStamp, dataid text)"];
                }
                [rs close];
            }
            [db close];
        }
    }
}

//关闭TCP
- (void)closeTCP {
    // 关闭套接字
    UNLogLBEProcess(@"手动关闭TCP")
    if (self.sendTcpSocket) {
        //        self.sendTcpSocket.userData = SocketCloseByUser;
        [self.sendTcpSocket disconnect];
        self.sendTcpSocket = nil;
    }
    [BlueToothDataManager shareManager].isTcpConnected = NO;
    [BlueToothDataManager shareManager].isBeingRegisting = NO;
    [BlueToothDataManager shareManager].isRegisted = NO;
}

- (void)closeTCPAndService {
    UNLogLBEProcess(@"关闭TCP和服务")
    [self sendDataToCloseService];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.sendTcpSocket) {
            //        self.sendTcpSocket.userData = SocketCloseByUser;
            [self.sendTcpSocket disconnect];
        }
        self.sendTcpSocket = nil;
        [BlueToothDataManager shareManager].isTcpConnected = NO;
        [BlueToothDataManager shareManager].isBeingRegisting = NO;
        [BlueToothDataManager shareManager].isRegisted = NO;
    });
}

- (void)connectingBLEAction {
    //发送数据
    self.communicateID = @"00000000";
    [self sendMsgWithMessage:self.tcpPacketStr];
}

#pragma mark - tcp相关
- (void)creatAsocketTcp {
    // 1. 创建一个 udp socket用来和服务端进行通讯
    UNLogLBEProcess(@"creatAsocketTcp")
    if (!self.sendTcpSocket) {
        UNLogLBEProcess(@"首次创建tcpSocket")
        dispatch_queue_t dQueue = dispatch_queue_create("client tdp socket", NULL);
        [UNPushKitMessageManager shareManager].isTcpConnecting = NO;
        self.sendTcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dQueue socketQueue:nil];
        [self.sendTcpSocket setPreferIPv4OverIPv6:NO];
        [UNPushKitMessageManager shareManager].isSendTcpString = NO;
        [self reConnectTcp];
    }else{
        if (!self.sendTcpSocket.isConnected) {
            UNLogLBEProcess(@"tcp未连接")
            [BlueToothDataManager shareManager].isTcpConnected = NO;
            [UNPushKitMessageManager shareManager].isSendTcpString = NO;
            [self reConnectTcp];
        }else{
            UNLogLBEProcess(@"tcp已连接")
            if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
                if (self.sendTcpSocket.isConnected) {
                    UNLogLBEProcess(@"tcp pushkit数据---%@",[UNPushKitMessageManager shareManager].tcpStringWithPushKit)
                    if ([UNPushKitMessageManager shareManager].tcpStringWithPushKit) {
                        self.communicateID = @"00000000";
#warning 此状态可能会对tcp状态判断有影响，需注意
//                        [BlueToothDataManager shareManager].isTcpConnected = YES;
                        // 等待数据来啊
                        [self.sendTcpSocket readDataWithTimeout:-1 tag:201];
                        //发送数据
                        [self setUpTcppacketFromPushKit];
                        UNDebugLogVerbose(@"最终发送给tcp的pushkit数据 -- %@", [UNPushKitMessageManager shareManager].tcpPacketStrWithPushKit);
                        [UNPushKitMessageManager shareManager].isSendTcpString = YES;
                    }
                }else{
                    [UNPushKitMessageManager shareManager].isSendTcpString = NO;
                    UNLogLBEProcess(@"走的这里");
                    [self reConnectTcp];
                }
            }else{
                if (![BlueToothDataManager shareManager].isReseted) {
                    UNLogLBEProcess(@"tcp数据---%@", self.tcpPacketStr)
                    //发送数据
                    if (self.tcpPacketStr) {
                        self.communicateID = @"00000000";
                        [BlueToothDataManager shareManager].isTcpConnected = YES;
                        // 等待数据来啊
                        [self.sendTcpSocket readDataWithTimeout:-1 tag:200];
                        UNDebugLogVerbose(@"最终发送给tcp的数据 -- %@", self.tcpPacketStr);
                        [self sendMsgWithMessage:self.tcpPacketStr];
                    }
                    
                } else {
                    UNLogLBEProcess(@"走的哪里？");
                }
            }
        }
    }
}

//从SDK收到注册数据
- (void)receiveTcpPacket:(NSNotification *)sender {
//    UNDebugLogVerbose(@"app里面收到数据了 -- %@", sender.object);
    UNLogLBEProcess(@"receiveTcpPacket====%@", sender.object)
    NSString *packteStr = [NSString stringWithFormat:@"%@", sender.object];
    NSString *packetLengthHex = [self hexNewStringFromString:[NSString stringWithFormat:@"%zd", packteStr.length/2]];
    UNDebugLogVerbose(@"数据包长度为 -- %zd  数据包长度转换成十六进制 -- %@", packteStr.length/2, packetLengthHex);
    self.packetFinalHex = [NSString stringWithFormat:@"c7%@%@", packetLengthHex, packteStr];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"downElectic" object:@"downElectic"];//发送对卡断电通知
}

- (void)receiveTcpIccidAndImsi:(NSNotification *)sender {
//    UNDebugLogVerbose(@"app里面收到iccid和imsi -- %@", sender.object);
    UNLogLBEProcess(@"receiveTcpIccidAndImsi====%@", sender.object)
    NSString *iccidStr = [sender.object substringWithRange:NSMakeRange(6, 20)];
    [UNPushKitMessageManager shareManager].iccidString = [[iccidStr copy] lowercaseString];
    NSString *iccidHex = [self hexStringFromString:iccidStr];
    NSString *iccidLengthHex = [self hexNewStringFromString:[NSString stringWithFormat:@"%zd", iccidHex.length/2]];
//    UNDebugLogVerbose(@"iccidStr -- %@  length -- %@", iccidHex, iccidLengthHex);
    self.iccidTotalHex = [NSString stringWithFormat:@"be%@%@", iccidLengthHex, iccidHex];
    NSString *imsiStr;
    NSString *checkStr;
    if ([NSString stringWithFormat:@"%@", sender.object].length >= 47) {
        imsiStr = [sender.object substringWithRange:NSMakeRange(32, 15)];
        NSString *imsiHex = [self hexStringFromString:imsiStr];
        NSString *imsiLengthHex = [self hexNewStringFromString:[NSString stringWithFormat:@"%ld", imsiHex.length/2]];
        //    UNDebugLogVerbose(@"imsiStr -- %@  length -- %@", imsiHex, imsiLengthHex);
        self.imsiTotalHex = [NSString stringWithFormat:@"bf%@%@", imsiLengthHex, imsiHex];
    }
    if (imsiStr.length >= 5) {
        checkStr = [imsiStr substringWithRange:NSMakeRange(0, 5)];
    } else {
        UNDebugLogVerbose(@"imsi前面的数据不对");
    }
    if ([checkStr isEqualToString:@"46000"] || [checkStr isEqualToString:@"46001"] || [checkStr isEqualToString:@"46002"] || [checkStr isEqualToString:@"46003"] || [checkStr isEqualToString:@"46007"]) {//因为移动网络编号46000下的IMSI已经用完，所以虚拟了一个46002编号，134/159号段使用了此编号
        [self groupPacket];
    } else {
        UNDebugLogVerbose(@"号码有问题");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [BlueToothDataManager shareManager].isBeingRegisting = NO;
            [BlueToothDataManager shareManager].isRegisted = NO;
            [BlueToothDataManager shareManager].isRegistedFail = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cardNumberNotTrue" object:HOMESTATUETITLE_NOSIGNAL];
            [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"卡注册失败") message:INTERNATIONALSTRING(@"您的电话卡可能出问题了，请核查号码是否能正常使用") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
        });
    }
}

- (void)receiveTcpLength:(NSNotification *)sender {
//    UNDebugLogVerbose(@"app里面收到数据包压缩前长度 -- %@", sender.object);
    NSString *totalLengthHex = [self hexNewStringFromString:sender.object];
    NSString *lengthHex = [self hexNewStringFromString:[NSString stringWithFormat:@"%zd", totalLengthHex.length/2]];
    self.packetTotalLengthHex = [NSString stringWithFormat:@"c6%@%@", lengthHex, totalLengthHex];
//    UNDebugLogVerbose(@"压缩前长度转换成十六进制 -- %@", self.packetTotalLengthHex);
}

#pragma mark 组合数据包
- (void)groupPacket {
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    NSString *token;
    if (userdata) {
        token = userdata[@"Token"];
    }
    UNLogLBEProcess(@"发送tcp连接的时候的token - %@", token)
    NSString *ascHex = [self hexStringFromString:token];
    //    UNDebugLogVerbose(@"转换前：%@\n 转换后：%@\n 转换后的长度：%lu", token, ascHex, (unsigned long)ascHex.length/2);
    NSString *lengthHex = [self hexNewStringFromString:[NSString stringWithFormat:@"%zd", ascHex.length/2]];
    //    UNDebugLogVerbose(@"长度为 -- %@", lengthHex);
    NSString *tokenHex = [NSString stringWithFormat:@"78%@%@", lengthHex, ascHex];
    NSString *tempString = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@", TCPGOIP, TCPLIFETIME, TCPCHECKPREREAD, tokenHex, TCPCONNECT, TCPUUWIFI, TCPSLOT, TCPIMEI, TCPMODTYPE, TCPMODVER, TCPSIMLOCAL, self.iccidTotalHex, self.imsiTotalHex, TCPSIMNUMBER, TCPSIMBALANCE, self.packetTotalLengthHex, self.packetFinalHex, TCPVERSIONTYPE, [UNPushKitMessageManager shareManager].pushKitTokenString];
    
    //PushKit
    NSString *isPushKitString = [self hexStringFromString:@"1"];
    NSString *isPushKitStringlength = [self hexNewStringFromString:[NSString stringWithFormat:@"%zd", isPushKitString.length/2]];
    //T : 203--cb
    NSString *isPushKit = [NSString stringWithFormat:@"cb%@%@", isPushKitStringlength, isPushKitString];
    NSString *PushKitTempString = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@", TCPGOIP, TCPLIFETIME, TCPCHECKPREREAD, tokenHex, TCPCONNECT, TCPUUWIFI, TCPSLOT, TCPIMEI, TCPMODTYPE, TCPMODVER, TCPSIMLOCAL, self.iccidTotalHex, self.imsiTotalHex, TCPSIMNUMBER, TCPSIMBALANCE, self.packetTotalLengthHex, self.packetFinalHex, TCPVERSIONTYPE, [UNPushKitMessageManager shareManager].pushKitTokenString, isPushKit];
    //PushKit下TCP包
    NSString *pushKitTempHex = [self hexTLVLength:[NSString stringWithFormat:@"%zd", PushKitTempString.length/2]];
    NSString *pushKitTcpPacket = [NSString stringWithFormat:@"%@%@0001%@%@", TCPFIRSTSUBNOT, TCPCOMMUNICATEID, pushKitTempHex, PushKitTempString];
    
    //正常状态TCP包
    NSString *tempHex = [self hexTLVLength:[NSString stringWithFormat:@"%zd", tempString.length/2]];
    NSString *tcpPacket = [NSString stringWithFormat:@"%@%@0001%@%@", TCPFIRSTSUBNOT, TCPCOMMUNICATEID, tempHex, tempString];
    
    //创建连接，重置会话id
    self.communicateID = @"00000000";
    if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate && ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)) {
        //PushKit
        self.tcpPacketStr = pushKitTcpPacket;
    }else{
        self.tcpPacketStr = tcpPacket;
    }
    
    //都存储
    [[NSUserDefaults standardUserDefaults] setObject:tcpPacket forKey:@"TCPPacketStr"];
    [[NSUserDefaults standardUserDefaults] setObject:pushKitTcpPacket forKey:@"PushKitTCPPacketStr"];
    
    NSDictionary *simData = @{
                              @"iccidTotalHex" : self.iccidTotalHex,
                              @"imsiTotalHex" : self.imsiTotalHex,
                              @"packetTotalLengthHex" : self.packetTotalLengthHex,
                              @"packetFinalHex" : self.packetFinalHex,
                              };
    [[NSUserDefaults standardUserDefaults] setObject:simData forKey:[[UNPushKitMessageManager shareManager].iccidString lowercaseString]];
    //创建tcp
    [BlueToothDataManager shareManager].isReseted = NO;
    [self creatAsocketTcp];
}

#pragma mark pushkit下接收需要发送数据并创建tcp
- (void)receiveTcpDataFromPushKit:(NSNotification *)noti
{
    NSString *tcpString = noti.userInfo[@"tcpString"];
    UNLogLBEProcess(@"pushkit下接收需要发送数据并创建tcp--%@",tcpString)
    if (tcpString) {
        [UNPushKitMessageManager shareManager].tcpStringWithPushKit = tcpString;
    }
    [self creatAsocketTcp];
}

#pragma mark pushkit下发送tcp数据
- (void)setUpTcppacketFromPushKit
{

    
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    NSString *token;
    if (userdata) {
        token = userdata[@"Token"];
    }
    
    NSString *ascHex = [self hexStringFromString:token];
    NSString *lengthHex = [self hexNewStringFromString:[NSString stringWithFormat:@"%zd", ascHex.length/2]];
    NSString *tokenHex = [NSString stringWithFormat:@"78%@%@", lengthHex, ascHex];
    
    UNLogLBEProcess(@"self.tlvFirstStr -- -- %@", self.tlvFirstStr)
    
    //判断是否有数据为空
    if (!self.tlvFirstStr || ![UNPushKitMessageManager shareManager].tcpStringWithPushKit) {
        return;
    }
    
    NSString *packteStr = [NSString stringWithFormat:@"%@", [UNPushKitMessageManager shareManager].tcpStringWithPushKit];
    NSString *packetLengthHex = [self hexNewStringFromString:[NSString stringWithFormat:@"%zd", packteStr.length/2]];
    NSString *newStr = [NSString stringWithFormat:@"%@%@%@",self.tlvFirstStr, packetLengthHex, packteStr];
    
    NSString *appendString = [NSString stringWithFormat:@"%@%@", newStr, tokenHex];
    
    NSString *countLengthStr = [appendString substringFromIndex:24];
    
    UNDebugLogVerbose(@"替换后面的文字之后 -- %@", appendString);
    NSString *countLengthHex = [self hexFinalTLVLength:[NSString stringWithFormat:@"%zd", countLengthStr.length/2]];
    NSString *tcpString = [appendString stringByReplacingCharactersInRange:NSMakeRange(20, 4) withString:countLengthHex];
    UNLogLBEProcess(@"发送给服务器的数据tcp -- %@", tcpString)
    [UNPushKitMessageManager shareManager].tcpPacketStrWithPushKit = tcpString;
    [UNCreatLocalNoti createLocalNotiMessageString:[NSString stringWithFormat:@"发送给服务器的数据--%@", tcpString]];
    [self sendMsgWithMessage:tcpString];
    
    if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
        UNDebugLogVerbose(@"删除前当前队列消息====%@", [UNPushKitMessageManager shareManager].pushKitMsgQueue);
        UNDebugLogVerbose(@"需要删除的队列消息====%@", [UNPushKitMessageManager shareManager].receivePushKitDataFormServices);
        
        [self checkPushKitMessage:[UNPushKitMessageManager shareManager].receivePushKitDataFormServices];
    }

//    [[NSNotificationCenter defaultCenter] postNotificationName:@"downElectic" object:@"downElectic"];//发送对卡断电通知
}


#pragma mark 转换成十六进制，换算长度
- (NSString *)hexNewStringFromString:(NSString *)string {
    if ([string intValue] < 128) {
        NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1x",[string intValue]]];
        if (hexString.length == 1) {
            NSString *hexString1 = [NSString stringWithFormat:@"0%@", hexString];
            return hexString1;
        }
        return hexString;
    } else if ([string intValue] >= 128 && [string intValue] < 256) {
        NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1x",[string intValue]]];
        NSString *hexFinalStr = [NSString stringWithFormat:@"80%@", hexString];
        return hexFinalStr;
    } else if ([string intValue] >= 256 && [string intValue] < 4096) {
        NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1x",[string intValue]]];
        NSString *hexFinalStr = [NSString stringWithFormat:@"8%@", hexString];
        return hexFinalStr;
    } else {
        NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1x",[string intValue]]];
        return hexString;
    }
}

#pragma mark tlv计算总长度专用
- (NSString *)hexTLVLength:(NSString *)string {
    if ([string intValue] < 128) {
        NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1x",[string intValue]]];
        if (hexString.length == 1) {
            NSString *hexString1 = [NSString stringWithFormat:@"0%@", hexString];
            return hexString1;
        }
        return hexString;
    } else if ([string intValue] >= 128 && [string intValue] < 256) {
        NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1x",[string intValue]]];
        NSString *hexFinalStr = [NSString stringWithFormat:@"%@", hexString];
        return hexFinalStr;
    } else if ([string intValue] >= 256 && [string intValue] < 4096) {
        NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1x",[string intValue]]];
        NSString *hexFinalStr = [NSString stringWithFormat:@"0%@", hexString];
        return hexFinalStr;
    } else {
        NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1x",[string intValue]]];
        return hexString;
    }
}

#pragma mark 计算最后发送给服务器专用
- (NSString *)hexFinalTLVLength:(NSString *)string {
    if ([string intValue] <= 15) {
        NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1x",[string intValue]]];
        if (hexString.length == 1) {
            NSString *hexString1 = [NSString stringWithFormat:@"000%@", hexString];
            return hexString1;
        }
        return hexString;
    } else if ([string intValue] >= 16 && [string intValue] < 256) {
        NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1x",[string intValue]]];
        NSString *hexFinalStr = [NSString stringWithFormat:@"00%@", hexString];
        return hexFinalStr;
    } else if ([string intValue] >= 256 && [string intValue] < 4096) {
        NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1x",[string intValue]]];
        NSString *hexFinalStr = [NSString stringWithFormat:@"0%@", hexString];
        return hexFinalStr;
    } else {
        NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1x",[string intValue]]];
        return hexString;
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

#pragma mark - 代理方法表示连接成功/失败 回调函数
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    UNLogLBEProcess(@"didConnectToHost")
    self.sendTcpSocket.userData = nil;
    if ([UNPushKitMessageManager shareManager].tcpReconnectTimer) {
        [[UNPushKitMessageManager shareManager].tcpReconnectTimer invalidate];
        [UNPushKitMessageManager shareManager].tcpReconnectTimer = nil;
    }
    
    [UNPushKitMessageManager shareManager].isTcpConnecting = NO;
//    [BlueToothDataManager shareManager].isTcpConnected = YES;
    if ([UNPushKitMessageManager shareManager].pushKitMsgType == PushKitMessageTypePingPacket) {
        if ([UNPushKitMessageManager shareManager].receivePushKitDataFormServices) {
            [BlueToothDataManager shareManager].isTcpConnected = YES;
            [sock readDataWithTimeout:-1 tag:201];
            UNLogLBEProcess(@"发送心跳包数据")
            [self sendPingPacketWithPushKitMessage:[UNPushKitMessageManager shareManager].receivePushKitDataFormServices[@"dataString"]];
        }
    }else if ([UNPushKitMessageManager shareManager].pushKitMsgType == PushKitMessageTypeSimDisconnect){
            UNLogLBEProcess(@"2tcp数据----%@", self.tcpPacketStr)
        if (!self.tcpPacketStr && [BlueToothDataManager shareManager].isConnected && [UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
            self.tcpPacketStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"PushKitTCPPacketStr"];
        }
        if (self.tcpPacketStr) {
            self.communicateID = @"00000000";
            UNDebugLogVerbose(@"tcp连接成功");
            [BlueToothDataManager shareManager].isTcpConnected = YES;
            // 等待数据来啊
            [sock readDataWithTimeout:-1 tag:200];
            UNLogLBEProcess(@"最终发送给tcp的数据 -- %@", self.tcpPacketStr)
            [UNCreatLocalNoti createLocalNotiMessageString:[NSString stringWithFormat:@"发送给服务器的数据--%@", self.tcpPacketStr]];
            //发送数据
            [self sendMsgWithMessage:self.tcpPacketStr];
            
            UNDebugLogVerbose(@"删除前当前队列消息====%@", [UNPushKitMessageManager shareManager].pushKitMsgQueue);
            UNLogLBEProcess(@"需要删除的队列消息====%@", [UNPushKitMessageManager shareManager].receivePushKitDataFormServices)
            [self checkPushKitMessage:[UNPushKitMessageManager shareManager].receivePushKitDataFormServices];
            [UNPushKitMessageManager shareManager].pushKitMsgType = PushKitMessageTypeNone;
        }
    }else if([UNPushKitMessageManager shareManager].pushKitMsgType == PushKitMessageTypeAuthSimData){
        if ([UNPushKitMessageManager shareManager].PushKitAuthDataType == 1) {
            UNLogLBEProcess(@"PushKitAuthDataType1")
            [BlueToothDataManager shareManager].isTcpConnected = YES;
            [sock readDataWithTimeout:-1 tag:201];
            [self checkPacketDetailWithStringFromPushKit:[UNPushKitMessageManager shareManager].receivePushKitDataFormServices];
        }else if([UNPushKitMessageManager shareManager].PushKitAuthDataType == 2){
            UNLogLBEProcess(@"PushKitAuthDataType2")
//            if (![UNPushKitMessageManager shareManager].isSendTcpString) {
            UNLogLBEProcess(@"pushkit--tcp数据----%@", [UNPushKitMessageManager shareManager].tcpStringWithPushKit)
                if ([UNPushKitMessageManager shareManager].tcpStringWithPushKit) {
                    self.communicateID = @"00000000";
                    UNLogLBEProcess(@"PushKit--tcp连接成功")
                    [BlueToothDataManager shareManager].isTcpConnected = YES;
                    [sock readDataWithTimeout:-1 tag:201];
                    //发送数据
                    [self setUpTcppacketFromPushKit];
                    UNLogLBEProcess(@"PushKit--最终发送给tcp的数据 -- %@", [UNPushKitMessageManager shareManager].tcpPacketStrWithPushKit)
//                    [UNPushKitMessageManager shareManager].isSendTcpString = YES;
                }
//            }
        }else{
            UNLogLBEProcess(@"PushKitAuthDataTypeNone")
//            if (![UNPushKitMessageManager shareManager].isSendTcpString) {
                UNLogLBEProcess(@"pushkit--tcp数据----%@", [UNPushKitMessageManager shareManager].tcpStringWithPushKit)
                if ([UNPushKitMessageManager shareManager].tcpStringWithPushKit) {
                    self.communicateID = @"00000000";
                    UNLogLBEProcess(@"PushKit--tcp连接成功")
                    [BlueToothDataManager shareManager].isTcpConnected = YES;
                    [sock readDataWithTimeout:-1 tag:201];
                    //发送数据
                    [self setUpTcppacketFromPushKit];
                    UNLogLBEProcess(@"PushKit--最终发送给tcp的数据 -- %@", [UNPushKitMessageManager shareManager].tcpPacketStrWithPushKit)
                    [UNPushKitMessageManager shareManager].isSendTcpString = YES;
                }
//            }
        }
    }else{
        if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
//            if (![UNPushKitMessageManager shareManager].isSendTcpString) {
                UNLogLBEProcess(@"pushkit--tcp数据----%@", [UNPushKitMessageManager shareManager].tcpStringWithPushKit)
                if ([UNPushKitMessageManager shareManager].tcpStringWithPushKit) {
                    self.communicateID = @"00000000";
                    UNLogLBEProcess(@"PushKit--tcp连接成功")
                    [BlueToothDataManager shareManager].isTcpConnected = YES;
                    [sock readDataWithTimeout:-1 tag:201];
                    //发送数据
                    [self setUpTcppacketFromPushKit];
                    UNLogLBEProcess(@"PushKit--最终发送给tcp的数据 -- %@", [UNPushKitMessageManager shareManager].tcpPacketStrWithPushKit)
                    [UNPushKitMessageManager shareManager].isSendTcpString = YES;
                }
//            }
        }else{
            [BlueToothDataManager shareManager].isTcpConnected = YES;
            self.isNeedToCheckSIMStatue = YES;
            [self sendDataToCheckRegistStatue];
            if (![BlueToothDataManager shareManager].isReseted) {
                UNLogLBEProcess(@"1tcp数据----%@", self.tcpPacketStr)
                if (self.tcpPacketStr) {
                    self.communicateID = @"00000000";
                    UNLogLBEProcess(@"tcp连接成功")
                    // 等待数据来啊
                    [sock readDataWithTimeout:-1 tag:200];
                    UNLogLBEProcess(@"最终发送给tcp的数据 -- %@", self.tcpPacketStr)
                    //发送数据
                    [self sendMsgWithMessage:self.tcpPacketStr];
                }
            }
        }
    }
}


// 如果对象关闭了 这里也会调用
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    [UNPushKitMessageManager shareManager].isTcpConnecting = NO;
    self.communicateID = @"00000000";
    UNLogLBEProcess(@"tcp连接失败 %@", err)
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] isEqualToString:@"off"]) {
        UNLogLBEProcess(@"关闭开关，断开tcp")
        [BlueToothDataManager shareManager].isTcpConnected = NO;
        [BlueToothDataManager shareManager].isRegisted = NO;
        return;
    }
    if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
        if (![BlueToothDataManager shareManager].isHaveCard) {
            //不是电话卡，断开tcp连接
            UNLogLBEProcess(@"没有电话卡，断开tcp")
            [BlueToothDataManager shareManager].isTcpConnected = NO;
            [BlueToothDataManager shareManager].isRegisted = NO;
            return;
        }
    } else {
        if ([[BlueToothDataManager shareManager].operatorType isEqualToString:@"4"] || [[BlueToothDataManager shareManager].operatorType isEqualToString:@"5"] || ![BlueToothDataManager shareManager].isHaveCard) {
            //不是电话卡，断开tcp连接
            UNLogLBEProcess(@"不是电话卡，断开tcp,运营商类型====%@",[BlueToothDataManager shareManager].operatorType);
            [BlueToothDataManager shareManager].isTcpConnected = NO;
            [BlueToothDataManager shareManager].isRegisted = NO;
            return;
        }
    }
    
    [BlueToothDataManager shareManager].isTcpConnected = NO;
    
    if ([UNNetWorkStatuManager shareManager].currentStatu == NotReachable) {
//        self.sendTcpSocket.userData = SocketCloseByNet;
        [self closeTCP];
        UNLogLBEProcess(@"无网络")
    }else{
        if (err) {
            UNLogLBEProcess(@"连接失败")
            
            [self closeTCP];
            if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
                if ([UNPushKitMessageManager shareManager].tcpReconnectTimer) {
                    [[UNPushKitMessageManager shareManager].tcpReconnectTimer invalidate];
                    [UNPushKitMessageManager shareManager].tcpReconnectTimer = nil;
                }
                return;
            }
            if (![[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] isEqualToString:@"on"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (![UNPushKitMessageManager shareManager].tcpReconnectTimer) {
                        [UNPushKitMessageManager shareManager].tcpSocketTimerIndex = 0;
                        [UNPushKitMessageManager shareManager].tcpReconnectTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tcpReconnectTimerAction) userInfo:nil repeats:YES];
                        [[UNPushKitMessageManager shareManager].tcpReconnectTimer fire];
                    }
                });
            } else {
                DebugUNLog(@"服务未开");
//                [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NOTSERVICE;
                [self changeBleStatue];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"changeStatueAll" object:HOMESTATUETITLE_NOTSERVICE];
            }
        }else{
            UNLogLBEProcess(@"正常断开")
            if (![[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] isEqualToString:@"on"]) {
                [BlueToothDataManager shareManager].isTcpConnected = NO;
                if ([UNPushKitMessageManager shareManager].tcpReconnectTimer) {
                    [[UNPushKitMessageManager shareManager].tcpReconnectTimer invalidate];
                    [UNPushKitMessageManager shareManager].tcpReconnectTimer = nil;
                }
            } else {
                DebugUNLog(@"服务未开");
//                [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NOTSERVICE;
                [self changeBleStatue];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"changeStatueAll" object:HOMESTATUETITLE_NOTSERVICE];
            }
        }
    }
}

//TCP重连定时器
- (void)tcpReconnectTimerAction
{
    UNLogLBEProcess(@"重连tcp定时器")
    [UNPushKitMessageManager shareManager].tcpSocketTimerIndex++;
    if ([UNPushKitMessageManager shareManager].tcpSocketTimerIndex >= 5) {
        [UNPushKitMessageManager shareManager].tcpSocketTimerIndex = 0;
        if (!self.sendTcpSocket.isConnected || !self.sendTcpSocket) {
            UNLogLBEProcess(@"重连TCP")
            [UNPushKitMessageManager shareManager].isTcpConnecting = NO;
            [BlueToothDataManager shareManager].isTcpConnected = NO;
            if (![UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
                UNLogLBEProcess(@"不在PushKit下")
                if (self.sendTcpSocket) {
                    [self reConnectTcp];
                }else{
                    [self creatAsocketTcp];
                }
            }
        }else{
            if ([UNPushKitMessageManager shareManager].tcpReconnectTimer) {
                [[UNPushKitMessageManager shareManager].tcpReconnectTimer invalidate];
                [UNPushKitMessageManager shareManager].tcpReconnectTimer = nil;
            }
        }
    }
}
#pragma mark - 消息发送成功 代理函数
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    UNLogLBEProcess(@"didWriteDataWithTag--tcp消息发送成功")
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (![UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
        UNLogLBEProcess(@"非PushKit状态")
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![BlueToothDataManager shareManager].isRegisted) {
                self.lessStep++;
                int stepStr = self.lessStep*10;
                UNLogLBEProcess(@"计算计算百分比 %d", stepStr)
                if (![BlueToothDataManager shareManager].isFirstRegist) {
                    //本地存储了的，不重新注册
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeStatue" object:[NSString stringWithFormat:@"%d", stepStr]];
                    [BlueToothDataManager shareManager].stepNumber = [NSString stringWithFormat:@"%d", stepStr];
                }else{
                    //第一次注册这张卡
                    UNLogLBEProcess(@"第一次注册这张卡，不发送通知")
                }
            }
        });
        [sock readDataWithTimeout:-1 tag:tag];
        NSString *ip = [sock connectedHost];
        uint16_t port = [sock connectedPort];
        //    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        UNLogLBEProcess(@"%ld接收到服务器返回的数据 tcp [%@:%d] %@",tag, ip, port, data)
        NSString *tempStr = [NSString stringWithFormat:@"%@", data];
        if ([tempStr containsString:@"<"]) {
            tempStr = [tempStr stringByReplacingOccurrencesOfString:@"<" withString:@""];
        }
        if ([tempStr containsString:@">"]) {
            tempStr = [tempStr stringByReplacingOccurrencesOfString:@">" withString:@""];
        }
        if ([tempStr containsString:@" "]) {
            tempStr = [tempStr stringByReplacingOccurrencesOfString:@" " withString:@""];
        }
        
        [self checkManyPacketString:tempStr];
    }else{
        UNLogLBEProcess(@"PushKit状态不回数据")
        UNDebugLogVerbose(@"PushKit状态接收到服务器返回的数据%@", data);
        
        //正常情况不走此处,(PushKit状态走此处说明后台出错)
        if (tag == 200) {
            [sock readDataWithTimeout:-1 tag:200];
            
            NSString *ip = [sock connectedHost];
            uint16_t port = [sock connectedPort];
            //    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            UNDebugLogVerbose(@"200接收到服务器返回的数据 tcp [%@:%d] %@", ip, port, data);
            NSString *tempStr = [NSString stringWithFormat:@"%@", data];
            if ([tempStr containsString:@"<"]) {
                tempStr = [tempStr stringByReplacingOccurrencesOfString:@"<" withString:@""];
            }
            if ([tempStr containsString:@">"]) {
                tempStr = [tempStr stringByReplacingOccurrencesOfString:@">" withString:@""];
            }
            if ([tempStr containsString:@" "]) {
                tempStr = [tempStr stringByReplacingOccurrencesOfString:@" " withString:@""];
            }
            
            [self checkManyPacketString:tempStr];
        }else if(tag == 100){
            [sock readDataWithTimeout:-1 tag:100];
            NSString *ip = [sock connectedHost];
            uint16_t port = [sock connectedPort];
            //    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            UNDebugLogVerbose(@"100接收到服务器返回的数据 tcp [%@:%d] %@", ip, port, data);
            NSString *tempStr = [NSString stringWithFormat:@"%@", data];
            if ([tempStr containsString:@"<"]) {
                tempStr = [tempStr stringByReplacingOccurrencesOfString:@"<" withString:@""];
            }
            if ([tempStr containsString:@">"]) {
                tempStr = [tempStr stringByReplacingOccurrencesOfString:@">" withString:@""];
            }
            if ([tempStr containsString:@" "]) {
                tempStr = [tempStr stringByReplacingOccurrencesOfString:@" " withString:@""];
            }
            
            [self checkManyPacketString:tempStr];
        }else if(tag == 201){
            [sock readDataWithTimeout:-1 tag:201];
            NSString *ip = [sock connectedHost];
            uint16_t port = [sock connectedPort];
            //    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            UNDebugLogVerbose(@"201接收到服务器返回的数据 tcp [%@:%d] %@", ip, port, data);
            NSString *tempStr = [NSString stringWithFormat:@"%@", data];
            if ([tempStr containsString:@"<"]) {
                tempStr = [tempStr stringByReplacingOccurrencesOfString:@"<" withString:@""];
            }
            if ([tempStr containsString:@">"]) {
                tempStr = [tempStr stringByReplacingOccurrencesOfString:@">" withString:@""];
            }
            if ([tempStr containsString:@" "]) {
                tempStr = [tempStr stringByReplacingOccurrencesOfString:@" " withString:@""];
            }
            [self checkManyPacketString:tempStr];
        }else{
            [sock readDataWithTimeout:-1 tag:tag];
            NSString *ip = [sock connectedHost];
            uint16_t port = [sock connectedPort];
            //    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            UNDebugLogVerbose(@"%ld接收到服务器返回的数据 tcp [%@:%d] %@",tag, ip, port, data);
            NSString *tempStr = [NSString stringWithFormat:@"%@", data];
            if ([tempStr containsString:@"<"]) {
                tempStr = [tempStr stringByReplacingOccurrencesOfString:@"<" withString:@""];
            }
            if ([tempStr containsString:@">"]) {
                tempStr = [tempStr stringByReplacingOccurrencesOfString:@">" withString:@""];
            }
            if ([tempStr containsString:@" "]) {
                tempStr = [tempStr stringByReplacingOccurrencesOfString:@" " withString:@""];
            }
            [self checkManyPacketString:tempStr];
        }
    }
}

//处理粘包
- (void)checkManyPacketString:(NSString *)tempStr
{
    UNLogLBEProcess(@"处理数据包")
    if (tempStr.length < 24) {
        UNDebugLogVerbose(@"数据包异常----%@", tempStr);
        return;
    }
    NSString *lengthStr = [tempStr substringWithRange:NSMakeRange(20, 4)];
    NSInteger leng = strtoul([lengthStr UTF8String], 0, 16);
    if (tempStr.length>= 24 + leng * 2) {
        NSString *currentStr = [tempStr substringWithRange:NSMakeRange(0, 24 + leng*2)];
        UNLogLBEProcess(@"当前数据包---%@", currentStr)
        dispatch_async(dispatch_get_main_queue(), ^{
            UNDebugLogVerbose(@"checkPacketDetailWithString-----%@",[NSThread currentThread]);
            [self checkPacketDetailWithString:currentStr];
        });
        
        if (tempStr.length > 24 + leng * 2) {
            UNLogLBEProcess(@"粘包处理")
            [self checkManyPacketString:[tempStr substringFromIndex:(24 + leng * 2)]];
        }else{
            return;
        }
    }
}

#pragma mark 处理数据包
- (void)checkPacketDetailWithString:(NSString *)string {
    NSString *classStr = [string substringWithRange:NSMakeRange(4, 2)];
    NSString *errorStr = [string substringWithRange:NSMakeRange(6, 2)];
    if (![errorStr isEqualToString:@"00"] && ![classStr isEqualToString:@"89"]) {
        UNLogLBEProcess(@"电话端口错误")
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [BlueToothDataManager shareManager].isBeingRegisting = NO;
            [BlueToothDataManager shareManager].isRegisted = NO;
            [BlueToothDataManager shareManager].isRegistedFail = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cardNumberNotTrue" object:HOMESTATUETITLE_NOSIGNAL];
            if ([errorStr isEqualToString:@"15"]) {
                //用户不存在或token已过期
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            } else if ([errorStr isEqualToString:@"29"]) {
                //会话id错误
                if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                    [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"卡注册失败") message:INTERNATIONALSTRING(@"身份验证失败，请重新注册") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
                }
            } else if ([errorStr isEqualToString:@"35"]) {
                //服务端暂时不可用
                if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                    [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"卡注册失败") message:INTERNATIONALSTRING(@"服务端暂时开小差啦，请重新注册") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
                }
            } else {
                if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                    [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"卡注册失败") message:INTERNATIONALSTRING(@"您的电话卡可能出问题了，请核查号码是否能正常使用") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
                }
            }
        });
        return;
    }
    if (![self.communicateID isEqualToString:@"00000000"] && ![self.communicateID isEqualToString:[string substringWithRange:NSMakeRange(8, 8)]] && ![classStr isEqualToString:@"89"]) {
        UNLogLBEProcess(@"忽略的包 -- %@", string)
        return;
    }
    if ([classStr isEqualToString:@"84"]) {
        
        UNLogLBEProcess(@"建立连接")
        self.communicateID = [string substringWithRange:NSMakeRange(8, 8)];
        [BlueToothDataManager shareManager].commicateIDFromTcp = [string substringWithRange:NSMakeRange(8, 8)];
        UNLogLBEProcess(@"会话id -- %@", self.communicateID)
        
        //获取电话端口号
        if ([string length] <= 44) {
            UNLogLBEProcess(@"获取电话端口出问题了")
            return;
        }
        NSString *callPortStr = [string substringFromIndex:44];
        NSString *newString = [NSString stringFromHexString:callPortStr];
        UNDebugLogVerbose(@"截取到的电话端口 -- %@", newString);
        if ([newString isEqualToString:@"n Failed"]) {
            UNLogLBEProcess(@"截取电话端口出错 -- %@", newString)
            return;
        }else if ([newString isEqualToString:@"Timeout"]) {
            UNLogLBEProcess(@"截取电话端口出错 -- %@", newString)
            return;
        }
        NSString *cutStr = [newString substringFromIndex:[newString rangeOfString:@"_"].location+1];
        cutStr = [cutStr stringByReplacingOccurrencesOfString:@"." withString:@""];
        UNLogLBEProcess(@"最终的电话端口 -- %@", cutStr)
        [VSWManager shareManager].callPort = cutStr;
        [BlueToothDataManager shareManager].portFromTcp = cutStr;
        [[NSUserDefaults standardUserDefaults] setObject:cutStr forKey:@"VSWCallPort"];
        
        //开启定时器
        [self startJumpDataTimer];
    }else if ([classStr isEqualToString:@"05"]) {
        UNLogLBEProcess(@"sim卡注册成功")
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [BlueToothDataManager shareManager].isBeingRegisting = NO;
            [BlueToothDataManager shareManager].stepNumber = @"0";
            self.lessStep = 0;
            [BlueToothDataManager shareManager].isRegisted = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:HOMESTATUETITLE_SIGNALSTRONG];
            if ([UNPushKitMessageManager shareManager].isSysCallKitPhone && [UNPushKitMessageManager shareManager].callKitHandleString) {
                UNDebugLogVerbose(@"拨打CallKit电话");
                [self callPhoneFromCallKitWithHandleString:[[UNPushKitMessageManager shareManager].callKitHandleString copy]];
            }
        });
        if (![_udpSocket isClosed]) {
            [_udpSocket close];
        }
        [UNPushKitMessageManager shareManager].isNeedRegister = NO;
    }else if ([classStr isEqualToString:@"0f"]) {
        UNLogLBEProcess(@"sim卡断开连接")
        [BlueToothDataManager shareManager].isBeingRegisting = NO;
        [BlueToothDataManager shareManager].stepNumber = @"0";
        self.lessStep = 0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [BlueToothDataManager shareManager].isRegisted = NO;
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:HOMESTATUETITLE_NOSIGNAL];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.communicateID = @"00000000";
                if ([BlueToothDataManager shareManager].isConnected) {
                    [BlueToothDataManager shareManager].isRegistedFail = NO;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:HOMESTATUETITLE_REGISTING];
                    [BlueToothDataManager shareManager].isBeingRegisting = YES;
                    
                    //tcp断开重连
                    if (!self.sendTcpSocket.isConnected || !self.sendTcpSocket) {
                        UNLogLBEProcess(@"重连TCP")
                        [UNPushKitMessageManager shareManager].isTcpConnecting = NO;
                        [BlueToothDataManager shareManager].isTcpConnected = NO;
                        if (![UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
                            UNLogLBEProcess(@"不在PushKit下")
                            if (self.sendTcpSocket) {
                                [self reConnectTcp];
                            }else{
                                [self creatAsocketTcp];
                            }
                        }
                    }else{
                        //发送数据
                        [self sendMsgWithMessage:self.tcpPacketStr];
                    }
                }else{
                    [BlueToothDataManager shareManager].isRegistedFail = YES;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:HOMESTATUETITLE_NOSIGNAL];
                }
            });
        });
    }else if ([classStr isEqualToString:@"10"]) {
        UNLogLBEProcess(@"透明传输SIM交互命令")
        NSInteger leng;
        NSString *TLVdetail;
        NSString *tempStr;
        string = [string stringByReplacingCharactersInRange:NSMakeRange(4, 2) withString:@"90"];
        self.tlvFirstStr = [string substringWithRange:NSMakeRange(0, 32)];
        UNLogLBEProcess(@"截取前面的数据 -- %@", self.tlvFirstStr)
        if ([[string substringWithRange:NSMakeRange(28, 2)] isEqualToString:@"01"]) {
            UNLogLBEProcess(@"这是01的执行方法")
            //01
            //不使用sdk
            if ([UNPushKitMessageManager shareManager].isNeedRegister) {
                [[VSWManager shareManager] reconnectAction];
            }
//            [[VSWManager shareManager] reconnectAction];
            if ([[string substringWithRange:NSMakeRange(32, 1)] isEqualToString:@"1"]) {
                //l长度为两位
                NSString *lengthStr = [string substringWithRange:NSMakeRange(32, 2)];
                leng = strtoul([lengthStr UTF8String], 0, 16);
                TLVdetail = [string substringWithRange:NSMakeRange(34, leng * 2)];
                UNDebugLogVerbose(@"两位leng = %zd  需要替换的字符串 -- %@", leng, TLVdetail);
            } else {
                NSString *lengthStr = [string substringWithRange:NSMakeRange(32, 4)];
                if ([[lengthStr substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"8"]) {
                    lengthStr = [lengthStr substringFromIndex:1];
                    if ([[lengthStr substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"0"]) {
                        lengthStr = [lengthStr substringFromIndex:1];
                    }
                }
                leng = strtoul([lengthStr UTF8String], 0, 16);
                TLVdetail = [string substringWithRange:NSMakeRange(36, leng * 2)];
                UNDebugLogVerbose(@"四位leng = %zd  需要替换的字符串 -- %@", leng, TLVdetail);
            }
            tempStr = TLVdetail;
            TLVdetail = @"000100163b9f94801fc78031e073fe211b573786609b30800119";
            for (int i = [[NSString stringWithFormat:@"%zd", TLVdetail.length] intValue]; i < leng * 2; i++) {
                TLVdetail = [TLVdetail stringByAppendingString:@"0"];
            }
            string = [string stringByReplacingOccurrencesOfString:tempStr withString:TLVdetail];
            UNLogLBEProcess(@"替换之后的字符串 -- %@", string)
            [self sendMsgWithMessage:string];

        } else if ([[string substringWithRange:NSMakeRange(28, 2)] isEqualToString:@"00"]) {
            //00
            UNLogLBEProcess(@"这是00的执行方法")
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"updataElectic" object:@"updataElectic"];//发送对卡上电通知
            NSString *lengthStr = [string substringWithRange:NSMakeRange(32, 2)];
            leng = strtoul([lengthStr UTF8String], 0, 16);
            TLVdetail = [string substringWithRange:NSMakeRange(34, leng * 2)];
            UNDebugLogVerbose(@"两位leng = %zd  需要传入的字符串 -- %@", leng, TLVdetail);
            
            if ([UNPushKitMessageManager shareManager].isNeedRegister) {
                UNLogLBEProcess(@"需要注册")
                [[NSNotificationCenter defaultCenter] postNotificationName:@"updataElectic" object:@"updataElectic"];//发送对卡上电通知
                //发送给sdk
                [[VSWManager shareManager] sendMessageToDev:[NSString stringWithFormat:@"%zd", leng] pdata:TLVdetail];
            }else{
                UNLogLBEProcess(@"发送鉴权数据-----%@",[NSThread currentThread])
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"AnalysisAuthData" object:TLVdetail];
                });
            }

            //发送给sdk
//            [[VSWManager shareManager] sendMessageToDev:[NSString stringWithFormat:@"%zd", leng] pdata:TLVdetail];
        }
    }else if ([classStr isEqualToString:@"89"]) {
        if (![BlueToothDataManager shareManager].isDoneRegist) {
            UNLogLBEProcess(@"接收到卡的注册状态数据 -- %@", string)
            if ([errorStr isEqualToString:@"00"]) {
                NSString *communicateIdStr = [string substringWithRange:NSMakeRange(8, 8)];
                if ([string containsString:@"00be"] && [string containsString:@"00bf"] && [string containsString:@"00a0"]) {
                    NSRange iccidRange = [string rangeOfString:@"00be"];
                    NSRange imsiRange = [string rangeOfString:@"00bf"];
                    NSRange goipnsRange = [string rangeOfString:@"00a0"];
                    //                UNDebugLogVerbose(@"iccidRange - %lu,%lu", iccidRange.location+4, imsiRange.location - (iccidRange.location+4));
                    //                UNDebugLogVerbose(@"imsiRange - %lu,%lu", imsiRange.location+4, goipnsRange.location - (imsiRange.location+4));
                    //                UNDebugLogVerbose(@"goipnsRange - %lu,%lu", goipnsRange.location+4, string.length-(goipnsRange.location+4));
                    NSString *iccidStr = [string substringWithRange:NSMakeRange(iccidRange.location+4, imsiRange.location - (iccidRange.location+4))];
                    NSString *newIccidString = [NSString stringFromHexString:iccidStr];
                    NSString *imsiStr = [string substringWithRange:NSMakeRange(imsiRange.location+4, goipnsRange.location - (imsiRange.location+4))];
                    NSString *newImsiString = [NSString stringFromHexString:imsiStr];
                    //去除数据中的特殊字符
                    newIccidString = [newIccidString stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
                    NSString *goipnsStr = [string substringWithRange:NSMakeRange(goipnsRange.location+4, string.length-(goipnsRange.location+4))];
                    NSString *newGoipnsString = [NSString stringFromHexString:goipnsStr];
                    
                    if ([newGoipnsString isEqualToString:@"n Failed"]) {
                        UNDebugLogVerbose(@"截取电话端口出错 -- %@", newGoipnsString);
                        return;
                    }else if ([newGoipnsString isEqualToString:@"Timeout"]) {
                        UNDebugLogVerbose(@"截取电话端口出错 -- %@", newGoipnsString);
                        return;
                    }
                    NSString *cutStr = [newGoipnsString substringFromIndex:[newGoipnsString rangeOfString:@"_"].location+1];
                    cutStr = [cutStr stringByReplacingOccurrencesOfString:@"." withString:@""];
                    UNDebugLogVerbose(@"转换出来的会话ID -- %@\n转换出来的ICCID -- %@\n转换出来的IMSI -- %@\n转换出来的goipns -- %@ -- 电话端口号：%@", communicateIdStr, newIccidString, newImsiString, newGoipnsString, cutStr);
                    [BlueToothDataManager shareManager].iccidFromTcp = newIccidString.lowercaseString;
                    [BlueToothDataManager shareManager].commicateIDFromTcp = communicateIdStr.lowercaseString;
                    [BlueToothDataManager shareManager].portFromTcp = cutStr;
                    if ([BlueToothDataManager shareManager].iccidFromBle) {
                        if ([[BlueToothDataManager shareManager].iccidFromTcp isEqualToString:[BlueToothDataManager shareManager].iccidFromBle]) {
                            //在线
                            UNDebugLogVerbose(@"同一张卡在线%s,%d", __FUNCTION__, __LINE__);
                        } else {
                            //不是同一张卡，需要重新注册
                            UNDebugLogVerbose(@"不是同一张卡在线，需要重新注册 - tcpiccid:%@ bleiccid:%@,%s,%d", [BlueToothDataManager shareManager].iccidFromTcp, [BlueToothDataManager shareManager].iccidFromBle, __FUNCTION__, __LINE__);
                        }
                    }
                } else {
                    UNLogLBEProcess(@"接收到的数据有问题")
                }
            } else {
                if ([errorStr isEqualToString:@"15"]) {
                    //用户不存在或token已过期
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
                } else if ([errorStr isEqualToString:@"16"]) {
                    //需要重新注册
                    [BlueToothDataManager shareManager].isNeedToRegistAgain = YES;
                    self.communicateID = @"00000000";
                    [BlueToothDataManager shareManager].iccidFromTcp = nil;
                    UNLogLBEProcess(@"需要重新注册")
                } else if ([errorStr isEqualToString:@"29"]) {
                    //会话id错误
                    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                        [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"卡注册失败") message:INTERNATIONALSTRING(@"身份验证失败，请重新注册") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
                    }
                } else if ([errorStr isEqualToString:@"35"]) {
                    //服务端暂时不可用
                    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                        [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"卡注册失败") message:INTERNATIONALSTRING(@"服务端暂时开小差啦，请重新注册") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
                    }
                } else {
                    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                        [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"卡注册失败") message:INTERNATIONALSTRING(@"您的电话卡可能出问题了，请核查号码是否能正常使用") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
                    }
                }
            }
        } else {
            UNLogLBEProcess(@"已经走过正常注册流程 %s,%d", __FUNCTION__, __LINE__)
        }
    } else if ([classStr isEqualToString:@"8d"]) {
        UNLogLBEProcess(@"关闭tcp成功")
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"isAlreadyCanRegist" object:@"isAlreadyCanRegist"];
        });
//        [BlueToothDataManager shareManager].isTcpConnected = NO;
        [BlueToothDataManager shareManager].isRegisted = NO;
        [BlueToothDataManager shareManager].iccidFromTcp = nil;
        [self closeTCP];
    } else {
        UNDebugLogVerbose(@"这是什么鬼");
    }
}

- (void)startJumpDataTimer {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.timer) {
            //开始计时
            UNDebugLogVerbose(@"开始计时 %s,%d", __FUNCTION__, __LINE__);
            self.sec = 0;
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(jumpTimerAction) userInfo:nil repeats:YES];
            //如果不添加下面这条语句，会阻塞定时器的调用
            [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:UITrackingRunLoopMode];
        } else {
            UNDebugLogVerbose(@"继续计时 %s,%d", __FUNCTION__, __LINE__);
            self.sec = 0;
            [self.timer setFireDate:[NSDate distantPast]];
        }
    });
}

//处理PushKit数据
- (void)checkPacketDetailWithStringFromPushKit:(NSDictionary *)dictString
{
    UNLogLBEProcess(@"PushKit数据包消息-----%@",dictString)
    NSString *string = dictString[@"dataString"];
    NSInteger leng;
    NSString *TLVdetail;
    NSString *tempStr;
    string = [string stringByReplacingCharactersInRange:NSMakeRange(4, 2) withString:@"90"];
    //01
    if ([[string substringWithRange:NSMakeRange(32, 1)] isEqualToString:@"1"]) {
        //l长度为两位
        NSString *lengthStr = [string substringWithRange:NSMakeRange(32, 2)];
        leng = strtoul([lengthStr UTF8String], 0, 16);
        TLVdetail = [string substringWithRange:NSMakeRange(34, leng * 2)];
        UNDebugLogVerbose(@"两位leng = %zd  需要替换的字符串 -- %@", leng, TLVdetail);
    } else {
        NSString *lengthStr = [string substringWithRange:NSMakeRange(32, 4)];
        if ([[lengthStr substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"8"]) {
            lengthStr = [lengthStr substringFromIndex:1];
            if ([[lengthStr substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"0"]) {
                lengthStr = [lengthStr substringFromIndex:1];
            }
        }
        leng = strtoul([lengthStr UTF8String], 0, 16);
        TLVdetail = [string substringWithRange:NSMakeRange(36, leng * 2)];
        UNDebugLogVerbose(@"四位leng = %zd  需要替换的字符串 -- %@", leng, TLVdetail);
    }
    tempStr = TLVdetail;
    TLVdetail = @"000100163b9f94801fc78031e073fe211b573786609b30800119";
    for (int i = [[NSString stringWithFormat:@"%zd", TLVdetail.length] intValue]; i < leng * 2; i++) {
        TLVdetail = [TLVdetail stringByAppendingString:@"0"];
    }
    string = [string stringByReplacingOccurrencesOfString:tempStr withString:TLVdetail];
    UNDebugLogVerbose(@"替换之后的字符串 -- %@", string);
    
    [UNCreatLocalNoti createLocalNotiMessageString:[NSString stringWithFormat:@"发送给服务器的数据--%@", string]];
    [self sendMsgWithMessage:string];
    if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
        UNLogLBEProcess(@"删除前当前队列消息====%@", [UNPushKitMessageManager shareManager].pushKitMsgQueue)
        UNLogLBEProcess(@"需要删除的队列消息====%@", [UNPushKitMessageManager shareManager].receivePushKitDataFormServices)
        [self checkPushKitMessage:[UNPushKitMessageManager shareManager].receivePushKitDataFormServices];
    }
}

- (void)jumpTimerAction {
//    if (self.sec == 300) {
    if (self.sec == 300) {
        self.sec = 0;
        if (![self.communicateID isEqualToString:@"00000000"]) {
            NSString *num = [NSString stringWithFormat:@"%d", self.currentNumber];
            NSString *str = [self hexFinalTLVLength:num];
            //108a 0500 20fd ef90 0008 0006 0101006501b4
            //发送心跳包
            NSString *sendStr = [NSString stringWithFormat:@"108a0500%@%@00060101006501b4", self.communicateID, str];
            if ([BlueToothDataManager shareManager].isTcpConnected) {
                UNDebugLogVerbose(@"发送心跳包 -- %@", sendStr);
                [self sendMsgWithMessage:sendStr];
                self.currentNumber++;
            } else {
                UNDebugLogVerbose(@"tcp断了，不发送心跳包,%s,%d", __FUNCTION__, __LINE__);
            }
        } else {
            UNDebugLogVerbose(@"会话id为0，不发送心跳包,%s,%d", __FUNCTION__, __LINE__);
        }
    }
    self.sec++;
//    UNDebugLogVerbose(@"心跳包的sec == %d", self.sec);
}

- (void)receiveNewDataStr:(NSNotification *)sender {
    UNLogLBEProcess(@"self.tlvFirstStr -- -- %@", self.tlvFirstStr)
    NSString *packteStr = [NSString stringWithFormat:@"%@", sender.object];
    NSString *packetLengthHex = [self hexNewStringFromString:[NSString stringWithFormat:@"%zd", packteStr.length/2]];
    NSString *newStr = [NSString stringWithFormat:@"%@%@%@",self.tlvFirstStr, packetLengthHex, packteStr];
    NSString *countLengthStr = [newStr substringFromIndex:24];
    UNDebugLogVerbose(@"替换后面的文字之后 -- %@", newStr);
//    UNDebugLogVerbose(@"jiequzhihoudes  -- %@", countLengthStr);
    NSString *countLengthHex = [self hexFinalTLVLength:[NSString stringWithFormat:@"%zd", countLengthStr.length/2]];
//    NSString *finalString = [newStr stringByReplacingOccurrencesOfString:[newStr substringWithRange:NSMakeRange(20, 4)] withString:countLengthHex];
    NSString *finalString = [newStr stringByReplacingCharactersInRange:NSMakeRange(20, 4) withString:countLengthHex];
    UNLogLBEProcess(@"发送给服务器的数据1611 -- %@", finalString)
    [self sendMsgWithMessage:finalString];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"downElectic" object:@"downElectic"];//发送对卡断电通知
}

//发送TCP数据
- (void)sendMsgWithMessage:(NSString *)message {
    if (message) {
        // 写这里代码
        NSString *s = message;
        NSData *data = [self convertHexStrToData:s];
        UNLogLBEProcess(@"sendMsgWithMessage发送给服务端的数据 -- %@", data)
        // 发送消息 这里不需要知道对象的ip地址和端口
        [self.sendTcpSocket writeData:data withTimeout:60 tag:100];
    }
}

#pragma mark 将nsstring转换成十六进制不改变内容
- (NSData *)convertHexStrToData:(NSString *)str {
    if (!str || [str length] == 0) {
        return nil;
    }
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:8];
    NSRange range;
    if ([str length] % 2 == 0) {
        range = NSMakeRange(0, 2);
    } else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < [str length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [str substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        range.location += range.length;
        range.length = 2;
    }
    return hexData;
}

#pragma mark udp协议
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    self.prot = [GCDAsyncUdpSocket portFromAddress:address];
    UNLogLBEProcess(@"接收到%@的消息:%@",address,data)//自行转换格式吧
    NSString *receivedMessage = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//    UNDebugLogVerbose(@"获取的端口号 -> %d", self.prot);
    self.currentPacketNumber = [receivedMessage substringWithRange:NSMakeRange(0, 6)];
    NSString *str = [self.currentPacketNumber substringWithRange:NSMakeRange(3, 3)];
    [BlueToothDataManager shareManager].isBeingRegisting = YES;
    //发送当前编号
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeStatue" object:str];
    [BlueToothDataManager shareManager].stepNumber = str;
    if (![BlueToothDataManager shareManager].isRegisted) {
        [BlueToothDataManager shareManager].isRegistedFail = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:HOMESTATUETITLE_REGISTING];
    }
    UNDebugLogVerbose(@"转换之后的内容：%@", receivedMessage);
    if ([receivedMessage isEqualToString:@"200001:0x0000"]) {
        if (![UNPushKitMessageManager shareManager].isUdpSendFristMsg) {
            DebugUNLog(@"注册百分之一");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"upLoadToCard" object:@"upLoadToCard"];
            [UNPushKitMessageManager shareManager].isUdpSendFristMsg = YES;
        }
        if ([BlueToothDataManager shareManager].isNeedToResert) {
            [BlueToothDataManager shareManager].isRegistedFail = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:HOMESTATUETITLE_REGISTING];
        }
    } else {
        DebugUNLog(@"注册百分之一");
        [UNPushKitMessageManager shareManager].isUdpSendFristMsg = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"receiveNewMessageFromBLE" object:[receivedMessage substringFromIndex:7]];
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    UNDebugLogVerbose(@"发送信息成功");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    UNDebugLogVerbose(@"发送信息失败");
}

- (void)sendNewMessage:(NSNotification *)sender {
    NSString *dataStr = [NSString stringWithFormat:@"%@:%@",self.currentPacketNumber, sender.object];
    UNDebugLogVerbose(@"最终发送的数据 -> %@", dataStr);
    NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    UNLogLBEProcess(@"最终发送的数据包 : %@", data);
    
    //开始发送
    //改函数只是启动一次发送 它本身不进行数据的发送, 而是让后台的线程慢慢的发送 也就是说这个函数调用完成后,数据并没有立刻发送,异步发送
    [_udpSocket sendData:data toHost:SERVERIP port:self.prot withTimeout:-1 tag:0];
}

-(void)log
{
//    UNDebugLogVerbose(@"执行");
}
-(void)startBgTask
{
    [_task beginNewBackgroundTask];
    
}

void addressBookChanged(ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"addressBookChanged" object:@"addressBookChanged"];
}

#pragma mark 提前验证
- (void)checkLogin {
    
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    if (userdata) {
//        strGetLogin = [NSString stringWithFormat:@"%@&TOKEN=%@",strGetLogin,[userdata objectForKey:@"Token"]];
        //
    }else{
        [self loadLoginViewController];
    }
    self.checkToken = YES;
    [self getBasicHeader];
    //    HUDNoStop1(@"正在登录...")
    [SSNetworkRequest getRequest:apiGetLogin params:nil success:^(id resonseObj){
        
        if (resonseObj) {
            if ([[resonseObj objectForKey:@"status"] intValue]==1) {
                [UNDataTools sharedInstance].isLogout = NO;
                //                NSString *alias = [NSString stringWithFormat:@"aixiaoqi%@", userdata[@"Tel"]];
                //更新别名为token
                NSString *alias = [NSString stringWithFormat:@"aixiaoqi%@", userdata[@"Token"]];
                [JPUSHService setTags:nil alias:alias fetchCompletionHandle:^(int iResCode, NSSet *iTags, NSString *iAlias) {
                    UNDebugLogVerbose(@"极光别名：irescode = %d\n itags = %@\n ialias = %@", iResCode, iTags, iAlias);
                }];
                //                    UNDebugLogVerbose(@"拿到数据：%@",resonseObj);
                [self loginSuccessAndCreatTCP];
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                if (storyboard) {
                    UIViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
                    if (mainViewController) {
                        self.window.rootViewController = mainViewController;
                    }
                }
            }else{
                [self loadLoginViewController];
            }
        }else{
            [self loadLoginViewController];
        }
        
    }failure:^(id dataObj, NSError *error) {
        UNDebugLogVerbose(@"登录失败：%@",[error description]);
        HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
        if (userdata) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            if (storyboard) {
                UIViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
                if (mainViewController) {
                    self.window.rootViewController = mainViewController;
                }
            }
        }
    } headers:self.headers];
}

#pragma mark 登录成功之后创建tcp
- (void)loginSuccessAndCreatTCP {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([UNNetWorkStatuManager shareManager].currentStatu != 0) {
            if (![UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
                self.isNeedToCheckSIMStatue = YES;
                [self creatAsocketTcp];
            }
        }
    });
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

- (void)loadLoginViewController {
    
    UNLoginViewController *loginVc = [[UNLoginViewController alloc] init];
    if (loginVc) {
        self.window.rootViewController = loginVc;
    }
    //token已过期，删除本地绑定的信息
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
}

#pragma mark 注册及初始化极光推送
- (void)resignJPushWithOptions:(NSDictionary *)launchOptions {
    //初始化APNs
    // Required
    // notice: 3.0.0及以后版本注册可以这样写，也可以继续 旧的注册 式
    JPUSHRegisterEntity * entity = [[JPUSHRegisterEntity alloc] init];
    entity.types = JPAuthorizationOptionAlert|JPAuthorizationOptionBadge|JPAuthorizationOptionSound;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        // 可以添加 定义categories
        // NSSet<UNNotificationCategory *> *categories for iOS10 or later
        // NSSet<UIUserNotificationCategory *> *categories for iOS8 and iOS9
    }
    [JPUSHService registerForRemoteNotificationConfig:entity delegate:self];
   
    //初始化JPush
    // Optional
    // 获取IDFA
    // 如需使 IDFA功能请添加此代码并在初始化方法的advertisingIdentifier参数中填写对应值 NSString *advertisingId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    // Required
    // init Push
    // notice: 2.1.5版本的SDK新增的注册方法，改成可上报IDFA，如果没有使 IDFA直接传nil
    // 如需继续使 pushConfig.plist文件声明appKey等配置内容，请依旧使 [JPUSHService setupWithOption:launchOptions] 式初始化。
    [JPUSHService setupWithOption:launchOptions
                           appKey:@"203b0b8a6747e85d18779ce0"
                          channel:@"App Store"
                 apsForProduction:!DEBUGMODE//0为开发环境，1为发布环境
            advertisingIdentifier:nil];
    UNDebugLogVerbose(@"极光环境为：%d", !DEBUGMODE);
}

#pragma mark 收到自定义通知
- (void)networkDidReceiveMessage:(NSNotification *)notification {
    NSDictionary * userInfo = [notification userInfo];
    UNDebugLogVerbose(@"收到极光推送短信userInfo========%@", userInfo)
    NSString *content = [userInfo valueForKey:@"content"];
    NSString *contentType = userInfo[@"content_type"];
    NSDictionary *extras = [userInfo valueForKey:@"extras"];
//    NSString *customizeField1 = [extras valueForKey:@"customizeField1"]; //服务端传递的Extras附加字段，key是自己定义的
    UNDebugLogVerbose(@"收到通知：\n content - %@\n content_type - %@\n extras - %@", content, contentType, extras);
    if ([contentType isEqualToString:@"SMSReceiveNew"]) {
        //收到对方发送的短信
        NSString *name = [self checkLinkNameWithPhoneStr:extras[@"Tel"]];
        [[UNBlueToothTool shareBlueToothTool] checkNotifiMessage];
        [self addNotificationWithTitle:[NSString stringWithFormat:@"%@%@%@", INTERNATIONALSTRING(@"收到"), name, INTERNATIONALSTRING(@"的短信")] body:extras[@"SMSContent"] userInfo:userInfo];
        
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReceiveNewSMSContentUpdate" object:nil];
        
    }else if ([contentType isEqualToString:@"SMSSendResult"]) {
        //更新数据库
        [[UNDatabaseTools sharedFMDBTools] updateMessageStatuWithSMSIDDictArray:@[extras]];
        
        //发送短信成功
        if ([extras[@"Status"] isEqualToString:@"1"]) {
            [self addNotificationWithTitle:INTERNATIONALSTRING(@"短信发送提醒") body:content userInfo:userInfo];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SendMessageStatuChange" object:@"MessageStatu" userInfo:userInfo];
            
        } else if ([extras[@"Status"] isEqualToString:@"2"]) {
            [self addNotificationWithTitle:INTERNATIONALSTRING(@"短信发送提醒") body:INTERNATIONALSTRING(@"短信发送失败！") userInfo:userInfo];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SendMessageStatuChange" object:@"MessageStatu" userInfo:userInfo];
        } else {
            UNDebugLogVerbose(@"收到短信发送结果的推送，状态码有问题");
        }
        
    }else if ([contentType isEqualToString:@"ProductNew"]){
        [UNDataTools sharedInstance].isHasMallMessage = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MallExtendMessage" object:nil userInfo:extras];
        [[NSUserDefaults standardUserDefaults] setObject:extras forKey:@"JPushMallMessage"];
    }
    
}

- (void)addNotificationWithTitle:(NSString *)title body:(NSString *)body userInfo:(NSDictionary *)userInfo {
    JPushNotificationContent *content = [[JPushNotificationContent alloc] init];
    content.title = title;
    content.subtitle = nil;
    content.body = body;
    content.badge = @1;//角标数
    content.categoryIdentifier = @"自己拓展名字";//行为分类标识
    content.userInfo = userInfo;
    
    // 5s后提醒 iOS 10 以上支持
    JPushNotificationTrigger *trigger1 = [[JPushNotificationTrigger alloc] init];
    if (kSystemVersionValue < 10.0) {
        trigger1.fireDate = [NSDate dateWithTimeIntervalSinceNow:0.5];
    }else{
        trigger1.timeInterval = 0.5;
    }
    JPushNotificationRequest *request = [[JPushNotificationRequest alloc] init];
    request.requestIdentifier = @"sampleRequest";
    request.content = content;
    request.trigger = trigger1;//trigger2;//trigger3;//trigger4;//trigger5;
    request.completionHandler = ^(id result) {
        UNDebugLogVerbose(@"结果返回：%@", result);
    };
    [JPUSHService addNotification:request];
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive && kSystemVersionValue < 10.0) {
        //声音提醒
//        NSURL *audioPath = [[NSBundle mainBundle] URLForResource:@"ReceivedMessage" withExtension:@"caf"];
        NSURL *audioPath = [NSURL fileURLWithPath:[NSString stringWithFormat:@"/System/Library/Audio/UISounds/%@.%@",@"sms-received1",@"caf"]];
        SystemSoundID soundID;
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)(audioPath), &soundID);
        AudioServicesPlaySystemSound(soundID);
    }
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url{
    
    UNDebugLogVerbose(@"url1=%@",url);
    
    return [WXApi handleOpenURL:url delegate:self];
}


/*
//返回

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    UNDebugLogVerbose(@"URL=%@",url);
    
    
    return [WXApi handleOpenURL:url delegate:self];
    
}*/

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    UNLogLBEProcess(@"进入后台---applicationDidEnterBackground")
    [self keepLongConnectionOfSocketWhenApplicationDidEnterBackground:application];
    [_location startUpdatingLocation];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)keepLongConnectionOfSocketWhenApplicationDidEnterBackground:(UIApplication *)application
{
    // 允许后台开启一个长期任务，记得配置voip(网络电话)
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier;
    backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (backgroundTaskIdentifier != UIBackgroundTaskInvalid)
            {
                backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            }
        });
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([SipEngineManager instance].resignStatue == 1) {
                [[SipEngineManager instance] enterBackgroundMode];
            }
            if (backgroundTaskIdentifier != UIBackgroundTaskInvalid)
            {
                backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            }
        });
    });
    
    UNDebugLogVerbose(@"后台backgroundTaskIdentifier--------  %zd",backgroundTaskIdentifier);
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    [JPUSHService resetBadge];
    [application setApplicationIconBadgeNumber:0];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"appEnterForeground" object:@"appEnterForeground"];
    
    //进入前台重新注册
    if (![UNPushKitMessageManager shareManager].isAlreadyInForeground) {
        if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
            UNLogLBEProcess(@"进入前台")
            if (![UNDataTools sharedInstance].isLogout) {
                UNDebugLogVerbose(@"在线：%s,%d", __FUNCTION__, __LINE__)
                [UNPushKitMessageManager shareManager].isPushKitFromAppDelegate = NO;
                [[UNPushKitMessageManager shareManager].pushKitMsgQueue removeAllObjects];
                [UNPushKitMessageManager shareManager].pushKitMsgType = PushKitMessageTypeNone;
                [self closeTCP];
                [BlueToothDataManager shareManager].isCheckAndRefreshBLEStatue = NO;
                [BlueToothDataManager shareManager].bleStatueForCard = 0;
//                [BlueToothDataManager shareManager].isBeingRegisting = NO;
//                [BlueToothDataManager shareManager].isRegisted = NO;
                [BlueToothDataManager shareManager].stepNumber = @"0";
                self.lessStep = 0;
                self.tcpPacketStr = nil;
                [[UNBlueToothTool shareBlueToothTool] fristJumpForeground];
                //在pushkit里初始化蓝牙
                dispatch_async(dispatch_get_main_queue(), ^{
                    UNLogLBEProcess(@"发送重置蓝牙状态通知")
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLBEStatuWithPushKit" object:nil];
                });
            } else {
                UNDebugLogVerbose(@"不在线：%s,%d", __FUNCTION__, __LINE__)
            }
        } else {
            [self checkRegistStatueEnterForeground];
        }
        [UNPushKitMessageManager shareManager].isAlreadyInForeground = YES;
    } else {
        [self checkRegistStatueEnterForeground];
    }
    [UNPushKitMessageManager shareManager].isPushKitFromAppDelegate = NO;
}

#pragma mark 从后台进入前台时执行的方法
- (void)checkRegistStatueEnterForeground {
    if (![UNDataTools sharedInstance].isLogout) {
        UNDebugLogVerbose(@"在线：%s,%d", __FUNCTION__, __LINE__);
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] isEqualToString:@"on"]) {
            if ([BlueToothDataManager shareManager].isOpened) {
                if ([UNNetWorkStatuManager shareManager].currentStatu != 0) {
                    self.isNeedToCheckSIMStatue = YES;
                    if ([BlueToothDataManager shareManager].isTcpConnected) {
                        [self sendDataToCheckRegistStatue];
                    } else {
                        [self creatAsocketTcp];
                    }
                    if (![BlueToothDataManager shareManager].isConnected) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"scanToConnect" object:@"connect"];
                    }
                } else {
                    UNLogLBEProcess(@"进入前台--没网络")
                }
            } else {
                UNLogLBEProcess(@"进入前台--蓝牙未开")
            }
        } else {
            UNLogLBEProcess(@"进入前台--服务未开")
//            [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NOTSERVICE;
            [self changeBleStatue];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"changeStatueAll" object:HOMESTATUETITLE_NOTSERVICE];
        }
    } else {
        UNDebugLogVerbose(@"不在线：%s,%d", __FUNCTION__, __LINE__);
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

//程序被手动杀死
- (void)applicationWillTerminate:(UIApplication *)application {
    //发送注销电话通知
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"appIsKilled" object:@"appIsKilled"];
    //发送即将被杀死通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AppWillBeKilled" object:nil];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    //跳转支付宝支付,处理支付结果
    //    [[AlipaySDK defaultService]processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
    //        UNDebugLogVerbose(@"result = %@",resultDic);
    //    }];
    
    if ([url.host isEqualToString:@"safepay"]) {
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            UNDebugLogVerbose(@"result = %@",resultDic);
            [self processAlipayResult:resultDic];
        }];
    }
    if ([url.host isEqualToString:@"platformapi"]){//支付宝钱包快登授权返回 authCode
        [[AlipaySDK defaultService] processAuthResult:url standbyCallback:^(NSDictionary *resultDic) {
            UNDebugLogVerbose(@"result = %@",resultDic);
            [self processAlipayResult:resultDic];
        }];
    }
    
    UNDebugLogVerbose(@"谁家的支付回调1：%@",[url absoluteString]);
    
    return [WXApi handleOpenURL:url delegate:self];
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options {
    UNDebugLogVerbose(@"谁家的支付回调2：%@",[url absoluteString]);
    if ([url.host isEqualToString:@"safepay"]) {
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            UNDebugLogVerbose(@"result = %@",resultDic);
            [self processAlipayResult:resultDic];
            //正常的支付宝回调哦
        }];
    }
    if ([url.host isEqualToString:@"platformapi"]){//支付宝钱包快登授权返回 authCode
        [[AlipaySDK defaultService] processAuthResult:url standbyCallback:^(NSDictionary *resultDic) {
            UNDebugLogVerbose(@"result = %@",resultDic);
            [self processAlipayResult:resultDic];
        }];
    }
    
    return [WXApi handleOpenURL:url delegate:self];
    
    return YES;
}

- (void)processAlipayResult:(NSDictionary *)resultDic {
    if ([[resultDic objectForKey:@"resultStatus"] intValue]==9000) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AlipayComplete" object:resultDic];//[resultDic objectForKey:@"result"]];
    }else{
        [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:[resultDic objectForKey:@"memo"] delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
    }
}

#pragma mark - WXApiDelegate
- (void)onResp:(BaseResp *)resp {
    if([resp isKindOfClass:[PayResp class]]){
        //支付返回结果，实际支付结果需要去微信服务器端查询
//        NSString *strMsg,*strTitle = [NSString stringWithFormat:@"支付结果"];
        
        switch (resp.errCode) {
            case WXSuccess:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"WeipayComplete" object:@"success"];
//                strMsg = @"支付结果：成功！";
                UNDebugLogVerbose(@"支付成功－PaySuccess，retcode = %d", resp.errCode);
                break;
                
            default:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"WeipayComplete" object:resp.errStr];
//                strMsg = [NSString stringWithFormat:@"支付结果：失败！retcode = %d, retstr = %@", resp.errCode,resp.errStr];
                UNDebugLogVerbose(@"错误，retcode = %d, retstr = %@", resp.errCode,resp.errStr);
                break;
        }
    }
    
}

- (void)onReq:(BaseReq *)req {
    
    
    //返回的请求
}

#pragma mark - 极光推送delegate
#pragma mark 注册APNs成功并上报DeviceToken
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    /// Required - 注册 DeviceToken
    [JPUSHService registerDeviceToken:deviceToken];
}

#pragma mark 实现注册APNs失败接
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    //Optional
    UNDebugLogVerbose(@"注册极光推送失败 did Fail To Register For Remote Notifications With Error: %@", error);
}

// iOS 10 Support,本地通知为notification，接收到通知
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(NSInteger))completionHandler {
    // Required
    NSDictionary * userInfo = notification.request.content.userInfo;
    UNDebugLogVerbose(@"willPresentNotification收到推送通知userInfo========%@", userInfo)
    if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        //刷新页面
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReceiveNewSMSContentUpdate" object:nil];
        [JPUSHService handleRemoteNotification:userInfo];
        NSString *name = [self checkLinkNameWithPhoneStr:userInfo[@"Tel"]];
        [[UNBlueToothTool shareBlueToothTool] checkNotifiMessage];
        [self addNotificationWithTitle:[NSString stringWithFormat:@"%@%@%@", INTERNATIONALSTRING(@"收到"), name, INTERNATIONALSTRING(@"的短信")] body:userInfo[@"SMSContent"] userInfo:userInfo];
    } else {
        // 本地通知
        completionHandler(UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionSound|UNNotificationPresentationOptionAlert); // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以设置
    }
    
}

// iOS 10 Support,本地通知为response.notification，点击通知跳转
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    // Required
    NSDictionary * userInfo = response.notification.request.content.userInfo;
    UNDebugLogVerbose(@"didReceiveNotificationResponse收到推送通知userInfo========%@", userInfo)
    if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [JPUSHService handleRemoteNotification:userInfo];
    } else {
        // 点击本地通知
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"jumpToMessage" object:@"jumpToMessage"];
    completionHandler();  // 系统要求执行这个方法
}

//ios8前台收到推送
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
        // Required, iOS 7 Support
    UNDebugLogVerbose(@"didReceiveRemoteNotification:fetchCompletionHandler收到推送通知userInfo========%@", userInfo)
    //刷新页面
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReceiveNewSMSContentUpdate" object:nil];
    
    [JPUSHService handleRemoteNotification:userInfo];
    NSString *name = [self checkLinkNameWithPhoneStr:userInfo[@"Tel"]];
    [[UNBlueToothTool shareBlueToothTool] checkNotifiMessage];
    [self addNotificationWithTitle:[NSString stringWithFormat:@"%@%@%@", INTERNATIONALSTRING(@"收到"), name, INTERNATIONALSTRING(@"的短信")] body:userInfo[@"SMSContent"] userInfo:userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    UNDebugLogVerbose(@"didReceiveRemoteNotification收到推送通知userInfo========%@", userInfo)
    UNLogLBEProcess(@"收到远程通知")
    
    // 取得 APNs 标准信息内容
    NSDictionary *aps = [userInfo valueForKey:@"aps"];
    NSString *content = [aps valueForKey:@"alert"]; //推送显示的内容
    NSInteger badge = [[aps valueForKey:@"badge"] integerValue]; //badge数量
    NSString *sound = [aps valueForKey:@"sound"]; //播放的声音
    
    // 取得Extras字段内容
    NSString *customizeField1 = [userInfo valueForKey:@"customizeExtras"]; //服务端中Extras字段，key是自己定义的
    UNDebugLogVerbose(@"content =[%@], badge=[%ld], sound=[%@], customize field  =[%@]",content,(long)badge,sound,customizeField1);
    
    // iOS 10 以下 Required
    [JPUSHService handleRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    UNDebugLogVerbose(@"收到通知了");
    UNDebugLogVerbose(@"didReceiveLocalNotification收到推送通知userInfo========%@", notification.userInfo)
}

//获取当前屏幕显示的viewcontroller
- (UIViewController *)currentViewController
{
    UIViewController *currentVc = nil;
    UIViewController *rootVc = self.window.rootViewController;
    do {
        if ([rootVc isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nav = (UINavigationController *)rootVc;
            UIViewController *vc = [nav.viewControllers lastObject];
            currentVc = vc;
            rootVc = vc.presentedViewController;
            continue;
        }else if ([rootVc isKindOfClass:[UITabBarController class]]){
            UITabBarController *tabVc = (UITabBarController *)rootVc;
            currentVc = tabVc;
            rootVc = [tabVc.viewControllers objectAtIndex:tabVc.selectedIndex];
            continue;
        }
    }while (rootVc != nil);
    return currentVc;
}


#pragma mark -BuglyDelegate

- (NSString *)attachmentForException:(NSException *)exception {
    UNDebugLogVerbose(@"attachmentForException %@",exception);
    [Bugly reportException:exception];  //直接上报异常
    return @"Test User attachment";
}

//处理号码
- (NSString *)checkLinkNameWithPhoneStr:(NSString *)phoneStr {
    NSString *linkName;
    NSString *tempStr;
    if ([phoneStr containsString:@"-"]) {
        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@"-" withString:@""];
        phoneStr = newStr;
    }
    if ([phoneStr containsString:@" "]) {
        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@" " withString:@""];
        phoneStr = newStr;
    }
    if ([phoneStr containsString:@"+86"]) {
        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@"+86" withString:@""];
        phoneStr = newStr;
    }
    if ([phoneStr containsString:@","]) {
        NSArray *arr = [phoneStr componentsSeparatedByString:@","];
        for (NSString *str in arr) {
            NSString *string;
            string = [self checkNameWithNumber:str];
            if (tempStr) {
                linkName = [NSString stringWithFormat:@"%@,%@", tempStr, string];
            } else {
                tempStr = string;
            }
        }
    } else {
        linkName = [self checkNameWithNumber:phoneStr];
        return linkName;
    }
    return linkName;
}

- (NSString *)checkNameWithNumber:(NSString *)number {
    ContactModel *tempModel;
    NSString *linkName = number;
    for (ContactModel *model in [AddressBookManager shareManager].dataArr) {
        tempModel = model;
        if ([model.phoneNumber containsString:@"-"]) {
            tempModel.phoneNumber = [model.phoneNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
        }
        if ([model.phoneNumber containsString:@" "]) {
            tempModel.phoneNumber = [model.phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
        }
        if ([model.phoneNumber containsString:@"+86"]) {
            tempModel.phoneNumber = [model.phoneNumber stringByReplacingOccurrencesOfString:@"+86" withString:@""];
        }
        if ([number isEqualToString:[NSString stringWithFormat:@"%@", tempModel.phoneNumber]]) {
            linkName = tempModel.name;
            return linkName;
        }
        if ([number isEqualToString:@"anonymous"]) {
            linkName = @"未知";
            return linkName;
        }
    }
    return linkName;
}

#pragma mark -从外部发起网络通话
//点击系统通话调用CallKit会回调此方法
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler
{
    if (kSystemVersionValue < 10.0) {
        return NO;
    }
    UNLogLBEProcess(@"application--continueUserActivity")
    UNDebugLogVerbose(@"userActivity:%@", userActivity.description);
    UNDebugLogVerbose(@"userActivity--userInfo:%@", userActivity.userInfo);
    if ([BlueToothDataManager shareManager].isTcpConnected && ![UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
        NSString * handle =userActivity.startCallHandle;
        if(nil == handle ){
            [UNPushKitMessageManager shareManager].isSysCallKitPhone = NO;
            [UNPushKitMessageManager shareManager].callKitHandleString = nil;
            UNDebugLogVerbose(@"Could not determine start call handle from user activity:%@", userActivity);
            return NO;
        }else{
            [self callPhoneFromCallKitWithHandleString:handle];
            return YES;
        }
    }else{
        [UNPushKitMessageManager shareManager].isSysCallKitPhone = YES;
        [UNPushKitMessageManager shareManager].callKitHandleString = userActivity.startCallHandle;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD showMessage:@"正在注册电话,注册成功后将为您拨打电话" toView:nil isLongText:YES DelayTime:2.0];
        });
    }
    return NO;
}

//通过CallKit拨打电话
- (void)callPhoneFromCallKit
{
    if ([UNPushKitMessageManager shareManager].isSysCallKitPhone && [UNPushKitMessageManager shareManager].callKitHandleString) {
        UNDebugLogVerbose(@"拨打CallKit电话");
        [self callPhoneFromCallKitWithHandleString:[[UNPushKitMessageManager shareManager].callKitHandleString copy]];
    }
}

//拨打CallKit电话
- (void)callPhoneFromCallKitWithHandleString:(NSString *)handle
{
    [UNPushKitMessageManager shareManager].isSysCallKitPhone = NO;
    [UNPushKitMessageManager shareManager].callKitHandleString = nil;
    
    UNContact * contact = [[UNContact alloc] init];
    contact.phoneNumber= handle;
    contact.uniqueIdentifier=@"";
    UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUUID *callUUID = [[UNCallKitCenter sharedInstance] startRequestCalllWithContact:contact completion:^(NSError * _Nullable error) {
        }];
        UNDebugLogVerbose(@"callUUID==%@", callUUID);
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
    });
}


#pragma mark --- PuskKitDelegate
//此处获取PushKit Token
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type {
    NSString *tokenString = [[[[credentials.token description] stringByReplacingOccurrencesOfString: @"<" withString: @""] stringByReplacingOccurrencesOfString: @">" withString: @""] stringByReplacingOccurrencesOfString: @" " withString: @""];
    UNLogLBEProcess(@"pushToken======%@=======", tokenString)
    NSString *newToken = [self hexStringFromString:tokenString];
    NSString *newTokenlength = [self hexNewStringFromString:[NSString stringWithFormat:@"%zd", newToken.length/2]];
    //T : 202
    [UNPushKitMessageManager shareManager].pushKitTokenString = [NSString stringWithFormat:@"ca%@%@", newTokenlength, newToken];
}


//PushKit消息回调(通过PushKit唤醒程序也会执行主流程,调用didFinishLaunchingWithOptions方法,但与用户手动启动程序调用时机有差别,在PushKit下,程序为后台状态)
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    if ([payload.type isEqualToString:@"PKPushTypeVoIP"]) {
        //判断是否通过PushKit启动(此处通过启动时机来判断是否为PushKit启动)
        if (![UNPushKitMessageManager shareManager].isAlreadyInForeground) {
            UNLogLBEProcess(@"isAlreadyInForeground==NO")
            if (![UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
                UNLogLBEProcess(@"isPushKitFromAppDelegate==NO")
                if (![UNPushKitMessageManager shareManager].isInitMainVc) {
                    UNLogLBEProcess(@"isInitMainVc==NO")
                    [UNPushKitMessageManager shareManager].isPushKitFromAppDelegate = YES;
                }
            }
        }else{
            UNLogLBEProcess(@"isAlreadyInForeground==YES")
            [UNPushKitMessageManager shareManager].isPushKitFromAppDelegate = NO;
        }
        
        UNDebugLogVerbose(@"开始电话接入======%@=======", payload.dictionaryPayload);
        //        if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground || [UNPushKitMessageManager shareManager].isAlreadyInForeground) {
        NSDictionary *dict = payload.dictionaryPayload;
        NSString *messageType = [dict[@"MessageType"] lowercaseString];
        if (messageType && [messageType isEqualToString:@"99"]) {
            UNLogLBEProcess(@"收到日志操作PushKit---%@", payload.dictionaryPayload)
            if ([dict[@"Data"] integerValue] == 100) {
                [[UNDDLogManager sharedInstance] clearAllLog];
            }else{
                [[UNDDLogManager sharedInstance] updateLogToServerWithLogCount:[dict[@"Data"] integerValue] Finished:nil];
            }
            return;
        }
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] && ![[[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] isEqualToString:@"on"]){
            UNLogLBEProcess(@"开关已关闭")
            return;
        }
        
        if (![UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
            //用户手动启动,接收到PushKit消息会走这里
            UNLogLBEProcess(@"非PushKit状态")
            NSDictionary *dict = payload.dictionaryPayload;
            NSString *servicePushKitData = [dict[@"Data"] lowercaseString];
            NSString *tempStr = [NSString stringWithFormat:@"%@", servicePushKitData];
            if ([tempStr containsString:@"<"]) {
                tempStr = [tempStr stringByReplacingOccurrencesOfString:@"<" withString:@""];
            }
            if ([tempStr containsString:@">"]) {
                tempStr = [tempStr stringByReplacingOccurrencesOfString:@">" withString:@""];
            }
            if ([tempStr containsString:@" "]) {
                tempStr = [tempStr stringByReplacingOccurrencesOfString:@" " withString:@""];
            }
            [self checkManyPacketString:tempStr];
            [UNPushKitMessageManager shareManager].pushKitMsgType = PushKitMessageTypeNone;
            return;
        }else{
            //通过PushKit启动程序会走这里
            if (payload.dictionaryPayload) {
                UNLogLBEProcess(@"PushKit状态")
                NSDictionary *dict = payload.dictionaryPayload;
                NSString *messageType = [dict[@"MessageType"] lowercaseString];
                
                if (dict[@"Data"] == nil) {
                    return;
                }
                NSString *servicePushKitData = [dict[@"Data"] lowercaseString];
                NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
                NSString *timeString = [NSString stringWithFormat:@"%f", time];
                NSDictionary *serviceTimeData = @{@"time" : timeString, @"dataString" : servicePushKitData, @"MessageType" : messageType};
                [UNCreatLocalNoti createLocalNotiMessageString:[NSString stringWithFormat:@"收到服务器---%@",servicePushKitData]];
                if ([messageType isEqualToString:@"10"]) {
                    UNLogLBEProcess(@"10鉴权数据PushKit消息")
                    //                [[UNSipEngineInitialize sharedInstance] initEngine];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UNSipEngineInitialize sharedInstance] initEngine];
                        
                        [[UNBlueToothTool shareBlueToothTool] initBlueTooth];
                        //在pushkit里初始化蓝牙
                        [self checkCurrentPushKitMessage:serviceTimeData];
                    });

                }else if ([messageType isEqualToString:@"06"]){
                    UNLogLBEProcess(@"06唤醒网络电话PushKit消息");
                    //创建网络电话服务
                    [[UNSipEngineInitialize sharedInstance] initEngine];
                    [UNPushKitMessageManager shareManager].pushKitMsgType = PushKitMessageTypeNetCall;
                    [UNPushKitMessageManager shareManager].simDataDict = nil;
                    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"VSWCallPort"]) {
                        [VSWManager shareManager].callPort = [[NSUserDefaults standardUserDefaults] objectForKey:@"VSWCallPort"];
                    }
                    [UNCreatLocalNoti createLocalNotiMessageString:@"pushKit消息唤醒网络电话"];
                }else if ([messageType isEqualToString:@"05"]){
                    UNLogLBEProcess(@"05心跳包PushKit消息")
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UNBlueToothTool shareBlueToothTool] initBlueTooth];
                        [self checkCurrentPushKitMessage:serviceTimeData];
                    });
                }else if ([messageType isEqualToString:@"0f"]){
                    UNLogLBEProcess(@"0FSIM卡断开连接PushKit消息")
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //在pushkit里初始化蓝牙
                        [[UNBlueToothTool shareBlueToothTool] initBlueTooth];
                        //创建网络电话服务
                        [[UNSipEngineInitialize sharedInstance] initEngine];
                        [self checkCurrentPushKitMessage:serviceTimeData];
                    });
                }else{
                    [UNPushKitMessageManager shareManager].pushKitMsgType = PushKitMessageTypeNone;
                    UNLogLBEProcess(@"未知PushKit消息---%@", dict)
                }
            }else{
                UNLogLBEProcess(@"PushKit消息异常")
            }
        }
    }

}

//处理当前PushKit消息
- (void)checkCurrentPushKitMessage:(NSDictionary *)serviceTimeData
{
    //存储到队列中
    if ([UNPushKitMessageManager shareManager].pushKitMsgQueue.count > 0) {
        NSString *timeString = [UNPushKitMessageManager shareManager].pushKitMsgQueue.firstObject[@"time"];
        
        CGFloat dataTime = [timeString doubleValue];
        NSDate *dataDate = [NSDate dateWithTimeIntervalSince1970:dataTime];
        NSTimeInterval timeValue = [dataDate timeIntervalSinceNow];
        UNLogLBEProcess(@"时间差为---%.f", timeValue)
        
        if ([serviceTimeData[@"MessageType"] isEqualToString:@"0f"]) {
            [[UNPushKitMessageManager shareManager].pushKitMsgQueue removeAllObjects];
            [UNPushKitMessageManager shareManager].simDataDict = nil;
        }else{
            if (timeValue > 20.0){
                UNLogLBEProcess(@"时间太久,清空PushKit数据")
                [[UNPushKitMessageManager shareManager].pushKitMsgQueue removeAllObjects];
                [UNPushKitMessageManager shareManager].simDataDict = nil;
            }
        }
    }
    [[UNPushKitMessageManager shareManager].pushKitMsgQueue addObject:serviceTimeData];
    
    //防止和手环交互出现异常导致的卡住流程,当消息超过3条时,删除所有过期数据,重置Pushkit消息,并处理当前PushKit消息
    UNLogLBEProcess(@"pushkit队列消息数量--%zd", [UNPushKitMessageManager shareManager].pushKitMsgQueue.count)
    if ([UNPushKitMessageManager shareManager].pushKitMsgQueue.count == 1) {
        [self sendPushKitMessage:[UNPushKitMessageManager shareManager].pushKitMsgQueue.firstObject];
    }else if ([UNPushKitMessageManager shareManager].pushKitMsgQueue.count > 3){
        NSDictionary *dict = [UNPushKitMessageManager shareManager].pushKitMsgQueue.lastObject;
        [[UNPushKitMessageManager shareManager].pushKitMsgQueue removeAllObjects];
        [[UNPushKitMessageManager shareManager].pushKitMsgQueue addObject:dict];
        [self sendPushKitMessage:[UNPushKitMessageManager shareManager].pushKitMsgQueue.firstObject];
    }
}

//重连TCP
- (void)reConnectTcp
{
    DebugUNLog(@"reConnectTcp");
    if (self.sendTcpSocket && !self.sendTcpSocket.isConnected) {
        DebugUNLog(@"tcp存在");
        if (![UNPushKitMessageManager shareManager].isTcpConnecting) {
            DebugUNLog(@"tcp没有正在重连");
            NSString *host = [VSWManager shareManager].vswIp;
            uint16_t port = [VSWManager shareManager].vswPort;
//            UNDebugLogVerbose(@"reConnectTcp---tcp连接或断线重连---[%@:%d]",host, port);
            self.lessStep = 0;
            if (!host || !port) {
                host = [[NSUserDefaults standardUserDefaults] objectForKey:@"VSWServerIp"];
                port = [[[NSUserDefaults standardUserDefaults] objectForKey:@"VSWServerPort"] intValue];
            }
            UNLogLBEProcess(@"reConnectTcp---tcp连接或断线重连---[%@:%d]",host, port)
            if (host && port) {
                NSError *error;
                [self.sendTcpSocket connectToHost:host onPort:port withTimeout:60 error:&error];
                if (error) {
                    UNLogLBEProcess(@"socket连接出错----%@", error)
                    [UNPushKitMessageManager shareManager].isTcpConnecting = NO;
                }else{
                    [UNPushKitMessageManager shareManager].isTcpConnecting = YES;
                }
            }else{
                [UNPushKitMessageManager shareManager].isTcpConnecting = NO;
            }
        }
    }else if (self.sendTcpSocket.isConnected){
        NSString *host = [VSWManager shareManager].vswIp;
        uint16_t port = [VSWManager shareManager].vswPort;
//        UNDebugLogVerbose(@"reConnectTcp---tcp连接或断线重连---[%@:%d]",host, port);
        self.lessStep = 0;
        if (!host || !port) {
            host = [[NSUserDefaults standardUserDefaults] objectForKey:@"VSWServerIp"];
            port = [[[NSUserDefaults standardUserDefaults] objectForKey:@"VSWServerPort"] intValue];
        }
        UNLogLBEProcess(@"reConnectTcp---tcp连接或断线重连---[%@:%d]",host, port)
        if (host && port) {
            NSError *error;
            [self.sendTcpSocket connectToHost:host onPort:port withTimeout:60 error:&error];
            if (error) {
                UNLogLBEProcess(@"socket连接出错----%@", error)
                [UNPushKitMessageManager shareManager].isTcpConnecting = NO;
            }else{
                [UNPushKitMessageManager shareManager].isTcpConnecting = YES;
            }
        }else{
            [UNPushKitMessageManager shareManager].isTcpConnecting = NO;
        }
    }
}

//发送心跳包
- (void)sendPingPacketWithPushKitMessage:(NSString *)message
{
    NSString *pingMessage = [message stringByReplacingCharactersInRange:NSMakeRange(4, 2) withString:@"85"];
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    NSString *token;
    if (userdata) {
        token = userdata[@"Token"];
    }
    NSString *ascHex = [self hexStringFromString:token];
    NSString *lengthHex = [self hexNewStringFromString:[NSString stringWithFormat:@"%zd", ascHex.length/2]];
    NSString *tokenHex = [NSString stringWithFormat:@"78%@%@", lengthHex, ascHex];
    
    NSString *appendString = [NSString stringWithFormat:@"%@%@", pingMessage, tokenHex];
    NSString *countLengthStr = [appendString substringFromIndex:24];
    NSString *countLengthHex = [self hexFinalTLVLength:[NSString stringWithFormat:@"%zd", countLengthStr.length/2]];
    NSString *tcpString = [appendString stringByReplacingCharactersInRange:NSMakeRange(20, 4) withString:countLengthHex];
    UNLogLBEProcess(@"发送给服务器的数据2668 -- %@", tcpString)
    [UNCreatLocalNoti createLocalNotiMessageString:[NSString stringWithFormat:@"发送PushKit心跳包给服务器的数据--%@", tcpString]];
    [self sendMsgWithMessage:tcpString];
    
    if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
        UNDebugLogVerbose(@"删除前当前队列消息====%@", [UNPushKitMessageManager shareManager].pushKitMsgQueue);
        UNLogLBEProcess(@"需要删除的队列消息====%@", [UNPushKitMessageManager shareManager].receivePushKitDataFormServices)
        [self checkPushKitMessage:[UNPushKitMessageManager shareManager].receivePushKitDataFormServices];
    }
}

//处理PushKit消息
- (void)checkPushKitMessage:(NSDictionary *)servicePushKitData
{
    if (!servicePushKitData) {
        //发送新的pushkit消息
        if ([UNPushKitMessageManager shareManager].pushKitMsgQueue.count) {
            [self sendPushKitMessage:[UNPushKitMessageManager shareManager].pushKitMsgQueue.firstObject];
        }
    }else{
        [UNPushKitMessageManager shareManager].receivePushKitDataFormServices = nil;
        if ([[UNPushKitMessageManager shareManager].pushKitMsgQueue containsObject:servicePushKitData]) {
            [[UNPushKitMessageManager shareManager].pushKitMsgQueue removeObject:servicePushKitData];
            UNLogLBEProcess(@"删除后当前队列消息====%@", [UNPushKitMessageManager shareManager].pushKitMsgQueue)
            //发送新的pushkit消息
            if ([UNPushKitMessageManager shareManager].pushKitMsgQueue.count) {
                [self sendPushKitMessage:[UNPushKitMessageManager shareManager].pushKitMsgQueue.firstObject];
            }
        }else{
            UNLogLBEProcess(@"不包含当前队列消息")
            if ([UNPushKitMessageManager shareManager].pushKitMsgQueue.count) {
                [self sendPushKitMessage:[UNPushKitMessageManager shareManager].pushKitMsgQueue.firstObject];
            }
        }

    }
}

//处理PushKit消息
- (void)sendPushKitMessage:(NSDictionary *)servicePushKitData
{
    UNLogLBEProcess(@"当前队列需要发送的pushkit消息=====%@", servicePushKitData[@"dataString"])
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        [UNPushKitMessageManager shareManager].isPushKitFromAppDelegate = NO;
        [[UNPushKitMessageManager shareManager].pushKitMsgQueue removeAllObjects];
        [UNPushKitMessageManager shareManager].pushKitMsgType = PushKitMessageTypeNone;
        return;
    }
    if ([servicePushKitData[@"MessageType"] isEqualToString:@"10"]) {
        //鉴权数据
        [UNPushKitMessageManager shareManager].pushKitMsgType = PushKitMessageTypeAuthSimData;
        
        [UNPushKitMessageManager shareManager].tcpStringWithPushKit = nil;
        self.tlvFirstStr = nil;
        [UNPushKitMessageManager shareManager].simDataDict = nil;
        //解析并发送当前pushkit
        if ([[servicePushKitData[@"dataString"] substringWithRange:NSMakeRange(28, 2)] isEqualToString:@"01"]) {
            UNLogLBEProcess(@"发送01pushkit消息")
            [UNPushKitMessageManager shareManager].PushKitAuthDataType = 1;
            [UNPushKitMessageManager shareManager].receivePushKitDataFormServices = servicePushKitData;
            if (!self.sendTcpSocket) {
                [self creatAsocketTcp];
            }else{
                if (!self.sendTcpSocket.isConnected) {
                    [self reConnectTcp];
                }else{
                    [self checkPacketDetailWithStringFromPushKit:servicePushKitData];
                }
            }
        }else{
            UNLogLBEProcess(@"发送正常pushkit消息")
            [UNPushKitMessageManager shareManager].PushKitAuthDataType = 2;
            [UNPushKitMessageManager shareManager].receivePushKitDataFormServices = servicePushKitData;
            [self separatePushKitString:servicePushKitData];
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"VSWCallPort"]) {
                [VSWManager shareManager].callPort = [[NSUserDefaults standardUserDefaults] objectForKey:@"VSWCallPort"];
            }
            //加载蓝牙手环
            if ([UNPushKitMessageManager shareManager].simDataDict) {
                UNLogLBEProcess(@"发送ReceivePushKitMessage通知")
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReceivePushKitMessage" object:nil];
                });
            }else{
                if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
                    UNDebugLogVerbose(@"删除前当前队列消息====%@", [UNPushKitMessageManager shareManager].pushKitMsgQueue);
                    UNLogLBEProcess(@"需要删除的队列消息====%@", [UNPushKitMessageManager shareManager].receivePushKitDataFormServices)
                    [self checkPushKitMessage:[UNPushKitMessageManager shareManager].receivePushKitDataFormServices];
                }
            }
        }
    }else if ([servicePushKitData[@"MessageType"] isEqualToString:@"05"]){
        [UNPushKitMessageManager shareManager].pushKitMsgType = PushKitMessageTypePingPacket;
        [UNPushKitMessageManager shareManager].isSendTcpString = YES;
        [UNPushKitMessageManager shareManager].receivePushKitDataFormServices = servicePushKitData;
        [UNCreatLocalNoti createLocalNotiMessageString:[NSString stringWithFormat:@"接收服务器的心跳包数据--%@", servicePushKitData]];
        if (!self.sendTcpSocket) {
            [self creatAsocketTcp];
        }else{
            if (!self.sendTcpSocket.isConnected) {
                [self reConnectTcp];
            }else{
                [self sendPingPacketWithPushKitMessage:[UNPushKitMessageManager shareManager].receivePushKitDataFormServices[@"dataString"]];
            }
        }
    }else if ([servicePushKitData[@"MessageType"] isEqualToString:@"0f"]){
        [[UNPushKitMessageManager shareManager].pushKitMsgQueue removeAllObjects];
        [UNPushKitMessageManager shareManager].simDataDict = nil;
        [UNPushKitMessageManager shareManager].pushKitMsgType = PushKitMessageTypeSimDisconnect;
        [UNCreatLocalNoti createLocalNotiMessageString:[NSString stringWithFormat:@"SIM卡断开连接--"]];
        
        NSInteger dealyTime = 0;
        BOOL isDealyTime = YES;
        if ([BlueToothDataManager shareManager].isOpened && [BlueToothDataManager shareManager].isConnected && [BlueToothDataManager shareManager].isHaveCard) {
            isDealyTime = NO;
        }
        if ([UNPushKitMessageManager shareManager].isAlreadyInForeground) {
            isDealyTime = NO;
        }
        if (![UNPushKitMessageManager shareManager].isAppAlreadyLoad || isDealyTime){
            dealyTime = 5;
        }
        if (![BlueToothDataManager shareManager].isOpened) {
            dealyTime = 5;
        }
        [[UNBlueToothTool shareBlueToothTool] checkSystemBaseInfo];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(dealyTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self reconnectToServer];
        });
        
    }else{
        UNDebugLogVerbose(@"删除前当前队列消息====%@", [UNPushKitMessageManager shareManager].pushKitMsgQueue);
        UNLogLBEProcess(@"需要删除的队列消息====%@", [UNPushKitMessageManager shareManager].receivePushKitDataFormServices)
        [UNPushKitMessageManager shareManager].receivePushKitDataFormServices = servicePushKitData;
        [self checkPushKitMessage:[UNPushKitMessageManager shareManager].receivePushKitDataFormServices];
    }
}

//重连服务器(注册)
- (void)reconnectToServer
{
    UNLogLBEProcess(@"已创建TCP")
    if (![BlueToothDataManager shareManager].isOpened) {
            [UNCreatLocalNoti createLBECloseNoti];
        UNLogLBEProcess(@"蓝牙未开")
        return;
    }else{
        if (![BlueToothDataManager shareManager].isHaveCard && [BlueToothDataManager shareManager].currentSimCardStatu == 1) {
            [UNCreatLocalNoti createLBEDisConnectNoti];
            UNLogLBEProcess(@"无电话卡")
            return;
        }
        if (![BlueToothDataManager shareManager].isConnected && ![BlueToothDataManager shareManager].isHaveCard) {
            UNLogLBEProcess(@"蓝牙未连接");
            return;
        }
    }
    
    if (!self.tcpPacketStr && [BlueToothDataManager shareManager].isConnected) {
        self.tcpPacketStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"PushKitTCPPacketStr"];
    }
    if (self.sendTcpSocket) {
        UNLogLBEProcess(@"注册过,重新发送注册信息")
        [BlueToothDataManager shareManager].isBeingRegisting = NO;
        [BlueToothDataManager shareManager].stepNumber = @"0";
        self.lessStep = 0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [BlueToothDataManager shareManager].isRegisted = NO;
            if (!self.sendTcpSocket.isConnected) {
                [self reConnectTcp];
            }else{
                [BlueToothDataManager shareManager].isBeingRegisting = YES;
                self.communicateID = @"00000000";
                [UNCreatLocalNoti createLocalNotiMessageString:[NSString stringWithFormat:@"发送重连信息--%@", self.tcpPacketStr]];
                //发送数据
                [self sendMsgWithMessage:self.tcpPacketStr];
                
                [self checkPushKitMessage:[UNPushKitMessageManager shareManager].receivePushKitDataFormServices];
                [UNPushKitMessageManager shareManager].pushKitMsgType = PushKitMessageTypeNone;
            }
        });
        
    }else{
        UNLogLBEProcess(@"当前没有注册过,需要重新注册")
        [BlueToothDataManager shareManager].isReseted = NO;
        [self creatAsocketTcp];
    }
}

//清理过期PushKit数据
- (void)clearTimeoutPushKitMessage
{
    UNLogLBEProcess(@"清除超时数据")
    if ([UNPushKitMessageManager shareManager].pushKitMsgQueue.count) {
        [UNPushKitMessageManager shareManager].simDataDict = nil;
        [self checkPushKitMessage:[UNPushKitMessageManager shareManager].pushKitMsgQueue.firstObject];
    }
}

- (void)separatePushKitString:(NSDictionary *)serviceData
{
    NSString *dataString = serviceData[@"dataString"];
    if (dataString.length < 70) {
        return;
    }
    NSString *classStr = [dataString substringWithRange:NSMakeRange(4, 2)];
    if ([classStr isEqualToString:@"10"]) {
        NSInteger leng;
        //        NSString *TLVdetail;
        dataString = [dataString stringByReplacingCharactersInRange:NSMakeRange(4, 2) withString:@"90"];
        self.tlvFirstStr = [dataString substringWithRange:NSMakeRange(0, 32)];
        UNDebugLogVerbose(@"截取Pushkit消息前面的数据 -- %@", self.tlvFirstStr)
        if ([[dataString substringWithRange:NSMakeRange(28, 2)] isEqualToString:@"00"]) {
//            00
            NSString *lengthStr = [dataString substringWithRange:NSMakeRange(32, 2)];
            //74
            leng = strtoul([lengthStr UTF8String], 0, 16);
            if (dataString.length >= (34+leng * 2)) {
                [UNPushKitMessageManager shareManager].simDataDict = @{@"time" : serviceData[@"time"], @"dataString" : [dataString substringWithRange:NSMakeRange(34, leng * 2)]};
            }
            UNDebugLogVerbose(@"两位leng = %zd  需要传入的字符串 -- %@", leng, [UNPushKitMessageManager shareManager].simDataDict)
        }
    }
}

- (void)changeBleStatue {
    if ([UNNetWorkStatuManager shareManager].currentStatu == NotReachable) {
        //无网络
        [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NETWORKCANNOTUSE;
    } else {
        if (![BlueToothDataManager shareManager].isBounded) {
            //未绑定
            [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NOTBOUND;
        } else {
            if (![BlueToothDataManager shareManager].isOpened) {
                //蓝牙未开
                [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_BLNOTOPEN;
            } else {
                if (![BlueToothDataManager shareManager].isConnected) {
                    //未连接
                    [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NOTCONNECTED;
                } else {
                    if ([BlueToothDataManager shareManager].isLbeConnecting) {
                        //连接中
                        [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_CONNECTING;
                    } else {
                        if ([[BlueToothDataManager shareManager].operatorType intValue] == 4) {
                            //爱小器卡
                            [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_AIXIAOQICARD;
                        } else {
                            if (![[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] isEqualToString:@"on"]) {
                                if ([[BlueToothDataManager shareManager].operatorType intValue] == 5) {
                                    //未插卡
                                    [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NOTINSERTCARD;
                                } else {
                                    if ([[BlueToothDataManager shareManager].operatorType isEqualToString:@"0"]) {
                                        //读取卡失败
                                        [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_READCARDFAIL;
                                    } else {
                                        if ([BlueToothDataManager shareManager].isBeingRegisting) {
                                            //注册中
                                            [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_REGISTING;
                                        } else {
                                            if ([BlueToothDataManager shareManager].isRegisted) {
                                                //信号强
                                                [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_SIGNALSTRONG;
                                            } else {
                                                if ([BlueToothDataManager shareManager].isRegistedFail) {
                                                    //注册失败
                                                    [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NOSIGNAL;
                                                } else {
                                                    //默认
                                                    [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_REGISTING;
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                //服务关闭
                                [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NOTSERVICE;
                            }
                        }
                    }
                }
            }
        }
    }
}

#pragma mark 判断系统是否是32位
- (BOOL)is32bit
{
    
#if defined(__LP64__) && __LP64__
    
    return NO;
    
#else
    
    return YES;
    
#endif
    
}

- (void)dealloc {
    // 关闭套接字
    [self.sendTcpSocket disconnect];
    self.sendTcpSocket = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"receiveNewDtaaPacket" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"tcppacket" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"iccidAndImsi" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"packetLength" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"receiveNewDataStr" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"connectingBLE" object:@"connectingBLE"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"noConnectedAndUnbind" object:@"noConnectedAndUnbind"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"disconnectTCP" object:@"disconnectTCP"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"deviceIsDisconnect" object:@"deviceIsDisconnect"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SendTcpDataFromPushKit" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CreateUDPSocketToBLE" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CreateTCPSocketToBLE" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PushKitMessageDataTimeout" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"closeServiceNotifi" object:@"closeServiceNotifi"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"loginSuccessAndCreatTcpNotif" object:@"loginSuccessAndCreatTcpNotif"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"isAlreadOnlineAndSendJumpDataNotifi" object:@"isAlreadOnlineAndSendJumpDataNotifi"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"reloginNotify" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"OTASuccessAndReConnectedNotif" object:@"OTASuccessAndReConnectedNotif"];
}

@end
