//
//  HomeViewController.m
//  unitoys
//
//  Created by sumars on 16/9/20.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "HomeViewController.h"
#import "ProductCollectionViewCell.h"
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
#import "CommunicateDetailViewController.h"
#import "UNDataTools.h"

#import "UITabBar+UNRedTip.h"
#import "UNPresentTool.h"
#import "UNPopTipMsgView.h"
#import "AbordSaveViewController.h"
#import "StatuesViewDetailViewController.h"

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

//通话套餐相关
@property (nonatomic, strong)NSMutableArray *communicatePackageDataArr;
@property (weak, nonatomic) IBOutlet UILabel *leftCountLbl;
@property (weak, nonatomic) IBOutlet UILabel *leftNameLbl;
@property (weak, nonatomic) IBOutlet UILabel *leftSubNameLbl;
@property (weak, nonatomic) IBOutlet UILabel *rightCountLbl;
@property (weak, nonatomic) IBOutlet UILabel *rightNameLbl;
@property (weak, nonatomic) IBOutlet UILabel *rightSubNameLbl;

//流量套餐相关
@property (weak, nonatomic) IBOutlet UIImageView *leftFlowImg;
@property (weak, nonatomic) IBOutlet UIImageView *midFlowImg;
@property (weak, nonatomic) IBOutlet UIImageView *rightFlowImg;
@property (weak, nonatomic) IBOutlet UILabel *leftFlowNameLbl;
@property (weak, nonatomic) IBOutlet UILabel *rightFlowNameLbl;
@property (weak, nonatomic) IBOutlet UILabel *midFlowNameLbl;
@property (weak, nonatomic) IBOutlet UILabel *leftFlowSubNameLbl;
@property (weak, nonatomic) IBOutlet UILabel *midFlowSubNameLbl;
@property (weak, nonatomic) IBOutlet UILabel *rightFlowSubNameLbl;
@property (nonatomic, strong) NSMutableArray *productInfoArr;

@property (nonatomic, strong) UNPresentTool *presentTool;
@property (nonatomic, weak) UNPopTipMsgView *popView;
@property (nonatomic, strong)UIView *statuesView;
@property (nonatomic, strong)UILabel *statuesLabel;
@property (nonatomic, strong)UIView *registProgressView;
@property (nonatomic, strong) NSTimer *otaFailTimer;
@property (nonatomic, assign) int otaFailTimeValue;

@end

@implementation HomeViewController

- (NSMutableArray *)productInfoArr {
    if (!_productInfoArr) {
        self.productInfoArr = [NSMutableArray array];
    }
    return _productInfoArr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UNLogLBEProcess(@"HomeViewController----viewDidLoad");
    if (![UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
        [[UNBlueToothTool shareBlueToothTool] initBlueTooth];
    }
    
    [self checkPackageResidue];
    
    //添加状态栏
    self.statuesView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, STATUESVIEWHEIGHT)];
    self.statuesView.backgroundColor = UIColorFromRGB(0xffbfbf);
    //添加手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(jumpToShowDetail)];
    [self.statuesView addGestureRecognizer:tap];
    //添加百分比
    if ([[BlueToothDataManager shareManager].stepNumber intValue] != 0 && [[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_REGISTING]) {
        int longStr = [[BlueToothDataManager shareManager].stepNumber intValue];
        CGFloat progressWidth;
        if ([[BlueToothDataManager shareManager].operatorType intValue] == 1 || [[BlueToothDataManager shareManager].operatorType intValue] == 2) {
            progressWidth = kScreenWidthValue *(longStr/160.00);
        } else if ([[BlueToothDataManager shareManager].operatorType intValue] == 3) {
            progressWidth = kScreenWidthValue *(longStr/340.00);
        } else {
            progressWidth = 0;
        }
        self.registProgressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, progressWidth, STATUESVIEWHEIGHT)];
    } else {
        self.registProgressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, STATUESVIEWHEIGHT)];
    }
    self.registProgressView.backgroundColor = UIColorFromRGB(0xffa0a0);
    [self.statuesView addSubview:self.registProgressView];
    //添加图片
    UIImageView *leftImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_bc"]];
    leftImg.frame = CGRectMake(15, (STATUESVIEWHEIGHT-STATUESVIEWIMAGEHEIGHT)/2, STATUESVIEWIMAGEHEIGHT, STATUESVIEWIMAGEHEIGHT);
    [self.statuesView addSubview:leftImg];
    //添加label
    self.statuesLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftImg.frame)+5, 0, kScreenWidthValue-30-leftImg.frame.size.width, STATUESVIEWHEIGHT)];
//    self.statuesLabel.text = [BlueToothDataManager shareManager].statuesTitleString;
    [self setStatuesLabelTextWithLabel:self.statuesLabel String:[BlueToothDataManager shareManager].statuesTitleString];
    self.statuesLabel.font = [UIFont systemFontOfSize:14];
    self.statuesLabel.textColor = UIColorFromRGB(0x999999);
    [self.statuesView addSubview:self.statuesLabel];
    if (![self isNeedToShowBLEStatue]) {
        self.statuesView.un_height = 0;
        self.registProgressView.un_width = 0;
        [self.tableView reloadData];
    }
    
    
    self.communicatePackageDataArr = [NSMutableArray array];
    [UNPushKitMessageManager shareManager].isAppAlreadyLoad = YES;
    self.isPushKitStatu = [UNPushKitMessageManager shareManager].isPushKitFromAppDelegate;
    self.navigationItem.leftBarButtonItem = nil;
    
//    if (![UNPushKitMessageManager shareManager].isPushKitFromAppDelegate) {
//        [[UNBlueToothTool shareBlueToothTool] initBlueTooth];
//    }
    kWeakSelf
    [UNBlueToothTool shareBlueToothTool].updateButtonImageAndTitleBlock = ^(NSString *title){
        UNDebugLogVerbose(@"updateButtonImageAndTitleBlock---%@", title);
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
        NSString *showMessageStr;
        if ([[BlueToothDataManager shareManager].operatorType isEqualToString:@"0"]) {
            showMessageStr = @"读取设备内SIM卡失败，请重启设备重新检测？";
        } else {
            showMessageStr = @"未能检测到设备内有电话卡，您需要重启设备重新检测吗？";
        }
        [weakSelf dj_alertAction:self alertTitle:nil actionTitle:@"重启" message:showMessageStr alertAction:^{
            [BlueToothDataManager shareManager].isNeedToResert = YES;
            [BlueToothDataManager shareManager].isBeingShowAlert = NO;
            //发送复位请求
            [[UNBlueToothTool shareBlueToothTool] sendBLESystemResetCommand];
            [BlueToothDataManager shareManager].isReseted = YES;
//            [BlueToothDataManager shareManager].isBounded = NO;
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
    
//    [self loadOrderList];
    
    [self loadHotCountry];
    
    [self loadBasicConfig];
    
    [self loadProductInfo];
    
    [self checkCommunicatePackageData];
    
    //境外通讯
    UITapGestureRecognizer *abroadMessage = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(abroadMessageAction)];
    [self.ivQuickSetting addGestureRecognizer:abroadMessage];
    
    //双卡双待
    UITapGestureRecognizer *doubleCards = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleCardsAction)];
    [self.ivDevices addGestureRecognizer:doubleCards];
    
    //通话套餐
    UITapGestureRecognizer *phonePackage = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(phonePackageAction)];
    [self.ivTutorial addGestureRecognizer:phonePackage];
    
    //接收通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(paySuccess) name:@"BuyConfrim" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundingConnectedDevice) name:@"boundingDevice" object:@"bound"];//绑定
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(relieveBoundAction) name:@"relieveBound" object:@"relieve"];//解绑
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkBindedDeviceFromNet) name:@"scanToConnect" object:@"connect"];//扫描并连接设备
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activitySuccessAction) name:@"actionOrderSuccess" object:@"actionOrderSuccess"];//激活套餐成功
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatues:) name:@"netWorkNotToUse" object:nil];//网络状态不可用
    
    //tabbar显示红点
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mallExtendMessage:) name:@"MallExtendMessage" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tipMessageStatuChange) name:@"TipMessageStatuChange" object:nil];
    
    //处理状态栏文字及高度
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(homeViewChangeStatuesView:) name:@"changeStatuesViewLable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showRegistProgress:) name:@"changeStatue" object:nil];//改变状态和百分比
    [[BlueToothDataManager shareManager] addObserver:self forKeyPath:@"isShowStatuesView" options:NSKeyValueObservingOptionInitial context:nil];
    
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
    [self checkVersion];
    
    NSDictionary *extras = [[NSUserDefaults standardUserDefaults] objectForKey:@"JPushMallMessage"];
    if (extras) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UNDataTools sharedInstance].isHasMallMessage = YES;
            //弹出页面
            [self updateMallTipMessage:extras];
        });
    }
    [self tipMessageStatuChange];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    [self changeStatueViewHeightWithString:[BlueToothDataManager shareManager].statuesTitleString];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"currentStatueChangedAndHeightChange" object:@"currentStatueChangedAndHeightChange"];
}

#pragma mark 手势点击事件
- (void)jumpToShowDetail {
    if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_REGISTING] || [[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_NOTCONNECTED]) {
        if ([BlueToothDataManager shareManager].isBounded) {
            //有绑定
            UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
            BindDeviceViewController *bindDeviceViewController = [mainStory instantiateViewControllerWithIdentifier:@"bindDeviceViewController"];
            if (bindDeviceViewController) {
                self.tabBarController.tabBar.hidden = YES;
                bindDeviceViewController.hintStrFirst = [BlueToothDataManager shareManager].statuesTitleString;
                [self.navigationController pushViewController:bindDeviceViewController animated:YES];
            }
        }
    } else {
        StatuesViewDetailViewController *statuesViewDetailVC = [[StatuesViewDetailViewController alloc] init];
        [self.navigationController pushViewController:statuesViewDetailVC animated:YES];
    }
}

- (void)homeViewChangeStatuesView:(NSNotification *)sender {
    UNDebugLogVerbose(@"状态栏文字 --> %@, %s, %d", sender.object, __FUNCTION__, __LINE__);
    [self changeStatueViewHeightWithString:sender.object];
}

- (void)changeStatueViewHeightWithString:(NSString *)statuesStr {
    [self changeBleStatue];
    [self setStatuesLabelTextWithLabel:self.statuesLabel String:[BlueToothDataManager shareManager].statuesTitleString];
    if (![self isNeedToShowBLEStatue]) {
        self.statuesView.un_height = 0;
        self.registProgressView.un_width = 0;
    } else {
        if (![statuesStr isEqualToString:HOMESTATUETITLE_REGISTING]) {
            self.registProgressView.un_width = 0;
        }
        self.statuesView.un_height = STATUESVIEWHEIGHT;
    }
    
    [self.tableView reloadData];
}

- (void)showRegistProgress:(NSNotification *)sender {
    NSString *senderStr = [NSString stringWithFormat:@"%@", sender.object];
    UNDebugLogVerbose(@"接收到传过来的通知 -- %@", senderStr);
    if (![BlueToothDataManager shareManager].isRegisted && [BlueToothDataManager shareManager].isBeingRegisting) {
        [self countAndShowRegistPercentage:senderStr];
    } else {
        UNDebugLogVerbose(@"注册成功的时候处理");
    }
}

- (void)countAndShowRegistPercentage:(NSString *)senderStr {
    if ([[BlueToothDataManager shareManager].operatorType intValue] == 1 || [[BlueToothDataManager shareManager].operatorType intValue] == 2) {
        if ([senderStr intValue] < 160) {
            float count = (float)[senderStr intValue]/160;
            self.registProgressView.un_width = kScreenWidthValue * count;
        } else {
            self.registProgressView.un_width = kScreenWidthValue * 0.99;
        }
    } else if ([[BlueToothDataManager shareManager].operatorType intValue] == 3) {
        if ([senderStr intValue] < 340) {
            float count = (float)[senderStr intValue]/340;
            self.registProgressView.un_width = kScreenWidthValue * count;
        } else {
            self.registProgressView.un_width = kScreenWidthValue * 0.99;
        }
    } else {
        self.registProgressView.un_width = 0;
    }
}

//商城红点
- (void)mallExtendMessage:(NSNotification *)noti
{
    [self updateMallTipMessage:noti.userInfo];
}

- (void)updateMallTipMessage:(NSDictionary *)extras
{
    if ([UNDataTools sharedInstance].isHasMallMessage) {
        if (extras) {
            //展示红点
            [self.tabBarController.tabBar showBadgeOnItemIndex:0];
            //弹出提示页面
            [self showMallExtendMessageView:extras];
        }else{
            [UNDataTools sharedInstance].isHasMallMessage = NO;
            //隐藏红点
            [self.tabBarController.tabBar hideBadgeOnItemIndex:0];
            //删除消息
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"JPushMallMessage"]) {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"JPushMallMessage"];
            }
        }
    }else{
        //隐藏红点
        [self.tabBarController.tabBar hideBadgeOnItemIndex:0];
        //删除消息
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"JPushMallMessage"]) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"JPushMallMessage"];
        }
    }
}

//我的Tabbar红点
- (void)tipMessageStatuChange
{
    if ([UNDataTools sharedInstance].isHasNotActiveTip || [UNDataTools sharedInstance].isHasFirmwareUpdateTip) {
        [self.tabBarController.tabBar showBadgeOnItemIndex:3];
    }else{
        [self.tabBarController.tabBar hideBadgeOnItemIndex:3];
    }
}

- (void)showMallExtendMessageView:(NSDictionary *)extras
{
    
    //Title:标题
    //Url:链接地址
    //ID:唯一标识
//    if (extras) {
//        [self initPopView:extras];
//    }
    [self loadProductInfo];
}

- (void)initPopView:(NSDictionary *)extras
{
    if (!_presentTool) {
        _presentTool = [UNPresentTool new];
    }
    if (_popView) {
        return;
    }
    
    NSString *title;
//    NSString *url = extras[@"Url"];
//    NSString *productId = extras[@"ID"];
    if (extras[@"Title"]) {
        title = extras[@"Title"];
    }else{
        title = @"提示";
    }
    UNPopTipMsgView *view = [UNPopTipMsgView sharePopTipMsgViewTitle:title detailTitle:@"有新的流量套餐出现了,是否去看看"];
    _popView = view;
    view.leftButtonText = @"下次再去";
    view.rightButtonText = @"去看看";
    kWeakSelf
    view.popTipButtonAction = ^(NSInteger type) {
        [UNDataTools sharedInstance].isHasMallMessage = NO;
        //隐藏红点
        [weakSelf updateMallTipMessage:nil];
        [weakSelf.presentTool dismissDuration:0.5 completion:^{
            weakSelf.presentTool = nil;
            if (type == 2) {
                UNDebugLogVerbose(@"push新界面----%@",extras);
            }
        }];
    };
    [_presentTool presentContentView:view duration:0.85 inView:nil];
}

//查询是否有未激活套餐
- (void)checkPackageResidue {
    self.checkToken = YES;
    [self getBasicHeader];
    [SSNetworkRequest getRequest:apiGetUserOrderUsageRemaining params:nil success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            if ([responseObj[@"data"][@"Unactivated"][@"TotalNumFlow"] intValue]) {
                //总未激活流量套餐数
                [UNDataTools sharedInstance].isHasNotActiveTip = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"TipMessageStatuChange" object:nil];
            }else{
                [UNDataTools sharedInstance].isHasNotActiveTip = NO;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"TipMessageStatuChange" object:nil];
            }
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
        UNDebugLogVerbose(@"查询到的用户套餐余量：%@",responseObj);
    } failure:^(id dataObj, NSError *error) {
        UNDebugLogVerbose(@"啥都没：%@",[error description]);
    } headers:self.headers];
}


- (void)networkStatues:(NSNotification *)sender {
    if ([sender.object isEqualToString:@"1"] && [BlueToothDataManager shareManager].isConnected) {
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] isEqualToString:@"on"]) {
            [[UNBlueToothTool shareBlueToothTool] checkSystemInfo];
        } else {
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTSERVICE];
        }
    }
}

- (void)checkVersion {
    [self getBasicHeader];
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"0", @"TerminalCode", [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"], @"Version", nil];
    [SSNetworkRequest getRequest:apiUpgrade params:info success:^(id responseObj){
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            UNDebugLogVerbose(@"app升级信息 -- %@", responseObj);
            if (responseObj[@"data"][@"Descr"]) {
                
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                // hh与HH的区别:分别表示12小时制,24小时制
                [formatter setDateFormat:@"YYYY-MM-dd"];
                NSDate *datenow = [NSDate date];
                NSString *currentTimeString = [formatter stringFromDate:datenow];
                NSString *timeString = [[NSUserDefaults standardUserDefaults] objectForKey:@"nowTime"];
                if (![timeString isEqualToString:currentTimeString]) {
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
                        UNDebugLogVerbose(@"不知道是不是强制性的");
                    }
                    if ([responseObj[@"data"][@"Mandatory"] intValue] == 0) {
                        //非强制性的才存储
                        [[NSUserDefaults standardUserDefaults] setObject:currentTimeString forKey:@"nowTime"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                }
            }
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            UNDebugLogVerbose(@"数据请求失败 -- %@", responseObj[@"mag"]);
        }
    }failure:^(id dataObj, NSError *error) {
        HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        UNDebugLogVerbose(@"数据错误：%@",[error description]);
        
    } headers:self.headers];
}

- (void)dj_alertActionWithAlertTitle:(NSString *)alertTitle leftActionTitle:(NSString *)leftActionTitle rightActionTitle:(NSString *)rightActionTitle message:(NSString *)message rightAlertAction:(void (^)())rightAlertAction {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:INTERNATIONALSTRING(alertTitle) message:INTERNATIONALSTRING(message) preferredStyle:UIAlertControllerStyleAlert];
    [self setAlertMessageTextAlignment:alertVC];
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
    [self setAlertMessageTextAlignment:alertVC];
    UIAlertAction *certailAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(rightActionTitle) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showMustAlert:alertVC];
        rightAlertAction();
    }];
    [alertVC addAction:certailAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)setAlertMessageTextAlignment:(UIAlertController *)alertController {
    UIView *subView1 = alertController.view.subviews[0];
    UIView *subView2 = subView1.subviews[0];
    UIView *subView3 = subView2.subviews[0];
    UIView *subView4 = subView3.subviews[0];
    UIView *subView5 = subView4.subviews[0];
    NSLog(@"%@",subView5.subviews);
    //取title和message：
//    UILabel *title = subView5.subviews[0];
    UILabel *message = subView5.subviews[1];
    message.textAlignment = NSTextAlignmentLeft;
}

- (void)showMustAlert:(UIAlertController *)alertVC {
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)dj_alertAction:(UIViewController *)controller alertTitle:(NSString *)alertTitle actionTitle:(NSString *)actionTitle message:(NSString *)message alertAction:(void (^)())alertAction {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:INTERNATIONALSTRING(alertTitle) message:INTERNATIONALSTRING(message) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(@"取消") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [BlueToothDataManager shareManager].isBeingShowAlert = NO;
    }];
    UIAlertAction *certailAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(actionTitle) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        alertAction();
    }];
    [alertVC addAction:cancelAction];
    [alertVC addAction:certailAction];
    [controller presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark 获取通话套餐数据
- (void)checkCommunicatePackageData {
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"pageNumber", @"20",@"pageSize",@"1", @"category", nil];
    NSString *apiNameStr = [NSString stringWithFormat:@"%@category%@", @"apiPackageGet", @"1"];
    [self getBasicHeader];
    //    UNDebugLogVerbose(@"表头：%@",self.headers);
    [SSNetworkRequest getRequest:apiPackageGet params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:apiNameStr dictData:responseObj];
            UNDebugLogVerbose(@"首页获取到的通话套餐:%@", responseObj);
            self.communicatePackageDataArr = responseObj[@"data"][@"list"];
            [self refreshCommunicatePackage];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
    } failure:^(id dataObj, NSError *error) {
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:apiNameStr];
        if (responseObj) {
            self.communicatePackageDataArr = responseObj[@"data"][@"list"];
            [self refreshCommunicatePackage];
        }
        UNDebugLogVerbose(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

- (void)refreshCommunicatePackage {
    NSDictionary *firstDict = self.communicatePackageDataArr[0];
    self.leftCountLbl.text = [NSString stringWithFormat:@"%@元", firstDict[@"Price"]];
    self.leftNameLbl.text = firstDict[@"PackageName"];
    self.leftSubNameLbl.text = [NSString stringWithFormat:@"有效期%@天", firstDict[@"ExpireDays"]];
    NSDictionary *secondDict = self.communicatePackageDataArr[1];
    self.rightCountLbl.text = [NSString stringWithFormat:@"%@元", secondDict[@"Price"]];
    self.rightNameLbl.text = secondDict[@"PackageName"];
    self.rightSubNameLbl.text = [NSString stringWithFormat:@"有效期%@天", secondDict[@"ExpireDays"]];
//    [self.tableView reloadData];
}

#pragma mark 手势点击事件
- (IBAction)leftAction:(UITapGestureRecognizer *)sender {
    NSDictionary *dict = self.communicatePackageDataArr[0];
    CommunicateDetailViewController *communicateDetailVC = [[CommunicateDetailViewController alloc] init];
    communicateDetailVC.communicateDetailID = dict[@"PackageId"];
    [self.navigationController pushViewController:communicateDetailVC animated:YES];
}

- (IBAction)rightAction:(UITapGestureRecognizer *)sender {
    NSDictionary *dict = self.communicatePackageDataArr[1];
    CommunicateDetailViewController *communicateDetailVC = [[CommunicateDetailViewController alloc] init];
    communicateDetailVC.communicateDetailID = dict[@"PackageId"];
    [self.navigationController pushViewController:communicateDetailVC animated:YES];
}

- (IBAction)leftFlowAction:(UITapGestureRecognizer *)sender {
    NSDictionary *dicCountry = self.arrCountry[0];
    
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Package" bundle:nil];
    PackageListViewController *packageListViewController = [mainStory instantiateViewControllerWithIdentifier:@"packageListViewController"];
    if (packageListViewController) {
        self.tabBarController.tabBar.hidden = YES;
        packageListViewController.CountryID = [dicCountry objectForKey:@"CountryID"];
        packageListViewController.dicCountry = dicCountry;
        [self.navigationController pushViewController:packageListViewController animated:YES];
    }
}

- (IBAction)midFlowAction:(UITapGestureRecognizer *)sender {
    NSDictionary *dicCountry = self.arrCountry[1];
    
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Package" bundle:nil];
    PackageListViewController *packageListViewController = [mainStory instantiateViewControllerWithIdentifier:@"packageListViewController"];
    if (packageListViewController) {
        self.tabBarController.tabBar.hidden = YES;
        packageListViewController.CountryID = [dicCountry objectForKey:@"CountryID"];
        packageListViewController.dicCountry = dicCountry;
        [self.navigationController pushViewController:packageListViewController animated:YES];
    }
}

- (IBAction)rightFlowAction:(UITapGestureRecognizer *)sender {
    NSDictionary *dicCountry = self.arrCountry[2];
    
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Package" bundle:nil];
    PackageListViewController *packageListViewController = [mainStory instantiateViewControllerWithIdentifier:@"packageListViewController"];
    if (packageListViewController) {
        self.tabBarController.tabBar.hidden = YES;
        packageListViewController.CountryID = [dicCountry objectForKey:@"CountryID"];
        packageListViewController.dicCountry = dicCountry;
        [self.navigationController pushViewController:packageListViewController animated:YES];
    }
}

- (IBAction)abordGuide:(UITapGestureRecognizer *)sender {
//    HUDNormal(@"海外节费引导")
    AbordSaveViewController *abordSaveVC = [[AbordSaveViewController alloc] init];
    [self.navigationController pushViewController:abordSaveVC animated:YES];
}

#pragma mark 刷新卡状态
- (void)refreshStatueToCard {
    UNDebugLogVerbose(@"刷新卡状态");
    if ([BlueToothDataManager shareManager].isConnected) {
        [BlueToothDataManager shareManager].bleStatueForCard = 0;
        //对卡上电
        [[UNBlueToothTool shareBlueToothTool] checkSystemInfo];
    }else{
        UNDebugLogVerbose(@"蓝牙未连接");
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
        UNDebugLogVerbose(@"蓝牙未连接");
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
        UNDebugLogVerbose(@"蓝牙未连接");
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
            UNDebugLogVerbose(@"打不开");
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
//    [BlueToothDataManager shareManager].statuesTitleString = title;
    [self changeBleStatue];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeStatueAll" object:title];
}

-(void)addressBookDidChange:(NSNotification*)notification{
    UNDebugLogVerbose(@"通讯录有变化");
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
            //将连接的信息存储到本地
            NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
            NSMutableDictionary *boundedDeviceInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"boundedDeviceInfo"]];
            if ([boundedDeviceInfo objectForKey:userdata[@"Tel"]]) {
                UNDebugLogVerbose(@"空中升级的时候删除本地绑定信息前的数据 %s,%d %@", __FUNCTION__, __LINE__, boundedDeviceInfo);
                [boundedDeviceInfo removeObjectForKey:userdata[@"Tel"]];
            }
            [[NSUserDefaults standardUserDefaults] setObject:boundedDeviceInfo forKey:@"boundedDeviceInfo"];
            UNDebugLogVerbose(@"空中升级的时候存储请求的绑定信息 %s,%d %@", __FUNCTION__, __LINE__, boundedDeviceInfo);
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[UNBlueToothTool shareBlueToothTool] oatUpdateCommand];
            [BlueToothDataManager shareManager].isBeingOTA = YES;
            [self showProgress];
            NSURL *downloadURL = [NSURL URLWithString:sender.object];
            [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:downloadURL] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                //下载完成之后的回调
                // 文件路径
                NSString* ceches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
                NSString* filepath = [ceches stringByAppendingPathComponent:response.suggestedFilename];
                UNDebugLogVerbose(@"文件路径 --> %@", filepath);
                
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
//                                NSString *pathStr = [[NSBundle mainBundle] pathForResource:@"unibox1.20" ofType:@"zip"];
                    
                    NSURL *fileURL = [NSURL fileURLWithPath:filepath];
//                                NSURL *fileURL = [NSURL fileURLWithPath:pathStr];
                    DFUFirmware *selectedFirmware = [[DFUFirmware alloc] initWithUrlToZipFile:fileURL type:DFUFirmwareTypeApplication];
                    UNDebugLogVerbose(@"mgr---%@=====peripheral----%@",[UNBlueToothTool shareBlueToothTool].mgr,[UNBlueToothTool shareBlueToothTool].peripheral);
                    DFUServiceInitiator *initiator = [[DFUServiceInitiator alloc] initWithCentralManager:[UNBlueToothTool shareBlueToothTool].mgr target:[UNBlueToothTool shareBlueToothTool].peripheral];
                    [initiator withFirmwareFile:selectedFirmware];
                    initiator.delegate = self;
                    initiator.logger = self;
                    initiator.progressDelegate = self;
                    self.myController = [initiator start];//开始升级
                });
            }];
        } else {
            UNDebugLogVerbose(@"URL有问题");
        }
    }else{
        UNDebugLogVerbose(@"蓝牙未连接");
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
    UNDebugLogVerbose(@"显示升级状态 --> %ld", (long)state);
//    if (state == 6&&self.progressWindow) {
//        self.myController = nil;
//    }
}

- (void)didErrorOccur:(enum DFUError)error withMessage:(NSString *)message {
    UNDebugLogVerbose(@"ERROR %ld:%@", (long)error, message);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        self.progressWindow = nil;
        self.progressNumberLabel.text = INTERNATIONALSTRING(@"升级失败\n120s后重新连接双待王");
        UNDebugLogVerbose(@"[BlueToothDataManager shareManager].isBeingOTA = NO;%s%d", __FUNCTION__, __LINE__);
        [BlueToothDataManager shareManager].isBeingOTA = NO;
    });
    [self startOtaFailTimer];
}

- (void)startOtaFailTimer {
    self.otaFailTimeValue = 120;
    if (!self.otaFailTimer) {
        self.otaFailTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(actionToOtaFailTimer) userInfo:nil repeats:YES];
        //如果不添加下面这条语句，在UITableView拖动的时候，会阻塞定时器的调用
        [[NSRunLoop currentRunLoop] addTimer:self.otaFailTimer forMode:UITrackingRunLoopMode];
    } else {
        [self.otaFailTimer setFireDate:[NSDate distantPast]];
    }
}

- (void)actionToOtaFailTimer {
    if (self.otaFailTimeValue == 0) {
        self.myController = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OTASuccessAndReConnectedNotif" object:@"OTASuccessAndReConnectedNotif"];
        [[UNBlueToothTool shareBlueToothTool] clearInstance];
        [[UNBlueToothTool shareBlueToothTool] initBlueTooth];
        [self hiddenProgressWindow];
        [self.otaFailTimer setFireDate:[NSDate distantFuture]];
    } else {
        self.progressNumberLabel.text = [NSString stringWithFormat:@"升级失败\n%ds后重新连接双待王", self.otaFailTimeValue];
    }
    self.otaFailTimeValue--;
//    UNDebugLogVerbose(@"升级失败正在计时 -- %d", self.otaFailTimeValue);
}

- (void)onUploadProgress:(NSInteger)part totalParts:(NSInteger)totalParts progress:(NSInteger)progress currentSpeedBytesPerSecond:(double)currentSpeedBytesPerSecond avgSpeedBytesPerSecond:(double)avgSpeedBytesPerSecond {
    //进度
    UNDebugLogVerbose(@"dfuProgressChangedFor: %ld%% (part %ld/%ld).speed:%f bps, Avg speed:%f bps", (long)progress, (long)part, (long)totalParts, currentSpeedBytesPerSecond, avgSpeedBytesPerSecond);
    self.progressNumberLabel.text = [NSString stringWithFormat:@"%ld%%\n%@", (long)progress, INTERNATIONALSTRING(@"升级过程中请勿退出程序")];
    if (self.progressView.hidden) {
        self.progressView.hidden = NO;
    }
    self.progressView.selectedMinimum = (float)progress/100;
//    UNDebugLogVerbose(@"当前百分比%f", (float)progress/100);
    if (progress == 100) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.progressNumberLabel.text = INTERNATIONALSTRING(@"升级成功\n正在重新连接双待王");
            self.myController = nil;
            [BlueToothDataManager shareManager].isBeingOTA = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"OTASuccessAndReConnectedNotif" object:@"OTASuccessAndReConnectedNotif"];
            [[UNBlueToothTool shareBlueToothTool] clearInstance];
            [[UNBlueToothTool shareBlueToothTool] initBlueTooth];
            [self hiddenProgressWindow];
            UNDebugLogVerbose(@"[BlueToothDataManager shareManager].isBeingOTA = NO;%s%d", __FUNCTION__, __LINE__);
        });
    }
}

- (void)hiddenProgressWindow {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.progressWindow = nil;
        self.progressWindow.hidden = YES;
    });
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
    UNDebugLogVerbose(@"升级步骤显示 --> %ld, %@", (long)level, message);
}

#pragma mark 进度条布局
- (void)showProgress {
    if (!self.progressWindow) {
        self.progressWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
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
    UNDebugLogVerbose(@"获取卡数据---%@", tempStr);
    if ([BlueToothDataManager shareManager].isConnected) {
        [[UNBlueToothTool shareBlueToothTool] sendBLECardDataWithValidData:tempStr];
    }else{
        UNDebugLogVerbose(@"蓝牙未连接");
        dispatch_async(dispatch_get_main_queue(), ^{
            HUDNormal(INTERNATIONALSTRING(@"蓝牙未连接"))
        });
    }
}

- (void)sendNewMessageToBLEWithPushKit:(NSString *)sendString
{
    if ([BlueToothDataManager shareManager].isConnected) {
        UNDebugLogVerbose(@"获取卡数据从pushkit---%@", sendString);
        [[UNBlueToothTool shareBlueToothTool] sendBLECardDataWithValidData:sendString];
    }else{
        UNDebugLogVerbose(@"蓝牙未连接");
        dispatch_async(dispatch_get_main_queue(), ^{
            HUDNormal(INTERNATIONALSTRING(@"蓝牙未连接"))
        });
    }
}

#pragma mark - 通讯录
- (void)fetchAddressBookBeforeIOS9{
    self.contactsDataArr = [[NSArray alloc] init];
    if ([AddressBookManager shareManager].dataArr.count) {
        [[AddressBookManager shareManager].dataArr removeAllObjects];
    }
    ABAddressBookRef addressBook = ABAddressBookCreate(); //首次访问需用户授权
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {//首次访问通讯录
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) { if (!error) { if (granted) {//允许
            UNDebugLogVerbose(@"已授权访问通讯录"); NSArray *contacts = [self fetchContactWithAddressBook:addressBook]; dispatch_async(dispatch_get_main_queue(), ^{
                //----------------主线程 更新 UI-----------------
//                UNDebugLogVerbose(@"contacts:%@", contacts);
                _contactsDataArr = contacts;
                for (NSDictionary *subDic in self.contactsDataArr) {
                    ContactModel *model=[[ContactModel alloc]initWithDic:subDic];
                    [[AddressBookManager shareManager].dataArr addObject:model];
                }
                [AddressBookManager shareManager].rowArr=[ContactDataHelper getFriendListDataBy:[AddressBookManager shareManager].dataArr];
                [AddressBookManager shareManager].sectionArr=[ContactDataHelper getFriendListSectionBy:[[AddressBookManager shareManager].rowArr mutableCopy]];
            });
            
        }else{//拒绝
            UNDebugLogVerbose(@"拒绝访问通讯录"); } }else{ UNDebugLogVerbose(@"发生错误!");
            }
        });
    }else{
        //非首次访问通讯录
        NSArray *contacts = [self fetchContactWithAddressBook:addressBook];
        CFRelease(addressBook);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //----------------主线程 更新 UI-----------------
            _contactsDataArr = contacts;
//            UNDebugLogVerbose(@"contacts:%@", contacts);
            
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
            ABRecordID peopleValue = ABRecordGetRecordID(people);
            NSString *firstName = (__bridge NSString *)ABRecordCopyValue(people, kABPersonFirstNameProperty);
            NSString *lastName = (__bridge NSString *)ABRecordCopyValue(people, kABPersonLastNameProperty);
            NSData * thumbnailImageData;
            if(ABPersonHasImageData(people)){
                thumbnailImageData = (__bridge NSData *)ABPersonCopyImageDataWithFormat(people,kABPersonImageFormatThumbnail);
            }else{
                UIImage *image = [UIImage imageNamed:@"default_icon"];
                thumbnailImageData = UIImagePNGRepresentation(image);
            }
            ABMutableMultiValueRef phoneNumRef = ABRecordCopyValue(people, kABPersonPhoneProperty);
            NSArray *arrNumber = ((__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(phoneNumRef));
            NSString *phoneNumber = arrNumber.firstObject;
            if (arrNumber.firstObject) {
                for (int i=1; i<arrNumber.count; i++) {
                    phoneNumber = [phoneNumber stringByAppendingString:[NSString stringWithFormat:@",%@",[arrNumber objectAtIndex:i]]];
                }
            }
            if (firstName && lastName) {
                if ((phoneNumber)&&([lastName stringByAppendingString:firstName])) {
                    [contacts addObject:@{@"name": [lastName stringByAppendingString:firstName], @"phoneNumber": phoneNumber, @"portrait":[NSString stringWithFormat:@"con_face%d",[self getRandomNumber:1 to:3]],@"thumbnailImageData":thumbnailImageData, @"recordRefId" : @(peopleValue)}];
                }
            } else if (firstName && !lastName) {
                if (phoneNumber) {
                    [contacts addObject:@{@"name": firstName, @"phoneNumber": phoneNumber, @"portrait":[NSString stringWithFormat:@"con_face%d",[self getRandomNumber:1 to:3]],@"thumbnailImageData":thumbnailImageData, @"recordRefId" : @(peopleValue)}];
                }
            } else if (!firstName && lastName) {
                if (phoneNumber) {
                    [contacts addObject:@{@"name": lastName, @"phoneNumber": phoneNumber, @"portrait":[NSString stringWithFormat:@"con_face%d",[self getRandomNumber:1 to:3]],@"thumbnailImageData":thumbnailImageData, @"recordRefId" : @(peopleValue)}];
                }
            } else {
                UNDebugLogVerbose(@"9.0以前的系统，通讯录数据格式不正确");
                if (phoneNumber) {
                    [contacts addObject:@{@"name": phoneNumber, @"phoneNumber": phoneNumber, @"portrait":[NSString stringWithFormat:@"con_face%d",[self getRandomNumber:1 to:3]],@"thumbnailImageData":thumbnailImageData, @"recordRefId" : @(peopleValue)}];
                } else {
                    UNDebugLogVerbose(@"通讯录没有号码");
                }
            }
        }
        return contacts;
    }else{//无权限访问
        UNDebugLogVerbose(@"无权限访问通讯录");
        return nil;
    }
}


- (void)fetchAddressBookOnIOS9AndLater{ //创建CNContactStore对象
    self.contactsDataArr = [[NSArray alloc] init];
    if ([AddressBookManager shareManager].dataArr.count) {
        [[AddressBookManager shareManager].dataArr removeAllObjects];
    }
    CNContactStore *contactStore = [[CNContactStore alloc] init]; //首次访问需用户授权
    if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusNotDetermined)
    {//首次访问通讯录
        [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error){
            if (!error){
                if (granted) {//允许
                    UNDebugLogVerbose(@"已授权访问通讯录");
                    NSArray *contacts = [self fetchContactWithContactStore:contactStore];//访问通讯录
                    dispatch_async(dispatch_get_main_queue(),^{ //----------------主线程 更新 UI-----------------
//                        UNDebugLogVerbose(@"contacts:%@", contacts);
                        _contactsDataArr = contacts;
                        for (NSDictionary *subDic in self.contactsDataArr) {
                            ContactModel *model=[[ContactModel alloc]initWithDic:subDic];
                            [[AddressBookManager shareManager].dataArr addObject:model];
                        }
                        [AddressBookManager shareManager].rowArr=[ContactDataHelper getFriendListDataBy:[AddressBookManager shareManager].dataArr];
                        [AddressBookManager shareManager].sectionArr=[ContactDataHelper getFriendListSectionBy:[[AddressBookManager shareManager].rowArr mutableCopy]];
                    });
                }else{//拒绝
                    UNDebugLogVerbose(@"拒绝访问通讯录");
                }
            }else{
                UNDebugLogVerbose(@"发生错误!");
            }
        }];
    }else{//非首次访问通讯录
        NSArray *contacts = [self fetchContactWithContactStore:contactStore];//访问通讯录
        dispatch_async(dispatch_get_main_queue(), ^{ //----------------主线程 更新 UI-----------------
//            UNDebugLogVerbose(@"contacts:%@", contacts);
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
        //需要传入所有的数据
        NSArray <id<CNKeyDescriptor>> *keysToFetch = @[CNContactFamilyNameKey, CNContactGivenNameKey, CNContactPhoneNumbersKey, CNContactThumbnailImageDataKey]; //获取通讯录数组
        
        NSArray<CNContact*> *arr = [contactStore unifiedContactsMatchingPredicate:nil keysToFetch:keysToFetch error:&error];
        if (!error){
            NSMutableArray *contacts = [NSMutableArray array];
            for (int i = 0; i < arr.count; i++){
                CNContact *contact = arr[i];
                NSString *givenName = contact.givenName;
                NSString *familyName = contact.familyName;
                NSArray *arrNumber = contact.phoneNumbers;
                NSString *contactId = contact.identifier;
                NSData * thumbnailImageData;
                if (contact.thumbnailImageData) {
                    thumbnailImageData = contact.thumbnailImageData;
                }else{
                    UIImage *image = [UIImage imageNamed:@"default_icon"];
                    thumbnailImageData = UIImagePNGRepresentation(image);
                }
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
//                    [contacts addObject:@{@"name": [familyName stringByAppendingString:givenName], @"phoneNumber": phoneNumber,@"portrait":[NSString stringWithFormat:@"con_face%d",[self getRandomNumber:1 to:3]]}];
                    [contacts addObject:@{@"name": [familyName stringByAppendingString:givenName], @"phoneNumber": phoneNumber,@"portrait":[NSString stringWithFormat:@"con_face%d",[self getRandomNumber:1 to:3]],@"thumbnailImageData":thumbnailImageData, @"contactId":contactId}];
                } else {
                    UNDebugLogVerbose(@"9.0以后的系统，通讯录数据格式不正确");
                    if (phoneNumber) {
                        [contacts addObject:@{@"name": phoneNumber, @"phoneNumber": phoneNumber,@"portrait":[NSString stringWithFormat:@"con_face%d",[self getRandomNumber:1 to:3]],@"thumbnailImageData":thumbnailImageData,@"contactId":contactId}];
                    } else {
                        UNDebugLogVerbose(@"通讯录没有号码");
                    }
                }
            }
            _contactsDataArr = contacts;
            return contacts;
        }else {
            return nil;
        }
    }else{//无权限访问
        UNDebugLogVerbose(@"无权限访问通讯录"); return nil;
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
    if (![BlueToothDataManager shareManager].isHavePackage) {
        //对卡上电
        if ([BlueToothDataManager shareManager].isConnected) {
            [[UNBlueToothTool shareBlueToothTool] checkSystemInfo];
        }
    }
}

- (void)abroadMessageAction
{
    UNDebugLogVerbose(@"境外通讯");
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
    UNDebugLogVerbose(@"双卡双待");
    
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
    UNDebugLogVerbose(@"通话套餐");
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
    
    [self changeStatueViewHeightWithString:[BlueToothDataManager shareManager].statuesTitleString];
    
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
        [self getBasicHeader];
        [SSNetworkRequest getRequest:apiGetBannerList params:nil success:^(id responseObj){
            
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
            UNDebugLogVerbose(@"数据错误：%@",[error description]);
            
        } headers:self.headers];
        self.AdView.delegate = self;
    }
}

- (void)loadProductInfo {
    if (self.isPushKitStatu) {
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:@"apiGetProductList"];
        UNDebugLogVerbose(@"产品信息 -- %@", responseObj);
        self.productInfoArr = responseObj[@"data"];
        [self.hotCollectionView reloadData];
    }else{
        [self getBasicHeader];
        [SSNetworkRequest getRequest:apiGetProductList params:nil success:^(id responseObj){
            
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:@"apiGetProductList" dictData:responseObj];
                UNDebugLogVerbose(@"产品信息 -- %@", responseObj);
                self.productInfoArr = responseObj[@"data"];
                [self.hotCollectionView reloadData];
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
            }
        }failure:^(id dataObj, NSError *error) {
            NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:@"apiGetProductList"];
            if (responseObj) {
                self.productInfoArr = responseObj[@"data"];
                [self.hotCollectionView reloadData];
            }
            UNDebugLogVerbose(@"数据错误：%@",[error description]);
            
        } headers:self.headers];
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
        self.AdView.delegate = self;
    }
    
}

#pragma mark 热门套餐
- (void)loadHotCountry {
    if (self.isPushKitStatu) {
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:@"apiCountryHot"];
        if (responseObj) {
            self.arrCountry = [responseObj objectForKey:@"data"];
            [self refreshFlowPackage];
        }else{
            HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        }
    }else{
        self.checkToken = YES;
        NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"16",@"pageSize", nil];
        [self getBasicHeader];
//        UNDebugLogVerbose(@"表演头：%@",self.headers);
        [SSNetworkRequest getRequest:apiCountryHot params:params success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:@"apiCountryHot" dictData:responseObj];
                self.arrCountry = [responseObj objectForKey:@"data"];
                [self refreshFlowPackage];
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
            }
            
            UNDebugLogVerbose(@"查询到的用户数据：%@",responseObj);
        } failure:^(id dataObj, NSError *error) {
            NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:@"apiCountryHot"];
            if (responseObj) {
                self.arrCountry = [responseObj objectForKey:@"data"];
                [self refreshFlowPackage];
            }else{
                HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
            }
            UNDebugLogVerbose(@"啥都没：%@",[error description]);
        } headers:self.headers];
    }
}

- (void)refreshFlowPackage {
    NSDictionary *leftDict = self.arrCountry[0];
    [self.leftFlowImg sd_setImageWithURL:[NSURL URLWithString:leftDict[@"LogoPic"]]];
    self.leftFlowNameLbl.text = leftDict[@"CountryName"];
    self.leftFlowSubNameLbl.text = leftDict[@"Descr"];
    NSDictionary *midDict = self.arrCountry[1];
    [self.midFlowImg sd_setImageWithURL:[NSURL URLWithString:midDict[@"LogoPic"]]];
    self.midFlowNameLbl.text = midDict[@"CountryName"];
    self.midFlowSubNameLbl.text = midDict[@"Descr"];
    NSDictionary *rightDict = self.arrCountry[2];
    [self.rightFlowImg sd_setImageWithURL:[NSURL URLWithString:rightDict[@"LogoPic"]]];
    self.rightFlowNameLbl.text = rightDict[@"CountryName"];
    self.rightFlowSubNameLbl.text = rightDict[@"Descr"];
}

- (void)showAlertViewWithMessage:(NSString *)message {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:INTERNATIONALSTRING(message) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *certailAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(@"确定") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"searchNoDevice" object:@"searchNoDevice"];
    }];
    [alertVC addAction:certailAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return self.statuesView.frame.size.height;
    } else {
        return CGFLOAT_MIN;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return self.statuesView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 6;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            if (ShowConvenienceService) {
                return [UIScreen mainScreen].bounds.size.width*360.00/750.00+(([UIScreen mainScreen].bounds.size.width-40)/2)*92.00/167.00+80.00;
            } else {
                return [UIScreen mainScreen].bounds.size.width*360.00/750.00+5.00;
            }
            break;
        case 1:
            return 46;
            break;
        case 2:
            return 151;
            break;
        case 3:
            return [UIScreen mainScreen].bounds.size.width*21.00/75.00+5.00;
            break;
        case 4:
            return 46;
            break;
        case 5:
        {
            NSInteger sizeWidth=[UIScreen mainScreen].bounds.size.width/2.00-18.00;
            NSInteger sizeHeight = sizeWidth*189.00/170.00;
            int lineNumber = (int)self.productInfoArr.count/2;
            int numa = self.productInfoArr.count%2;
//            UNDebugLogVerbose(@"jisuan - %d - %d", lineNumber, numa);
            if (numa == 0) {
                return sizeHeight*lineNumber+6*(lineNumber-1)+15;
            } else {
                return sizeHeight*(lineNumber+1)+6*lineNumber+15;
            }
        }
            break;
        default:
            return 0;
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 1:
        {
            UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Package" bundle:nil];
            UIViewController *countryListViewController = [mainStory instantiateViewControllerWithIdentifier:@"countryListViewController"];
            if (countryListViewController) {
                self.tabBarController.tabBar.hidden = YES;
                [self.navigationController pushViewController:countryListViewController animated:YES];
            }
        }
            break;
        case 4:
//            HUDNormal(@"敬请期待")
            break;
        default:
            break;
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
    HUDNormal(@"敬请期待")
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Order" bundle:nil];
//    if (storyboard) {
//        self.tabBarController.tabBar.hidden = YES;
//        UIViewController *orderListViewController = [storyboard instantiateViewControllerWithIdentifier:@"orderListViewController"];
//        if (orderListViewController) {
//            [self.navigationController pushViewController:orderListViewController animated:YES];
//        }
//    }
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
    NSInteger sizeWidth=[UIScreen mainScreen].bounds.size.width/2.00-18.00;
    NSInteger sizeHeight = sizeWidth*189.00/170.00;
    return CGSizeMake(sizeWidth, sizeHeight);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    //先获取数据
    
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return  self.productInfoArr.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    ProductCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ProductCollectionViewCell" forIndexPath:indexPath];
    NSDictionary *dicCountry = self.productInfoArr[indexPath.row];
    [cell.productImg sd_setImageWithURL:[NSURL URLWithString:dicCountry[@"Image"]]];
    cell.productName.text = dicCountry[@"Title"];
    if ([dicCountry[@"Price"] intValue] != 0) {
        cell.productPrice.text = [NSString stringWithFormat:@"￥%@", dicCountry[@"Price"]];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dicCountry = self.productInfoArr[indexPath.row];
    if (![dicCountry[@"Url"] isEqualToString:@""]) {
        UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        BrowserViewController *browserViewController = [mainStory instantiateViewControllerWithIdentifier:@"browserViewController"];
        if (browserViewController) {
            self.tabBarController.tabBar.hidden = YES;
            browserViewController.loadUrl = dicCountry[@"Url"];
            browserViewController.titleStr = dicCountry[@"Title"];
            [self.navigationController pushViewController:browserViewController animated:YES];
        }
    } else {
        HUDNormal(@"我们正在努力研发中，\n敬请期待!")
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
        } else {
            HUDNormal(@"网络连接出错啦")
        }
    } else {
        HUDNormal(@"服务器开小差啦")
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
    UNLogLBEProcess(@"updateLBEStatuWithPushKit")
    if (!self.isUpdatedLBEInfo) {
        UNLogLBEProcess(@"更新蓝牙状态==============================");
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
//            [BlueToothDataManager shareManager].isBounded = NO;
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"changeStatuesViewLable" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"changeStatue" object:nil];
    
    [[BlueToothDataManager shareManager] removeObserver:self forKeyPath:@"isShowStatuesView" context:nil];
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:CNContactStoreDidChangeNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addressBookChanged" object:@"addressBookChanged"];
    }
}

@end
