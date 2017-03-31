//
//  HomeViewController.m
//  unitoys
//
//  Created by sumars on 16/9/20.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "HomeViewController.h"
#import "CountryCell.h"
#import "PackageListViewController.h"
#import "BrowserViewController.h"
#import "OrderDetailViewController.h"
#import "UIImageView+WebCache.h"
#import "BindDeviceViewController.h"

#import <AddressBook/AddressBook.h>
#import <Contacts/Contacts.h>
#import "ContactModel.h"
#import "ContactDataHelper.h"//根据拼音A~Z~#进行排序的tool
#import "AddressBookManager.h"
#import "ActivateGiftCardViewController.h"
#import "VSWManager.h"

#import "QuickSettingViewController.h"
#import <iOSDFULibrary/iOSDFULibrary-Swift.h>
#import "TTRangeSlider.h"
#import "OrderListViewController.h"
#import "CommunicatePackageViewController.h"

#import "UNDatabaseTools.h"
#import "ChooseDeviceTypeViewController.h"

#import "UNCreatLocalNoti.h"
//#import "AppDelegate.h"

#import "UNBlueToothTool.h"
#import "UNPushKitMessageManager.h"

//#import "AbroadMessageController.h"

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface HomeViewController ()<DFUServiceDelegate,LoggerDelegate,DFUProgressDelegate>
@property (nonatomic, strong) DFUServiceController *myController;
@property (nonatomic, strong) NSFileHandle *writeHandle;
@property (nonatomic, strong)UIWindow *progressWindow;
@property (nonatomic, strong)TTRangeSlider *progressView;
@property (nonatomic, strong)UILabel *titleLabel;
@property (nonatomic, strong)UILabel *progressNumberLabel;
@property (nonatomic, strong)ChooseDeviceTypeViewController *chooseDeviceTypeVC;

//是否更新过蓝牙信息
@property (nonatomic, assign) BOOL isUpdatedLBEInfo;

@property (nonatomic, assign) BOOL isPushKitStatu;
@end

@implementation HomeViewController

- (NSMutableArray *)todays {
    if (!_todays) {
        self.todays = [NSMutableArray array];
    }
    return _todays;
}

- (NSMutableArray *)yesterdays {
    if (!_yesterdays) {
        self.yesterdays = [NSMutableArray array];
    }
    return _yesterdays;
}

- (NSMutableArray *)berforeYesterdays {
    if (!_berforeYesterdays) {
        self.berforeYesterdays = [NSMutableArray array];
    }
    return _berforeYesterdays;
}

- (NSMutableArray *)threeDaysAgo {
    if (!_threeDaysAgo) {
        self.threeDaysAgo = [NSMutableArray array];
    }
    return _threeDaysAgo;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [UNPushKitMessageManager shareManager].isAppAlreadyLoad = YES;
    self.isPushKitStatu = [UNPushKitMessageManager shareManager].isPushKitFromAppDelegate;
    self.navigationItem.leftBarButtonItem = nil;
    
    if (![UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
        [[UNBlueToothTool shareBlueToothTool] initBlueTooth];
    }
    kWeakSelf
    [UNBlueToothTool shareBlueToothTool].updateButtonImageAndTitleBlock = ^(NSString *title){
        NSLog(@"updateButtonImageAndTitleBlock---%@", title);
        [weakSelf setButtonImageAndTitleWithTitle:title];
    };
    [UNBlueToothTool shareBlueToothTool].showHudNormalBlock = ^(NSInteger hudType, NSString *string){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (hudType == 1) {
                HUDNormal(string)
            }else if (hudType == 2){
                HUDNoStop1(string)
            }
            
        });
    };
    [UNBlueToothTool shareBlueToothTool].endHudBlock = ^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            HUDStop
        });
    };
    [UNBlueToothTool shareBlueToothTool].checkBLEAndResetBlock = ^(){
        [weakSelf dj_alertAction:self alertTitle:nil actionTitle:@"重启" message:@"未能检测到手环内有电话卡，您需要重启手环重新检测吗？" alertAction:^{
            [BlueToothDataManager shareManager].isNeedToResert = YES;
            //发送复位请求
//            [self sendMessageToBLEWithType:BLESystemReset validData:nil];
            [[UNBlueToothTool shareBlueToothTool] sendBLESystemResetCommand];
            [BlueToothDataManager shareManager].isReseted = YES;
            [BlueToothDataManager shareManager].isBounded = NO;
            //重新连接
            [self checkBindedDeviceFromNet];
        }];
    };
    [UNBlueToothTool shareBlueToothTool].registFailActionBlock = ^(){
        [weakSelf registFailAction];
    };
    [UNBlueToothTool shareBlueToothTool].paySuccessBlock = ^(){
        [weakSelf paySuccess];
    };
    
    [self loadAdvertisment];
    
    [self loadOrderList];
    
    [self loadHotCountry];
    
    [self loadBasicConfig];
    
    //境外通讯
    UITapGestureRecognizer *abroadMessage = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(abroadMessageAction)];
    [self.ivQuickSetting addGestureRecognizer:abroadMessage];
    
    //双卡双待
    UITapGestureRecognizer *doubleCards = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleCardsAction)];
    [self.ivDevices addGestureRecognizer:doubleCards];
    
    //通话套餐
    UITapGestureRecognizer *phonePackage = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(phonePackageAction)];
    [self.ivTutorial addGestureRecognizer:phonePackage];
    
    //左边按钮
    self.leftButton = [[UIButton alloc]initWithFrame:CGRectMake(0,0,120,30)];//原来宽是100
    NSDictionary *userData = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    if (userData[@"BraceletIMEI"]) {
        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_CONNECTING];
    } else {
        //未绑定
        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTBOUND];
    }
    self.leftButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.leftButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.leftButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 3.0, 0.0, 0.0)];
    [self.leftButton addTarget:self action:@selector(leftButtonAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithCustomView:self.leftButton];
    self.navigationItem.leftBarButtonItem = left;
    
    //接收通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(paySuccess) name:@"BuyConfrim" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundingConnectedDevice) name:@"boundingDevice" object:@"bound"];//绑定
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(relieveBoundAction) name:@"relieveBound" object:@"relieve"];//解绑
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkBindedDeviceFromNet) name:@"scanToConnect" object:@"connect"];//扫描并连接设备
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activitySuccessAction) name:@"actionOrderSuccess" object:@"actionOrderSuccess"];//激活套餐成功
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(upLoadToCard) name:@"upLoadToCard" object:@"upLoadToCard"];//对卡上电
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(senderNewMessageToBLE:) name:@"receiveNewMessageFromBLE" object:nil];//给蓝牙发送消息
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(homeStatueHasChanged:) name:@"homeStatueChanged" object:nil];//蓝牙状态改变
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchMyBluetooth) name:@"searchMyBluetooth" object:@"searchMyBluetooth"];//查找手环
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downElectToCard) name:@"downElectic" object:@"downElectic"];//对卡断电
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updataToCard) name:@"updataElectic" object:@"updataElectic"];//对卡上电
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkEmptyCardSerialNumberFirst:) name:@"checkBLESerialNumber" object:nil];//获取空卡序列号
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unBindSuccess) name:@"noConnectedAndUnbind" object:@"noConnectedAndUnbind"];//解绑成功
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notToConnectedAndStopScan) name:@"stopScanBLE" object:@"stopScanBLE"];//停止扫描
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cardNumberNotTrueAction:) name:@"cardNumberNotTrue" object:nil];//号码有问题专用
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(oatUpdataAction:) name:@"OTAAction" object:nil];//空中升级
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshStatueToCard) name:@"refreshStatueToCard" object:@"refreshStatueToCard"];//刷新卡状态
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(paySuccess) name:@"boundGiftCardSuccess" object:@"boundGiftCardSuccess"];//绑定礼包卡成功
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivePushKitMessage) name:@"ReceivePushKitMessage" object:nil];//接收PushKit消息
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLBEStatuWithPushKit) name:@"UpdateLBEStatuWithPushKit" object:nil];//通过PushKit启动程序更新蓝牙状态
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(analysisAuthData:) name:@"AnalysisAuthData" object:nil];//解析鉴权数据
    
    [AddressBookManager shareManager].dataArr = [NSMutableArray array];
    
    //通讯录
    if (!_contactsDataArr) {
        if (SYSTEM_VERSION_LESS_THAN(@"9")) {
            [self fetchAddressBookBeforeIOS9];
        }else {
            [self fetchAddressBookOnIOS9AndLater];
        }
    }
    [AddressBookManager shareManager].contactsDataArr = _contactsDataArr;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addressBookDidChange:) name:CNContactStoreDidChangeNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addressBookDidChange:) name:@"addressBookChanged" object:@"addressBookChanged"];
    }
    //检查更新
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    // hh与HH的区别:分别表示12小时制,24小时制
    [formatter setDateFormat:@"YYYY-MM-dd"];
    NSDate *datenow = [NSDate date];
    NSString *currentTimeString = [formatter stringFromDate:datenow];
    NSString *timeString = [[NSUserDefaults standardUserDefaults] objectForKey:@"nowTime"];
    if (![timeString isEqualToString:currentTimeString]) {
        [self checkVersion];
        [[NSUserDefaults standardUserDefaults] setObject:currentTimeString forKey:@"nowTime"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)checkVersion {
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"0", @"TerminalCode", [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"], @"Version", nil];
    [SSNetworkRequest getRequest:[apiUpgrade stringByAppendingString:[self getParamStr]] params:info success:^(id responseObj){
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"app升级信息 -- %@", responseObj);
            if (responseObj[@"data"][@"Descr"]) {
                NSString *infoStr = [NSString stringWithFormat:@"新版本：%@\n%@", responseObj[@"data"][@"Version"], responseObj[@"data"][@"Descr"]];
                if ([responseObj[@"data"][@"Mandatory"] intValue] == 0) {
                    //不强制
                    [self dj_alertActionWithAlertTitle:@"版本升级" leftActionTitle:@"下次再说" rightActionTitle:@"现在升级" message:infoStr rightAlertAction:^{
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ai-xiao-qi/id1184825159?mt=8"]];
                    }];
                } else if ([responseObj[@"data"][@"Mandatory"] intValue] == 1) {
                    //强制
                    [self dj_alertActionWithAlertTitle:@"版本升级" rightActionTitle:@"确定" message:infoStr rightAlertAction:^{
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/ai-xiao-qi/id1184825159?mt=8"]];
                    }];
                } else {
                    NSLog(@"不知道是不是强制性的");
                }
            }
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            NSLog(@"数据请求失败 -- %@", responseObj[@"mag"]);
        }
    }failure:^(id dataObj, NSError *error) {
        HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        NSLog(@"数据错误：%@",[error description]);
        
    } headers:nil];
}

- (void)dj_alertActionWithAlertTitle:(NSString *)alertTitle leftActionTitle:(NSString *)leftActionTitle rightActionTitle:(NSString *)rightActionTitle message:(NSString *)message rightAlertAction:(void (^)())rightAlertAction {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:INTERNATIONALSTRING(alertTitle) message:INTERNATIONALSTRING(message) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(leftActionTitle) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *certailAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(rightActionTitle) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        rightAlertAction();
    }];
    [alertVC addAction:cancelAction];
    [alertVC addAction:certailAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)dj_alertActionWithAlertTitle:(NSString *)alertTitle rightActionTitle:(NSString *)rightActionTitle message:(NSString *)message rightAlertAction:(void (^)())rightAlertAction {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:INTERNATIONALSTRING(alertTitle) message:INTERNATIONALSTRING(message) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *certailAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(rightActionTitle) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        rightAlertAction();
    }];
    [alertVC addAction:certailAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark 刷新卡状态
- (void)refreshStatueToCard {
    NSLog(@"刷新卡状态");
    if ([BlueToothDataManager shareManager].isConnected) {
        [BlueToothDataManager shareManager].bleStatueForCard = 0;
        //对卡上电
        [[UNBlueToothTool shareBlueToothTool] phoneCardToUpeLectrifyWithType:@"01"];
    }else{
        NSLog(@"蓝牙未连接");
        dispatch_async(dispatch_get_main_queue(), ^{
            HUDNormal(INTERNATIONALSTRING(@"蓝牙未连接"))
        });
    }
}

#pragma mark 对卡上电
- (void)updataToCard {
    if ([BlueToothDataManager shareManager].isConnected) {
        [[UNBlueToothTool shareBlueToothTool] phoneCardToUpeLectrifyWithType:@"03"];
    }else{
        NSLog(@"蓝牙未连接");
        dispatch_async(dispatch_get_main_queue(), ^{
            HUDNormal(INTERNATIONALSTRING(@"蓝牙未连接"))
        });
    }
}

#pragma mark 查找手环
- (void)searchMyBluetooth {
    if ([BlueToothDataManager shareManager].isConnected) {
        [[UNBlueToothTool shareBlueToothTool] searchBluetooth];
    }else{
        NSLog(@"蓝牙未连接");
        dispatch_async(dispatch_get_main_queue(), ^{
            HUDNormal(INTERNATIONALSTRING(@"蓝牙未连接"))
        });
    }
}

- (void)unBindSuccess {
    if ([UNBlueToothTool shareBlueToothTool].boundedDeviceInfo) {
        [UNBlueToothTool shareBlueToothTool].boundedDeviceInfo = nil;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([[BlueToothDataManager shareManager].boundedDeviceName isEqualToString:MYDEVICENAMEUNITOYS]) {
            [self showAlertWithMessageUnbound:@"已解除绑定，请打开蓝牙设置界面忽略蓝牙设备"];
        }
    });
    [BlueToothDataManager shareManager].deviceType = nil;
    [BlueToothDataManager shareManager].isAllowToBound = NO;
    [BlueToothDataManager shareManager].isBounded = NO;
    [BlueToothDataManager shareManager].isConnectedPairedDevice = NO;
    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTBOUND];
}

- (void)showAlertWithMessageUnbound:(NSString *)message {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:INTERNATIONALSTRING(@"解绑成功") message:INTERNATIONALSTRING(message) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *certailAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(@"确定") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"App-prefs:root=Bluetooth"]]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-prefs:root=Bluetooth"]];
        } else {
            NSLog(@"打不开");
        }
    }];
    [alertVC addAction:certailAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark 停止扫描
- (void)notToConnectedAndStopScan {
    if ([BlueToothDataManager shareManager].isBounded) {
        if (![BlueToothDataManager shareManager].isTcpConnected) {
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
        }
    } else {
        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTBOUND];
    }
    [[UNBlueToothTool shareBlueToothTool] stopScanBluetooth];
}

- (void)checkBindedDeviceFromNet
{
    [[UNBlueToothTool shareBlueToothTool] checkBindedDeviceFromNet];
}

- (void)leftButtonAction {
    if ([BlueToothDataManager shareManager].isBounded) {
        //有绑定
        UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
        BindDeviceViewController *bindDeviceViewController = [mainStory instantiateViewControllerWithIdentifier:@"bindDeviceViewController"];
        if (bindDeviceViewController) {
            self.tabBarController.tabBar.hidden = YES;
            bindDeviceViewController.hintStrFirst = self.leftButton.titleLabel.text;
            [self.navigationController pushViewController:bindDeviceViewController animated:YES];
        }
    } else {
        //没绑定
        if (!self.chooseDeviceTypeVC) {
            self.chooseDeviceTypeVC = [[ChooseDeviceTypeViewController alloc] init];
        }
        [self.navigationController pushViewController:self.chooseDeviceTypeVC animated:YES];
    }
}

- (void)homeStatueHasChanged:(NSNotification *)sender {
    [self setButtonImageAndTitleWithTitle:sender.object];
}

- (void)cardNumberNotTrueAction:(NSNotification *)sender {
    [self setButtonImageAndTitleWithTitle:sender.object];
}

#pragma mark 设置按钮的文字和图片
- (void)setButtonImageAndTitleWithTitle:(NSString *)title {
    [self.leftButton setTitle:INTERNATIONALSTRING(title) forState:UIControlStateNormal];
    [BlueToothDataManager shareManager].homeVCLeftTitle = INTERNATIONALSTRING(title);
    [BlueToothDataManager shareManager].statuesTitleString = title;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeStatueAll" object:title];
    if ([title isEqualToString:HOMESTATUETITLE_BLNOTOPEN]) {
        //蓝牙未开
        [self.leftButton setImage:[UIImage imageNamed:HOMESTATUE_BLNOTOPEN] forState:UIControlStateNormal];
    } else if ([title isEqualToString:HOMESTATUETITLE_NOTBOUND]) {
        //未绑定
        [self.leftButton setImage:[UIImage imageNamed:HOMESTATUE_NOTBOUND] forState:UIControlStateNormal];
    } else if ([title isEqualToString:HOMESTATUETITLE_NOTINSERTCARD]) {
        //未插卡
        [self.leftButton setImage:[UIImage imageNamed:HOMESTATUE_NOTINSERTCARD] forState:UIControlStateNormal];
    } else if ([title isEqualToString:HOMESTATUETITLE_NOTCONNECTED]) {
        //未连接
        [self.leftButton setImage:[UIImage imageNamed:HOMESTATUE_NOTCONNECTED] forState:UIControlStateNormal];
    } else if ([title isEqualToString:HOMESTATUETITLE_CONNECTING]) {
        //连接中
        [self.leftButton setImage:[UIImage imageNamed:HOMESTATUE_CONNECTING] forState:UIControlStateNormal];
    }else if ([title isEqualToString:HOMESTATUETITLE_REGISTING]) {
        //注册中
        [self.leftButton setImage:[UIImage imageNamed:HOMESTATUE_CONNECTING] forState:UIControlStateNormal];
    } else if ([title isEqualToString:HOMESTATUETITLE_NOPACKAGE]) {
        //无套餐
        [self.leftButton setImage:[UIImage imageNamed:HOMESTATUE_NOPACKAGE] forState:UIControlStateNormal];
    } else if ([title isEqualToString:HOMESTATUETITLE_NOSIGNAL]) {
        //注册失败
        [self.leftButton setImage:[UIImage imageNamed:HOMESTATUE_NOSIGNAL] forState:UIControlStateNormal];
    } else if ([title isEqualToString:HOMESTATUETITLE_SIGNALSTRONG]) {
        //信号强
        [self.leftButton setImage:[UIImage imageNamed:HOMESTATUE_SIGNALSTRONG] forState:UIControlStateNormal];
    } else if ([title isEqualToString:HOMESTATUETITLE_AIXIAOQICARD]) {
        //爱小器卡
        [self.leftButton setImage:[UIImage imageNamed:HOMESTATUE_AIXIAOQICARD] forState:UIControlStateNormal];
    } else {
        NSLog(@"蓝牙状态有问题");
    }
}

-(void)addressBookDidChange:(NSNotification*)notification{
    NSLog(@"通讯录有变化");
    if (self.contactsDataArr.count) {
        _contactsDataArr = nil;
    }
    if ([AddressBookManager shareManager].dataArr.count) {
        [[AddressBookManager shareManager].dataArr removeAllObjects];
    }
    //通讯录
    if (!_contactsDataArr) {
        if (SYSTEM_VERSION_LESS_THAN(@"9")) {
            [self fetchAddressBookBeforeIOS9];
        }else {
            [self fetchAddressBookOnIOS9AndLater];
        }
    }
}


#pragma mark - 空中升级
- (void)oatUpdataAction:(NSNotification *)sender {
    if ([BlueToothDataManager shareManager].isConnected) {
        if (sender && ![sender.object isEqualToString:@"<null>"]) {
            [BlueToothDataManager shareManager].isBeingOTA = YES;
            //将连接的信息存储到本地
            NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
            NSMutableDictionary *boundedDeviceInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"boundedDeviceInfo"]];
            if ([boundedDeviceInfo objectForKey:userdata[@"Tel"]]) {
                [boundedDeviceInfo removeObjectForKey:userdata[@"Tel"]];
            }
            [[NSUserDefaults standardUserDefaults] setObject:boundedDeviceInfo forKey:@"boundedDeviceInfo"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[UNBlueToothTool shareBlueToothTool] oatUpdateCommand];
            [self showProgress];
            NSURL *downloadURL = [NSURL URLWithString:sender.object];
            [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:downloadURL] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                //下载完成之后的回调
                // 文件路径
                NSString* ceches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
                NSString* filepath = [ceches stringByAppendingPathComponent:response.suggestedFilename];
                NSLog(@"文件路径 --> %@", filepath);
                
                // 创建一个空的文件到沙盒中
                NSFileManager *mgr = [NSFileManager defaultManager];
                [mgr createFileAtPath:filepath contents:nil attributes:nil];
                
                // 创建一个用来写数据的文件句柄对象
                self.writeHandle = [NSFileHandle fileHandleForWritingAtPath:filepath];
                // 将数据写入沙盒
                [self.writeHandle writeData:data];
                // 关闭文件
                [self.writeHandle closeFile];
                self.writeHandle = nil;
                NSString *showStr = [NSString stringWithFormat:@"%@\n%@", INTERNATIONALSTRING(@"正在重启蓝牙"), INTERNATIONALSTRING(@"升级过程中请勿退出程序")];
                self.progressNumberLabel.text = showStr;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    //            NSString *pathStr = [[NSBundle mainBundle] pathForResource:@"yynew15" ofType:@"zip"];
                    
                    NSURL *fileURL = [NSURL fileURLWithPath:filepath];
                    //            NSURL *fileURL = [NSURL fileURLWithPath:pathStr];
                    DFUFirmware *selectedFirmware = [[DFUFirmware alloc] initWithUrlToZipFile:fileURL type:DFUFirmwareTypeApplication];
                    NSLog(@"mgr---%@=====peripheral----%@",[UNBlueToothTool shareBlueToothTool].mgr,[UNBlueToothTool shareBlueToothTool].peripheral);
                    DFUServiceInitiator *initiator = [[DFUServiceInitiator alloc] initWithCentralManager:[UNBlueToothTool shareBlueToothTool].mgr target:[UNBlueToothTool shareBlueToothTool].peripheral];
                    [initiator withFirmwareFile:selectedFirmware];
                    initiator.delegate = self;
                    initiator.logger = self;
                    initiator.progressDelegate = self;
                    self.myController = [initiator start];//开始升级
                });
            }];
        } else {
            NSLog(@"URL有问题");
        }
    }else{
        NSLog(@"蓝牙未连接");
        dispatch_async(dispatch_get_main_queue(), ^{
            HUDNormal(INTERNATIONALSTRING(@"蓝牙未连接"))
        });
    }
}

#pragma mark 代理方法
- (void)didStateChangedTo:(enum DFUState)state {
    /*
     DFUStateConnecting = 0,
     DFUStateStarting = 1,
     DFUStateEnablingDfuMode = 2,
     DFUStateUploading = 3,
     DFUStateValidating = 4,
     DFUStateDisconnecting = 5,
     DFUStateCompleted = 6,
     DFUStateAborted = 7,
     DFUStateSignatureMismatch = 8,
     DFUStateOperationNotPermitted = 9,
     DFUStateFailed = 10,
     */
    //    DFUState dfuStateType = (DFUState)state;
    NSLog(@"显示升级状态 --> %ld", (long)state);
    if (state == 6&&self.progressWindow) {
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            self.progressWindow = nil;
//        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            if (self.peripheral != nil) {
//                self.myController = nil;
//                [self checkBindedDeviceFromNet];
//                NSLog(@"------------------------------------------------");
//            }
            if ([UNBlueToothTool shareBlueToothTool].peripheral != nil) {
                self.myController = nil;
                [[UNBlueToothTool shareBlueToothTool] checkBindedDeviceFromNet];
                NSLog(@"------------------------------------------------");
            }
        });
    }
}

- (void)didErrorOccur:(enum DFUError)error withMessage:(NSString *)message {
    NSLog(@"ERROR %ld:%@", (long)error, message);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        self.progressWindow = nil;
        self.progressNumberLabel.text = INTERNATIONALSTRING(@"升级失败\n请重新启动爱小器App");
        [BlueToothDataManager shareManager].isBeingOTA = NO;
    });
}

- (void)onUploadProgress:(NSInteger)part totalParts:(NSInteger)totalParts progress:(NSInteger)progress currentSpeedBytesPerSecond:(double)currentSpeedBytesPerSecond avgSpeedBytesPerSecond:(double)avgSpeedBytesPerSecond {
    //进度
    NSLog(@"dfuProgressChangedFor: %ld%% (part %ld/%ld).speed:%f bps, Avg speed:%f bps", (long)progress, (long)part, (long)totalParts, currentSpeedBytesPerSecond, avgSpeedBytesPerSecond);
    self.progressNumberLabel.text = [NSString stringWithFormat:@"%ld%%\n%@", (long)progress, INTERNATIONALSTRING(@"升级过程中请勿退出程序")];
    if (self.progressView.hidden) {
        self.progressView.hidden = NO;
    }
    self.progressView.selectedMinimum = (float)progress/100;
//    NSLog(@"当前百分比%f", (float)progress/100);
    if (progress == 100) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.progressNumberLabel.text = INTERNATIONALSTRING(@"升级成功\n请重新启动爱小器App");
            [BlueToothDataManager shareManager].isBeingOTA = NO;
        });
    }
}

- (void)logWith:(enum LogLevel)level message:(NSString *)message {
    /*
     LogLevelDebug = 0,
     LogLevelVerbose = 1,
     LogLevelInfo = 5,
     LogLevelApplication = 10,
     LogLevelWarning = 15,
     LogLevelError = 20,
     */
    NSLog(@"升级步骤显示 --> %ld, %@", (long)level, message);
}

#pragma mark 进度条布局
- (void)showProgress {
    if (!self.progressWindow) {
        self.progressWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-20)];
        self.progressWindow.windowLevel = UIWindowLevelStatusBar+1;
        self.progressWindow.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
        
        UIView *littleView = [[UIView alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width/2)-110, ([UIScreen mainScreen].bounds.size.height/2)-60, 220, 120)];
        littleView.backgroundColor = [UIColor whiteColor];
        littleView.layer.masksToBounds = YES;
        littleView.layer.cornerRadius = 10;
        [self.progressWindow addSubview:littleView];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, CGRectGetWidth(littleView.frame)-20, 21)];
        self.titleLabel.text = INTERNATIONALSTRING(@"固件升级");
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [littleView addSubview:self.titleLabel];
        
        self.progressNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, littleView.frame.size.height/2-30, CGRectGetWidth(littleView.frame)-20, 60)];
        self.progressNumberLabel.textAlignment = NSTextAlignmentCenter;
        self.progressNumberLabel.numberOfLines = 0;
        self.progressNumberLabel.font = [UIFont systemFontOfSize:17];
        NSString *showStr = [NSString stringWithFormat:@"%@\n%@", INTERNATIONALSTRING(@"正在下载升级文件"), INTERNATIONALSTRING(@"升级过程中请勿退出程序")];
        self.progressNumberLabel.text = showStr;
        [littleView addSubview:self.progressNumberLabel];
        
        self.progressView = [[TTRangeSlider alloc] initWithFrame:CGRectMake(10, littleView.frame.size.height-30, CGRectGetWidth(littleView.frame)-20, 20)];
        self.progressView.hidden = YES;
        self.progressView.minValue = 0;
        self.progressView.maxValue = 1;
        self.progressView.selectedMinimum = 0;
        self.progressView.selectedMaximum = 1;
        self.progressView.handleImage = nil;
        self.progressView.handleDiameter = 0;
        self.progressView.minLabelFont = [UIFont systemFontOfSize:0];
        self.progressView.maxLabelFont = [UIFont systemFontOfSize:0];
        self.progressView.selectedHandleDiameterMultiplier = 1;
        self.progressView.tintColorBetweenHandles = [UIColor whiteColor];
        self.progressView.lineHeight = 3;
        self.progressView.enabled = NO;
        //设置进度条颜色
        self.progressView.tintColor = [UIColor magentaColor];
        [littleView addSubview:self.progressView];
        
        [self.progressWindow makeKeyAndVisible];
    }
}

- (void)senderNewMessageToBLE:(NSNotification *)sender {
    NSString *tempStr = sender.object;
    NSLog(@"获取卡数据---%@", tempStr);
    if ([BlueToothDataManager shareManager].isConnected) {
        [[UNBlueToothTool shareBlueToothTool] sendBLECardDataWithValidData:tempStr];
    }else{
        NSLog(@"蓝牙未连接");
        dispatch_async(dispatch_get_main_queue(), ^{
            HUDNormal(INTERNATIONALSTRING(@"蓝牙未连接"))
        });
    }
}

- (void)sendNewMessageToBLEWithPushKit:(NSString *)sendString
{
    if ([BlueToothDataManager shareManager].isConnected) {
        NSLog(@"获取卡数据从pushkit---%@", sendString);
        [[UNBlueToothTool shareBlueToothTool] sendBLECardDataWithValidData:sendString];
    }else{
        NSLog(@"蓝牙未连接");
        dispatch_async(dispatch_get_main_queue(), ^{
            HUDNormal(INTERNATIONALSTRING(@"蓝牙未连接"))
        });
    }
}

#pragma mark - 通讯录
- (void)fetchAddressBookBeforeIOS9{
    self.contactsDataArr = [[NSArray alloc] init];
    ABAddressBookRef addressBook = ABAddressBookCreate(); //首次访问需用户授权
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {//首次访问通讯录
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) { if (!error) { if (granted) {//允许
            NSLog(@"已授权访问通讯录"); NSArray *contacts = [self fetchContactWithAddressBook:addressBook]; dispatch_async(dispatch_get_main_queue(), ^{
                //----------------主线程 更新 UI-----------------
                NSLog(@"contacts:%@", contacts);
                _contactsDataArr = contacts;
                for (NSDictionary *subDic in self.contactsDataArr) {
                    ContactModel *model=[[ContactModel alloc]initWithDic:subDic];
                    [[AddressBookManager shareManager].dataArr addObject:model];
                }
                [AddressBookManager shareManager].rowArr=[ContactDataHelper getFriendListDataBy:[AddressBookManager shareManager].dataArr];
                [AddressBookManager shareManager].sectionArr=[ContactDataHelper getFriendListSectionBy:[[AddressBookManager shareManager].rowArr mutableCopy]];
            });
            
        }else{//拒绝
            NSLog(@"拒绝访问通讯录"); } }else{ NSLog(@"发生错误!");
            }
        });
    }else{
        //非首次访问通讯录
        NSArray *contacts = [self fetchContactWithAddressBook:addressBook];
        CFRelease(addressBook);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //----------------主线程 更新 UI-----------------
            _contactsDataArr = contacts;
            NSLog(@"contacts:%@", contacts);
            
            for (NSDictionary *subDic in self.contactsDataArr) {
                ContactModel *model=[[ContactModel alloc]initWithDic:subDic];
                [[AddressBookManager shareManager].dataArr addObject:model];
            }
            [AddressBookManager shareManager].rowArr=[ContactDataHelper getFriendListDataBy:[AddressBookManager shareManager].dataArr];
            [AddressBookManager shareManager].sectionArr=[ContactDataHelper getFriendListSectionBy:[[AddressBookManager shareManager].rowArr mutableCopy]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"addressBookChanged" object:@"addressBook"];
        });
    }
}

- (NSMutableArray *)fetchContactWithAddressBook:(ABAddressBookRef)addressBook {
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {////有权限访问 //获取联系人数组
        NSArray *array = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
        NSMutableArray *contacts = [NSMutableArray array];
        for (int i = 0; i < array.count; i++)
        { //获取联系人
            ABRecordRef people = CFArrayGetValueAtIndex((__bridge ABRecordRef)array, i); //获取联系人详细信息,如:姓名,电话,住址等信息
            NSString *firstName = (__bridge NSString *)ABRecordCopyValue(people, kABPersonFirstNameProperty);
            NSString *lastName = (__bridge NSString *)ABRecordCopyValue(people, kABPersonLastNameProperty);
            ABMutableMultiValueRef *phoneNumRef = ABRecordCopyValue(people, kABPersonPhoneProperty);
            NSArray *arrNumber = ((__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(phoneNumRef));
            NSString *phoneNumber = arrNumber.firstObject;
            if (arrNumber.firstObject) {
                for (int i=1; i<arrNumber.count; i++) {
                    phoneNumber = [phoneNumber stringByAppendingString:[NSString stringWithFormat:@",%@",[arrNumber objectAtIndex:i]]];
                }
            }
            if (firstName && lastName) {
                if ((phoneNumber)&&([lastName stringByAppendingString:firstName])) {
                    [contacts addObject:@{@"name": [lastName stringByAppendingString:firstName], @"phoneNumber": phoneNumber, @"portrait":[NSString stringWithFormat:@"con_face%d",[self getRandomNumber:1 to:3]]}];
                }
            } else if (firstName && !lastName) {
                if (phoneNumber) {
                    [contacts addObject:@{@"name": firstName, @"phoneNumber": phoneNumber, @"portrait":[NSString stringWithFormat:@"con_face%d",[self getRandomNumber:1 to:3]]}];
                }
            } else if (!firstName && lastName) {
                if (phoneNumber) {
                    [contacts addObject:@{@"name": lastName, @"phoneNumber": phoneNumber, @"portrait":[NSString stringWithFormat:@"con_face%d",[self getRandomNumber:1 to:3]]}];
                }
            } else {
                NSLog(@"9.0以前的系统，通讯录数据格式不正确");
                if (phoneNumber) {
                    [contacts addObject:@{@"name": phoneNumber, @"phoneNumber": phoneNumber, @"portrait":[NSString stringWithFormat:@"con_face%d",[self getRandomNumber:1 to:3]]}];
                } else {
                    NSLog(@"通讯录没有号码");
                }
            }
        }
        return contacts;
    }else{//无权限访问
        NSLog(@"无权限访问通讯录");
        return nil;
    }
}


- (void)fetchAddressBookOnIOS9AndLater{ //创建CNContactStore对象
    self.contactsDataArr = [[NSArray alloc] init];
    CNContactStore *contactStore = [[CNContactStore alloc] init]; //首次访问需用户授权
    if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusNotDetermined)
    {//首次访问通讯录
        [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error){
            if (!error){
                if (granted) {//允许
                    NSLog(@"已授权访问通讯录");
                    NSArray *contacts = [self fetchContactWithContactStore:contactStore];//访问通讯录
                    dispatch_async(dispatch_get_main_queue(),^{ //----------------主线程 更新 UI-----------------
                        NSLog(@"contacts:%@", contacts);
                        _contactsDataArr = contacts;
                        for (NSDictionary *subDic in self.contactsDataArr) {
                            ContactModel *model=[[ContactModel alloc]initWithDic:subDic];
                            [[AddressBookManager shareManager].dataArr addObject:model];
                        }
                        [AddressBookManager shareManager].rowArr=[ContactDataHelper getFriendListDataBy:[AddressBookManager shareManager].dataArr];
                        [AddressBookManager shareManager].sectionArr=[ContactDataHelper getFriendListSectionBy:[[AddressBookManager shareManager].rowArr mutableCopy]];
                    });
                }else{//拒绝
                    NSLog(@"拒绝访问通讯录");
                }
            }else{
                NSLog(@"发生错误!");
            }
        }];
    }else{//非首次访问通讯录
        NSArray *contacts = [self fetchContactWithContactStore:contactStore];//访问通讯录
        dispatch_async(dispatch_get_main_queue(), ^{ //----------------主线程 更新 UI-----------------
            NSLog(@"contacts:%@", contacts);
            _contactsDataArr = contacts;
            for (NSDictionary *subDic in self.contactsDataArr) {
                ContactModel *model=[[ContactModel alloc]initWithDic:subDic];
                [[AddressBookManager shareManager].dataArr addObject:model];
            }
            [AddressBookManager shareManager].rowArr=[ContactDataHelper getFriendListDataBy:[AddressBookManager shareManager].dataArr];
            [AddressBookManager shareManager].sectionArr=[ContactDataHelper getFriendListSectionBy:[[AddressBookManager shareManager].rowArr mutableCopy]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"addressBookChanged" object:@"addressBook"];
        });
    }
}

- (NSMutableArray *)fetchContactWithContactStore:(CNContactStore *)contactStore{ //判断访问权限
    if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized)
    {//有权限访问
        NSError *error = nil; //创建数组,必须遵守CNKeyDescriptor协议,放入相应的字符串常量来获取对应的联系人信息
        NSArray <id<CNKeyDescriptor>> *keysToFetch = @[CNContactFamilyNameKey, CNContactGivenNameKey, CNContactPhoneNumbersKey]; //获取通讯录数组
        NSArray<CNContact*> *arr = [contactStore unifiedContactsMatchingPredicate:nil keysToFetch:keysToFetch error:&error];
        if (!error){
            NSMutableArray *contacts = [NSMutableArray array];
            for (int i = 0; i < arr.count; i++){
                CNContact *contact = arr[i];
                NSString *givenName = contact.givenName;
                NSString *familyName = contact.familyName;
                NSArray *arrNumber = contact.phoneNumbers;
                NSString *phoneNumber = ((CNPhoneNumber *)(contact.phoneNumbers.firstObject.value)).stringValue;
                if (arrNumber.firstObject) {
                    for (CNLabeledValue *labelValue in arrNumber) {
                        if (![phoneNumber containsString:[labelValue.value stringValue]]) {
                            CNPhoneNumber *number = labelValue.value;
                            phoneNumber = [phoneNumber stringByAppendingString:[NSString stringWithFormat:@",%@",number.stringValue]];
                        }
                    }
                }
                if ((phoneNumber)&&([familyName stringByAppendingString:givenName])&&![[familyName stringByAppendingString:givenName] isEqualToString:@""]) {
                    [contacts addObject:@{@"name": [familyName stringByAppendingString:givenName], @"phoneNumber": phoneNumber,@"portrait":[NSString stringWithFormat:@"con_face%d",[self getRandomNumber:1 to:3]]}];
                } else {
                    NSLog(@"9.0以后的系统，通讯录数据格式不正确");
                    if (phoneNumber) {
                        [contacts addObject:@{@"name": phoneNumber, @"phoneNumber": phoneNumber,@"portrait":[NSString stringWithFormat:@"con_face%d",[self getRandomNumber:1 to:3]]}];
                    } else {
                        NSLog(@"通讯录没有号码");
                    }
                }
            }
            _contactsDataArr = contacts;
            return contacts;
        }else {
            return nil;
        }
    }else{//无权限访问
        NSLog(@"无权限访问通讯录"); return nil;
    }
}

-(int)getRandomNumber:(int)from to:(int)to
{
    return (int)(from + (arc4random() % (to-from + 1)));
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

- (void)devicesAction {
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
    
    BindDeviceViewController *bindDeviceViewController = [mainStory instantiateViewControllerWithIdentifier:@"bindDeviceViewController"];
    if (bindDeviceViewController) {
        self.tabBarController.tabBar.hidden = YES;
        bindDeviceViewController.hintStrFirst = self.leftButton.titleLabel.text;
        [self.navigationController pushViewController:bindDeviceViewController animated:YES];
    }
}

#pragma mark 支付成功刷新
- (void)paySuccess {
    [self loadOrderList];
    if (![BlueToothDataManager shareManager].isHavePackage) {
        //对卡上电
        if ([BlueToothDataManager shareManager].isConnected) {
            [BlueToothDataManager shareManager].bleStatueForCard = 0;
//            [self phoneCardToUpeLectrify:@"01"];
            [[UNBlueToothTool shareBlueToothTool] phoneCardToUpeLectrifyWithType:@"01"];
        }
    }
}

- (void)activitySuccessAction {
    [self loadOrderList];
}

- (void)abroadMessageAction
{
    NSLog(@"境外通讯");
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Order" bundle:nil];
    if (storyboard) {
        self.tabBarController.tabBar.hidden = YES;
        UIViewController *orderListViewController = [storyboard instantiateViewControllerWithIdentifier:@"orderListViewController"];
        OrderListViewController *orderListVc = (OrderListViewController *)orderListViewController;
        orderListVc.isAbroadMessage = YES;
        if (orderListVc) {
            [self.navigationController pushViewController:orderListVc animated:YES];
        }
    }
}

- (void)doubleCardsAction
{
    NSLog(@"双卡双待");
    
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    BrowserViewController *browserViewController = [mainStory instantiateViewControllerWithIdentifier:@"browserViewController"];
    if (browserViewController) {
        browserViewController.loadUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"dualSimStandbyTutorialUrl"];
        browserViewController.titleStr = INTERNATIONALSTRING(@"双卡双待使用教程");
        [self.navigationController pushViewController:browserViewController animated:YES];
    }
}

- (void)phonePackageAction
{
    NSLog(@"通话套餐");
    CommunicatePackageViewController *communicateVC = [[CommunicatePackageViewController alloc] init];
    [self.navigationController pushViewController:communicateVC animated:YES];
}


- (void)quickSetting {
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
    QuickSettingViewController *quickSettingViewController = [mainStory instantiateViewControllerWithIdentifier:@"quickSettingViewController"];
    if (quickSettingViewController) {
        self.tabBarController.tabBar.hidden = YES;
        [self.navigationController pushViewController:quickSettingViewController animated:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    self.tabBarController.tabBar.hidden = NO;
}

- (void)loadOrderList {
    
    if (self.isPushKitStatu) {
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:@"apiOrderList"];
        if (responseObj) {
            self.arrOrderList = [[responseObj objectForKey:@"data"] objectForKey:@"list"];
            [self viewOrders];
            [self.tableView reloadData];
        }else{
            HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        }
    }else{
        self.checkToken = YES;
        
        NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"3",@"PageSize",@"1",@"PageNumber", nil];
        
        [self getBasicHeader];
        NSLog(@"表头：%@",self.headers);
        
        
        [SSNetworkRequest getRequest:apiOrderList params:params success:^(id responseObj) {
            
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:@"apiOrderList" dictData:responseObj];
                self.arrOrderList = [[responseObj objectForKey:@"data"] objectForKey:@"list"];
                [self viewOrders];
                
                [self.tableView reloadData];
                
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                
            }
            NSLog(@"查询到的套餐数据：%@",responseObj);
        } failure:^(id dataObj, NSError *error) {
            //
            NSLog(@"啥都没：%@",[error description]);
            NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:@"apiOrderList"];
            if (responseObj) {
                self.arrOrderList = [[responseObj objectForKey:@"data"] objectForKey:@"list"];
                [self viewOrders];
                [self.tableView reloadData];
            }else{
                HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
            }
        } headers:self.headers];
    }
}

- (void)viewOrders {
    if (self.arrOrderList.count==0) {
        //
        [self.lblOrderHint setHidden:NO];
        [self.ivLogoPic1 setHidden:YES];
        [self.lblFlow1 setHidden:YES];
        [self.lblExpireDays1 setHidden:YES];
        [self.btnOrderStatus1 setHidden:YES];
        
        
    } else {
        [self.lblOrderHint setHidden:YES];
        [self.ivLogoPic1 setHidden:NO];
        [self.lblFlow1 setHidden:NO];
        [self.lblExpireDays1 setHidden:NO];
        [self.btnOrderStatus1 setHidden:NO];
        
        if (self.arrOrderList.count>0) {
            NSDictionary *dicOrder = [self.arrOrderList objectAtIndex:0];
            [self.ivLogoPic1 sd_setImageWithURL:[NSURL URLWithString:dicOrder[@"LogoPic"]]];
            
            self.lblFlow1.text = [dicOrder objectForKey:@"PackageName"];
            self.lblExpireDays1.text = [dicOrder objectForKey:@"ExpireDays"];
            if ([[dicOrder objectForKey:@"PayStatus"] intValue]==0) {
                NSLog(@"未支付");
            }else{
                switch ([[dicOrder objectForKey:@"OrderStatus"] intValue]) {
                    case 0:
                        [self.btnOrderStatus1 setTitle:INTERNATIONALSTRING(@"未激活") forState:UIControlStateNormal];
                        [self.btnOrderStatus1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    case 1:
                        if ([[dicOrder objectForKey:@"PackageCategory"] intValue] == 1) {
                            [self.btnOrderStatus1 setTitle:[NSString stringWithFormat:@"%@ %@ %@", INTERNATIONALSTRING(@"剩余"), dicOrder[@"RemainingCallMinutes"], INTERNATIONALSTRING(@"分钟")] forState:UIControlStateNormal];
                            [self.btnOrderStatus1 setImage:nil forState:UIControlStateNormal];
                        } else {
                            [self.btnOrderStatus1 setTitle:INTERNATIONALSTRING(@"已激活") forState:UIControlStateNormal];
                            [self.btnOrderStatus1 setImage:[UIImage imageNamed:@"order_actived"] forState:UIControlStateNormal];
                        }
                        [self.btnOrderStatus1 setTitleColor:[UIColor colorWithRed:23/255.0 green:186/255.0 blue:34/255.0 alpha:1.0] forState:UIControlStateNormal];
                        break;
                    case 2:
                        [self.btnOrderStatus1 setTitle:INTERNATIONALSTRING(@"已激活") forState:UIControlStateNormal];
                        [self.btnOrderStatus1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    case 3:
                        [self.btnOrderStatus1 setTitle:INTERNATIONALSTRING(@"已取消") forState:UIControlStateNormal];
                        [self.btnOrderStatus1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    case 4:
                        [self.btnOrderStatus1 setTitle:INTERNATIONALSTRING(@"激活失败") forState:UIControlStateNormal];
                        [self.btnOrderStatus1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    default:
                        [self.btnOrderStatus1 setTitle:INTERNATIONALSTRING(@"未知状态") forState:UIControlStateNormal];
                        [self.btnOrderStatus1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                }
            }
        }
        
        if (self.arrOrderList.count>1) {
            NSDictionary *dicOrder = [self.arrOrderList objectAtIndex:1];
            [self.ivLogoPic2 sd_setImageWithURL:[NSURL URLWithString:dicOrder[@"LogoPic"]]];
            self.lblFlow2.text = [dicOrder objectForKey:@"PackageName"];
            self.lblExpireDays2.text = [dicOrder objectForKey:@"ExpireDays"];
            if ([[dicOrder objectForKey:@"PayStatus"] intValue]==0) {
                NSLog(@"未支付");
            }else{
                switch ([[dicOrder objectForKey:@"OrderStatus"] intValue]) {
                    case 0:
                        [self.btnOrderStatus2 setTitle:INTERNATIONALSTRING(@"未激活") forState:UIControlStateNormal];
                        [self.btnOrderStatus2 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    case 1:
                        if ([[dicOrder objectForKey:@"PackageCategory"] intValue] == 1) {
                            [self.btnOrderStatus2 setTitle:[NSString stringWithFormat:@"%@ %@ %@", INTERNATIONALSTRING(@"剩余"), dicOrder[@"RemainingCallMinutes"], INTERNATIONALSTRING(@"分钟")] forState:UIControlStateNormal];
                            [self.btnOrderStatus2 setImage:nil forState:UIControlStateNormal];
                        } else {
                            [self.btnOrderStatus2 setTitle:INTERNATIONALSTRING(@"已激活") forState:UIControlStateNormal];
                            [self.btnOrderStatus2 setImage:[UIImage imageNamed:@"order_actived"] forState:UIControlStateNormal];
                        }
                        [self.btnOrderStatus2 setTitleColor:[UIColor colorWithRed:23/255.0 green:186/255.0 blue:34/255.0 alpha:1.0] forState:UIControlStateNormal];
                        break;
                    case 2:
                        [self.btnOrderStatus2 setTitle:INTERNATIONALSTRING(@"已过期") forState:UIControlStateNormal];
                        [self.btnOrderStatus2 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    case 3:
                        [self.btnOrderStatus2 setTitle:INTERNATIONALSTRING(@"已取消") forState:UIControlStateNormal];
                        [self.btnOrderStatus2 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    case 4:
                        [self.btnOrderStatus2 setTitle:INTERNATIONALSTRING(@"激活失败") forState:UIControlStateNormal];
                        [self.btnOrderStatus2 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                        
                    default:
                        [self.btnOrderStatus2 setTitle:INTERNATIONALSTRING(@"未知状态") forState:UIControlStateNormal];
                        [self.btnOrderStatus2 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                }
            }
            
        }
        
        if (self.arrOrderList.count>2) {
            NSDictionary *dicOrder = [self.arrOrderList objectAtIndex:2];
            [self.ivLogoPic3 sd_setImageWithURL:[NSURL URLWithString:dicOrder[@"LogoPic"]]];
            self.lblFlow3.text = [dicOrder objectForKey:@"PackageName"];
            self.lblExpireDays3.text = [dicOrder objectForKey:@"ExpireDays"];
            if ([[dicOrder objectForKey:@"PayStatus"] intValue]==0) {
                NSLog(@"未支付");
            }else{
                switch ([[dicOrder objectForKey:@"OrderStatus"] intValue]) {
                    case 0:
                        [self.btnOrderStatus3 setTitle:INTERNATIONALSTRING(@"未激活") forState:UIControlStateNormal];
                        [self.btnOrderStatus3 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    case 1:
                        if ([[dicOrder objectForKey:@"PackageCategory"] intValue] == 1) {
                            [self.btnOrderStatus3 setTitle:[NSString stringWithFormat:@"%@ %@ %@", INTERNATIONALSTRING(@"剩余"), dicOrder[@"RemainingCallMinutes"], INTERNATIONALSTRING(@"分钟")] forState:UIControlStateNormal];
                            [self.btnOrderStatus3 setImage:nil forState:UIControlStateNormal];
                        } else {
                            [self.btnOrderStatus3 setTitle:INTERNATIONALSTRING(@"已激活") forState:UIControlStateNormal];
                            [self.btnOrderStatus3 setImage:[UIImage imageNamed:@"order_actived"] forState:UIControlStateNormal];
                        }
                        [self.btnOrderStatus3 setTitleColor:[UIColor colorWithRed:23/255.0 green:186/255.0 blue:34/255.0 alpha:1.0] forState:UIControlStateNormal];
                        break;
                    case 2:
                        [self.btnOrderStatus3 setTitle:INTERNATIONALSTRING(@"已过期") forState:UIControlStateNormal];
                        [self.btnOrderStatus3 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    case 3:
                        [self.btnOrderStatus3 setTitle:INTERNATIONALSTRING(@"已取消") forState:UIControlStateNormal];
                        [self.btnOrderStatus3 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    case 4:
                        [self.btnOrderStatus3 setTitle:INTERNATIONALSTRING(@"激活失败") forState:UIControlStateNormal];
                        [self.btnOrderStatus3 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                        
                    default:
                        [self.btnOrderStatus3 setTitle:INTERNATIONALSTRING(@"未知状态") forState:UIControlStateNormal];
                        [self.btnOrderStatus3 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                }
            }
        }
    }
}

- (void)loadAdvertisment {
    if (self.isPushKitStatu) {
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:@"apiGetBannerList"];
        if (responseObj) {
            self.arrPicUrls = [[NSMutableArray alloc] init];
            self.arrPicJump = [[NSMutableArray alloc] init];
            self.arrPicTitles = [[NSMutableArray alloc] init];
            //构造图片列表和链接列表
            for (NSDictionary *dicPic in [responseObj objectForKey:@"data"]) {
                [self.arrPicUrls addObject:[dicPic objectForKey:@"Image"]];
                [self.arrPicJump addObject:[dicPic objectForKey:@"Url"]];
                [self.arrPicTitles addObject:[dicPic objectForKey:@"Title"]];
            }
            self.AdView.imageURLStringsGroup = self.arrPicUrls;
            self.AdView.placeholderImage = [UIImage imageNamed:@"img_placeHolder"];
        }else{
            HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        }
    }else{
        [SSNetworkRequest getRequest:[apiGetBannerList stringByAppendingString:[self getParamStr]] params:nil success:^(id responseObj){
            
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:@"apiGetBannerList" dictData:responseObj];
                
                self.arrPicUrls = [[NSMutableArray alloc] init];
                self.arrPicJump = [[NSMutableArray alloc] init];
                self.arrPicTitles = [[NSMutableArray alloc] init];
                //构造图片列表和链接列表
                for (NSDictionary *dicPic in [responseObj objectForKey:@"data"]) {
                    [self.arrPicUrls addObject:[dicPic objectForKey:@"Image"]];
                    [self.arrPicJump addObject:[dicPic objectForKey:@"Url"]];
                    [self.arrPicTitles addObject:[dicPic objectForKey:@"Title"]];
                }
                
                
                self.AdView.imageURLStringsGroup = self.arrPicUrls;
                self.AdView.placeholderImage = [UIImage imageNamed:@"img_placeHolder"];
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
            }
        }failure:^(id dataObj, NSError *error) {
            NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:@"apiGetBannerList"];
            if (responseObj) {
                self.arrPicUrls = [[NSMutableArray alloc] init];
                self.arrPicJump = [[NSMutableArray alloc] init];
                self.arrPicTitles = [[NSMutableArray alloc] init];
                //构造图片列表和链接列表
                for (NSDictionary *dicPic in [responseObj objectForKey:@"data"]) {
                    [self.arrPicUrls addObject:[dicPic objectForKey:@"Image"]];
                    [self.arrPicJump addObject:[dicPic objectForKey:@"Url"]];
                    [self.arrPicTitles addObject:[dicPic objectForKey:@"Title"]];
                }
                self.AdView.imageURLStringsGroup = self.arrPicUrls;
                self.AdView.placeholderImage = [UIImage imageNamed:@"img_placeHolder"];
            }else{
                HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
            }
            NSLog(@"数据错误：%@",[error description]);
            
        } headers:nil];
        self.AdView.delegate = self;
    }
}

- (void)loadBasicConfig {
    if (!self.isPushKitStatu) {
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
                [[NSUserDefaults standardUserDefaults] synchronize];
                
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
            }
            
            
            
        }failure:^(id dataObj, NSError *error) {
            
            NSLog(@"数据错误：%@",[error description]);
            
        } headers:nil];
        self.AdView.delegate = self;
    }
    
}

#pragma mark 热门套餐
- (void)loadHotCountry {
    if (self.isPushKitStatu) {
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:@"apiCountryHot"];
        if (responseObj) {
            self.arrCountry = [responseObj objectForKey:@"data"];
            [self.hotCollectionView reloadData];
        }else{
            HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        }
    }else{
        self.checkToken = YES;
        NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"16",@"pageSize", nil];
        [self getBasicHeader];
        NSLog(@"表演头：%@",self.headers);
        [SSNetworkRequest getRequest:apiCountryHot params:params success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:@"apiCountryHot" dictData:responseObj];
                self.arrCountry = [responseObj objectForKey:@"data"];
                [self.hotCollectionView reloadData];
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
            }
            
            NSLog(@"查询到的用户数据：%@",responseObj);
        } failure:^(id dataObj, NSError *error) {
            NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:@"apiCountryHot"];
            if (responseObj) {
                self.arrCountry = [responseObj objectForKey:@"data"];
                [self.hotCollectionView reloadData];
            }else{
                HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
            }
            NSLog(@"啥都没：%@",[error description]);
        } headers:self.headers];
    }
}

- (void)showAlertViewWithMessage:(NSString *)message {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:INTERNATIONALSTRING(message) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *certailAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(@"确定") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"searchNoDevice" object:@"searchNoDevice"];
    }];
    [alertVC addAction:certailAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return 1;
            break;
        case 1:
                if (self.arrOrderList.count>0){
                    if (self.arrOrderList.count ==1) {
                        self.orderFoot1.hidden = YES;
                        self.orderFoot2.hidden = YES;
                    }
                    if (self.arrOrderList.count == 2) {
                        self.orderFoot1.hidden = YES;
                    }
                    return self.arrOrderList.count+1;
                }else{
                    return 2;
                }
            break;
        case 2:
            return 2;
            break;
            
        default:
            return 0;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==0) {
        return 120*[UIScreen mainScreen].bounds.size.width/340+92;
    } else if(indexPath.section==1){
        if (self.arrOrderList.count>0){
            if (indexPath.row==0) {
                return 32*[UIScreen mainScreen].bounds.size.width/320;
            } else {
                return 50*[UIScreen mainScreen].bounds.size.width/320;
            }
        }else{
            return 0;
        }
    }else if(indexPath.section==2){
        if (indexPath.row==0) {
            return 36*[UIScreen mainScreen].bounds.size.width/320;
        } else {
            //后边按实际的热门套餐数量
            return 320*[UIScreen mainScreen].bounds.size.width/320 * 0.75;
        }
    }else return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==1) {
        
        switch (indexPath.row) {
            case 1:
                if (self.arrOrderList.count>0) {
                    [self showDetail:0];
                }
                
                break;
            case 2:
                [self showDetail:1];
                break;
            case 3:
                [self showDetail:2];
                break;
            default:
                break;
        }
    }
}

- (void)showDetail :(NSInteger)index {
    NSDictionary *dicOrder = [self.arrOrderList objectAtIndex:index];
    ActivateGiftCardViewController *giftCardVC = [[ActivateGiftCardViewController alloc] init];
    giftCardVC.packageCategory = [dicOrder[@"PackageCategory"] intValue];
    giftCardVC.idOrder = dicOrder[@"OrderID"];
    [self.navigationController pushViewController:giftCardVC animated:YES];
}

- (IBAction)viewAllOrders:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Order" bundle:nil];
    if (storyboard) {
        self.tabBarController.tabBar.hidden = YES;
        UIViewController *orderListViewController = [storyboard instantiateViewControllerWithIdentifier:@"orderListViewController"];
        if (orderListViewController) {
            [self.navigationController pushViewController:orderListViewController animated:YES];
        }
    }
}

- (IBAction)viewAllContury:(id)sender {
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Package" bundle:nil];
    UIViewController *countryListViewController = [mainStory instantiateViewControllerWithIdentifier:@"countryListViewController"];
    if (countryListViewController) {
        self.tabBarController.tabBar.hidden = YES;
        [self.navigationController pushViewController:countryListViewController animated:YES];
    }
}

#pragma mark --HotCountryCollectionView

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger size=[UIScreen mainScreen].bounds.size.width/4;
    return CGSizeMake(size, size);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    //先获取数据
    
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return  [self.arrCountry count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CountryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CountryCell" forIndexPath:indexPath];
    NSDictionary *dicCountry = [self.arrCountry objectAtIndex:indexPath.row];
    
    cell.lblCountryName.text = [dicCountry objectForKey:@"CountryName"];
    [cell.ivCountry sd_setImageWithURL:[NSURL URLWithString:[dicCountry objectForKey:@"LogoPic"]]];
    cell.urlPic = [dicCountry objectForKey:@"Pic"];
    cell.countryID = [dicCountry objectForKey:@"CountryID"];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //开始弹弹弹
    NSDictionary *dicCountry = [self.arrCountry objectAtIndex:indexPath.row];
    
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Package" bundle:nil];
    PackageListViewController *packageListViewController = [mainStory instantiateViewControllerWithIdentifier:@"packageListViewController"];
    if (packageListViewController) {
        self.tabBarController.tabBar.hidden = YES;
        packageListViewController.CountryID = [dicCountry objectForKey:@"CountryID"];
        packageListViewController.dicCountry = dicCountry;
        [self.navigationController pushViewController:packageListViewController animated:YES];
    }
}

- (void)cycleScrollView:(SDCycleScrollView *)cycleScrollView didSelectItemAtIndex:(NSInteger)index {
    NSString *url = [self.arrPicJump objectAtIndex:index];
    NSString *title = [self.arrPicTitles objectAtIndex:index];
    if ((NSNull*)url!=[NSNull null]) {
        if ([url length]>5) {
            UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            BrowserViewController *browserViewController = [mainStory instantiateViewControllerWithIdentifier:@"browserViewController"];
            if (browserViewController) {
                self.tabBarController.tabBar.hidden = YES;
                browserViewController.loadUrl = url;
                browserViewController.titleStr = title;
                [self.navigationController pushViewController:browserViewController animated:YES];
            }
        }
    }
}

#pragma mark - 蓝牙相关
#pragma mark 绑定设备
- (void)boundingConnectedDevice {
    if ([BlueToothDataManager shareManager].isConnected) {
        [[UNBlueToothTool shareBlueToothTool] checkDeviceIsBound];
    } else {
        [self showAlertWithMessage:@"还没有连接设备，请先连接设备"];
    }
}

#pragma mark 解除绑定
- (void)relieveBoundAction {
    if ([BlueToothDataManager shareManager].isBounded) {
        [BlueToothDataManager shareManager].isAccordBreak = YES;
        if ([BlueToothDataManager shareManager].isConnected && [UNBlueToothTool shareBlueToothTool].peripheral) {
            [[UNBlueToothTool shareBlueToothTool].mgr cancelPeripheralConnection:[UNBlueToothTool shareBlueToothTool].peripheral];
        }
        [BlueToothDataManager shareManager].isTcpConnected = NO;
    } else {
        [self showAlertWithMessage:@"该账号没有绑定设备"];
    }
}

#pragma mark 对卡上电
- (void)upLoadToCard {
    [[UNBlueToothTool shareBlueToothTool] phoneCardToUpeLectrifyWithType:@"02"];
}

#pragma mark 各种蓝牙功能
- (IBAction)checkPastAction:(UIButton *)sender {
    if ([BlueToothDataManager shareManager].isBounded) {
        
        //设置闹钟:闹钟1 开启闹钟 重复 周一到周六 15：30
        //        [self checkClockAlarmSetWithNumber:@"00" open:@"01" reuse:@"00" monday:@"01" tuesday:@"01" wednesday:@"01" thursday:@"01" friday:@"01" saturday:@"01" sunday:@"00" hour:@"16" min:@"38"];
        
        //是否使能抬手功能 00:禁止 01:使能
//        [self sendMessageToBLEWithType:BLEIsUpHands validData:@"01"];
    } else {
        [self showAlertWithMessage:@"还没有连接设备，请先连接设备"];
    }
}

- (void)updateLBEStatuWithPushKit
{
    if (!self.isUpdatedLBEInfo) {
        NSLog(@"更新蓝牙状态==============================");
        self.isPushKitStatu = NO;
        [[UNBlueToothTool shareBlueToothTool] setPushKitStatu:NO];
        [UNPushKitMessageManager shareManager].isQuickLoad = NO;
        [BlueToothDataManager shareManager].bleStatueForCard = 0;
        [BlueToothDataManager shareManager].isTcpConnected = NO;
        [BlueToothDataManager shareManager].isRegisted = NO;
        [BlueToothDataManager shareManager].isBeingRegisting = NO;

        if ([UNBlueToothTool shareBlueToothTool].isInitInstance) {
            [[UNBlueToothTool shareBlueToothTool] sendLBEMessageNoPushKit];
        }else{
            [[UNBlueToothTool shareBlueToothTool] initBlueTooth];
        }

        self.isUpdatedLBEInfo = YES;
    }
}


#pragma mark 注册失败
- (void)registFailAction {
    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
    if ([BlueToothDataManager shareManager].isNeedToResert) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:INTERNATIONALSTRING(@"注册失败，是否复位？") preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(@"取消") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [BlueToothDataManager shareManager].isNeedToResert = NO;
        }];
        UIAlertAction *certailAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(@"确定") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [BlueToothDataManager shareManager].isNeedToResert = YES;
            //发送复位请求
            [[UNBlueToothTool shareBlueToothTool] sendBLESystemResetCommand];
            [BlueToothDataManager shareManager].isReseted = YES;
            [BlueToothDataManager shareManager].isBounded = NO;
            //重新连接
            [[UNBlueToothTool shareBlueToothTool] checkBindedDeviceFromNet];
        }];
        [alertVC addAction:cancelAction];
        [alertVC addAction:certailAction];
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}

#pragma mark ------------发送的数据包------------
#pragma mark 获取空卡序列号第一步
- (void)checkEmptyCardSerialNumberFirst:(NSNotification *)sender {
    [[UNBlueToothTool shareBlueToothTool] checkEmptyCardSerialNumberFirstWithString:sender.object];
}

- (void)dealloc {
    //移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BuyConfrim" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"boundingDevice" object:@"bound"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"relieveBound" object:@"relieve"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"scanToConnect" object:@"connect"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"actionOrderSuccess" object:@"actionOrderSuccess"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"upLoadToCard" object:@"upLoadToCard"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"receiveNewMessageFromBLE" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"homeStatueChanged" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"updataElectic" object:@"updataElectic"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"stopScanBLE" object:@"stopScanBLE"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"cardNumberNotTrue" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"noConnectedAndUnbind" object:@"noConnectedAndUnbind"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"OTAAction" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshStatueToCard" object:@"refreshStatueToCard"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"boundGiftCardSuccess" object:@"boundGiftCardSuccess"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UpdateLBEStatuWithPushKit" object:nil];
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:CNContactStoreDidChangeNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addressBookChanged" object:@"addressBookChanged"];
    }
}

@end
