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

//@property (nonatomic, assign) BOOL isPushKit;
//@property (nonatomic, copy) NSString *tcpStringWithPushKit;
//@property (nonatomic, copy) NSString *tcpPacketStrWithPushKit;
//
//@property (nonatomic, copy) NSString *pushKitTokenString;
//@property (nonatomic, copy) NSDictionary *receivePushKitDataFormServices;
//@property (nonatomic, assign) BOOL isSendTcpString;
//
//@property (nonatomic, copy) NSString *iccidString;
//@property (nonatomic, assign) BOOL isUdpSendFristMsg;
//
//@property (nonatomic, strong) NSMutableArray *pushKitMsgQueue;
//
////PushKit消息类型
//@property (nonatomic, assign) PushKitMessageType pushKitMsgType;
//
////TCP是否为第一次连接
////@property (nonatomic, assign) BOOL isTcpFristConnect;
//
////是否已经进入过前台
//@property (nonatomic, assign) BOOL isAlreadyInForeground;
////TCP是否正在连接
//@property (nonatomic, assign) BOOL isTcpConnecting;
////当前PushKit心跳包数据
//@property (nonatomic, copy) NSString *currentPushKitPingPackect;

@end

@implementation AppDelegate



- (void)redirectNSLogToDocumentFolder
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    
    NSString *fileName = [NSString stringWithFormat:@"%@.log",[[NSDate alloc] initWithTimeIntervalSinceNow:8*3600]]; // 注意不是NSData!
    NSString *logFilePath = [documentDirectory stringByAppendingPathComponent:fileName];
    
    // 将log输入到文件
//    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+", stdout);
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [UNPushKitMessageManager shareManager].pushKitMsgType = PushKitMessageTypeNone;
    
//    NSString *servicePushKitData = @"108a10002ffd82190003001a010100c71500010500001900023f007f206f740000a0c0000016";
    
//    NSString *servicePushKitData = @"108A1000300CBDE7000E002A010100C72500090510000200033F007F206F740000A088000010A458F84D016BD7C2A75F6A752D6E0FD9";
//    
//    [self separatePushKitString:servicePushKitData];
//    
//    self.isPushKit = YES;
    //制定真机调试保存日志文件
    [self redirectNSLogToDocumentFolder];
    
    [[UNNetWorkStatuManager shareManager] initNetWorkStatuManager];
    [UNNetWorkStatuManager shareManager].netWorkStatuChangeBlock = ^(NetworkStatus currentStatu){
        if (currentStatu != NotReachable) {
            NSLog(@"有网络");
            if (self.sendTcpSocket && ![BlueToothDataManager shareManager].isTcpConnected && [self.sendTcpSocket.userData isEqualToString:SocketCloseByNet]) {
                [self closeTCP];
                if ([UNPushKitMessageManager shareManager].pushKitMsgType == PushKitMessageTypeNone) {
                    [UNPushKitMessageManager shareManager].isSendTcpString = NO;
                }
                [self creatAsocketTcp];
            }
        }
    };
    
    if (kSystemVersionValue >= 10.0) {
        [[UNCallKitCenter sharedInstance] configurationCallProvider];
    }
    
    if (kSystemVersionValue >= 8.0) {
        PKPushRegistry *pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
        pushRegistry.delegate = self;
        pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    }
    
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
    
    BuglyConfig *config = [[BuglyConfig alloc] init];  //初始化
    config.delegate = self;
    self.window.backgroundColor = [UIColor colorWithRed:234/255.0 green:236/255.0 blue:240/255.0 alpha:1.0];
    
//    [self checkLogin];
    
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
    
    //创建一个udp
//    _udpSocket = [[GCDAsyncUdpSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
//    _udpSocket = [[GCDAsyncUdpSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
//    [_udpSocket receiveOnce:nil];
//    //监听接口和接收数据
//    NSError * error = nil;
//    [_udpSocket bindToPort:PORT error:&error];
//    if (error) {//监听错误打印错误信息
//        NSLog(@"error:%@",error);
//    }else {//监听成功则开始接收信息
//        [_udpSocket beginReceiving:&error];
//    }
    
    
#warning 先不创建udp,获取imsi
//    [self setUpUdpSocket];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendNewMessage:) name:@"receiveNewDtaaPacket" object:nil];//udp发包
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTcpPacket:) name:@"tcppacket" object:nil];//收到tcp部分数据包
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTcpIccidAndImsi:) name:@"iccidAndImsi" object:nil];//收到tcp的iccid和imsi
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTcpLength:) name:@"packetLength" object:nil];//收到tcp的数据包压缩前长度
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNewDataStr:) name:@"receiveNewDataStr" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectingBLEAction) name:@"connectingBLE" object:@"connectingBLE"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeTCP) name:@"noConnectedAndUnbind" object:@"noConnectedAndUnbind"];//解绑之后关闭tcp
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dicConnectedBLE) name:@"deviceIsDisconnect" object:@"deviceIsDisconnect"];//蓝牙断开连接
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeTCP) name:@"disconnectTCP" object:@"disconnectTCP"];//关闭tcp
    // Override point for customization after application launch.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTcpDataFromPushKit:) name:@"SendTcpDataFromPushKit" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createUDPSocketToBLE:) name:@"CreateUDPSocketToBLE" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createTCPSocketToBLE:) name:@"CreateTCPSocketToBLE" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearTimeoutPushKitMessage) name:@"PushKitMessageDataTimeout" object:nil];
    
    return YES;
}

- (void)showLaunchView {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
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
    });
    NSLog(@"创建udp");
    [self setUpUdpSocket];
}

- (void)createTCPSocketToBLE:(NSNotification *)noti
{
//    [BlueToothDataManager shareManager].isRegisted = NO;
//    [BlueToothDataManager shareManager].isBeingRegisting = YES;
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeStatue" object:@"100"];
//    [BlueToothDataManager shareManager].stepNumber = @"100";
    NSLog(@"获取ICCID数据");
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
    NSLog(@"simData====%@", simData);
    [self groupPacket];
}


- (void)setUpUdpSocket
{
    _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_udpSocket receiveOnce:nil];
    //监听接口和接收数据
    NSError * error = nil;
    [_udpSocket bindToPort:PORT error:&error];
    if (error) {//监听错误打印错误信息
        NSLog(@"error:%@",error);
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
                NSLog(@"The table count: %zd", count);
                if (count == 0) {
                    [db executeUpdate:@"CREATE TABLE CallRecord (datas Text, calltime TimeStamp, dataid text)"];
                }
                [rs close];
            }
            [db close];
        }
    }
}

- (void)closeTCP {
    // 关闭套接字
    NSLog(@"关闭TCP");
    if (self.sendTcpSocket) {
        self.sendTcpSocket.userData = SocketCloseByUser;
        [self.sendTcpSocket disconnect];
    }
    self.sendTcpSocket = nil;
    [BlueToothDataManager shareManager].isTcpConnected = NO;
}

- (void)connectingBLEAction {
    //发送数据
    [self sendMsgWithMessage:self.tcpPacketStr];
}

#pragma mark - tcp相关
- (void)creatAsocketTcp {
    // 1. 创建一个 udp socket用来和服务端进行通讯
    if (!self.sendTcpSocket) {
        NSLog(@"首次创建tcpSocket");
        dispatch_queue_t dQueue = dispatch_queue_create("client tdp socket", NULL);
        [UNPushKitMessageManager shareManager].isTcpConnecting = NO;
        self.sendTcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dQueue socketQueue:nil];
        [self.sendTcpSocket setPreferIPv4OverIPv6:NO];
        [self reConnectTcp];
    }else{
        if (!self.sendTcpSocket.isConnected) {
            [BlueToothDataManager shareManager].isTcpConnected = NO;
            [UNPushKitMessageManager shareManager].isSendTcpString = NO;
            [self reConnectTcp];
        }else{
            if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
                if (self.sendTcpSocket.isConnected) {
                    NSLog(@"tcp pushkit数据---%@",[UNPushKitMessageManager shareManager].tcpStringWithPushKit);
                    if ([UNPushKitMessageManager shareManager].tcpStringWithPushKit) {
                        self.communicateID = @"00000000";
//                        [BlueToothDataManager shareManager].isTcpConnected = YES;
                        // 等待数据来啊
                        [self.sendTcpSocket readDataWithTimeout:-1 tag:201];
                        //发送数据
                        [self setUpTcppacketFromPushKit];
                        NSLog(@"最终发送给tcp的pushkit数据 -- %@", [UNPushKitMessageManager shareManager].tcpPacketStrWithPushKit);
                        [UNPushKitMessageManager shareManager].isSendTcpString = YES;
                    }
                }else{
                    [UNPushKitMessageManager shareManager].isSendTcpString = NO;
                    [self reConnectTcp];
                }
            }else{
                if (![BlueToothDataManager shareManager].isReseted) {
                    NSLog(@"tcp数据---%@", self.tcpPacketStr);
                    //发送数据
                    if (self.tcpPacketStr) {
                        self.communicateID = @"00000000";
//                        [BlueToothDataManager shareManager].isTcpConnected = YES;
                        // 等待数据来啊
                        [self.sendTcpSocket readDataWithTimeout:-1 tag:200];
                        NSLog(@"最终发送给tcp的数据 -- %@", self.tcpPacketStr);
                        [self sendMsgWithMessage:self.tcpPacketStr];
                    }
                    
                }
            }
        }
    }
}

- (void)receiveTcpPacket:(NSNotification *)sender {
//    NSLog(@"app里面收到数据了 -- %@", sender.object);
    NSString *packteStr = [NSString stringWithFormat:@"%@", sender.object];
    NSString *packetLengthHex = [self hexNewStringFromString:[NSString stringWithFormat:@"%lu", packteStr.length/2]];
    NSLog(@"数据包长度为 -- %lu  数据包长度转换成十六进制 -- %@", packteStr.length/2, packetLengthHex);
    self.packetFinalHex = [NSString stringWithFormat:@"c7%@%@", packetLengthHex, packteStr];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"downElectic" object:@"downElectic"];//发送对卡断电通知
}

- (void)receiveTcpIccidAndImsi:(NSNotification *)sender {
//    NSLog(@"app里面收到iccid和imsi -- %@", sender.object);
    NSString *iccidStr = [sender.object substringWithRange:NSMakeRange(6, 20)];
    [UNPushKitMessageManager shareManager].iccidString = [[iccidStr copy] lowercaseString];
    NSString *iccidHex = [self hexStringFromString:iccidStr];
    NSString *iccidLengthHex = [self hexNewStringFromString:[NSString stringWithFormat:@"%ld", iccidHex.length/2]];
//    NSLog(@"iccidStr -- %@  length -- %@", iccidHex, iccidLengthHex);
    self.iccidTotalHex = [NSString stringWithFormat:@"be%@%@", iccidLengthHex, iccidHex];
    NSString *imsiStr;
    NSString *checkStr;
    if ([NSString stringWithFormat:@"%@", sender.object].length >= 47) {
        imsiStr = [sender.object substringWithRange:NSMakeRange(32, 15)];
        NSString *imsiHex = [self hexStringFromString:imsiStr];
        NSString *imsiLengthHex = [self hexNewStringFromString:[NSString stringWithFormat:@"%ld", imsiHex.length/2]];
        //    NSLog(@"imsiStr -- %@  length -- %@", imsiHex, imsiLengthHex);
        self.imsiTotalHex = [NSString stringWithFormat:@"bf%@%@", imsiLengthHex, imsiHex];
    }
    if (imsiStr.length >= 5) {
        checkStr = [imsiStr substringWithRange:NSMakeRange(0, 5)];
    } else {
        NSLog(@"imsi前面的数据不对");
    }
    if ([checkStr isEqualToString:@"46000"] || [checkStr isEqualToString:@"46001"] || [checkStr isEqualToString:@"46002"] || [checkStr isEqualToString:@"46003"] || [checkStr isEqualToString:@"46007"]) {//因为移动网络编号46000下的IMSI已经用完，所以虚拟了一个46002编号，134/159号段使用了此编号
        [self groupPacket];
    } else {
        NSLog(@"号码有问题");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [BlueToothDataManager shareManager].isBeingRegisting = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cardNumberNotTrue" object:HOMESTATUETITLE_NOSIGNAL];
            [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"卡注册失败") message:INTERNATIONALSTRING(@"您的电话卡可能出问题了，请核查号码是否能正常使用") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
        });
    }
}

- (void)receiveTcpLength:(NSNotification *)sender {
//    NSLog(@"app里面收到数据包压缩前长度 -- %@", sender.object);
    NSString *totalLengthHex = [self hexNewStringFromString:sender.object];
    NSString *lengthHex = [self hexNewStringFromString:[NSString stringWithFormat:@"%lu", totalLengthHex.length/2]];
    self.packetTotalLengthHex = [NSString stringWithFormat:@"c6%@%@", lengthHex, totalLengthHex];
//    NSLog(@"压缩前长度转换成十六进制 -- %@", self.packetTotalLengthHex);
}

#pragma mark 组合数据包
- (void)groupPacket {
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    NSString *token;
    if (userdata) {
        token = userdata[@"Token"];
    }
    
    NSString *ascHex = [self hexStringFromString:token];
//    NSLog(@"转换前：%@\n 转换后：%@\n 转换后的长度：%lu", token, ascHex, (unsigned long)ascHex.length/2);
    NSString *lengthHex = [self hexNewStringFromString:[NSString stringWithFormat:@"%zd", ascHex.length/2]];
//    NSLog(@"长度为 -- %@", lengthHex);
    NSString *tokenHex = [NSString stringWithFormat:@"78%@%@", lengthHex, ascHex];
//    NSLog(@"tokenHex -- %@", tokenHex);
    
    NSString *tempString = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@", TCPGOIP, TCPLIFETIME, TCPCHECKPREREAD, tokenHex, TCPCONNECT, TCPUUWIFI, TCPSLOT, TCPIMEI, TCPMODTYPE, TCPMODVER, TCPSIMLOCAL, self.iccidTotalHex, self.imsiTotalHex, TCPSIMNUMBER, TCPSIMBALANCE, self.packetTotalLengthHex, self.packetFinalHex, TCPVERSIONTYPE, [UNPushKitMessageManager shareManager].pushKitTokenString];
    NSString *tempHex = [self hexTLVLength:[NSString stringWithFormat:@"%zd", tempString.length/2]];
//    NSLog(@"最终发送出去的数据包长度为 ---> %lu\n 转换之后的十六进制数 ---> %@", tempString.length/2, tempHex);
    self.tcpPacketStr = [NSString stringWithFormat:@"%@%@0001%@%@", TCPFIRSTSUBNOT, TCPCOMMUNICATEID, tempHex, tempString];
    
    NSDictionary *simData = @{
                              @"iccidTotalHex" : self.iccidTotalHex,
                              @"imsiTotalHex" : self.imsiTotalHex,
                              @"packetTotalLengthHex" : self.packetTotalLengthHex,
                              @"packetFinalHex" : self.packetFinalHex,
                              };
    [[NSUserDefaults standardUserDefaults] setObject:simData forKey:[[UNPushKitMessageManager shareManager].iccidString lowercaseString]];
    
    //创建tcp
    [self creatAsocketTcp];
}

#pragma mark pushkit下接收需要发送数据并创建tcp
- (void)receiveTcpDataFromPushKit:(NSNotification *)noti
{
    NSString *tcpString = noti.userInfo[@"tcpString"];
    NSLog(@"pushkit下接收需要发送数据并创建tcp--%@",tcpString);
    if (tcpString) {
        [UNPushKitMessageManager shareManager].tcpStringWithPushKit = tcpString;
    }
    [self creatAsocketTcp];
}

#pragma mark pushkit下发送tcp数据
- (void)setUpTcppacketFromPushKit
{
    //    NSString *tempString = self.tcpStringWithPushKit;
    //    NSString *tempHex = [self hexTLVLength:[NSString stringWithFormat:@"%lu", tempString.length/2]];
    //    //    NSLog(@"最终发送出去的数据包长度为 ---> %lu\n 转换之后的十六进制数 ---> %@", tempString.length/2, tempHex);
    //    self.tcpPacketStr = [NSString stringWithFormat:@"%@%@0001%@%@", TCPFIRSTSUBNOT, TCPCOMMUNICATEID, tempHex, tempString];
    //    [self sendMsgWithMessage:self.tcpPacketStr];
    
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    NSString *token;
    if (userdata) {
        token = userdata[@"Token"];
    }
    
    NSString *ascHex = [self hexStringFromString:token];
    NSString *lengthHex = [self hexNewStringFromString:[NSString stringWithFormat:@"%lu", ascHex.length/2]];
    NSString *tokenHex = [NSString stringWithFormat:@"78%@%@", lengthHex, ascHex];
    
    NSLog(@"self.tlvFirstStr -- -- %@", self.tlvFirstStr);
    
    //判断是否有数据为空
    if (!self.tlvFirstStr || ![UNPushKitMessageManager shareManager].tcpStringWithPushKit) {
        return;
    }
    
    NSString *packteStr = [NSString stringWithFormat:@"%@", [UNPushKitMessageManager shareManager].tcpStringWithPushKit];
    NSString *packetLengthHex = [self hexNewStringFromString:[NSString stringWithFormat:@"%lu", packteStr.length/2]];
    NSString *newStr = [NSString stringWithFormat:@"%@%@%@",self.tlvFirstStr, packetLengthHex, packteStr];
    
    NSString *appendString = [NSString stringWithFormat:@"%@%@", newStr, tokenHex];
    
    NSString *countLengthStr = [appendString substringFromIndex:24];
    
    NSLog(@"替换后面的文字之后 -- %@", appendString);
    NSString *countLengthHex = [self hexFinalTLVLength:[NSString stringWithFormat:@"%lu", countLengthStr.length/2]];
    NSString *tcpString = [appendString stringByReplacingCharactersInRange:NSMakeRange(20, 4) withString:countLengthHex];
    NSLog(@"发送给服务器的数据 -- %@", tcpString);
    [UNPushKitMessageManager shareManager].tcpPacketStrWithPushKit = tcpString;
    [UNCreatLocalNoti createLocalNotiMessageString:[NSString stringWithFormat:@"发送给服务器的数据--%@", tcpString]];
    [self sendMsgWithMessage:tcpString];
    
    if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
        NSLog(@"删除前当前队列消息====%@", [UNPushKitMessageManager shareManager].pushKitMsgQueue);
        NSLog(@"需要删除的队列消息====%@", [UNPushKitMessageManager shareManager].receivePushKitDataFormServices);
        
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
    NSLog(@"didConnectToHost");
    self.sendTcpSocket.userData = nil;
    if ([UNPushKitMessageManager shareManager].tcpReconnectTimer) {
        [[UNPushKitMessageManager shareManager].tcpReconnectTimer invalidate];
        [UNPushKitMessageManager shareManager].tcpReconnectTimer = nil;
    }
    
    [UNPushKitMessageManager shareManager].isTcpConnecting = NO;
    if ([UNPushKitMessageManager shareManager].pushKitMsgType == PushKitMessageTypePingPacket) {
        if ([UNPushKitMessageManager shareManager].receivePushKitDataFormServices) {
            [BlueToothDataManager shareManager].isTcpConnected = YES;
            [sock readDataWithTimeout:-1 tag:201];
            NSLog(@"发送心跳包数据");
            [self sendPingPacketWithPushKitMessage:[UNPushKitMessageManager shareManager].receivePushKitDataFormServices[@"dataString"]];
        }
    }else if ([UNPushKitMessageManager shareManager].pushKitMsgType == PushKitMessageTypeSimDisconnect){
        if (![BlueToothDataManager shareManager].isReseted) {
            NSLog(@"tcp数据----%@", self.tcpPacketStr);
            if (self.tcpPacketStr) {
                self.communicateID = @"00000000";
                NSLog(@"tcp连接成功");
                [BlueToothDataManager shareManager].isTcpConnected = YES;
                // 等待数据来啊
                [sock readDataWithTimeout:-1 tag:200];
                NSLog(@"最终发送给tcp的数据 -- %@", self.tcpPacketStr);
                //发送数据
                [self sendMsgWithMessage:self.tcpPacketStr];
                
                NSLog(@"删除前当前队列消息====%@", [UNPushKitMessageManager shareManager].pushKitMsgQueue);
                NSLog(@"需要删除的队列消息====%@", [UNPushKitMessageManager shareManager].receivePushKitDataFormServices);
                [self checkPushKitMessage:[UNPushKitMessageManager shareManager].receivePushKitDataFormServices];
                [UNPushKitMessageManager shareManager].pushKitMsgType = PushKitMessageTypeNone;
            }
        }
    }else if([UNPushKitMessageManager shareManager].pushKitMsgType == PushKitMessageTypeAuthSimData){
        if ([UNPushKitMessageManager shareManager].PushKitAuthDataType == 1) {
            NSLog(@"PushKitAuthDataType1");
            [BlueToothDataManager shareManager].isTcpConnected = YES;
            [sock readDataWithTimeout:-1 tag:201];
            [self checkPacketDetailWithStringFromPushKit:[UNPushKitMessageManager shareManager].receivePushKitDataFormServices];
        }else if([UNPushKitMessageManager shareManager].PushKitAuthDataType == 2){
            NSLog(@"PushKitAuthDataType2");
            if (![UNPushKitMessageManager shareManager].isSendTcpString) {
                NSLog(@"pushkit--tcp数据----%@", [UNPushKitMessageManager shareManager].tcpStringWithPushKit);
                if ([UNPushKitMessageManager shareManager].tcpStringWithPushKit) {
                    self.communicateID = @"00000000";
                    NSLog(@"PushKit--tcp连接成功");
                    [BlueToothDataManager shareManager].isTcpConnected = YES;
                    [sock readDataWithTimeout:-1 tag:201];
                    //发送数据
                    [self setUpTcppacketFromPushKit];
                    NSLog(@"PushKit--最终发送给tcp的数据 -- %@", [UNPushKitMessageManager shareManager].tcpPacketStrWithPushKit);
                    [UNPushKitMessageManager shareManager].isSendTcpString = YES;
                }
            }
        }else{
            NSLog(@"PushKitAuthDataTypeNone");
            if (![UNPushKitMessageManager shareManager].isSendTcpString) {
                NSLog(@"pushkit--tcp数据----%@", [UNPushKitMessageManager shareManager].tcpStringWithPushKit);
                if ([UNPushKitMessageManager shareManager].tcpStringWithPushKit) {
                    self.communicateID = @"00000000";
                    NSLog(@"PushKit--tcp连接成功");
                    [BlueToothDataManager shareManager].isTcpConnected = YES;
                    [sock readDataWithTimeout:-1 tag:201];
                    //发送数据
                    [self setUpTcppacketFromPushKit];
                    NSLog(@"PushKit--最终发送给tcp的数据 -- %@", [UNPushKitMessageManager shareManager].tcpPacketStrWithPushKit);
                    [UNPushKitMessageManager shareManager].isSendTcpString = YES;
                }
            }
        }
    }else{
        if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
            if (![UNPushKitMessageManager shareManager].isSendTcpString) {
                NSLog(@"pushkit--tcp数据----%@", [UNPushKitMessageManager shareManager].tcpStringWithPushKit);
                if ([UNPushKitMessageManager shareManager].tcpStringWithPushKit) {
                    self.communicateID = @"00000000";
                    NSLog(@"PushKit--tcp连接成功");
                    [BlueToothDataManager shareManager].isTcpConnected = YES;
                    [sock readDataWithTimeout:-1 tag:201];
                    //发送数据
                    [self setUpTcppacketFromPushKit];
                    NSLog(@"PushKit--最终发送给tcp的数据 -- %@", [UNPushKitMessageManager shareManager].tcpPacketStrWithPushKit);
                    [UNPushKitMessageManager shareManager].isSendTcpString = YES;
                }
            }
        }else{
            if (![BlueToothDataManager shareManager].isReseted) {
                NSLog(@"tcp数据----%@", self.tcpPacketStr);
                if (self.tcpPacketStr) {
                    self.communicateID = @"00000000";
                    NSLog(@"tcp连接成功");
                    [BlueToothDataManager shareManager].isTcpConnected = YES;
                    // 等待数据来啊
                    [sock readDataWithTimeout:-1 tag:200];
                    NSLog(@"最终发送给tcp的数据 -- %@", self.tcpPacketStr);
                    //发送数据
                    [self sendMsgWithMessage:self.tcpPacketStr];
                }
            }
        }
    }
}


// 如果对象关闭了 这里也会调用
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"tcp连接失败 %@", err);
    if ([UNNetWorkStatuManager shareManager].currentStatu == NotReachable) {
        [BlueToothDataManager shareManager].isTcpConnected = NO;
        self.sendTcpSocket.userData = SocketCloseByNet;
        NSLog(@"无网络");
    }else{
        if (err) {
            NSLog(@"连接失败");
            if(err.code == 7){
                self.sendTcpSocket.userData = SocketCloseByServer;
                [BlueToothDataManager shareManager].isTcpConnected = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (![UNPushKitMessageManager shareManager].tcpReconnectTimer) {
                        [UNPushKitMessageManager shareManager].tcpSocketTimerIndex = 0;
                        [UNPushKitMessageManager shareManager].tcpReconnectTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tcpReconnectTimerAction) userInfo:nil repeats:YES];
                        [[UNPushKitMessageManager shareManager].tcpReconnectTimer fire];
                    }
                });
            }else if (err.code == 57 || err.code == 32 || err.code == 51 || err.code == 1) {
                if ([UNPushKitMessageManager shareManager].tcpReconnectTimer) {
                    [[UNPushKitMessageManager shareManager].tcpReconnectTimer invalidate];
                    [UNPushKitMessageManager shareManager].tcpReconnectTimer = nil;
                }
                self.sendTcpSocket.userData = SocketCloseByNet;
                [self closeTCP];
                if ([UNPushKitMessageManager shareManager].pushKitMsgType == PushKitMessageTypeNone) {
                    [UNPushKitMessageManager shareManager].isSendTcpString = NO;
                }
                [self creatAsocketTcp];
            } else{
                NSLog(@"其他原因断开");
                if ([self.sendTcpSocket.userData isEqualToString:SocketCloseByNet]) {
                    if ([UNPushKitMessageManager shareManager].tcpReconnectTimer) {
                        [[UNPushKitMessageManager shareManager].tcpReconnectTimer invalidate];
                        [UNPushKitMessageManager shareManager].tcpReconnectTimer = nil;
                    }
                    [self closeTCP];
                    if ([UNPushKitMessageManager shareManager].pushKitMsgType == PushKitMessageTypeNone) {
                        [UNPushKitMessageManager shareManager].isSendTcpString = NO;
                    }
                    [self creatAsocketTcp];
                }else if ([self.sendTcpSocket.userData isEqualToString:SocketCloseByServer]){
//                    self.sendTcpSocket.userData = SocketCloseByServer;
                    [BlueToothDataManager shareManager].isTcpConnected = NO;
                    if (![UNPushKitMessageManager shareManager].tcpReconnectTimer) {
                        [UNPushKitMessageManager shareManager].tcpSocketTimerIndex = 0;
                        [UNPushKitMessageManager shareManager].tcpReconnectTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tcpReconnectTimerAction) userInfo:nil repeats:YES];
                        [[UNPushKitMessageManager shareManager].tcpReconnectTimer fire];
                    }
                }else{
                    NSLog(@"不重连");
                }
            }
        }else{
            NSLog(@"正常断开");
        }
    }
    
    
//    [BlueToothDataManager shareManager].isTcpConnected = NO;
//    if (![UNPushKitMessageManager shareManager].tcpReconnectTimer) {
//        [UNPushKitMessageManager shareManager].tcpSocketTimerIndex = 0;
//        [UNPushKitMessageManager shareManager].tcpReconnectTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tcpReconnectTimerAction) userInfo:nil repeats:YES];
//    }
    
//    if (![UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
//        [self reConnectTcp];
//    }
}

- (void)tcpReconnectTimerAction
{
    NSLog(@"重连tcp定时器");
    [UNPushKitMessageManager shareManager].tcpSocketTimerIndex++;
    if ([UNPushKitMessageManager shareManager].tcpSocketTimerIndex >= 5) {
        [UNPushKitMessageManager shareManager].tcpSocketTimerIndex = 0;
        if (!self.sendTcpSocket.isConnected) {
            NSLog(@"重连TCP");
            [UNPushKitMessageManager shareManager].isTcpConnecting = NO;
            [BlueToothDataManager shareManager].isTcpConnected = NO;
            if (![UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
                [self reConnectTcp];
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
    NSLog(@"didWriteDataWithTag--tcp消息发送成功");
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (tag == 200) {
        [sock readDataWithTimeout:-1 tag:200];
        
        NSString *ip = [sock connectedHost];
        uint16_t port = [sock connectedPort];
        //    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"接收到服务器返回的数据 tcp [%@:%d] %@", ip, port, data);
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
        [sock readDataWithTimeout:-1 tag:201];
        NSString *ip = [sock connectedHost];
        uint16_t port = [sock connectedPort];
        NSLog(@"接收到服务器返回的数据 tcp [%@:%d] %@", ip, port, data);
        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            if (!self.timer) {
//                //开始计时
//                self.sec = 0;
//                self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
//                //如果不添加下面这条语句，会阻塞定时器的调用
//                [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:UITrackingRunLoopMode];
//            }
//        });
    }
//    [sock readDataWithTimeout:-1 tag:200];
//    if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
//        NSString *ip = [sock connectedHost];
//        uint16_t port = [sock connectedPort];
//        //    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        NSLog(@"接收到服务器返回的数据 tcp [%@:%d] %@", ip, port, data);
//        //        [BlueToothDataManager shareManager].isBeingRegisting = NO;
//        //        [BlueToothDataManager shareManager].stepNumber = @"0";
//        //        [BlueToothDataManager shareManager].isRegisted = YES;
//        //        [BlueToothDataManager shareManager].isConnected = YES;
//        //        [BlueToothDataManager shareManager].isTcpConnected = YES;
//        //        [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:HOMESTATUETITLE_SIGNALSTRONG];
//        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            if (!self.timer) {
//                //开始计时
//                self.sec = 0;
//                self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
//                //如果不添加下面这条语句，会阻塞定时器的调用
//                [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:UITrackingRunLoopMode];
//            }
//        });
//    }else{
//        NSString *ip = [sock connectedHost];
//        uint16_t port = [sock connectedPort];
//        //    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        NSLog(@"接收到服务器返回的数据 tcp [%@:%d] %@", ip, port, data);
//        NSString *tempStr = [NSString stringWithFormat:@"%@", data];
//        if ([tempStr containsString:@"<"]) {
//            tempStr = [tempStr stringByReplacingOccurrencesOfString:@"<" withString:@""];
//        }
//        if ([tempStr containsString:@">"]) {
//            tempStr = [tempStr stringByReplacingOccurrencesOfString:@">" withString:@""];
//        }
//        if ([tempStr containsString:@" "]) {
//            tempStr = [tempStr stringByReplacingOccurrencesOfString:@" " withString:@""];
//        }
//
//        [self checkManyPacketString:tempStr];
//    }
}

- (void)checkManyPacketString:(NSString *)tempStr
{
    NSLog(@"处理数据包");
    if (tempStr.length < 24) {
        NSLog(@"数据包异常----%@", tempStr);
        return;
    }
    NSString *lengthStr = [tempStr substringWithRange:NSMakeRange(20, 4)];
    NSInteger leng = strtoul([lengthStr UTF8String], 0, 16);
    if (tempStr.length>= 24 + leng * 2) {
        NSString *currentStr = [tempStr substringWithRange:NSMakeRange(0, 24 + leng*2)];
        NSLog(@"当前数据包---%@", currentStr);
        [self checkPacketDetailWithString:currentStr];
        if (tempStr.length > 24 + leng * 2) {
            NSLog(@"粘包处理");
            [self checkManyPacketString:[tempStr substringFromIndex:(24 + leng * 2)]];
        }else{
            return;
        }
    }
}

#pragma mark 处理数据包
- (void)checkPacketDetailWithString:(NSString *)string {
    if (![self.communicateID isEqualToString:@"00000000"] && ![self.communicateID isEqualToString:[string substringWithRange:NSMakeRange(8, 8)]]) {
        NSLog(@"忽略的包 -- %@", string);
        return;
    }
    NSString *classStr = [string substringWithRange:NSMakeRange(4, 2)];
    NSString *errorStr = [string substringWithRange:NSMakeRange(6, 2)];
    if ([classStr isEqualToString:@"84"]) {
        if (![errorStr isEqualToString:@"00"]) {
            NSLog(@"电话端口错误");
            return;
        }
        
        NSLog(@"建立连接");
        self.communicateID = [string substringWithRange:NSMakeRange(8, 8)];
        NSLog(@"会话id -- %@", self.communicateID);
        
        //获取电话端口号
        if ([string length] <= 44) {
            NSLog(@"获取电话端口出问题了");
            return;
        }
        NSString *callPortStr = [string substringFromIndex:44];
        NSString *newString = [NSString stringFromHexString:callPortStr];
        NSLog(@"截取到的电话端口 -- %@", newString);
        if ([newString isEqualToString:@"n Failed"]) {
            NSLog(@"截取电话端口出错 -- %@", newString);
            return;
        }else if ([newString isEqualToString:@"Timeout"]) {
            NSLog(@"截取电话端口出错 -- %@", newString);
            return;
        }
        NSString *cutStr = [newString substringFromIndex:[newString rangeOfString:@"_"].location+1];
        cutStr = [cutStr stringByReplacingOccurrencesOfString:@"." withString:@""];
        NSLog(@"最终的电话端口 -- %@", cutStr);
        [VSWManager shareManager].callPort = cutStr;
        [[NSUserDefaults standardUserDefaults] setObject:cutStr forKey:@"VSWCallPort"];
        //保存端口到本地
//        NSDictionary *userData = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
//        if (userData) {
//            NSString *userPhone = userData[@"Tel"];
//            if (userPhone) {
//                NSString *portStr = [NSString stringWithFormat:@"%@%@", @"VSWCallPort", userPhone];
//                NSString *isRegister = [NSString stringWithFormat:@"%@%@", @"IsRegisterPhoneCard", userPhone];
//                [[NSUserDefaults standardUserDefaults] setObject:cutStr forKey:portStr];
//                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:isRegister];
//            }
//        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!self.timer) {
                //开始计时
                self.sec = 0;
                self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
                //如果不添加下面这条语句，会阻塞定时器的调用
                [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:UITrackingRunLoopMode];
            }
        });
    }else if ([classStr isEqualToString:@"05"]) {
        NSLog(@"sim卡注册成功");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [BlueToothDataManager shareManager].isBeingRegisting = NO;
            [BlueToothDataManager shareManager].stepNumber = @"0";
            [BlueToothDataManager shareManager].isRegisted = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:HOMESTATUETITLE_SIGNALSTRONG];
        });
    }else if ([classStr isEqualToString:@"0f"]) {
        NSLog(@"sim卡断开连接");
        [BlueToothDataManager shareManager].isBeingRegisting = NO;
        [BlueToothDataManager shareManager].stepNumber = @"0";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [BlueToothDataManager shareManager].isRegisted = NO;
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:HOMESTATUETITLE_NOSIGNAL];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ([BlueToothDataManager shareManager].isConnected) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:HOMESTATUETITLE_REGISTING];
                    [BlueToothDataManager shareManager].isBeingRegisting = YES;
                    self.communicateID = @"00000000";
                    //发送数据
                    [self sendMsgWithMessage:self.tcpPacketStr];
                }else{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:HOMESTATUETITLE_NOSIGNAL];
                }
            });
        });
    }else if ([classStr isEqualToString:@"10"]) {
        NSLog(@"透明传输SIM交互命令");
        NSInteger leng;
        NSString *TLVdetail;
        NSString *tempStr;
        string = [string stringByReplacingCharactersInRange:NSMakeRange(4, 2) withString:@"90"];
        self.tlvFirstStr = [string substringWithRange:NSMakeRange(0, 32)];
        NSLog(@"截取前面的数据 -- %@", self.tlvFirstStr);
        if ([[string substringWithRange:NSMakeRange(28, 2)] isEqualToString:@"01"]) {
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
                NSLog(@"两位leng = %zd  需要替换的字符串 -- %@", leng, TLVdetail);
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
                NSLog(@"四位leng = %zd  需要替换的字符串 -- %@", leng, TLVdetail);
            }
            tempStr = TLVdetail;
            TLVdetail = @"000100163b9f94801fc78031e073fe211b573786609b30800119";
            for (int i = [[NSString stringWithFormat:@"%lu", TLVdetail.length] intValue]; i < leng * 2; i++) {
                TLVdetail = [TLVdetail stringByAppendingString:@"0"];
            }
            string = [string stringByReplacingOccurrencesOfString:tempStr withString:TLVdetail];
            NSLog(@"替换之后的字符串 -- %@", string);
            [self sendMsgWithMessage:string];

        } else if ([[string substringWithRange:NSMakeRange(28, 2)] isEqualToString:@"00"]) {
            //00
            NSLog(@"这是00的执行方法");
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"updataElectic" object:@"updataElectic"];//发送对卡上电通知
            NSString *lengthStr = [string substringWithRange:NSMakeRange(32, 2)];
            leng = strtoul([lengthStr UTF8String], 0, 16);
            TLVdetail = [string substringWithRange:NSMakeRange(34, leng * 2)];
            NSLog(@"两位leng = %zd  需要传入的字符串 -- %@", leng, TLVdetail);
            
            if ([UNPushKitMessageManager shareManager].isNeedRegister) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"updataElectic" object:@"updataElectic"];//发送对卡上电通知
                //发送给sdk
                [[VSWManager shareManager] sendMessageToDev:[NSString stringWithFormat:@"%zd", leng] pdata:TLVdetail];
            }else{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"AnalysisAuthData" object:TLVdetail];
            }

            //发送给sdk
//            [[VSWManager shareManager] sendMessageToDev:[NSString stringWithFormat:@"%zd", leng] pdata:TLVdetail];
        }
    } else {
        NSLog(@"这是什么鬼");
    }
}

- (void)checkPacketDetailWithStringFromPushKit:(NSDictionary *)dictString
{
    NSLog(@"PushKit数据包消息-----%@",dictString);
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
        NSLog(@"两位leng = %zd  需要替换的字符串 -- %@", leng, TLVdetail);
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
        NSLog(@"四位leng = %zd  需要替换的字符串 -- %@", leng, TLVdetail);
    }
    tempStr = TLVdetail;
    TLVdetail = @"000100163b9f94801fc78031e073fe211b573786609b30800119";
    for (int i = [[NSString stringWithFormat:@"%lu", TLVdetail.length] intValue]; i < leng * 2; i++) {
        TLVdetail = [TLVdetail stringByAppendingString:@"0"];
    }
    string = [string stringByReplacingOccurrencesOfString:tempStr withString:TLVdetail];
    NSLog(@"替换之后的字符串 -- %@", string);
    
//    if (!self.sendTcpSocket) {
//        [self creatAsocketTcp];
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [self sendMsgWithMessage:string];
//        });
//    }else{
//        if (!self.sendTcpSocket.isConnected) {
//            [self reConnectTcp];
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [self sendMsgWithMessage:string];
//            });
//        }else{
//            [self sendMsgWithMessage:string];
//        }
//    }
    
    [UNCreatLocalNoti createLocalNotiMessageString:[NSString stringWithFormat:@"发送给服务器的数据--%@", string]];
    [self sendMsgWithMessage:string];
    if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
        NSLog(@"删除前当前队列消息====%@", [UNPushKitMessageManager shareManager].pushKitMsgQueue);
        NSLog(@"需要删除的队列消息====%@", [UNPushKitMessageManager shareManager].receivePushKitDataFormServices);
        [self checkPushKitMessage:[UNPushKitMessageManager shareManager].receivePushKitDataFormServices];
    }
}

- (void)timerAction {
    if (self.sec == 59) {
        self.sec = 0;
        NSString *num = [NSString stringWithFormat:@"%d", self.currentNumber];
        NSString *str = [self hexFinalTLVLength:num];
        //108a050020fdef90000800060101006501b4
        //发送心跳包
        NSString *sendStr = [NSString stringWithFormat:@"108a0500%@%@00060101006501b4", self.communicateID, str];
        NSLog(@"发送心跳包 -- %@", sendStr);
        [self sendMsgWithMessage:sendStr];
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"sendHeartPacket" object:@"sendHeartPacket"];
        self.currentNumber++;
    }
    self.sec++;
//    NSLog(@"sec == %d", self.sec);
}

- (void)receiveNewDataStr:(NSNotification *)sender {
    NSLog(@"self.tlvFirstStr -- -- %@", self.tlvFirstStr);
    NSString *packteStr = [NSString stringWithFormat:@"%@", sender.object];
    NSString *packetLengthHex = [self hexNewStringFromString:[NSString stringWithFormat:@"%lu", packteStr.length/2]];
    NSString *newStr = [NSString stringWithFormat:@"%@%@%@",self.tlvFirstStr, packetLengthHex, packteStr];
    NSString *countLengthStr = [newStr substringFromIndex:24];
    NSLog(@"替换后面的文字之后 -- %@", newStr);
//    NSLog(@"jiequzhihoudes  -- %@", countLengthStr);
    NSString *countLengthHex = [self hexFinalTLVLength:[NSString stringWithFormat:@"%lu", countLengthStr.length/2]];
//    NSString *finalString = [newStr stringByReplacingOccurrencesOfString:[newStr substringWithRange:NSMakeRange(20, 4)] withString:countLengthHex];
    NSString *finalString = [newStr stringByReplacingCharactersInRange:NSMakeRange(20, 4) withString:countLengthHex];
    NSLog(@"发送给服务器的数据 -- %@", finalString);
    [self sendMsgWithMessage:finalString];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"downElectic" object:@"downElectic"];//发送对卡断电通知
}

- (void)sendMsgWithMessage:(NSString *)message {
    if (message) {
        // 写这里代码
        NSString *s = message;
        NSData *data = [self convertHexStrToData:s];
        NSLog(@"sendMsgWithMessage发送给服务端的数据 -- %@", data);
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
    NSLog(@"接收到%@的消息:%@",address,data);//自行转换格式吧
    NSString *receivedMessage = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"获取的端口号 -> %d", self.prot);
    self.currentPacketNumber = [receivedMessage substringWithRange:NSMakeRange(0, 6)];
    NSString *str = [self.currentPacketNumber substringWithRange:NSMakeRange(3, 3)];
    [BlueToothDataManager shareManager].isBeingRegisting = YES;
    //发送当前编号
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeStatue" object:str];
    [BlueToothDataManager shareManager].stepNumber = str;
    if (![BlueToothDataManager shareManager].isRegisted) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:HOMESTATUETITLE_REGISTING];
    }
    NSLog(@"转换之后的内容：%@", receivedMessage);
    if ([receivedMessage isEqualToString:@"200001:0x0000"]) {
        if (![UNPushKitMessageManager shareManager].isUdpSendFristMsg) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"upLoadToCard" object:@"upLoadToCard"];
            [UNPushKitMessageManager shareManager].isUdpSendFristMsg = YES;
        }
        if ([BlueToothDataManager shareManager].isNeedToResert) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:HOMESTATUETITLE_REGISTING];
        }
    } else {
        [UNPushKitMessageManager shareManager].isUdpSendFristMsg = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"receiveNewMessageFromBLE" object:[receivedMessage substringFromIndex:7]];
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"发送信息成功");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@"发送信息失败");
}

- (void)sendNewMessage:(NSNotification *)sender {
    NSString *dataStr = [NSString stringWithFormat:@"%@:%@",self.currentPacketNumber, sender.object];
//    NSLog(@"最终发送的数据 -> %@", dataStr);
    NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"最终发送的数据包 : %@", data);
    
    //开始发送
    //改函数只是启动一次发送 它本身不进行数据的发送, 而是让后台的线程慢慢的发送 也就是说这个函数调用完成后,数据并没有立刻发送,异步发送
    [_udpSocket sendData:data toHost:SERVERIP port:self.prot withTimeout:-1 tag:0];
}

-(void)log
{
//    NSLog(@"执行");
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
    NSString *strGetLogin = [apiGetLogin stringByAppendingString:[self getParamStr]];
    
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    if (userdata) {
        strGetLogin = [NSString stringWithFormat:@"%@&TOKEN=%@",strGetLogin,[userdata objectForKey:@"Token"]];
        //
    }else{
        [self loadLoginViewController];
    }
    //    HUDNoStop1(@"正在登录...")
    if (strGetLogin) {
        [SSNetworkRequest getRequest:strGetLogin params:nil success:^(id resonseObj){
            
            if (resonseObj) {
                if ([[resonseObj objectForKey:@"status"] intValue]==1) {
                    //                NSString *alias = [NSString stringWithFormat:@"aixiaoqi%@", userdata[@"Tel"]];
                    //更新别名为token
                    NSString *alias = [NSString stringWithFormat:@"aixiaoqi%@", userdata[@"Token"]];
                    [JPUSHService setTags:nil alias:alias fetchCompletionHandle:^(int iResCode, NSSet *iTags, NSString *iAlias) {
                        NSLog(@"极光别名：irescode = %d\n itags = %@\n ialias = %@", iResCode, iTags, iAlias);
                    }];
                    NSLog(@"拿到数据：%@",resonseObj);
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    if (storyboard) {
                        UIViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
                        if (mainViewController) {
                            self.window.rootViewController = mainViewController;
                        }
                    }
                    
                    //                [[UITabBar appearance] setBackgroundImage:<#(UIImage * _Nullable)#>:[UIColor blueColor]];
                }else{
                    [self loadLoginViewController];
                    //                [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"999" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
                }
            }else{
                [self loadLoginViewController];
                //            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"服务器好像有点忙，请稍后重试" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
            }
            
        }failure:^(id dataObj, NSError *error) {
            NSLog(@"登录失败：%@",[error description]);
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
        } headers:nil];

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

- (NSString *)getParamStr {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    [params setObject:@"2006808" forKey:@"partner"];
    
//    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
//    NSInteger a=[dat timeIntervalSince1970];
    //    NSString *timestemp = [NSString stringWithFormat:@"%ld", (long)a];
    NSString *timestemp = @"1471316792";
    
    [params setObject:timestemp forKey:@"expires"];
    
    timestemp = [NSString stringWithFormat:@"2006808%@BAS123!@#FD1A56K",timestemp];
    
    [params setObject:[[self md5:timestemp] uppercaseString] forKey:@"sign"];
    
    
    return [NSString stringWithFormat:@"?partner=%@&expires=%@&sign=%@",[params objectForKey:@"partner"],[params objectForKey:@"expires"],[params objectForKey:@"sign"]];
}

- (void)loadLoginViewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if (storyboard) {
        UIViewController *loginViewController = [storyboard instantiateViewControllerWithIdentifier:@"loginViewController"];
        if (loginViewController) {
            self.window.rootViewController = loginViewController;
            
            //            [self.window makeKeyAndVisible];
            
            //                        [self presentViewController:mainViewController animated:YES completion:nil];
        }
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
    NSLog(@"极光环境为：%d", !DEBUGMODE);
}

#pragma mark 收到自定义通知
- (void)networkDidReceiveMessage:(NSNotification *)notification {
    NSDictionary * userInfo = [notification userInfo];
    NSString *content = [userInfo valueForKey:@"content"];
    NSString *contentType = userInfo[@"content_type"];
    NSDictionary *extras = [userInfo valueForKey:@"extras"];
//    NSString *customizeField1 = [extras valueForKey:@"customizeField1"]; //服务端传递的Extras附加字段，key是自己定义的
    NSLog(@"收到通知：\n content - %@\n content_type - %@\n extras - %@", content, contentType, extras);
//    [self testAddNotification];
    if ([contentType isEqualToString:@"SMSReceiveNew"]) {
        //收到对方发送的短信
        NSString *name = [self checkLinkNameWithPhoneStr:extras[@"Tel"]];
        [self addNotificationWithTitle:[NSString stringWithFormat:@"%@%@%@", INTERNATIONALSTRING(@"收到"), name, INTERNATIONALSTRING(@"的短信")] body:extras[@"SMSContent"] userInfo:userInfo];
        
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReceiveNewSMSContentUpdate" object:nil];
        
    } if ([contentType isEqualToString:@"SMSSendResult"]) {
        //发送短信成功
        if ([extras[@"Status"] isEqualToString:@"1"]) {
            [self addNotificationWithTitle:INTERNATIONALSTRING(@"短信发送提醒") body:content userInfo:userInfo];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SendMessageStatuChange" object:@"MessageStatu" userInfo:userInfo];
        } else if ([extras[@"Status"] isEqualToString:@"2"]) {
            [self addNotificationWithTitle:INTERNATIONALSTRING(@"短信发送提醒") body:INTERNATIONALSTRING(@"短信发送失败！") userInfo:userInfo];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SendMessageStatuChange" object:@"MessageStatu" userInfo:userInfo];
        } else {
            NSLog(@"收到短信发送结果的推送，状态码有问题");
        }
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
    
    //每小时重复 1 次 iOS 10 以上支持
//    JPushNotificationTrigger *trigger2 = [[JPushNotificationTrigger alloc] init];
//    trigger2.timeInterval = 3600;
//    trigger2.repeat = YES;
    
    //每周一早上8：00提醒，iOS10以上支持
//    NSDateComponents *components = [[NSDateComponents alloc] init];
//    components.weekday = 2;
//    components.hour = 8;
//    JPushNotificationTrigger *trigger3 = [[JPushNotificationTrigger alloc] init];
//    trigger3.dateComponents = components;
//    trigger3.repeat = YES;
    
    //#import <CoreLocation/CoreLocation.h>
    //一到某地点提醒，iOS8以上支持
//    CLRegion *region = [[CLRegion alloc] initCircularRegionWithCenter:CLLocationCoordinate2DMake(0, 0) radius:0 identifier:@"test"];
//    JPushNotificationTrigger *trigger4 = [[JPushNotificationTrigger alloc] init];
//    trigger4.region = region;
    
    //5s后提醒，iOS10以下支持
//    JPushNotificationTrigger *trigger5 = [[JPushNotificationTrigger alloc] init];
//    trigger5.fireDate = [NSDate dateWithTimeIntervalSinceNow:5];
    
    JPushNotificationRequest *request = [[JPushNotificationRequest alloc] init];
    request.requestIdentifier = @"sampleRequest";
    request.content = content;
    request.trigger = trigger1;//trigger2;//trigger3;//trigger4;//trigger5;
    request.completionHandler = ^(id result) {
        NSLog(@"结果返回：%@", result);
    };
    [JPUSHService addNotification:request];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url{
    
    NSLog(@"url1=%@",url);
    
    return [WXApi handleOpenURL:url delegate:self];
}


/*
//返回

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    NSLog(@"URL=%@",url);
    
    
    return [WXApi handleOpenURL:url delegate:self];
    
}*/

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
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
    
    NSLog(@"后台backgroundTaskIdentifier--------  %lu",(unsigned long)backgroundTaskIdentifier);
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    [JPUSHService resetBadge];
    [application setApplicationIconBadgeNumber:0];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    //进入前台重新注册
    if (![UNPushKitMessageManager shareManager].isAlreadyInForeground) {
        if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
            [UNPushKitMessageManager shareManager].isPushKitFromAppDelegate = NO;
            NSLog(@"进入前台");
            [[UNPushKitMessageManager shareManager].pushKitMsgQueue removeAllObjects];
            [self closeTCP];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLBEStatuWithPushKit" object:nil];
        }
        [UNPushKitMessageManager shareManager].isAlreadyInForeground = YES;
    }

    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

//程序被手动杀死
- (void)applicationWillTerminate:(UIApplication *)application {
//    if (self.phoneViewController) {
//        [self.phoneViewController unregister];  //注销电话登入账号
//        NSLog(@"电话注销了");
//    }
    //发送注销电话通知
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"appIsKilled" object:@"appIsKilled"];
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    //跳转支付宝支付,处理支付结果
    //    [[AlipaySDK defaultService]processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
    //        NSLog(@"result = %@",resultDic);
    //    }];
    
    if ([url.host isEqualToString:@"safepay"]) {
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
            [self processAlipayResult:resultDic];
        }];
    }
    if ([url.host isEqualToString:@"platformapi"]){//支付宝钱包快登授权返回 authCode
        [[AlipaySDK defaultService] processAuthResult:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
            [self processAlipayResult:resultDic];
        }];
    }
    
    NSLog(@"谁家的支付回调1：%@",[url absoluteString]);
    
    return [WXApi handleOpenURL:url delegate:self];
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options {
    NSLog(@"谁家的支付回调2：%@",[url absoluteString]);
    if ([url.host isEqualToString:@"safepay"]) {
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
            [self processAlipayResult:resultDic];
            //正常的支付宝回调哦
        }];
    }
    if ([url.host isEqualToString:@"platformapi"]){//支付宝钱包快登授权返回 authCode
        [[AlipaySDK defaultService] processAuthResult:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
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
                NSLog(@"支付成功－PaySuccess，retcode = %d", resp.errCode);
                break;
                
            default:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"WeipayComplete" object:resp.errStr];
//                strMsg = [NSString stringWithFormat:@"支付结果：失败！retcode = %d, retstr = %@", resp.errCode,resp.errStr];
                NSLog(@"错误，retcode = %d, retstr = %@", resp.errCode,resp.errStr);
                break;
        }
        /*
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];*/
//        [alert release];
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
    NSLog(@"注册极光推送失败 did Fail To Register For Remote Notifications With Error: %@", error);
}

// iOS 10 Support,本地通知为notification，接收到通知
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(NSInteger))completionHandler {
    // Required
    NSDictionary * userInfo = notification.request.content.userInfo;
    if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [JPUSHService handleRemoteNotification:userInfo];
        NSString *name = [self checkLinkNameWithPhoneStr:userInfo[@"Tel"]];
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
    if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [JPUSHService handleRemoteNotification:userInfo];
    } else {
        // 点击本地通知
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"jumpToMessage" object:@"jumpToMessage"];
    completionHandler();  // 系统要求执行这个方法
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
        // Required, iOS 7 Support
    //刷新页面
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReceiveNewSMSContentUpdate" object:nil];
    
    [JPUSHService handleRemoteNotification:userInfo];
    NSString *name = [self checkLinkNameWithPhoneStr:userInfo[@"Tel"]];
    [self addNotificationWithTitle:[NSString stringWithFormat:@"%@%@%@", INTERNATIONALSTRING(@"收到"), name, INTERNATIONALSTRING(@"的短信")] body:userInfo[@"SMSContent"] userInfo:userInfo];
    
    NSLog(@" -- %@", userInfo);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
        // Required,For systems with less than or equal to iOS6
//        [JPUSHService handleRemoteNotification:userInfo];
//    application.applicationIconBadgeNumber = 0;
    
    NSLog(@"收到远程通知");
    
    // 取得 APNs 标准信息内容
    NSDictionary *aps = [userInfo valueForKey:@"aps"];
    NSString *content = [aps valueForKey:@"alert"]; //推送显示的内容
    NSInteger badge = [[aps valueForKey:@"badge"] integerValue]; //badge数量
    NSString *sound = [aps valueForKey:@"sound"]; //播放的声音
    
    // 取得Extras字段内容
    NSString *customizeField1 = [userInfo valueForKey:@"customizeExtras"]; //服务端中Extras字段，key是自己定义的
    NSLog(@"content =[%@], badge=[%ld], sound=[%@], customize field  =[%@]",content,(long)badge,sound,customizeField1);
    
    // iOS 10 以下 Required
    [JPUSHService handleRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    NSLog(@"收到通知了");
//    UIViewController *currentVc = [self currentViewController];
//    NSLog(@"%@", NSStringFromClass([[self currentViewController] class]));
//    if ([NSStringFromClass([currentVc class]) isEqualToString:@"PhoneViewController"]) {
//        PhoneViewController *phoneVc = (PhoneViewController *)currentVc;
//        if (phoneVc.phoneOperation == 1) {
//            phoneVc.arrMessageRecord = nil;
//            phoneVc.page = 1;
//            [phoneVc.tableView.mj_footer resetNoMoreData];
//            [phoneVc loadMessage];
//        }
//    }else if ([NSStringFromClass([currentVc class]) isEqualToString:@"PhoneViewController"]){
//        
//    }
//    NSLog(@"%@", NSStringFromClass([[self presentingVC] class]));
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
    NSLog(@"attachmentForException %@",exception);
    [Bugly reportException:exception];  //直接上报异常
    return @"Test User attachment";
}

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
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler
{
    if (kSystemVersionValue < 10.0) {
        return NO;
    }
    NSLog(@"userActivity:%@", userActivity.description);
    NSLog(@"userActivity--userInfo:%@", userActivity.userInfo);
    NSString * handle =userActivity.startCallHandle;
    UNContact * contact = [[UNContact alloc] init];
    contact.phoneNumber= handle;
    contact.uniqueIdentifier=@"";
    if(nil == handle ){
        NSLog(@"Could not determine start call handle from user activity:%@", userActivity);
        return NO;
    }else{
        UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSUUID *callUUID = [[UNCallKitCenter sharedInstance] startRequestCalllWithContact:contact completion:^(NSError * _Nullable error) {
                
            }];
            NSLog(@"callUUID==%@", callUUID);
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
        });
        return YES;
    }
    return NO;
}



#pragma mark --- PuskKitDelegate
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type {
    NSString *tokenString = [[[[credentials.token description] stringByReplacingOccurrencesOfString: @"<" withString: @""] stringByReplacingOccurrencesOfString: @">" withString: @""] stringByReplacingOccurrencesOfString: @" " withString: @""];
    NSLog(@"pushToken======%@=======", tokenString);
    NSString *newToken = [self hexStringFromString:tokenString];
    NSString *newTokenlength = [self hexNewStringFromString:[NSString stringWithFormat:@"%lu", newToken.length/2]];
    [UNPushKitMessageManager shareManager].pushKitTokenString = [NSString stringWithFormat:@"ca%@%@", newTokenlength, newToken];
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    if ([payload.type isEqualToString:@"PKPushTypeVoIP"]) {
        NSLog(@"开始电话接入======%@=======", payload.dictionaryPayload);
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
            NSLog(@"前台PushKit消息---%@", payload.dictionaryPayload);
            return;
        }
        if (payload.dictionaryPayload) {
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
                NSLog(@"鉴权数据PushKit消息");
                [self checkCurrentPushKitMessage:serviceTimeData];
                //在pushkit里初始化蓝牙
                [[UNBlueToothTool shareBlueToothTool] initBlueTooth];
                
            }else if ([messageType isEqualToString:@"06"]){
                NSLog(@"唤醒网络电话PushKit消息");
                [UNPushKitMessageManager shareManager].pushKitMsgType = PushKitMessageTypeNetCall;
                [UNPushKitMessageManager shareManager].simDataDict = nil;
                if ([[NSUserDefaults standardUserDefaults] objectForKey:@"VSWCallPort"]) {
                    [VSWManager shareManager].callPort = [[NSUserDefaults standardUserDefaults] objectForKey:@"VSWCallPort"];
                }
                [UNCreatLocalNoti createLocalNotiMessageString:@"pushKit消息唤醒网络电话"];
                //创建网络电话服务
                [[UNSipEngineInitialize sharedInstance] initEngine];
            }else if ([messageType isEqualToString:@"05"]){
                NSLog(@"心跳包PushKit消息");
                [self checkCurrentPushKitMessage:serviceTimeData];
                
            }else if ([messageType isEqualToString:@"0f"]){
                NSLog(@"SIM卡断开连接PushKit消息");
                [self checkCurrentPushKitMessage:serviceTimeData];
                //在pushkit里初始化蓝牙
                [[UNBlueToothTool shareBlueToothTool] initBlueTooth];
                //创建网络电话服务
                [[UNSipEngineInitialize sharedInstance] initEngine];
            }else{
                [UNPushKitMessageManager shareManager].pushKitMsgType = PushKitMessageTypeNone;
                NSLog(@"未知PushKit消息---%@", dict);
            }
        }else{
            NSLog(@"PushKit消息异常");
        }
    }
}

- (void)checkCurrentPushKitMessage:(NSDictionary *)serviceTimeData
{
    //存储到队列中
    if ([UNPushKitMessageManager shareManager].pushKitMsgQueue.count > 0) {
        NSString *timeString = [UNPushKitMessageManager shareManager].pushKitMsgQueue.lastObject[@"time"];
        
        CGFloat dataTime = [timeString doubleValue];
        NSDate *dataDate = [NSDate dateWithTimeIntervalSince1970:dataTime];
        NSTimeInterval timeValue = [dataDate timeIntervalSinceNow];
        NSLog(@"时间差为---%.f", timeValue);
        
        if ([serviceTimeData[@"MessageType"] isEqualToString:@"0f"]) {
            [[UNPushKitMessageManager shareManager].pushKitMsgQueue removeAllObjects];
            [UNPushKitMessageManager shareManager].simDataDict = nil;
        }else{
            if (timeValue < -9.0){
                NSLog(@"时间太久,清空PushKit数据");
                [[UNPushKitMessageManager shareManager].pushKitMsgQueue removeAllObjects];
                [UNPushKitMessageManager shareManager].simDataDict = nil;
            }
        }
    }
    [[UNPushKitMessageManager shareManager].pushKitMsgQueue addObject:serviceTimeData];
    
    //防止和手环交互出现异常导致的卡住流程,当消息为7条时,再次发送第一条pushkit消息,当消息超过15条时,删除所有过期数据,重置Pushkit消息
    NSLog(@"pushkit队列消息数量--%zd", [UNPushKitMessageManager shareManager].pushKitMsgQueue.count);
    if ([UNPushKitMessageManager shareManager].pushKitMsgQueue.count == 1) {
        [self sendPushKitMessage:[UNPushKitMessageManager shareManager].pushKitMsgQueue.firstObject];
    }else if ([UNPushKitMessageManager shareManager].pushKitMsgQueue.count > 15){
        [[UNPushKitMessageManager shareManager].pushKitMsgQueue removeAllObjects];
    }
}

- (void)reConnectTcp
{
    if (self.sendTcpSocket && !self.sendTcpSocket.isConnected) {
        if (![UNPushKitMessageManager shareManager].isTcpConnecting) {
            [UNPushKitMessageManager shareManager].isTcpConnecting = YES;
            NSString *host = [VSWManager shareManager].vswIp;
            uint16_t port = [VSWManager shareManager].vswPort;
            NSLog(@"reConnectTcp---tcp连接或断线重连---[%@:%d]",host, port);
            if (!host || !port) {
                host = [[NSUserDefaults standardUserDefaults] objectForKey:@"VSWServerIp"];
                port = [[[NSUserDefaults standardUserDefaults] objectForKey:@"VSWServerPort"] intValue];
            }
            NSError *error;
            [self.sendTcpSocket connectToHost:host onPort:port withTimeout:60 error:&error];
            if (error) {
                NSLog(@"socket连接出错----%@", error);
            }
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
    NSLog(@"发送给服务器的数据 -- %@", tcpString);
    [UNCreatLocalNoti createLocalNotiMessageString:[NSString stringWithFormat:@"发送PushKit心跳包给服务器的数据--%@", tcpString]];
    [self sendMsgWithMessage:tcpString];
    
    if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
        NSLog(@"删除前当前队列消息====%@", [UNPushKitMessageManager shareManager].pushKitMsgQueue);
        NSLog(@"需要删除的队列消息====%@", [UNPushKitMessageManager shareManager].receivePushKitDataFormServices);
        [self checkPushKitMessage:[UNPushKitMessageManager shareManager].receivePushKitDataFormServices];
    }
}



- (void)checkPushKitMessage:(NSDictionary *)servicePushKitData
{
    if (!servicePushKitData) {
        return;
    }
    if ([[UNPushKitMessageManager shareManager].pushKitMsgQueue containsObject:servicePushKitData]) {
        [[UNPushKitMessageManager shareManager].pushKitMsgQueue removeObject:servicePushKitData];
        NSLog(@"删除后当前队列消息====%@", [UNPushKitMessageManager shareManager].pushKitMsgQueue);
        //发送新的pushkit消息
        if ([UNPushKitMessageManager shareManager].pushKitMsgQueue.count) {
            [self sendPushKitMessage:[UNPushKitMessageManager shareManager].pushKitMsgQueue.firstObject];
        }
//        else{
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"downElectic" object:@"downElectic"];
//        }
    }else{
        NSLog(@"不包含当前队列消息");
        if ([UNPushKitMessageManager shareManager].pushKitMsgQueue.count) {
            [self sendPushKitMessage:[UNPushKitMessageManager shareManager].pushKitMsgQueue.firstObject];
        }
//        else{
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"downElectic" object:@"downElectic"];
//        }
    }
    [UNPushKitMessageManager shareManager].receivePushKitDataFormServices = nil;
}

- (void)sendPushKitMessage:(NSDictionary *)servicePushKitData
{
    NSLog(@"当前队列需要发送的pushkit消息=====%@", servicePushKitData);
    
    if ([servicePushKitData[@"MessageType"] isEqualToString:@"10"]) {
        //鉴权数据
        [UNPushKitMessageManager shareManager].isPushKitFromAppDelegate = YES;
        [UNPushKitMessageManager shareManager].pushKitMsgType = PushKitMessageTypeAuthSimData;
        
        [UNPushKitMessageManager shareManager].tcpStringWithPushKit = nil;
        self.tlvFirstStr = nil;
        [UNPushKitMessageManager shareManager].simDataDict = nil;
        //创建网络电话服务
        [[UNSipEngineInitialize sharedInstance] initEngine];
        //解析并发送当前pushkit
        if ([[servicePushKitData[@"dataString"] substringWithRange:NSMakeRange(28, 2)] isEqualToString:@"01"]) {
            NSLog(@"发送01pushkit消息");
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
            NSLog(@"发送正常pushkit消息");
            [UNPushKitMessageManager shareManager].PushKitAuthDataType = 2;
            [UNPushKitMessageManager shareManager].receivePushKitDataFormServices = servicePushKitData;
            [self separatePushKitString:servicePushKitData];
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"VSWCallPort"]) {
                [VSWManager shareManager].callPort = [[NSUserDefaults standardUserDefaults] objectForKey:@"VSWCallPort"];
            }
            //加载蓝牙手环
            if ([UNPushKitMessageManager shareManager].simDataDict) {
                NSLog(@"发送ReceivePushKitMessage通知");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ReceivePushKitMessage" object:nil];
            }else{
                if ([UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
                    NSLog(@"删除前当前队列消息====%@", [UNPushKitMessageManager shareManager].pushKitMsgQueue);
                    NSLog(@"需要删除的队列消息====%@", [UNPushKitMessageManager shareManager].receivePushKitDataFormServices);
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
        if (![UNPushKitMessageManager shareManager].isAppAlreadyLoad){
            dealyTime = 3;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(dealyTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"已创建TCP");
            if (self.tcpPacketStr && self.sendTcpSocket) {
                NSLog(@"注册过,重新发送注册信息");
                [BlueToothDataManager shareManager].isBeingRegisting = NO;
                [BlueToothDataManager shareManager].stepNumber = @"0";
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [BlueToothDataManager shareManager].isRegisted = NO;
                    if (!self.sendTcpSocket.isConnected) {
                        [self reConnectTcp];
                    }else{
                        //                        if ([BlueToothDataManager shareManager].isConnected) {
                        //                            [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:HOMESTATUETITLE_REGISTING];
                        [BlueToothDataManager shareManager].isBeingRegisting = YES;
                        self.communicateID = @"00000000";
                        //发送数据
                        [self sendMsgWithMessage:self.tcpPacketStr];
                        
                        [self checkPushKitMessage:[UNPushKitMessageManager shareManager].receivePushKitDataFormServices];
                        [UNPushKitMessageManager shareManager].pushKitMsgType = PushKitMessageTypeNone;
                        
                        //                        }else{
                        //                            [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:HOMESTATUETITLE_NOSIGNAL];
                        //                        }
                    }
                });
                
            }else{
                NSLog(@"当前没有注册过,需要重新注册");
                [UNPushKitMessageManager shareManager].isPushKitFromAppDelegate = NO;
                [BlueToothDataManager shareManager].bleStatueForCard = 0;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ReceivePushKitMessage" object:nil];
            }
        });
        
    }else{
        NSLog(@"删除前当前队列消息====%@", [UNPushKitMessageManager shareManager].pushKitMsgQueue);
        NSLog(@"需要删除的队列消息====%@", [UNPushKitMessageManager shareManager].receivePushKitDataFormServices);
        [UNPushKitMessageManager shareManager].receivePushKitDataFormServices = servicePushKitData;
        [self checkPushKitMessage:[UNPushKitMessageManager shareManager].receivePushKitDataFormServices];
    }
}

- (void)clearTimeoutPushKitMessage
{
    NSLog(@"清除超时数据");
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
        NSLog(@"截取Pushkit消息前面的数据 -- %@", self.tlvFirstStr);
        if ([[dataString substringWithRange:NSMakeRange(28, 2)] isEqualToString:@"00"]) {
//            00
            NSString *lengthStr = [dataString substringWithRange:NSMakeRange(32, 2)];
            //74
            leng = strtoul([lengthStr UTF8String], 0, 16);
            if (dataString.length >= (34+leng * 2)) {
                [UNPushKitMessageManager shareManager].simDataDict = @{@"time" : serviceData[@"time"], @"dataString" : [dataString substringWithRange:NSMakeRange(34, leng * 2)]};
            }
            NSLog(@"两位leng = %zd  需要传入的字符串 -- %@", leng, [UNPushKitMessageManager shareManager].simDataDict);
        }
    }
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
}

@end
