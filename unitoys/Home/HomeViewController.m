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

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@implementation HomeViewController


//80+80+112=272  section 0 scale 320width
//

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

- (NSMutableArray *)dataPacketArray {
    if (!_dataPacketArray) {
        self.dataPacketArray = [NSMutableArray array];
    }
    return _dataPacketArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = nil;
    [BlueToothDataManager shareManager].bleStatueForCard = 0;
    self.macAddressDict = [NSMutableDictionary new];
    self.RSSIDict = [NSMutableDictionary new];
    
    [self loadAdvertisment];
    
    [self loadSportData];
    
    [self loadOrderList];
    
    [self loadHotCountry];
    
    [self loadBasicConfig];
    
    [self checkBindedDeviceFromNet];
    
    self.simtype = [self checkSimType];
    [BlueToothDataManager shareManager].isNeedToResert = YES;
    [BlueToothDataManager shareManager].currentStep = @"0";
    
    UITapGestureRecognizer *tapQuickSetting = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(quickSetting)];
    [self.ivQuickSetting addGestureRecognizer:tapQuickSetting];
    
    //设备按钮添加手势
    UITapGestureRecognizer *tapDevices = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(devicesAction)];
    [self.ivDevices addGestureRecognizer:tapDevices];
    UITapGestureRecognizer *tapSport = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(jumpToSport)];
    [self.sportView addGestureRecognizer:tapSport];
    
    //左边按钮
    self.leftButton = [[UIButton alloc]initWithFrame:CGRectMake(0,0,100,30)];
    NSDictionary *userData = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    if (userData[@"BraceletIMEI"]) {
        if (![BlueToothDataManager shareManager].isOpened) {
            //蓝牙未开
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_BLNOTOPEN];
        } else {
            //连接中
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_CONNECTING];
        }
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkPastStep) name:@"checkPastStep" object:@"pastStep"];//历史步数
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentStep) name:@"checkCurrentStep" object:@"currentStep"];//当前步数
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkBindedDeviceFromNet) name:@"scanToConnect" object:@"connect"];//扫描并连接设备
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(paySuccess) name:@"actionOrderSuccess" object:@"actionOrderSuccess"];//激活套餐成功
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(upLoadToCard) name:@"upLoadToCard" object:@"upLoadToCard"];//对卡上电
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(senderNewMessageToBLE:) name:@"receiveNewMessageFromBLE" object:nil];//给蓝牙发送消息
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(homeStatueHasChanged:) name:@"homeStatueChanged" object:nil];//蓝牙状态改变
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchMyBluetooth) name:@"searchMyBluetooth" object:@"searchMyBluetooth"];//查找手环
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downElectToCard) name:@"downElectic" object:@"downElectic"];//对卡断电
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updataToCard) name:@"updataElectic" object:@"updataElectic"];//对卡上电
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkEmptyCardSerialNumberFirst:) name:@"checkBLESerialNumber" object:nil];//获取空卡序列号
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unBindSuccess) name:@"noConnectedAndUnbind" object:@"noConnectedAndUnbind"];//解绑成功
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notToConnectedAndStopScan) name:@"stopScanBLE" object:@"stopScanBLE"];//停止扫描
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cardNumberNotTrueAction:) name:@"cardNumberNotTrue" object:nil];//号码有问题专用
    
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
}

#pragma mark 对卡上电
- (void)updataToCard {
    [self sendConnectingInstructWithData:[self phoneCardToUpelectrifyWithReturn]];
}

#pragma mark 对卡断电
- (void)downElectToCard {
    [self sendConnectingInstructWithData:[self phoneCardToOutage]];
}

#pragma mark 查找手环
- (void)searchMyBluetooth {
    [self sendConnectingInstructWithData:[self sendDateToSearchMyBluetooth]];
}

- (void)unBindSuccess {
    if (self.boundedDeviceInfo) {
        self.boundedDeviceInfo = nil;
    }
}

#pragma mark 停止扫描
- (void)notToConnectedAndStopScan {
    if (![BlueToothDataManager shareManager].isTcpConnected) {
        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
    }
    [self.mgr stopScan];
}

#pragma mark 查询绑定设备
- (void)checkBindedDeviceFromNet {
    if (self.boundedDeviceInfo) {
        self.boundedDeviceInfo = nil;
    }
    self.checkToken = YES;
    [self getBasicHeader];
    NSLog(@"表头：%@",self.headers);
    NSDictionary *info = [[NSDictionary alloc] init];
    [SSNetworkRequest getRequest:apiDeviceBracelet params:info success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"查询绑定设备 -- %@", responseObj);
            self.boundedDeviceInfo = [[NSDictionary alloc] initWithDictionary:responseObj[@"data"]];
            //扫描蓝牙设备
            [self scanAndConnectDevice];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else if ([[responseObj objectForKey:@"status"] intValue]==0){
            //数据请求失败
            NSLog(@"没有设备");
            //扫描蓝牙设备
            [self scanAndConnectDevice];
        }
    } failure:^(id dataObj, NSError *error) {
        HUDNormal(@"网络貌似有问题")
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

- (void)leftButtonAction {
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
    
    BindDeviceViewController *bindDeviceViewController = [mainStory instantiateViewControllerWithIdentifier:@"bindDeviceViewController"];
    if (bindDeviceViewController) {
        self.tabBarController.tabBar.hidden = YES;
        [self.navigationController pushViewController:bindDeviceViewController animated:YES];
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
    [self.leftButton setTitle:title forState:UIControlStateNormal];
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
    } else if ([title isEqualToString:HOMESTATUETITLE_NOPACKAGE]) {
        //无套餐
        [self.leftButton setImage:[UIImage imageNamed:HOMESTATUE_NOPACKAGE] forState:UIControlStateNormal];
    } else if ([title isEqualToString:HOMESTATUETITLE_NOSIGNAL]) {
        //无信号
        [self.leftButton setImage:[UIImage imageNamed:HOMESTATUE_NOSIGNAL] forState:UIControlStateNormal];
    } else if ([title isEqualToString:HOMESTATUETITLE_SIGNALSTRONG]) {
        //信号强
        [self.leftButton setImage:[UIImage imageNamed:HOMESTATUE_SIGNALSTRONG] forState:UIControlStateNormal];
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

#pragma mark - VSW相关
#pragma mark 判断网络运营商 1:移动或者联通 2:电信 0:网络运营商或号码有问题
- (NSString *)checkSimType {
    NSString *type = @"0";
    NSDictionary *userData = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    if (userData[@"Tel"]) {
        NSString *checkStr = [userData[@"Tel"] substringWithRange:NSMakeRange(0, 3)];
        //电信
        for (NSString *tel in TELECOM) {
            if ([checkStr isEqualToString:tel]) {
                type = @"2";
                [BlueToothDataManager shareManager].operatorType = type;
                return type;
            }
        }
        //联通
        for (NSString *tel in UNICOM) {
            if ([checkStr isEqualToString:tel]) {
                type = @"1";
                [BlueToothDataManager shareManager].operatorType = type;
                return type;
            }
        }
        //移动
        for (NSString *tel in CMCC) {
            if ([checkStr isEqualToString:tel]) {
                type = @"1";
                [BlueToothDataManager shareManager].operatorType = type;
                return type;
            }
        }
    }
    return type;
}

- (void)senderNewMessageToBLE:(NSNotification *)sender {
    NSString *firstStr = sender.object;
    NSString *totalNumber = [NSString stringWithFormat:@"%lu", (firstStr.length/2)/14 + 1];
    NSLog(@"总包数 -> %@", totalNumber);
    for (int i = 1; i <= [totalNumber intValue]; i++) {
        NSString *tempStr;//后面拼接的字节
        NSString *currentNumStr;//数据包编号
        NSString *validStrLength;//有效字节长度
        NSString *packetTotalNum;//数据包总个数
        if (i == [totalNumber intValue]) {
            tempStr = [firstStr substringFromIndex:14 * 2 * (i-1)];
        } else {
            tempStr = [firstStr substringWithRange:NSMakeRange(14 * 2 * (i-1), 14*2)];
        }
        currentNumStr = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)i]];
        validStrLength = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)firstStr.length/2]];
        packetTotalNum = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)[totalNumber intValue]]];
        NSString *totalStr = [NSString stringWithFormat:@"aada%@%@%@%@", validStrLength, packetTotalNum, currentNumStr, tempStr];
        NSLog(@"最终发送的包内容 -> %@", totalStr);
        [self sendConnectingInstructWithData:[self checkNewMessageReuseWithString:totalStr]];
    }
}

- (void)senderNewStringMessageToBLE:(NSString *)sender {
    NSString *firstStr = sender;
    NSString *totalNumber = [NSString stringWithFormat:@"%lu", (firstStr.length/2)/14 + 1];
    NSLog(@"总包数 -> %@", totalNumber);
    for (int i = 1; i <= [totalNumber intValue]; i++) {
        NSString *tempStr;//后面拼接的字节
        NSString *currentNumStr;//数据包编号
        NSString *validStrLength;//有效字节长度
        NSString *packetTotalNum;//数据包总个数
        if (i == [totalNumber intValue]) {
            tempStr = [firstStr substringFromIndex:14 * 2 * (i-1)];
        } else {
            tempStr = [firstStr substringWithRange:NSMakeRange(14 * 2 * (i-1), 14*2)];
        }
        currentNumStr = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)i]];
        validStrLength = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)firstStr.length/2]];
        packetTotalNum = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)[totalNumber intValue]]];
        NSString *totalStr = [NSString stringWithFormat:@"aada%@%@%@%@", validStrLength, packetTotalNum, currentNumStr, tempStr];
        NSLog(@"最终发送的包内容 -> %@", totalStr);
        [self sendConnectingInstructWithData:[self checkNewMessageReuseWithString:totalStr]];
    }
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
    NSLog(@"最终发送的包 -> %@", data);
    return data;
}

#pragma mark 判断用户是否存在指定套餐
- (void)checkUserIsExistAppointPackage {
    self.checkToken = YES;
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"PackageCategory", nil];
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    
    [SSNetworkRequest postRequest:apiCheckUsedExistByPageCategory params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"是否存在制定套餐:%@", responseObj);
            if ([responseObj[@"data"][@"Used"] intValue]/*0：不存在，1：存在*/) {
                dispatch_queue_t global = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_async(global, ^{
                    if ([self.simtype isEqualToString:@"1"] || [self.simtype isEqualToString:@"2"]) {
                        if ([BlueToothDataManager shareManager].isTcpConnected) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"connectingBLE" object:@"connectingBLE"];
                        } else {
                            [[VSWManager shareManager] simActionWithSimType:self.simtype];
                        }
                    } else {
                        HUDNormal(@"电话卡运营商不属于三大运营商")
                        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOSIGNAL];
                    }
                });
            } else {
                HUDNormal(@"您还没有购买通话套餐")
                [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOPACKAGE];
            }
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            NSLog(@"请求失败：%@", responseObj[@"msg"]);
        }
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

#pragma mark 查询订单卡数据
- (void)checkQueueOrderData {
    self.checkToken = YES;
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.bigKingCardNumber,@"EmptyCardSerialNumber", self.activityOrderId, @"OrderID", nil];
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    
    [SSNetworkRequest postRequest:apiQueryOrderData params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"%@", responseObj);
            //上电
            //对卡上电
            [self sendConnectingInstructWithData:[self phoneCardToUpelectrifyWithReturn]];
            [self senderNewStringMessageToBLE:responseObj[@"data"][@"Data"]];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            NSLog(@"请求失败：%@", responseObj[@"msg"]);
        }
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

#pragma mark 激活成功
- (void)activitySuccess {
    self.checkToken = YES;
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.activityOrderId, @"OrderID", nil];
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    
    [SSNetworkRequest postRequest:apiActivationLocalCompleted params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"%@", responseObj);
            HUDStop;
            [BlueToothDataManager shareManager].isShowHud = NO;
            HUDNormal(@"激活成功")
            [self paySuccess];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            NSLog(@"请求失败：%@", responseObj[@"msg"]);
        }
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
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
        NSLog(@"无权限访问通讯录"); return nil;
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
    ContactModel *tempModel = [[ContactModel alloc] init];
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
        [self.navigationController pushViewController:bindDeviceViewController animated:YES];
    }
}

#pragma mark 支付成功刷新
- (void)paySuccess {
    [self loadOrderList];
}

#pragma mark 设置点击跳转到运动界面
- (void)jumpToSport {
    //发送跳转通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"jumpToSport" object:@"jump"];
}

#pragma mark 上传运动数据
- (void)updataForStep {
    self.checkToken = YES;
    //    ;
    //
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.todays,@"todays", self.yesterdays, @"yesterdays", self.berforeYesterdays, @"berforeYesterdays", self.threeDaysAgo, @"historyDays", nil];
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    
    [SSNetworkRequest postRequest:apiAddHistorys params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
//            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            NSLog(@"请求失败：%@", responseObj[@"msg"]);
        }
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
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
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"3",@"PageSize",@"1",@"PageNumber", nil];
    
    [self getBasicHeader];
    NSLog(@"表头：%@",self.headers);
    
    
    [SSNetworkRequest getRequest:apiOrderList params:params success:^(id responseObj) {
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            self.arrOrderList = [[responseObj objectForKey:@"data"] objectForKey:@"list"];
        
            [self viewOrders];
        
            [self.tableView reloadData];
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
        
        
        
        NSLog(@"查询到的套餐数据：%@",responseObj);
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

- (void)loadSportData {
    self.checkToken = YES;
    
    [self getBasicHeader];
    NSLog(@"表头：%@",self.headers);
    
    
    [SSNetworkRequest getRequest:apiGetSportTotal params:nil success:^(id responseObj) {
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            _lblStepNum.text = [self convertNull:[[responseObj objectForKey:@"data"] objectForKey:@"StepNum"]];
            _lblStepNum.font = [UIFont systemFontOfSize:20 weight:2];
            _lblKM.text = [self convertNull:[[responseObj objectForKey:@"data"] objectForKey:@"KM"]];
            _lblKM.font = [UIFont systemFontOfSize:17 weight:2];
            _lblDate.text = [self convertNull:[[responseObj objectForKey:@"data"] objectForKey:@"Date"]];
            _lblDate.font = [UIFont systemFontOfSize:17 weight:2];
            _lblKcal.text = [self convertNull:[[responseObj objectForKey:@"data"] objectForKey:@"Kcal"]];
            _lblKcal.font = [UIFont systemFontOfSize:17 weight:2];
            //将数据存储到单例里面
            [BlueToothDataManager shareManager].sportDays = _lblDate.text;
            [BlueToothDataManager shareManager].distance = _lblKM.text;
            [BlueToothDataManager shareManager].consume = _lblKcal.text;
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
        NSLog(@"查询到的运动数据：%@",responseObj);
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

- (void)viewOrders {
    self.lblTotalPrice1.font = [UIFont systemFontOfSize:17 weight:2];
    self.lblTotalPrice2.font = [UIFont systemFontOfSize:17 weight:2];
    self.lblTotalPrice3.font = [UIFont systemFontOfSize:17 weight:2];
    if (self.arrOrderList.count==0) {
        //
        [self.lblOrderHint setHidden:NO];
        [self.ivLogoPic1 setHidden:YES];
        [self.lblFlow1 setHidden:YES];
        [self.lblTotalPrice1 setHidden:YES];
        [self.lblExpireDays1 setHidden:YES];
        [self.btnOrderStatus1 setHidden:YES];
        
        
    } else {
        [self.lblOrderHint setHidden:YES];
        [self.ivLogoPic1 setHidden:NO];
        [self.lblFlow1 setHidden:NO];
        [self.lblTotalPrice1 setHidden:NO];
        [self.lblExpireDays1 setHidden:NO];
        [self.btnOrderStatus1 setHidden:NO];
        
        if (self.arrOrderList.count>0) {
            NSDictionary *dicOrder = [self.arrOrderList objectAtIndex:0];
            self.ivLogoPic1.image = [[UIImage alloc] initWithData:[[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[dicOrder objectForKey:@"LogoPic"]]]];
            self.lblFlow1.text = [dicOrder objectForKey:@"PackageName"];
            self.lblExpireDays1.text = [dicOrder objectForKey:@"ExpireDays"];
            self.lblTotalPrice1.text = [NSString stringWithFormat:@"￥%.2f",[[dicOrder objectForKey:@"TotalPrice"] floatValue]];
            if ([[dicOrder objectForKey:@"PayStatus"] intValue]==0) {
                NSLog(@"未支付");
            }else{
                switch ([[dicOrder objectForKey:@"OrderStatus"] intValue]) {
                    case 0:
                        [self.btnOrderStatus1 setTitle:@"未激活" forState:UIControlStateNormal];
                        [self.btnOrderStatus1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    case 1:
                        if ([[dicOrder objectForKey:@"PackageCategory"] intValue] == 1) {
                            [self.btnOrderStatus1 setTitle:[NSString stringWithFormat:@"剩余%@分钟", dicOrder[@"RemainingCallMinutes"]] forState:UIControlStateNormal];
                            [self.btnOrderStatus1 setImage:nil forState:UIControlStateNormal];
                        } else {
                            [self.btnOrderStatus1 setTitle:@"已激活" forState:UIControlStateNormal];
                            [self.btnOrderStatus1 setImage:[UIImage imageNamed:@"order_actived"] forState:UIControlStateNormal];
                        }
                        [self.btnOrderStatus1 setTitleColor:[UIColor colorWithRed:23/255.0 green:186/255.0 blue:34/255.0 alpha:1.0] forState:UIControlStateNormal];
                        break;
                    case 2:
                        [self.btnOrderStatus1 setTitle:@"已过期" forState:UIControlStateNormal];
                        [self.btnOrderStatus1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    case 3:
                        [self.btnOrderStatus1 setTitle:@"已取消" forState:UIControlStateNormal];
                        [self.btnOrderStatus1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    case 4:
                        [self.btnOrderStatus1 setTitle:@"激活失败" forState:UIControlStateNormal];
                        [self.btnOrderStatus1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    default:
                        [self.btnOrderStatus1 setTitle:@"未知状态" forState:UIControlStateNormal];
                        [self.btnOrderStatus1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                }
            }
        }
        
        if (self.arrOrderList.count>1) {
            NSDictionary *dicOrder = [self.arrOrderList objectAtIndex:1];
            self.ivLogoPic2.image = [[UIImage alloc] initWithData:[[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[dicOrder objectForKey:@"LogoPic"]]]];
            self.lblFlow2.text = [dicOrder objectForKey:@"PackageName"];
            self.lblExpireDays2.text = [dicOrder objectForKey:@"ExpireDays"];
            self.lblTotalPrice2.text = [NSString stringWithFormat:@"￥%.2f",[[dicOrder objectForKey:@"TotalPrice"] floatValue]];
            if ([[dicOrder objectForKey:@"PayStatus"] intValue]==0) {
                NSLog(@"未支付");
            }else{
                switch ([[dicOrder objectForKey:@"OrderStatus"] intValue]) {
                    case 0:
                        [self.btnOrderStatus2 setTitle:@"未激活" forState:UIControlStateNormal];
                        [self.btnOrderStatus2 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    case 1:
                        if ([[dicOrder objectForKey:@"PackageCategory"] intValue] == 1) {
                            [self.btnOrderStatus2 setTitle:[NSString stringWithFormat:@"剩余%@分钟", dicOrder[@"RemainingCallMinutes"]] forState:UIControlStateNormal];
                            [self.btnOrderStatus2 setImage:nil forState:UIControlStateNormal];
                        } else {
                            [self.btnOrderStatus2 setTitle:@"已激活" forState:UIControlStateNormal];
                            [self.btnOrderStatus2 setImage:[UIImage imageNamed:@"order_actived"] forState:UIControlStateNormal];
                        }
                        [self.btnOrderStatus2 setTitleColor:[UIColor colorWithRed:23/255.0 green:186/255.0 blue:34/255.0 alpha:1.0] forState:UIControlStateNormal];
                        break;
                    case 2:
                        [self.btnOrderStatus2 setTitle:@"已过期" forState:UIControlStateNormal];
                        [self.btnOrderStatus2 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    case 3:
                        [self.btnOrderStatus2 setTitle:@"已取消" forState:UIControlStateNormal];
                        [self.btnOrderStatus2 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    case 4:
                        [self.btnOrderStatus2 setTitle:@"激活失败" forState:UIControlStateNormal];
                        [self.btnOrderStatus2 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                        
                    default:
                        [self.btnOrderStatus2 setTitle:@"未知状态" forState:UIControlStateNormal];
                        [self.btnOrderStatus2 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                }
            }
            
        }
        
        if (self.arrOrderList.count>2) {
            NSDictionary *dicOrder = [self.arrOrderList objectAtIndex:2];
            self.ivLogoPic3.image = [[UIImage alloc] initWithData:[[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[dicOrder objectForKey:@"LogoPic"]]]];
            self.lblFlow3.text = [dicOrder objectForKey:@"PackageName"];
            self.lblExpireDays3.text = [dicOrder objectForKey:@"ExpireDays"];
            self.lblTotalPrice3.text = [NSString stringWithFormat:@"￥%.2f",[[dicOrder objectForKey:@"TotalPrice"] floatValue]];
            if ([[dicOrder objectForKey:@"PayStatus"] intValue]==0) {
                NSLog(@"未支付");
            }else{
                switch ([[dicOrder objectForKey:@"OrderStatus"] intValue]) {
                    case 0:
                        [self.btnOrderStatus3 setTitle:@"未激活" forState:UIControlStateNormal];
                        [self.btnOrderStatus3 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    case 1:
                        if ([[dicOrder objectForKey:@"PackageCategory"] intValue] == 1) {
                            [self.btnOrderStatus3 setTitle:[NSString stringWithFormat:@"剩余%@分钟", dicOrder[@"RemainingCallMinutes"]] forState:UIControlStateNormal];
                            [self.btnOrderStatus3 setImage:nil forState:UIControlStateNormal];
                        } else {
                            [self.btnOrderStatus3 setTitle:@"已激活" forState:UIControlStateNormal];
                            [self.btnOrderStatus3 setImage:[UIImage imageNamed:@"order_actived"] forState:UIControlStateNormal];
                        }
                        [self.btnOrderStatus3 setTitleColor:[UIColor colorWithRed:23/255.0 green:186/255.0 blue:34/255.0 alpha:1.0] forState:UIControlStateNormal];
                        break;
                    case 2:
                        [self.btnOrderStatus3 setTitle:@"已过期" forState:UIControlStateNormal];
                        [self.btnOrderStatus3 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    case 3:
                        [self.btnOrderStatus3 setTitle:@"已取消" forState:UIControlStateNormal];
                        [self.btnOrderStatus3 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                    case 4:
                        [self.btnOrderStatus3 setTitle:@"激活失败" forState:UIControlStateNormal];
                        [self.btnOrderStatus3 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                        
                    default:
                        [self.btnOrderStatus3 setTitle:@"未知状态" forState:UIControlStateNormal];
                        [self.btnOrderStatus3 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                        break;
                }
            }
        }
        //
    }
}

- (void)loadAdvertisment {
//    self.AdView.imageURLStringsGroup = [responseObj objectForKey:@"data"];
 
    [SSNetworkRequest getRequest:[apiGetBannerList stringByAppendingString:[self getParamStr]] params:nil success:^(id responseObj){
       
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
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
        NSLog(@"数据错误：%@",[error description]);
        
    } headers:nil];
    self.AdView.delegate = self;
}

- (void)loadBasicConfig {
    //    self.AdView.imageURLStringsGroup = [responseObj objectForKey:@"data"];
    
    [SSNetworkRequest getRequest:apiGetBasicConfig params:nil success:^(id responseObj){
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            [[NSUserDefaults standardUserDefaults] setObject:[[responseObj objectForKey:@"data"] objectForKey:@"paymentOfTerms"] forKey:@"paymentOfTerms"];
            [[NSUserDefaults standardUserDefaults] setObject:[[responseObj objectForKey:@"data"] objectForKey:@"howToUse"]  forKey:@"howToUse"];
            [[NSUserDefaults standardUserDefaults] setObject:[[responseObj objectForKey:@"data"] objectForKey:@"userAgreementUrl"] forKey:@"userAgreementUrl"];
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

#pragma mark 热门套餐
- (void)loadHotCountry {
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"16",@"pageSize", nil];
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest getRequest:apiCountryHot params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            self.arrCountry = [responseObj objectForKey:@"data"];
        
            [self.hotCollectionView reloadData];
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
        NSLog(@"查询到的用户数据：%@",responseObj);
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

#pragma mark 调用绑定手环接口
- (void)bindBoundDevice {
    if ([BlueToothDataManager shareManager].deviceMacAddress&&![[BlueToothDataManager shareManager].deviceMacAddress isEqualToString:@"(null):(null):(null):(null):(null):(null)"]) {
        self.checkToken = YES;
        NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:[BlueToothDataManager shareManager].deviceMacAddress,@"IMEI", [BlueToothDataManager shareManager].versionNumber, @"Version", nil];
        
        [self getBasicHeader];
        NSLog(@"表演头：%@",self.headers);
        
        [SSNetworkRequest postRequest:apiBind params:info success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                NSLog(@"绑定结果：%@", responseObj);
                //绑定成功之后再绑定蓝牙
                if (self.strongestRssiPeripheral) {
                    self.peripheral = self.strongestRssiPeripheral;
                    [self.mgr connectPeripheral:self.peripheral options:nil];
                }
                [BlueToothDataManager shareManager].isBounded = YES;
                HUDNormal(responseObj[@"msg"])
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
                NSLog(@"请求失败：%@", responseObj[@"msg"]);
                HUDNormal(responseObj[@"msg"])
                //断开蓝牙
//                [BlueToothDataManager shareManager].isAccordBreak = YES;
//                [self.mgr cancelPeripheralConnection:self.peripheral];
            }
        } failure:^(id dataObj, NSError *error) {
            //
            NSLog(@"啥都没：%@",[error description]);
            //断开蓝牙
//            [BlueToothDataManager shareManager].isAccordBreak = YES;
//            [self.mgr cancelPeripheralConnection:self.peripheral];
        } headers:self.headers];
    } else {
        NSLog(@"绑定蓝牙接口出问题 -- %s:%d", __func__, __LINE__);
    }
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
        return 120*[UIScreen mainScreen].bounds.size.width/340+194;
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
    NSDictionary *dicOrder;
    dicOrder = [self.arrOrderList objectAtIndex:index];
    ActivateGiftCardViewController *giftCardVC = [[ActivateGiftCardViewController alloc] init];
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
    //    return nil;
    
    CountryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CountryCell" forIndexPath:indexPath];
    
    
    
    NSDictionary *dicCountry = [self.arrCountry objectAtIndex:indexPath.row];
    
//    NSLog(@"国家数据：%@",dicCountry);
    
    cell.lblCountryName.text = [dicCountry objectForKey:@"CountryName"];
//    cell.ivCountry.image = [[UIImage alloc] initWithData:[[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[dicCountry objectForKey:@"LogoPic"]]]];
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
        [self bindBoundDevice];
    } else {
        [self showAlertWithMessage:@"还没有连接蓝牙，请先连接设备"];
    }
}

#pragma mark 解除绑定
- (void)relieveBoundAction {
    if ([BlueToothDataManager shareManager].isBounded) {
        [BlueToothDataManager shareManager].isAccordBreak = YES;
        [self.mgr cancelPeripheralConnection:self.peripheral];
        [BlueToothDataManager shareManager].isTcpConnected = NO;
    } else {
        [self showAlertWithMessage:@"设备本没有绑定"];
    }
}

#pragma mark 请求历史步数
- (void)checkPastStep {
    if ([BlueToothDataManager shareManager].isBounded) {
        //请求历史步数
        [self sendConnectingInstructWithData:[self checkPastStepNumber]];
    } else {
        [self showAlertWithMessage:@"请先绑定设备"];
    }
}

#pragma mark 请求当前步数
- (void)checkCurrentStep {
    if ([BlueToothDataManager shareManager].isBounded) {
        //请求当前步数
        [self sendConnectingInstructWithData:[self checkCurrentStepNumber]];
    } else {
        [self showAlertWithMessage:@"请先绑定设备"];
    }
}

#pragma mark 对卡上电
- (void)upLoadToCard {
    [self sendConnectingInstructWithData:[self phoneCardToUpeLectrify]];
}

//- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
//    switch (peripheral.state) {
//        case CBPeripheralManagerStatePoweredOn: {
//            NSLog(@"蓝牙开启且可用");
////            HUDNormal(@"蓝牙开启且可用")
//        }
//            break;
//        default:
//            NSLog(@"蓝牙不可用");
////            HUDNormal(@"蓝牙不可用")
//            break;
//    }
//    
//}

#pragma mark 扫描连接外设
- (void)scanAndConnectDevice {
    if (self.peripherals.count) {
        [self.peripherals removeAllObjects];
    }
    if (self.macAddressDict.allKeys.count) {
        [self.macAddressDict removeAllObjects];
    }
    // 扫描外设
    [self centralManagerDidUpdateState:self.mgr];
    //自动连接,延时1秒
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CBPeripheral *temPer;
        NSNumber *tempRssi;
        switch (self.peripherals.count) {
            case 0:
                NSLog(@"没有搜索到可连接的设备");
                //未连接
                if ([BlueToothDataManager shareManager].isOpened) {
                    if (!self.boundedDeviceInfo) {
                        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
                    }
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(BLESCANTIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (![BlueToothDataManager shareManager].isConnected) {
                            if (![BlueToothDataManager shareManager].isShowAlert) {
                                HUDNormal(@"没有搜索到可连接的设备")
                            }
                            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
                            [self.mgr stopScan];
                        }
                    });
                } else {
                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_BLNOTOPEN];
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

#pragma mark 获取历史计步按钮点击事件
- (IBAction)checkPastAction:(UIButton *)sender {
    if ([BlueToothDataManager shareManager].isBounded) {
        //请求历史步数
        //                [self sendConnectingInstructWithData:[self checkPastStepNumber]];
        
        //设置闹钟:闹钟1 开启闹钟 重复 周一到周六 15：30
        //        [self checkClockAlarmSetWithNumber:@"00" open:@"01" reuse:@"00" monday:@"01" tuesday:@"01" wednesday:@"01" thursday:@"01" friday:@"01" saturday:@"01" sunday:@"00" hour:@"16" min:@"38"];
        
        //设置使能抬手亮屏 00:禁止 01:使能
        //        [self sendConnectingInstructWithData:[self isSetUpToLightWithSet:@"01"]];
    } else {
        [self showAlertWithMessage:@"还没有连接设备，请先连接设备"];
    }
}


#pragma mark - CBCentralManagerDelegate
#pragma mark 发现外围设备的时候调用,RSSI为负值，越接近0，信号越强
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // 添加外围设备
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
                //旧版本不带mac地址的
                if (advertisementData[@"kCBAdvDataManufacturerData"] && [[self conventMACAddressFromNetWithStr:[NSString stringWithFormat:@"%@", advertisementData[@"kCBAdvDataManufacturerData"]]] isEqualToString:imeiLowStr]) {
                    self.peripheral = peripheral;
                    [self.mgr connectPeripheral:self.peripheral options:nil];
                    [self.macAddressDict setObject:[NSString stringWithFormat:@"%@", advertisementData[@"kCBAdvDataManufacturerData"]] forKey:peripheral.identifier];
                    [self.RSSIDict setObject:RSSI forKey:peripheral.identifier];
                    [BlueToothDataManager shareManager].deviceMacAddress = imeiLowStr;
                }
                //新版本带mac地址的
                if (peripheral.name.length > 7) {
                    NSString *macStr = [peripheral.name substringFromIndex:7];
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
                //旧版本不带mac地址的
                if (advertisementData[@"kCBAdvDataManufacturerData"] && [MYDEVICENAME containsString:nameStr.lowercaseString]) {
                    [self.peripherals addObject:peripheral];
                    NSLog(@"不带mac地址 -- uuid = %@ name = %@ 信号强度是：%@ mac地址是：%@", peripheral.identifier, peripheral.name, RSSI, advertisementData[@"kCBAdvDataManufacturerData"]);
                    [self.macAddressDict setObject:[NSString stringWithFormat:@"%@", advertisementData[@"kCBAdvDataManufacturerData"]] forKey:peripheral.identifier];
                    [self.RSSIDict setObject:RSSI forKey:peripheral.identifier];
                }
                //新版本带mac地址的
                if (peripheral.name.length > 7 && [MYDEVICENAME containsString:nameStr.lowercaseString]) {
                    NSString *macStr = [peripheral.name substringFromIndex:7];
                    
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

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    [BlueToothDataManager shareManager].executeNum++;
    //第一次打开或者每次蓝牙状态改变都会调用这个函数
    if(central.state==CBCentralManagerStatePoweredOn) {
        NSLog(@"蓝牙设备开着");
        [BlueToothDataManager shareManager].isOpened = YES;
        //连接中
        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_CONNECTING];
        
        //已经被系统或者其他APP连接上的设备数组
        NSArray *arr = [self.mgr retrieveConnectedPeripheralsWithServices:@[[CBUUID UUIDWithString:UUIDFORSERVICE1SERVICE]]];
        if(arr.count>0) {
            for (CBPeripheral* peripheral in arr) {
                NSString *nameStr = [peripheral.name substringWithRange:NSMakeRange(0, 7)];
                if (peripheral != nil && [MYDEVICENAME containsString:nameStr.lowercaseString]) {
                    peripheral.delegate = self;
                    self.peripheral = peripheral;
                    [self.mgr connectPeripheral:self.peripheral options:nil];
                    if (peripheral.name.length > 7) {
                        [BlueToothDataManager shareManager].deviceMacAddress = [peripheral.name substringFromIndex:7].lowercaseString;
                    }
                }
            }
        } else {
            [self.mgr scanForPeripheralsWithServices:nil options:nil];
        }
    } else {
        NSLog(@"蓝牙设备关着");
        [self.mgr stopScan];
        //蓝牙未开
        [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_BLNOTOPEN];
        if (![BlueToothDataManager shareManager].isOpened) {
            if ([BlueToothDataManager shareManager].executeNum < 3) {
                //第一次什么都不执行
            } else {
                HUDNormal(@"连接蓝牙设备才能正常使用")
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
    [self.mgr stopScan];
    [self.timer setFireDate:[NSDate distantFuture]];
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

#pragma mark 跟某个外设失去连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
//    [BlueToothDataManager shareManager].isRegisted = NO;
    [BlueToothDataManager shareManager].isBounded = NO;
    [BlueToothDataManager shareManager].isConnected = NO;
    [BlueToothDataManager shareManager].deviceMacAddress = nil;
    [BlueToothDataManager shareManager].electricQuantity = nil;
    [BlueToothDataManager shareManager].versionNumber = nil;
    [BlueToothDataManager shareManager].currentStep = @"0";
    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"deviceIsDisconnect" object:@"deviceIsDisconnect"];
    if (![BlueToothDataManager shareManager].isAccordBreak) {
        //重新连接
        [self checkBindedDeviceFromNet];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (![BlueToothDataManager shareManager].isConnected) {
                [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
                [self.mgr stopScan];
                //开始计时
                [self startTimer];
            }
        });
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
        if (![BlueToothDataManager shareManager].isConnected) {
            //重新连接
            [self checkBindedDeviceFromNet];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (![BlueToothDataManager shareManager].isConnected) {
                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
                    [self.mgr stopScan];
                    //开始计时
                    [self startTimer];
                }
            });
        }
        
//        [self dj_alertAction:self alertTitle:nil actionTitle:@"重试" message:@"未能搜索到爱小器手环" alertAction:^{
//            [self.timer setFireDate:[NSDate distantPast]];
//        }];
    }
    self.time++;
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
            //发送连接指令
//            [self sendConnectingInstructWithData:[self connectBao]];
//            [BlueToothDataManager shareManager].isConnected = NO;
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
    [self sendConnectingInstructWithData:[self tellBLEIsAppleDevice]];
    //判断是否有卡
    [self sendConnectingInstructWithData:[self isHaveCard]];
    [self refreshBLEStatue];
    //请求固件版本号
    [self sendConnectingInstructWithData:[self checkDeviceVersionNumber]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([BlueToothDataManager shareManager].isBounded) {
            //同步时间
            [self checkNowTime];
            //请求电量
            [self sendConnectingInstructWithData:[self checkElectricQuantity]];
        }
    });
}

#pragma mark 更新蓝牙状态
- (void)refreshBLEStatue {
    if ([BlueToothDataManager shareManager].isConnected && [BlueToothDataManager shareManager].isTcpConnected && [BlueToothDataManager shareManager].isRegisted) {
        if (![BlueToothDataManager shareManager].isHaveCard) {
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTINSERTCARD];
        } else {
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_SIGNALSTRONG];
        }
    } else if ([BlueToothDataManager shareManager].isConnected && [BlueToothDataManager shareManager].isTcpConnected && ![BlueToothDataManager shareManager].isRegisted) {
        if (![BlueToothDataManager shareManager].isHaveCard) {
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTINSERTCARD];
        } else {
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOSIGNAL];
        }
    } else {
        if (![BlueToothDataManager shareManager].isHaveCard) {
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTINSERTCARD];
        } else {
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOSIGNAL];
        }
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

#pragma mark 当接收到蓝牙设备发送来的数据包时就会调用此方法
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    NSLog(@"接收到蓝牙发送过来的数据value --> %@",characteristic.value);
    
    
#pragma mark 把接收到的数据进行截取
    NSString *str = [NSString stringWithFormat:@"%@",characteristic.value];
    NSLog(@"%@", str);
    //判断是否绑定成功
    if (str.length>8&&[[str substringWithRange:NSMakeRange(1, 8)]isEqualToString:@"bbeeeebb"]) {
        //调用解析总包数方法
        if ([self SetBoundingData:characteristic.value]) {
            NSLog(@"绑定成功了");
            //调用绑定设备接口
            [self bindBoundDevice];
            if ([BlueToothDataManager shareManager].isBounded) {
                if ([BlueToothDataManager shareManager].isReseted) {
                    // 读取缓存数据
                    NSUserDefaults *resetData = [NSUserDefaults standardUserDefaults];
                    NSMutableDictionary *info = [resetData objectForKey:@"resetStepData"];
                    NSData *stepData = info[@"stepDataForReset"];
                    //发送重置之后的数据
                    [self sendConnectingInstructWithData:stepData];
                }
            }
        } else {
            NSLog(@"绑定失败");
        }
    }
    //判断接收到的固件版本号
    if (str.length > 8 &&[[str substringWithRange:NSMakeRange(1, 4)] isEqualToString:@"bb0a"]) {
        int versionNumber = [self convertRangeStringToIntWithString:str rangeLoc:5 rangeLen:2];
        NSLog(@"版本号:%d", versionNumber);
        [BlueToothDataManager shareManager].versionNumber = [NSString stringWithFormat:@"%d", versionNumber];
    }
    //判断接收到的电量
    if (str.length > 10 && [[str substringWithRange:NSMakeRange(1, 6)] isEqualToString:@"bb0404"]) {
        if ([self checkFiveLenthData:characteristic.value]) {
            int electricQuantity = [self convertRangeStringToIntWithString:str rangeLoc:7 rangeLen:2];
            NSLog(@"当前电量为：%d%%", electricQuantity);
            [BlueToothDataManager shareManager].electricQuantity = [NSString stringWithFormat:@"%d", electricQuantity];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"boundSuccess" object:@"boundSuccess"];
        }
    }
    //判断接收到的充电状态数据 00:没有充电 01:正在充电 02:充满电了
    if (str.length > 10 && [[str substringWithRange:NSMakeRange(1, 6)] isEqualToString:@"bb0504"]) {
        if ([self checkFiveLenthData:characteristic.value]) {
            int chargingState = [self convertRangeStringToIntWithString:str rangeLoc:7 rangeLen:2];
            NSLog(@"当前充电状态为：%d", chargingState);
            [BlueToothDataManager shareManager].chargingState = chargingState;
            switch (chargingState) {
                case 0:
                    NSLog(@"没有充电");
                    break;
                case 1:
                    NSLog(@"正在充电");
                    break;
                case 2:
                    NSLog(@"充满电了");
                    break;
                default:
                    NSLog(@"充电状态数据出错了");
                    break;
            }
        }
    }
    //判断上次充电时间数据 BB 09 08  10 0A 0A 0F 0E AB
    if (str.length > 18 && [[str substringWithRange:NSMakeRange(1, 6)] isEqualToString:@"bb0908"]) {
        if ([self checkNineLenthData:characteristic.value]) {
            int lastChargeYear = [self convertRangeStringToIntWithString:str rangeLoc:7 rangeLen:2];
            int lastChargeMonth = [self convertRangeStringToIntWithString:str rangeLoc:10 rangeLen:2];
            int lastChargeDay = [self convertRangeStringToIntWithString:str rangeLoc:12 rangeLen:2];
            int lastChargeHour = [self convertRangeStringToIntWithString:str rangeLoc:14 rangeLen:2];
            int lastChargeMin = [self convertRangeStringToIntWithString:str rangeLoc:16 rangeLen:2];
            NSString *timeStr = [NSString stringWithFormat:@"20%d年%d月%d日%d时%d分", lastChargeYear, lastChargeMonth, lastChargeDay, lastChargeHour, lastChargeMin];
            NSLog(@"上次充电时间为：20%d年%d月%d日%d时%d分", lastChargeYear, lastChargeMonth, lastChargeDay, lastChargeHour, lastChargeMin);
//            NSMutableDictionary *info = [NSMutableDictionary new];
//            [info setObject:[NSString stringWithFormat:@"%d", lastChargeYear] forKey:@"year"];
//            [info setObject:[NSString stringWithFormat:@"%d", lastChargeMonth] forKey:@"month"];
//            [info setObject:[NSString stringWithFormat:@"%d", lastChargeDay] forKey:@"day"];
//            [info setObject:[NSString stringWithFormat:@"%d", lastChargeHour] forKey:@"hour"];
//            [info setObject:[NSString stringWithFormat:@"%d", lastChargeMin] forKey:@"min"];
            [BlueToothDataManager shareManager].lastChargTime = timeStr;
        }
    }
    //判断当前步数数据 0xBB, 0x01, 0x05, 0xO7, 0xD0, 0x68 ，07和D0是步数数据
    if (str.length > 12 && [[str substringWithRange:NSMakeRange(1, 6)] isEqualToString:@"bb0105"]) {
        if ([self checkSixLenthData:characteristic.value]) {
            int currentStepNumber1 = [self convertRangeStringToIntWithString:str rangeLoc:7 rangeLen:2];
            int currentStepNumber2 = [self convertRangeStringToIntWithString:str rangeLoc:10 rangeLen:2];
            int totalNumber = currentStepNumber1 * 256 + currentStepNumber2;
            NSLog(@"当前步数为：%d", totalNumber);
            [BlueToothDataManager shareManager].currentStep = [NSString stringWithFormat:@"%d", totalNumber];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"stepChanged" object:@"toSport"];
        }
    }
    //判断历史计步数据 0xBB, 0x03, 0x17, 0x00（哪天）, 0x00（时段）, 0x00。。。步数
    if (str.length > 36 && [[str substringWithRange:NSMakeRange(1, 6)] isEqualToString:@"bb0317"]) {
        //校验
        /*
         if ([self checkEighteenLenthData:characteristic.value]) {
         switch ([self convertRangeStringToIntWithString:str rangeLoc:7 rangeLen:2]) {
         case 0:
         NSLog(@"当天的数据");
         break;
         case 1:
         NSLog(@"昨天的数据");
         break;
         case 2:
         NSLog(@"前天的数据");
         break;
         case 3:
         NSLog(@"3天之前的数据");
         break;
         
         default:
         NSLog(@"步数数据不对啊");
         break;
         }
         }
         */
        //未校验
        switch ([self convertRangeStringToIntWithString:str rangeLoc:7 rangeLen:2]) {
            case 0:
                NSLog(@"当天的数据");
                //解析时段数据
                [self resolvingOnedayDataWithString:str dayNumber:0];
                break;
            case 1:
                NSLog(@"昨天的数据");
                [self resolvingOnedayDataWithString:str dayNumber:1];
                break;
            case 2:
                NSLog(@"前天的数据");
                [self resolvingOnedayDataWithString:str dayNumber:2];
                break;
            case 3:
                NSLog(@"3天之前的数据");
                [self resolvingOnedayDataWithString:str dayNumber:3];
                break;
                
            default:
                NSLog(@"步数数据不对啊");
                break;
        }
        if (self.todays.count == 24 && self.yesterdays.count == 24 && self.berforeYesterdays.count == 24 && self.threeDaysAgo.count == 6) {
            //上传历史步数
            [self updataForStep];
        }
    }
    //判断是否有卡回应数据
    if (str.length > 10 && [[str substringWithRange:NSMakeRange(1, 8)] isEqualToString:@"bb332211"]) {
        if ([[str substringWithRange:NSMakeRange(10, 2)] isEqualToString:@"bb"]) {
            NSLog(@"有卡");
            [BlueToothDataManager shareManager].isHaveCard = YES;
            //更新蓝牙状态
            [self refreshBLEStatue];
            //判断卡类型
            [self checkCardType];
            
        } else {
            NSLog(@"最后两位不正确 -- %s%d", __func__, __LINE__);
        }
    }
    
    //判断对卡上电失败回应数据
    if (str.length > 10 && ([[str substringWithRange:NSMakeRange(1, 8)] isEqualToString:@"bb445566"] || [[str substringWithRange:NSMakeRange(1, 8)] isEqualToString:@"bb778899"])) {
        if ([[str substringWithRange:NSMakeRange(10, 2)] isEqualToString:@"bb"]) {
            NSLog(@"对卡上电失败");
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTCONNECTED];
            if ([BlueToothDataManager shareManager].isNeedToResert) {
                UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:@"注册失败，是否复位？" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    [BlueToothDataManager shareManager].isNeedToResert = NO;
                }];
                UIAlertAction *certailAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [BlueToothDataManager shareManager].isNeedToResert = YES;
                    //发送复位请求
                    [self sendConnectingInstructWithData:[self resettingInstruct]];
                    //            self.isReseted = YES;
                    //            self.isBoundingSuccess = NO;
                    //            self.relieveBoundButton.enabled = NO;
                    [BlueToothDataManager shareManager].isReseted = YES;
                    [BlueToothDataManager shareManager].isBounded = NO;
                    //重新连接
                    [self checkBindedDeviceFromNet];
                }];
                [alertVC addAction:cancelAction];
                [alertVC addAction:certailAction];
                [self presentViewController:alertVC animated:YES completion:nil];
            }
        } else {
            NSLog(@"最后两位不正确 -- %s%d", __func__, __LINE__);
        }
    }
    //接收到对卡上电成功之后返回的数据包
    if (str.length > 38 && [[str substringWithRange:NSMakeRange(1, 4)] isEqualToString:@"bbdb"]) {
        if ([BlueToothDataManager shareManager].bleStatueForCard == 0) {
            //默认状态，查询卡类型
            NSString *subString1 = [str substringWithRange:NSMakeRange(12, 6)];
            NSString *subString2 = [str substringWithRange:NSMakeRange(19, 8)];
            NSString *subString3 = [str substringWithRange:NSMakeRange(28, 8)];
            NSString *subString4 = [str substringWithRange:NSMakeRange(37, 6)];
            NSString *totalString = [NSString stringWithFormat:@"%@%@%@%@", subString1, subString2, subString3, subString4];
            NSLog(@"totalString -- %@", totalString);
            if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"9f17"]) {
                [self sendMessageToBLEFromeStr:@"a0a40000022f02"];
            } else if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"9f0f"]) {
                //A0B000000A
                [self sendMessageToBLEFromeStr:@"a0b000000a"];
            } else if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"0344"]) {
                //对卡断电
                [self sendConnectingInstructWithData:[self phoneCardToOutage]];
                //是大王卡
                NSLog(@"是大王卡");
                [BlueToothDataManager shareManager].isActivityCard = YES;
                [BlueToothDataManager shareManager].bleStatueForCard = 1;
                [BlueToothDataManager shareManager].operatorType = @"2";
            } else {
                //对卡断电
                [self sendConnectingInstructWithData:[self phoneCardToOutage]];
                NSLog(@"不是大王卡");
                //判断是否有指定套餐，并创建连接
                [BlueToothDataManager shareManager].bleStatueForCard = 2;
                if (![BlueToothDataManager shareManager].isTcpConnected && ![BlueToothDataManager shareManager].isRegisted) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self checkUserIsExistAppointPackage];
                    });
                } else {
                    [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_SIGNALSTRONG];
                }
            }
        } else if ([BlueToothDataManager shareManager].bleStatueForCard == 1) {
            if ([BlueToothDataManager shareManager].isActivityCard) {
                //激活大王卡的步骤
                NSLog(@"接收到激活大王卡的数据 -- %@", str);
                NSString *subString1 = [str substringWithRange:NSMakeRange(12, 6)];
                NSString *subString2 = [str substringWithRange:NSMakeRange(19, 8)];
                NSString *subString3 = [str substringWithRange:NSMakeRange(28, 8)];
                NSString *subString4 = [str substringWithRange:NSMakeRange(37, 6)];
                NSString *totalString = [NSString stringWithFormat:@"%@%@%@%@", subString1, subString2, subString3, subString4];
                NSLog(@"totalString -- %@", totalString);
                if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"9f17"]) {
                    [self sendMessageToBLEFromeStr:@"a0a40000022f02"];
                } else if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"9f0f"]) {
                    //A0B000000A
                    [self sendMessageToBLEFromeStr:@"a0b000000a"];
                } else if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"0344"]) {
                    //对卡断电
                    [self sendConnectingInstructWithData:[self phoneCardToOutage]];
                    self.bigKingCardNumber = [totalString substringWithRange:NSMakeRange(4, 16)];
                    [self checkQueueOrderData];
                } else if ([[totalString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"9000"]) {
                    //对卡断电
                    [self sendConnectingInstructWithData:[self phoneCardToOutage]];
                    [self activitySuccess];
                } else {
                    //对卡断电
                    [self sendConnectingInstructWithData:[self phoneCardToOutage]];
                    NSLog(@"返回数据有问题");
                    HUDStop;
                    HUDNormal(@"激活失败")
                    [self paySuccess];
                }
            }else {
                NSLog(@"激活大王卡状态有问题");
            }
        } else if ([BlueToothDataManager shareManager].bleStatueForCard == 2) {
            //注册手机卡状态
            //注册电话卡的步骤
            /*NSLog(@"对卡上电成功之后的数据包%@", receivedMessage);*/
            NSString *subString1 = [str substringWithRange:NSMakeRange(12, 6)];
            NSString *subString2 = [str substringWithRange:NSMakeRange(19, 8)];
            NSString *subString3 = [str substringWithRange:NSMakeRange(28, 8)];
            NSString *subString4 = [str substringWithRange:NSMakeRange(37, 6)];
            NSString *totalString = [NSString stringWithFormat:@"%@%@%@%@", subString1, subString2, subString3, subString4];
            [self.dataPacketArray addObject:totalString];
            //数据长度
            NSString *dataStrLength = [NSString stringWithFormat:@"%lu", strtoul([[str substringWithRange:NSMakeRange(5, 2)] UTF8String], 0, 16)];
            //数据总包数
            NSString *dataTotalNumber = [NSString stringWithFormat:@"%lu", strtoul([[str substringWithRange:NSMakeRange(7, 2)] UTF8String], 0, 16)];
            //数据当前包数
            NSString *dataCurrentNumber = [NSString stringWithFormat:@"%lu", strtoul([[str substringWithRange:NSMakeRange(10, 2)] UTF8String], 0, 16)];
            if ([dataTotalNumber isEqualToString:dataCurrentNumber]) {
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
                    if ([dataTotalNumber intValue] >= 19 && [dataStrLength intValue] < 253) {
                        int newLength = [dataStrLength intValue] + 255;
                        dataStrLength = [NSString stringWithFormat:@"%d", newLength];
                    }
                    NSString *newStr;
                    if ([dataStrLength intValue] * 2<=self.totalString.length) {
                        newStr = [self.totalString substringWithRange:NSMakeRange(0, [dataStrLength intValue] * 2)];
                    } else {
                        NSLog(@"newStr出问题了");
                    }
                    NSLog(@"最终发送的数据包字符为：%@", newStr);
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"receiveNewDtaaPacket" object:newStr];
                    [self.dataPacketArray removeAllObjects];
                    self.totalString = nil;
                }
            }
        } else {
            //状态有问题
            NSLog(@"状态有问题");
        }
    }
    //判断断电回应数据
    //未校验
    if (str.length > 10 && [[str substringWithRange:NSMakeRange(1, 8)] isEqualToString:@"bbdc0401"]) {
        NSLog(@"对卡断电成功");
    }
    //校验
    /*
     if (str.length > 10 && [[str substringWithRange:NSMakeRange(1, 10)] isEqualToString:@"bbdc040162"]) {
     if ([self checkFiveLenthData:characteristic.value]) {
     NSLog(@"对卡断电成功");
     }
     }
     */
    //读卡不成功回应数据
    if (str.length > 10 && [[str substringWithRange:NSMakeRange(1, 8)] isEqualToString:@"bb112233"]) {
        if ([[str substringWithRange:NSMakeRange(10, 2)] isEqualToString:@"bb"]) {
            HUDNormal(@"您的手环还未插入电话卡")
            [BlueToothDataManager shareManager].isHaveCard = NO;
            [self setButtonImageAndTitleWithTitle:HOMESTATUETITLE_NOTINSERTCARD];
        } else {
            NSLog(@"最后两位不正确 -- %s%d", __func__, __LINE__);
        }
    }
    //判断发送复位请求之后接收的步数数据
    if (str.length > 14 &&[[str substringWithRange:NSMakeRange(1, 4)] isEqualToString:@"aaff"]) {
        NSLog(@"收到复位前的步数了：%@", characteristic.value);
        NSData *stepData = characteristic.value;
        //把复位前的步数存储到本地
        NSMutableDictionary *info = [NSMutableDictionary new];
        [info setValue:stepData forKey:@"stepDataForReset"];
        NSUserDefaults *resetData = [NSUserDefaults standardUserDefaults];
        [resetData setObject:info forKey:@"resetStepData"];
        [[NSUserDefaults standardUserDefaults] synchronize];//同步
    }
}

#pragma mark 获取当前时间
- (void)checkNowTime {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *now;
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    NSInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit |
    NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    
    now=[NSDate date];
    comps = [calendar components:unitFlags fromDate:[NSDate date]];
    int year=[comps year];
    int week = [comps weekday];
    int month = [comps month];
    int day = [comps day];
    int hour = [comps hour];
    int min = [comps minute];
    int sec = [comps second];
    
    NSArray * arrWeek=[NSArray arrayWithObjects:@"07",@"01",@"02",@"03",@"04",@"05",@"06", nil];
    NSString *weekString = [NSString stringWithFormat:@"%@",[arrWeek objectAtIndex:[comps weekday] - 1]];
    //    NSString *a = [NSString stringWithFormat:@"%d", year];
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
    //    NSLog(@"十六进制：%@ %@ %@ %@ %@ %@ %@", hexYear, hexMonth, hexDay, hexWeek, hexHour, hexMin, hexSec);
    
    //获取检验位
    NSMutableArray *array1 = [NSMutableArray arrayWithObjects:@"AA", @"02", @"0A", hexYear, hexMonth, hexDay, hexWeek, hexHour, hexMin, hexSec, nil];
    NSString *checkString = [self check_sum:array1];
    //    NSLog(@"时间校验码：%@", hexCheckString);
    
    //发送时间指令
    [self sendConnectingInstructWithData:[self sendInfoToCheckTimeWithYear:yearString month:monthString day:dayString week:weekString hour:hourString min:minString sec:secString checkString:checkString]];
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
#pragma mark 发送时间同步,输入十进制的数据
- (NSData *)sendInfoToCheckTimeWithYear:(NSString *)year month:(NSString *)month day:(NSString *)day week:(NSString *)week hour:(NSString *)hour min:(NSString *)min sec:(NSString *)sec checkString:(NSString *)checkString {
    Byte reg[12];
    //    0xAA 0x02 0x0A ....
    reg[0]=0xAA;
    reg[1]=0x02;
    reg[2]=0x0A;
    reg[3]=[self strEndMinute:year];
    reg[4]=[self strEndMinute:month];
    reg[5]=[self strEndMinute:day];
    reg[6]=[self strEndMinute:week];
    reg[7]=[self strEndMinute:hour];
    reg[8]=[self strEndMinute:min];
    reg[9]=[self strEndMinute:sec];
    reg[10]=[self strEndMinute:checkString];
    reg[11]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]^reg[4]^reg[5]^reg[6]^reg[7]^reg[8]^reg[9]^reg[10]);
    NSData *data=[NSData dataWithBytes:reg length:12];
    return data;
}

#pragma mark APP请求连接设备指令
//- (NSData *)connectBao {
//    Byte reg[6];
//    //    0xAA 0x06 0x04 0x01 0xA9
//    reg[0]=0xAA;
//    reg[1]=0x06;
//    reg[2]=0x04;
//    reg[3]=0x01;
//    reg[4]=0xA9;
//    reg[5]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]^reg[4]);
//    NSData *data=[NSData dataWithBytes:reg length:6];
//    //发送指令之前使标识符为NO
//    [BlueToothDataManager shareManager].isConnected = NO;
//    return data;
//}

#pragma mark 连接成功之后向设备发送第一条指令
//- (NSData *)TheFirstInstructAfterConnectd {
//    Byte reg[7];
//    //    0xAA 0xBB 0xCC 0xDD 0xEE 0xFF
//    reg[0]=0xAA;
//    reg[1]=0xBB;
//    reg[2]=0xCC;
//    reg[3]=0xDD;
//    reg[4]=0xEE;
//    reg[5]=0xFF;
//    reg[6]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]^reg[4]^reg[5]);
//    NSData *data=[NSData dataWithBytes:reg length:7];
//    return data;
//}

#pragma mark 发送请求固件版本号指令
- (NSData *)checkDeviceVersionNumber {
    Byte reg[5];
    //    0xAA 0x0A 0x01 0xA1
    reg[0]=0xAA;
    reg[1]=0x0A;
    reg[2]=0x01;
    reg[3]=0xA1;
    reg[4]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]);
    NSData *data=[NSData dataWithBytes:reg length:5];
    return data;
}

#pragma mark 绑定设备
//- (NSData *)boundingDevice {
//    Byte reg[5];
//    //    0xAA 0xEE 0xEE 0xAA
//    reg[0]=0xAA;
//    reg[1]=0xEE;
//    reg[2]=0xEE;
//    reg[3]=0xAA;
//    reg[4]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]);
//    NSData *data=[NSData dataWithBytes:reg length:5];
//    return data;
//}

#pragma mark 绑定成功与否 发送指令 01 ：绑定成功 00：不同意绑定
//- (NSData *)boundingDeviceAnswer:(NSString *)answer {
//    Byte reg[6];
//    //    0xAA 0xDD 0x01 0xDD 0xAA
//    reg[0]=0xAA;
//    reg[1]=0xDD;
//    reg[2]=[self strEndMinute:answer];
//    reg[3]=0xDD;
//    reg[4]=0xAA;
//    reg[5]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]^reg[4]);
//    NSData *data=[NSData dataWithBytes:reg length:6];
//    return data;
//}

#pragma mark 解除绑定指令
//- (NSData *)relieveBound {
//    Byte reg[6];
//    //    0xAA 0xAB 0xCD 0xEF 0xAA
//    reg[0]=0xAA;
//    reg[1]=0xAB;
//    reg[2]=0xCD;
//    reg[3]=0xEF;
//    reg[4]=0xAA;
//    reg[5]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]^reg[4]);
//    NSData *data=[NSData dataWithBytes:reg length:6];
//    
//    //存储到本地
//    NSMutableDictionary *info = [NSMutableDictionary new];
//    if ([self.uuidArray containsObject:[self.peripheral.identifier UUIDString]]) {
//        NSLog(@"已加入进来过");
//        [self.uuidArray removeObject:[self.peripheral.identifier UUIDString]];
//    } else {
//        NSLog(@"根本就不包含这个设备");
//    }
//    [info setValue:self.uuidArray forKey:@"UUIDArray"];
//    NSUserDefaults *boundedUuid = [NSUserDefaults standardUserDefaults];
//    [boundedUuid setObject:info forKey:@"boundedDevices"];
//    [[NSUserDefaults standardUserDefaults] synchronize];//同步
//    
//    return data;
//}

#pragma mark 请求电量指令
- (NSData *)checkElectricQuantity {
    Byte reg[6];
    //    0xAA 0x0B 0x04 0x01 0xA4
    reg[0]=0xAA;
    reg[1]=0x0B;
    reg[2]=0x04;
    reg[3]=0x01;
    reg[4]=0xA4;
    reg[5]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]^reg[4]);
    NSData *data=[NSData dataWithBytes:reg length:6];
    return data;
}

#pragma mark 获取空卡序列号第一步
- (void)checkEmptyCardSerialNumberFirst:(NSNotification *)sender {
    self.activityOrderId = [NSString stringWithFormat:@"%@", sender.object];
    if ([BlueToothDataManager shareManager].bleStatueForCard == 1) {
        [BlueToothDataManager shareManager].isActivityCard = YES;
    }
//    HUDNoStop1(@"正在激活...")
    [self sendConnectingInstructWithData:[self phoneCardToUpelectrifyWithReturn]];
    //    A0A4000002 3F00
    [self sendMessageToBLEFromeStr:@"a0a40000023f00"];
}

#pragma mark 判断卡类型第一步
- (void)checkCardType {
    [self sendMessageToBLEFromeStr:@"a0a40000023f00"];
}

#pragma mark 激活时获取空卡序列号用
- (void)sendMessageToBLEFromeStr:(NSString *)string {
    NSString *firstStr = string;
    NSString *totalNumber = [NSString stringWithFormat:@"%lu", (firstStr.length/2)/14 + 1];
    NSLog(@"总包数 -> %@", totalNumber);
    for (int i = 1; i <= [totalNumber intValue]; i++) {
        NSString *tempStr;//后面拼接的字节
        NSString *currentNumStr;//数据包编号
        NSString *validStrLength;//有效字节长度
        NSString *packetTotalNum;//数据包总个数
        if (i == [totalNumber intValue]) {
            tempStr = [firstStr substringFromIndex:14 * 2 * (i-1)];
        } else {
            tempStr = [firstStr substringWithRange:NSMakeRange(14 * 2 * (i-1), 14*2)];
        }
        currentNumStr = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)i]];
        validStrLength = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)firstStr.length/2]];
        packetTotalNum = [self hexStringFromString:[NSString stringWithFormat:@"%ld", (long)[totalNumber intValue]]];
        NSString *totalStr = [NSString stringWithFormat:@"aada%@%@%@%@", validStrLength, packetTotalNum, currentNumStr, tempStr];
        NSLog(@"最终发送的包内容 -> %@", totalStr);
        [self sendConnectingInstructWithData:[self checkNewMessageReuseWithString:totalStr]];
    }
}

#pragma mark 查询实时步数指令(实时步数)
- (NSData *)checkCurrentStepNumber {
    //0xAA, 0x01, 0x04, 0xO1, 0xAE
    Byte reg[6];
    reg[0]=0xAA;
    reg[1]=0x01;
    reg[2]=0x04;
    reg[3]=0x01;
    reg[4]=0xAE;
    reg[5]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]^reg[4]);
    NSData *data=[NSData dataWithBytes:reg length:6];
    return data;
}

#pragma mark 查询历史计步指令
- (NSData *)checkPastStepNumber {
    //0xAA, 0x03, 0x04, 0x01, 0xAC
    Byte reg[6];
    reg[0]=0xAA;
    reg[1]=0x03;
    reg[2]=0x04;
    reg[3]=0x01;
    reg[4]=0xAC;
    reg[5]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]^reg[4]);
    NSData *data=[NSData dataWithBytes:reg length:6];
    [self.todays removeAllObjects];
    [self.yesterdays removeAllObjects];
    [self.berforeYesterdays removeAllObjects];
    [self.threeDaysAgo removeAllObjects];
    return data;
}

#pragma mark 删除所有步数指令
- (NSData *)deleteAllStepNumber {
    Byte reg[6];
    //    0xAA 0x09 0x04 0x01 0xA6
    reg[0]=0xAA;
    reg[1]=0x09;
    reg[2]=0x04;
    reg[3]=0x01;
    reg[4]=0xA6;
    reg[5]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]^reg[4]);
    NSData *data=[NSData dataWithBytes:reg length:6];
    return data;
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

#pragma mark 是否使能抬手亮屏指令(禁止/使能)
- (NSData *)isSetUpToLightWithSet:(NSString *)set {
    Byte reg[6];
    //    0xAA 0x0C 0x04 0x00/01 0xA2/A3
    reg[0]=0xAA;
    reg[1]=0x0C;
    reg[2]=0x04;
    reg[3]=[self strEndMinute:set];
    if ([set isEqualToString:@"00"]) {
        reg[4]=0xA2;
    } else if ([set isEqualToString:@"01"]) {
        reg[4]=0xA3;
    }
    reg[5]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]^reg[4]);
    NSData *data=[NSData dataWithBytes:reg length:6];
    return data;
}

#pragma mark 对卡上电指令（无返回命令）
- (NSData *)phoneCardToUpelectrifyWithReturn {
    Byte reg[6];
    //    0xAA 0xDB 0x04 0x03 0x76
    reg[0]=0xAA;
    reg[1]=0xDB;
    reg[2]=0x04;
    reg[3]=0x03;
    reg[4]=0x76;
    reg[5]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]^reg[4]);
    NSData *data=[NSData dataWithBytes:reg length:6];
    NSLog(@"第三种上电指令");
    return data;
}

#pragma mark 对卡上电指令（有返回命令）
- (NSData *)phoneCardToUpeLectrify {
    Byte reg[6];
    //    0xAA 0xDB 0x04 0x02 0x77
    reg[0]=0xAA;
    reg[1]=0xDB;
    reg[2]=0x04;
    reg[3]=0x02;
    reg[4]=0x77;
    reg[5]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]^reg[4]);
    NSData *data=[NSData dataWithBytes:reg length:6];
    NSLog(@"第二种上电指令");
    return data;
}

#pragma mark 判断是否有卡
- (NSData *)isHaveCard {
    Byte reg[6];
    //    0xAA 0xDB 0x04 0x01 0x74
    reg[0]=0xAA;
    reg[1]=0xDB;
    reg[2]=0x04;
    reg[3]=0x01;
    reg[4]=0x74;
    reg[5]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]^reg[4]);
    NSData *data=[NSData dataWithBytes:reg length:6];
    return data;
}

#pragma mark 对卡断电指令
- (NSData *)phoneCardToOutage {
    Byte reg[6];
    //    0xAA 0xDC 0x04 0x01 0x73
    reg[0]=0xAA;
    reg[1]=0xDC;
    reg[2]=0x04;
    reg[3]=0x01;
    reg[4]=0x73;
    reg[5]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]^reg[4]);
    NSData *data=[NSData dataWithBytes:reg length:6];
    return data;
}

#pragma mark 告诉蓝牙是苹果设备指令
- (NSData *)tellBLEIsAppleDevice {
    Byte reg[6];
    //    0xAA 0x01 0x04 0x01 0xAE
    reg[0]=0xAA;
    reg[1]=0x01;
    reg[2]=0x04;
    reg[3]=0x01;
    reg[4]=0xAE;
    reg[5]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]^reg[4]);
    NSData *data=[NSData dataWithBytes:reg length:6];
    return data;
}

#pragma mark 查找手环
- (NSData *)sendDateToSearchMyBluetooth {
    Byte reg[6];
    //    0xAA 0x06 0x04 0x01 0xA9
    reg[0]=0xAA;
    reg[1]=0x06;
    reg[2]=0x04;
    reg[3]=0x01;
    reg[4]=0xA9;
    reg[5]=(Byte)(reg[0]^reg[1]^reg[2]^reg[3]^reg[4]);
    NSData *data=[NSData dataWithBytes:reg length:6];
    return data;
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

#pragma mark ------------接收的数据包------------
#pragma mark 四位校验，接收到绑定答复的数据包/接收到固件版本号的数据包，数据校验
- (BOOL)SetBoundingData:(NSData *)data
{
    //    0xBB 0xEE 0xEE 0xBB
    Byte *testByte = (Byte *)[data bytes];
    if (data.length == 4) {
        //收到数据之后，要异或校验，看数据是否完整以及正确
        if (testByte[4]==(testByte[0]^testByte[1]^testByte[2]^testByte[3]))
        {
            NSLog(@"数据完整且正确");
            return YES;
        } else {
            NSLog(@"数据不对");
            return NO;
        }
    } else {
        NSLog(@"数据长度不对");
        return NO;
    }
}

#pragma mark 五位长度数据包校验:电量数据包、充电状态数据包
- (BOOL)checkFiveLenthData:(NSData *)data {
    //    0xBB 0x04 0x04 0x** 0x**
    Byte *testByte = (Byte *)[data bytes];
    if (data.length == 5) {
        //收到数据之后，要异或校验，看数据是否完整以及正确
        if (testByte[5]==(testByte[0]^testByte[1]^testByte[2]^testByte[3]^testByte[4]))
        {
            NSLog(@"数据完整且正确");
            return YES;
        } else {
            NSLog(@"数据不对");
            return NO;
        }
    } else {
        NSLog(@"数据长度不对");
        return NO;
    }
}

#pragma mark 六位长度数据包校验：当前步数数据包
- (BOOL)checkSixLenthData:(NSData *)data {
    Byte *testByte = (Byte *)[data bytes];
    if (data.length == 6) {
        //收到数据之后，要异或校验，看数据是否完整以及正确
        if (testByte[6]==(testByte[0]^testByte[1]^testByte[2]^testByte[3]^testByte[4]^testByte[5]))
        {
            NSLog(@"数据完整且正确");
            return YES;
        } else {
            NSLog(@"数据不对");
            return NO;
        }
    } else {
        NSLog(@"数据长度不对");
        return NO;
    }
}

#pragma mark 九位长度数据包校验：充电时间数据包
- (BOOL)checkNineLenthData:(NSData *)data {
    Byte *testByte = (Byte *)[data bytes];
    if (data.length == 9) {
        //收到数据之后，要异或校验，看数据是否完整以及正确
        if (testByte[9]==(testByte[0]^testByte[1]^testByte[2]^testByte[3]^testByte[4]^testByte[5]^testByte[6]^testByte[7]^testByte[8]))
        {
            NSLog(@"数据完整且正确");
            return YES;
        } else {
            NSLog(@"数据不对");
            return NO;
        }
    } else {
        NSLog(@"数据长度不对");
        return NO;
    }
}

#pragma mark 十八位长度数据包校验：历史计步数据包
- (BOOL)checkEighteenLenthData:(NSData *)data {
    Byte *testByte = (Byte *)[data bytes];
    if (data.length == 18) {
        //收到数据之后，要异或校验，看数据是否完整以及正确
        if (testByte[18]==(testByte[0]^testByte[1]^testByte[2]^testByte[3]^testByte[4]^testByte[5]^testByte[6]^testByte[7]^testByte[8]^testByte[9]^testByte[10]^testByte[11]^testByte[12]^testByte[13]^testByte[14]^testByte[15]^testByte[16]^testByte[17]))
        {
            NSLog(@"数据完整且正确");
            return YES;
        } else {
            NSLog(@"数据不对");
            return NO;
        }
    } else {
        NSLog(@"数据长度不对");
        return NO;
    }
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
    //    NSLog(@"返回的结果为：%d", result);
    return result;
}

#pragma mark 解析每天的每个小时的数据
- (void)resolvingOnedayDataWithString:(NSString *)string dayNumber:(int)dayNumber {
    NSArray *arr = [self checkStepNumberForDetailWithString:string];
    if (dayNumber == 0) {
        for (int i = 0; i < arr.count; i++) {
            [self.todays addObject:arr[i]];
        }
    } else if (dayNumber == 1) {
        for (int i = 0; i < arr.count; i++) {
            [self.yesterdays addObject:arr[i]];
        }
    } else if (dayNumber == 2) {
        for (int i = 0; i < arr.count; i++) {
            [self.berforeYesterdays addObject:arr[i]];
        }
    } else if (dayNumber == 3) {
        //三天前的数据
        self.threeDaysAgo = [self checkStepNumberForDetailWithString:string];
        for (int i = 0; i < self.threeDaysAgo.count; i++) {
            NSLog(@"第%d天：%@步", i+4, self.threeDaysAgo[i]);
        }
    }
}

#pragma mark 用来解析一天的步数
- (NSMutableArray *)checkOneDayStepDataWithString:(NSString *)string {
    NSMutableArray *array = [NSMutableArray array];
    switch ([self convertRangeStringToIntWithString:string rangeLoc:10 rangeLen:2]) {
        case 0:
            NSLog(@"0点到5点的数据");
            array = [self checkStepNumberForDetailWithString:string];
            for (int i = 0; i < array.count; i++) {
                NSLog(@"%d点：%@步", i, array[i]);
            }
            break;
        case 1:
            NSLog(@"6点到11点的数据");
            array = [self checkStepNumberForDetailWithString:string];
            for (int i = 0; i < array.count; i++) {
                NSLog(@"%d点：%@步", i+6, array[i]);
            }
            break;
        case 2:
            NSLog(@"12点到17点的数据");
            array = [self checkStepNumberForDetailWithString:string];
            for (int i = 0; i < array.count; i++) {
                NSLog(@"%d点：%@步", i+12, array[i]);
            }
            break;
        case 3:
            NSLog(@"18点到23点的数据");
            array = [self checkStepNumberForDetailWithString:string];
            for (int i = 0; i < array.count; i++) {
                NSLog(@"%d点：%@步", i+18, array[i]);
            }
            break;
            
        default:
            NSLog(@"时间段标志不对啊");
            break;
    }
    return array;
}

#pragma mark 专门用来计算步数的
- (NSMutableArray *)checkStepNumberForDetailWithString:(NSString *)string {
    NSMutableArray *stepArray = [NSMutableArray array];
    if (string.length > 37) {
        int firstNum = [self convertRangeStringToIntWithString:string rangeLoc:12 rangeLen:2] *256 + [self convertRangeStringToIntWithString:string rangeLoc:14 rangeLen:2];
        [stepArray addObject:[NSString stringWithFormat:@"%d", firstNum]];
        int secondNum = [self convertRangeStringToIntWithString:string rangeLoc:16 rangeLen:2] * 256 + [self convertRangeStringToIntWithString:string rangeLoc:19 rangeLen:2];
        [stepArray addObject:[NSString stringWithFormat:@"%d", secondNum]];
        int thirdNum = [self convertRangeStringToIntWithString:string rangeLoc:21 rangeLen:2] * 256 + [self convertRangeStringToIntWithString:string rangeLoc:23 rangeLen:2];
        [stepArray addObject:[NSString stringWithFormat:@"%d", thirdNum]];
        int forthNum = [self convertRangeStringToIntWithString:string rangeLoc:25 rangeLen:2] * 256 + [self convertRangeStringToIntWithString:string rangeLoc:28 rangeLen:2];
        [stepArray addObject:[NSString stringWithFormat:@"%d", forthNum]];
        int fifthNum = [self convertRangeStringToIntWithString:string rangeLoc:30 rangeLen:2] *256 + [self convertRangeStringToIntWithString:string rangeLoc:32 rangeLen:2];
        [stepArray addObject:[NSString stringWithFormat:@"%d", fifthNum]];
        int sixthNum = [self convertRangeStringToIntWithString:string rangeLoc:34 rangeLen:2] * 256 + [self convertRangeStringToIntWithString:string rangeLoc:37 rangeLen:2];
        [stepArray addObject:[NSString stringWithFormat:@"%d", sixthNum]];
    }
    return stepArray;
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
    if (str.length > 17) {
        NSString *string1 = [str substringWithRange:NSMakeRange(5, 2)];
        NSString *string2 = [str substringWithRange:NSMakeRange(7, 2)];
        NSString *string3 = [str substringWithRange:NSMakeRange(10, 2)];
        NSString *string4 = [str substringWithRange:NSMakeRange(12, 2)];
        NSString *string5 = [str substringWithRange:NSMakeRange(14, 2)];
        NSString *string6 = [str substringWithRange:NSMakeRange(16, 2)];
        NSString *string = [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@", string1, string2, string3, string4, string5, string6];
        NSString *lowStr = string.lowercaseString;
        NSLog(@"mac地址：%@", lowStr);
        return lowStr;
    } else {
        NSLog(@"mac地址有问题,未连接");
        return nil;
    }
}

- (void)dealloc {
    //移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BuyConfrim" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"boundingDevice" object:@"bound"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"relieveBound" object:@"relieve"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"checkPastStep" object:@"pastStep"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"checkCurrentStep" object:@"currentStep"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"scanToConnect" object:@"connect"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"actionOrderSuccess" object:@"actionOrderSuccess"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"upLoadToCard" object:@"upLoadToCard"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"receiveNewMessageFromBLE" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"homeStatueChanged" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"downElectic" object:@"downElectic"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"updataElectic" object:@"updataElectic"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"stopScanBLE" object:@"stopScanBLE"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"cardNumberNotTrue" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"noConnectedAndUnbind" object:@"noConnectedAndUnbind"];
    
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:CNContactStoreDidChangeNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addressBookChanged" object:@"addressBookChanged"];
    }
}

@end
