//
//  PhoneRecordController.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "PhoneRecordController.h"

#import "CallComingInViewController.h"
#import "UNCallKitCenter.h"
#import "AddressBookManager.h"
#import "SipEngineManager.h"

#import "PhoneRecordCell.h"
#import "CallingViewController.h"
#import "FMDatabase.h"
#import "BlueToothDataManager.h"
#import "SearchContactsCell.h"
#import <SSZipArchive/SSZipArchive.h>
#import "UNBlueToothTool.h"
#import "VSWManager.h"
#import "UNNetWorkStatuManager.h"

//#import "PhoneRecordSearchController.h"

#import "ContactModel.h"
#import "ContactsDetailViewController.h"
//#import "AddTouchAreaButton.h"
#import "HLDragView.h"
#import "ContactsCallDetailsController.h"
#import "UNDataTools.h"
#import "ServiceRecommendView.h"
#import "ConvenienceServiceController.h"
#import "MainViewController.h"
#import "UNSipEngineInitialize.h"
#import "UNConvertFormatTool.h"

@interface PhoneRecordController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong)NSDictionary *userInfo;
@property (nonatomic, weak)CallComingInViewController *callCominginVC;

@property (nonatomic, strong) UNCallKitCenter *callCenter;

//@property(nonatomic,strong)PhoneRecordSearchController *searchRecordVC;
//@property(nonatomic,strong)UISearchController *searchController;

//当前是否为搜索状态
@property (nonatomic, assign) BOOL isSearchStatu;

//处理过的拨打记录列表
@property (nonatomic, copy) NSArray *searchPhoneRecords;
//联系人列表
@property (nonatomic, copy) NSArray *contactsLists;
//搜索列表
@property (nonatomic, strong) NSMutableArray *searchLists;

@property (nonatomic, strong) HLDragButton *phonePadButton;

//@property (nonatomic, strong) UIWindow *window;

@property (nonatomic, copy) NSString *currentCallPhone;

@property (nonatomic, strong) UILabel *noDataLabel;

@property (nonatomic, copy) NSString *currentCid;
@end

static NSString *searchContactsCellID = @"SearchContactsCell";
@implementation PhoneRecordController


- (NSMutableArray *)searchLists
{
    if (!_searchLists) {
        _searchLists = [NSMutableArray array];
    }
    return _searchLists;
}

- (NSArray *)contactsLists
{
    if (!_contactsLists) {
        //获取联系人信息
        _contactsLists = [[AddressBookManager shareManager].dataArr copy];
    }
    return _contactsLists;
}

- (NSArray *)searchPhoneRecords
{
    if (!_searchPhoneRecords) {
        //去除记录重复
        NSMutableArray *tempArray = [NSMutableArray array];
        [_arrPhoneRecord enumerateObjectsUsingBlock:^(NSArray *objArray, NSUInteger idx, BOOL * _Nonnull stop) {
            if (objArray.count) {
                [tempArray addObject:objArray[0]];
            }
        }];
        
        _searchPhoneRecords = [tempArray copy];
    }
    return _searchPhoneRecords;
}


- (void)unregister {
    SipEngine *theSipEngine = [SipEngineManager getSipEngine];
    if (theSipEngine->AccountIsRegstered()) {
        theSipEngine->DeRegisterSipAccount();
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    UNLogLBEProcess(@"PhoneRecordController")
    
    [self initTableView];
    [self initNoDataLabel];
    //解压联系人数据库
    [self unZipNumberPhoneDB];
    
    if (!_arrPhoneRecord) {
        [self loadPhoneRecord];
    }
    
    kWeakSelf
    self.phonePadView = [[UCallPhonePadView alloc] initWithFrame:CGRectMake(0, kScreenHeightValue - 64, kScreenWidthValue, 225)];
    self.phonePadView.isCanTouch = YES;
    [self.view addSubview:self.phonePadView];
    self.phonePadView.completeBlock = ^(NSString *btnText, NSString *currentNum){
        if (btnText.length>0){
            //当前为搜索状态
            weakSelf.isSearchStatu = YES;
            weakSelf.phonePadView.hidden = NO;
            weakSelf.tableView.un_height = weakSelf.view.un_height - (100 - 49) - 225 - 70;
            //搜索电话并展示
            [weakSelf searchInfoWithString:btnText];
        }else{
            //当前不为搜索状态
            weakSelf.isSearchStatu = NO;
            weakSelf.tableView.un_height = weakSelf.view.un_height - (100 - 49) - 225;
            [weakSelf.tableView reloadData];
        }
    };
    
    [self showWindow];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tipStatuBarHeightChange:) name:@"TipStatuBarHeightChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(registerSipServer) name:@"NetStatusIsWell" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(registerNetWorkCallPhone) name:@"RegisterNetWorkCallPhone" object:nil];
    UNDebugLogVerbose(@"statusBarHeight--------%@", NSStringFromCGRect(self.tabBarController.tabBar.frame));
    
    //app将要被杀死时调用
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillBeKilled) name:@"AppWillBeKilled" object:nil];
}

- (void)appWillBeKilled
{
    //app被杀死之前注销网络电话
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self unregister];
    });
}

- (void)registerNetWorkCallPhone
{
    [self registerSipServer];
}

//无数据占位显示
- (void)initNoDataLabel
{
    if (!_noDataLabel) {
        _noDataLabel = [[UILabel alloc] init];
        _noDataLabel.text = [NSString stringWithFormat:@"暂无通话记录\n您还没有打过电话"];
        _noDataLabel.font = [UIFont systemFontOfSize:16];
        _noDataLabel.textColor = UIColorFromRGB(0xcccccc);
        _noDataLabel.numberOfLines = 2;
        _noDataLabel.textAlignment = NSTextAlignmentCenter;
        [_noDataLabel sizeToFit];
        _noDataLabel.un_centerX = kScreenWidthValue * 0.5;
        _noDataLabel.un_centerY = (kScreenHeightValue - 64 - 49 - STATUESVIEWHEIGHT - 50) * 0.5;
        [self.view addSubview:_noDataLabel];
        _noDataLabel.hidden = YES;
    }
}

- (void)tipStatuBarHeightChange:(NSNotification *)noti
{
    if (self.phonePadButton.isHidden) {
        self.phonePadView.un_top = [UNDataTools sharedInstance].pageViewHeight - (100 - 49) - 225;
        if (self.phonePadView.inputedPhoneNumber && self.phonePadView.inputedPhoneNumber.length) {
            self.tableView.un_height = self.phonePadView.un_top - 70;
        }else{
            self.tableView.un_height = self.phonePadView.un_top;
        }
    }else{
        self.phonePadView.un_top = [UNDataTools sharedInstance].pageViewHeight;
        self.tableView.un_height = [UNDataTools sharedInstance].pageViewHeight;
    }
    
    if ([UNDataTools sharedInstance].tipStatusHeight) {
        _phonePadButton.un_bottom -= STATUESVIEWHEIGHT;
    }else{
        _phonePadButton.un_bottom += STATUESVIEWHEIGHT;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (self.phonePadView.un_top == self.view.un_height - (100 - 49)) {
        self.phonePadView.un_top = self.view.un_height;
    }
}

//注册网络电话服务
- (void)registerSipServer
{
    [[SipEngineManager instance] Init];
    [[SipEngineManager instance] LoadConfig];
    
    [[SipEngineManager instance] setCallDelegate:self];
    
    [[SipEngineManager instance] setRegistrationDelegate:self];
    
    [self doRegister];
    
//    [self getMaxPhoneCall];
}


//初始化网络电话
- (BOOL)initEngine {
    UNLogLBEProcess(@"PhoneRecordController---initEngine")
    [self registerSipServer];
    
    //读取本地缓存的账号信息
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    self.userInfo = [[NSDictionary alloc] initWithDictionary:userdata];
    
    //添加通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAddressBook) name:@"addressBookChanged" object:@"addressBook"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callingAction:) name:@"CallingAction" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makeCallAction:) name:@"MakeCallAction" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makeUnitysCallAction:) name:@"MakeUnitysCallAction" object:nil];
    //监听数字键盘
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callPhoneKeyBoard:) name:@"CallPhoneKeyBoard" object:nil];
    
    kWeakSelf
    if (kSystemVersionValue >= 10.0) {
        if (!self.callCenter) {
            self.callCenter=[UNCallKitCenter sharedInstance];
        }
        self.callCenter.actionNotificationBlock = ^(CXCallAction *action, UNCallActionType actionType){
            switch (actionType) {
                case UNCallActionTypeAnswer:
                {
                    CallComingInViewController *callCominginVC     = [[CallComingInViewController alloc] init];
                    weakSelf.callCominginVC = callCominginVC;
                    if (weakSelf.callCenter.currentCallKitName) {
                        weakSelf.callCominginVC.nameStr            = [weakSelf checkLinkNameWithPhoneStr:weakSelf.callCenter.currentCallKitName];
                    }
                    weakSelf.callCominginVC.isPresentInCallKit = YES;
                    [weakSelf.nav presentViewController:weakSelf.callCominginVC animated:NO completion:^{
//                        [weakSelf.callCominginVC showCenterView];
                    }];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        NSNotification *noti = [[NSNotification alloc] initWithName:@"CallingAction" object:@"Answer" userInfo:nil];
                        [weakSelf callingAction:noti];
                    });
                }
                    break;
                case UNCallActionTypeEnd:
                {
                    //对APP通话进行挂断操作
                    if (weakSelf.callCominginVC) {
                        [weakSelf.callCominginVC endCallPhone];
                    }
                    SipEngine *theSipEngine = [SipEngineManager getSipEngine];
                    if(theSipEngine->InCalling())
                        theSipEngine->TerminateCall();
                    weakSelf.hostHungup = @"source";
                }
                    break;
                case UNCallActionTypeMute:
                {
                    //对APP通话进行无声操作
                    if ([action isKindOfClass:[CXSetMutedCallAction class]]) {
                        CXSetMutedCallAction *muteAction = (CXSetMutedCallAction *)action;
                        //发送是否无声的操作
                        if (weakSelf.callCominginVC) {
                            weakSelf.muteStatus = muteAction.isMuted;
                            [weakSelf.callCominginVC setUpMuteButtonStatu:muteAction.isMuted];
                        }
                    }
                }
                    break;
                case UNCallActionTypeHeld:
                {
                    
                }
                    break;
                case UNCallActionTypeStart:
                {
                    //发起通话
                    UNDebugLogVerbose(@"发起通话");
                    if ([action isKindOfClass:[CXStartCallAction class]]) {
                        CXStartCallAction *startAction = (CXStartCallAction *)action;
                        //手环电话
                        if ([BlueToothDataManager shareManager].isRegisted) {
                            if (startAction.handle.value) {
                                UNDebugLogVerbose(@"CallKit发起通话回调")
                                [weakSelf callUnitysNumber:startAction.handle.value FromCallKit:YES];
                            }
                        } else {
                            [weakSelf showAlertMessageToCall];
                            if ([[BlueToothDataManager shareManager].homeVCLeftTitle isEqualToString:INTERNATIONALSTRING(HOMESTATUETITLE_SIGNALSTRONG)]) {
                                [BlueToothDataManager shareManager].isRegistedFail = NO;
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:INTERNATIONALSTRING(HOMESTATUETITLE_REGISTING)];
                            }
                        }
                    }
                }
                    break;
                default:
                    break;
            }
            
        };
        
    }
    
    return YES;
}

- (void)statusBarHeightChange
{
//    if (kStatusBarHeight == 20) {
//        if (kScreenHeightValue - self.tabBarController.tabBar.frame.origin.y - 49 == 40) {
//            self.tabBarController.tabBar.top = kScreenHeightValue - 49 - 40 - 20;
//        }
//    }
    UNDebugLogVerbose(@"StatusBarHeight--------%.f", kStatusBarHeight);
    UNDebugLogVerbose(@"statusBarHeight--------%@", NSStringFromCGRect(self.tabBarController.tabBar.frame));
}


- (void)refreshAddressBook {
    if (_arrPhoneRecord) {
        [self.arrPhoneRecord removeAllObjects];
        [self loadPhoneRecord];
    }
}

- (BOOL) isZeroStarted :(NSString *)number {
    if (number && number.length) {
        if ([[number substringToIndex:1] isEqualToString:@"0"]) {
            return YES;
        }else{
            return NO;
        }
    } else {
        return NO;
    }
}

- (void)unZipNumberPhoneDB
{
    // 取得沙盒目录
    NSString *localPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    // 要检查的文件目录
    NSString *dbPath = [localPath stringByAppendingPathComponent:@"number_location.db"];
    NSString *zipPath = [[NSBundle mainBundle] pathForResource:@"number_location" ofType:@"zip"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //判断是否有数据库文件
    if (![fileManager fileExistsAtPath:dbPath]) {
        UNDebugLogVerbose(@"数据库文件不存在");
        //判断是否有解压文件
        if ([fileManager fileExistsAtPath:zipPath]) {
            UNDebugLogVerbose(@"解压文件存在");
            NSError *error;
            //解压文件
            if ([SSZipArchive unzipFileAtPath:zipPath toDestination:localPath overwrite:YES password:nil error:&error]) {
                if (error) {
                    UNDebugLogVerbose(@"error---%@", error);
                }else{
                    UNDebugLogVerbose(@"解压成功");
                }
            }else{
                UNDebugLogVerbose(@"解压失败");
            }
        }
    }
}


- (void)startCallPhoneAction
{
    //手环电话
    if ([BlueToothDataManager shareManager].isRegisted) {
        //电话记录，拨打电话
        if (self.currentCallPhone) {
            [self.phonePadView hideCallView];
            [self switchNumberPad:YES];
            //        weakSelf.callView.hidden = YES;
            //清空搜索状态
            self.isSearchStatu = NO;
            [self.searchLists removeAllObjects];
            [self.tableView reloadData];
            
            if ([UNNetWorkStatuManager shareManager].currentStatu == NotReachable) {
                HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
                return;
            }
            if (![UNConvertFormatTool isAllNumberWithString:self.currentCallPhone]) {
                HUDNormal(INTERNATIONALSTRING(@"号码格式错误"))
                return;
            }
            
            [self callUnitysNumber:self.currentCallPhone FromCallKit:NO];
        }else{
            UNDebugLogVerbose(@"当前拨打号码为空");
        }
    } else {
        [self showAlertMessageToCall];
        if ([[BlueToothDataManager shareManager].homeVCLeftTitle isEqualToString:INTERNATIONALSTRING(HOMESTATUETITLE_SIGNALSTRONG)]) {
            [BlueToothDataManager shareManager].isRegistedFail = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:INTERNATIONALSTRING(HOMESTATUETITLE_REGISTING)];
        }
    }
}


- (void)initTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.un_height -= (64 + 49 + [UNDataTools sharedInstance].tipStatusHeight);
//    self.tableView.height = self.view.height-49;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    self.tableView.tableFooterView = [UIView new];
    NSString *strPhoneRecordCell = @"PhoneRecordCell";
    UINib * phoneRecordNib = [UINib nibWithNibName:strPhoneRecordCell bundle:nil];
    [self.tableView registerNib:phoneRecordNib forCellReuseIdentifier:strPhoneRecordCell];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerNib:[UINib nibWithNibName:searchContactsCellID bundle:nil] forCellReuseIdentifier:searchContactsCellID];
}

- (void)showWindow
{
    if (!_phonePadButton) {
        [self createButton];
    }else{
        _phonePadButton.hidden = NO;
//        [self.view bringSubviewToFront:_phonePadButton];
    }
}

- (void)hideWindow
{
    if (_phonePadButton) {
        _phonePadButton.hidden = YES;
    }
}

//创建弹出键盘按钮
- (void)createButton{
    if (_phonePadButton) {
        return;
    }
    _phonePadButton = [HLDragButton buttonWithType:UIButtonTypeCustom];
    [_phonePadButton setImage:[UIImage imageNamed:@"phonepad_btn_nor"] forState:UIControlStateNormal];
    [_phonePadButton addTarget:self action:@selector(showPhonePadView:) forControlEvents:UIControlEventTouchUpInside];
    [_phonePadButton sizeToFit];
    _phonePadButton.un_right = kScreenWidthValue - 10;
    _phonePadButton.un_bottom = self.view.un_height - _phonePadButton.un_height - 49 - [UNDataTools sharedInstance].tipStatusHeight;
    [self.view addSubview:_phonePadButton];
}

- (void)showPhonePadView:(AddTouchAreaButton *)button
{
    [self switchNumberPad:NO];
}

- (void)showOperation {
    if (self.callView) {
        [self.callView setHidden:NO];
        [self.nav.tabBarController.tabBar bringSubviewToFront:self.callView];
    }else{
        NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"PhoneOperationPad" owner:nil options:nil];
        
        PhoneOperationPad *callView = [nibContents lastObject];
        CGRect tabbarRect = self.nav.tabBarController.tabBar.bounds;
        [callView setFrame:CGRectMake(0, tabbarRect.size.height - 100, tabbarRect.size.width, 100)];
        callView.hidden = NO;
        [self.nav.tabBarController.tabBar addSubview:callView];
        
        self.callView = callView;
        kWeakSelf
        self.callView.calloutBlock = ^(){
            [weakSelf standardCall];
        };
        self.callView.switchStatusBlock = ^(BOOL hidden) {
            [weakSelf.phonePadView hideCallView];
            //开始加载谁
            [weakSelf switchNumberPad:YES];
            weakSelf.isSearchStatu = NO;
            [weakSelf.tableView reloadData];
        };
    }

}

//谓词搜索
- (void)searchInfoWithString:(NSString *)searchText
{
    NSString *searchString = [NSString stringWithUTF8String:searchText.UTF8String];
    NSPredicate *contactsPredicate = [NSPredicate predicateWithFormat:@"phoneNumber CONTAINS[c] %@ || allPinyinNumber CONTAINS[c] %@ || headerPinyinNumber CONTAINS[c] %@", searchString, searchString, searchString];
    NSPredicate *recordsPredicate = [NSPredicate predicateWithFormat:@"hostnumber CONTAINS[c] %@ || destnumber CONTAINS[c] %@", searchString, searchString];
    //用predicateWithFormat创建一个谓词，name作为键路径
    if (_searchLists!= nil) {
        [_searchLists removeAllObjects];
    }
    
    NSArray *filter = [self filterNumerWithSearchList:[self.searchPhoneRecords filteredArrayUsingPredicate:recordsPredicate] SearchText:searchText];
    [self.searchLists addObjectsFromArray:filter];
    [self.searchLists addObjectsFromArray:[self.contactsLists filteredArrayUsingPredicate:contactsPredicate]];
    [self.tableView reloadData];
}

- (NSArray *)filterNumerWithSearchList:(NSArray *)searchLists SearchText:(NSString *)searchText
{
    NSMutableArray *tempArray = [NSMutableArray array];
    for (NSDictionary *recordDict in searchLists) {
        if ([[recordDict objectForKey:@"calltype"] isEqualToString:@"来电"]) {
            if ([(NSString *)[recordDict objectForKey:@"hostnumber"] containsString:searchText]) {
                [tempArray addObject:recordDict];
            }
        }else{
            if ([(NSString *)[recordDict objectForKey:@"destnumber"] containsString:searchText]) {
                [tempArray addObject:recordDict];
            }
        }
    }
    return tempArray;
}


- (void)standardCall {
    if (self.phonePadView.inputedPhoneNumber && self.phonePadView.inputedPhoneNumber.length) {
        NSString *strPhoneNumber = self.phonePadView.inputedPhoneNumber;
        //展示拨打电话选项
        [self selectCallPhoneType:[self formatPhoneNum:strPhoneNumber]];
    }
}

- (void)selectCallPhoneType:(NSString *)phoneNumber
{
    self.currentCallPhone = phoneNumber;
    [self startCallPhoneAction];
}

//改变键盘状态
- (void)switchNumberPad :(BOOL)hidden {
    if (hidden) {
        UNDebugLogVerbose(@"关闭键盘");
        self.phonePadButton.hidden = NO;
        self.phonePadView.un_top = self.view.un_height;
        self.phonePadView.phoneNumLabel.hidden = YES;
        self.callView.hidden = YES;
        self.isSearchStatu = NO;
        self.phonePadView.inputedPhoneNumber = nil;
        [self setTitleViewIsHidden:YES];
        self.tableView.un_height = self.view.un_height;
    }else{
        UNDebugLogVerbose(@"打开键盘");
        self.phonePadButton.hidden = YES;
        self.phonePadView.un_top = self.view.un_height - (100 - 49) - 225;
        self.phonePadView.placeholderLabel.hidden = NO;
        self.phonePadView.phoneNumLabel.hidden = NO;
        [self showOperation];
        self.isSearchStatu = YES;
        [self setTitleViewIsHidden:NO];
        self.tableView.un_height = self.phonePadView.un_top;
    }
}


/**
 初始化搜索
 */
//- (void)initSearchVc
//{
//    self.searchRecordVC =[[PhoneRecordSearchController  alloc]init];
//    kWeakSelf
//    self.searchRecordVC.didSelectSearchCellBlock = ^(id contacts){
//        [weakSelf didSelectSearchCellAction:contacts];
//    };
//    self.searchController = [[UISearchController alloc]initWithSearchResultsController:self.searchRecordVC];
//    [self.searchController.searchBar sizeToFit];   //大小调整
//    self.tableView.tableHeaderView = self.searchController.searchBar;
//    self.searchController.searchResultsUpdater = self;
//    self.searchController.searchBar.placeholder = @"输入联系人的姓名/电话";
//    self.searchController.searchBar.delegate = self;
//    self.definesPresentationContext = YES;
//}

//- (void)didSelectSearchCellAction:(id)contacts
//{
//    if ([contacts isKindOfClass:[ContactModel class]]) {
//        ContactModel *model = (ContactModel *)contacts;
//        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
//        if (storyboard) {
//            
//            ContactsDetailViewController *contactsDetailViewController = [storyboard instantiateViewControllerWithIdentifier:@"contactsDetailViewController"];
//            if (contactsDetailViewController) {
//                UNDebugLogVerbose(@"联系结果：%@",model);
//                //重置状态
//                [self.callActionView hideActionView];
//                [self.tableView reloadData];
//                
//                contactsDetailViewController.contactMan = model.name;
//                contactsDetailViewController.phoneNumbers = model.phoneNumber;
//                contactsDetailViewController.contactHead = model.portrait;
//                [contactsDetailViewController.ivContactMan  setImage:[UIImage imageNamed:model.portrait]];
//                [self.nav pushViewController:contactsDetailViewController animated:YES];
//            }
//        }
//    }else if ([contacts isKindOfClass:[NSDictionary class]]){
//        NSDictionary *dicCallRecord = (NSDictionary *)contacts;
//        
//        //电话记录，拨打电话
//        if (!self.callActionView){
//            self.callActionView = [[CallActionView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, kScreenHeightValue)];
//        }
//        
//        __weak typeof(self) weakSelf = self;
//        
//        self.callActionView.cancelBlock = ^(){
//            [weakSelf.callActionView hideActionView];
//        };
//        
//        self.callActionView.actionBlock = ^(NSInteger callType){
//            [weakSelf.callActionView hideActionView];
//            if (callType==1) {
//                //网络电话
//                //电话记录，拨打电话
//                if (dicCallRecord) {
//                    if ([dicCallRecord[@"calltype"] isEqualToString:@"来电"]) {
//                        [weakSelf callNumber:[dicCallRecord objectForKey:@"hostnumber"]];
//                    } else if ([dicCallRecord[@"calltype"] isEqualToString:@"去电"]) {
//                        [weakSelf callNumber:[dicCallRecord objectForKey:@"destnumber"]];
//                    } else {
//                        UNDebugLogVerbose(@"无法识别的电话方式");
//                    }
//                    UNDebugLogVerbose(@"%@", dicCallRecord[@"calltype"]);
//                }
//            }else if (callType==2){
//                //手环电话
//                if ([BlueToothDataManager shareManager].isRegisted) {
//                    //电话记录，拨打电话
//                    //                            NSDictionary *dicCallRecord = [weakSelf.arrPhoneRecord objectAtIndex:indexPath.row];
//                    if (dicCallRecord) {
//                        if ([dicCallRecord[@"calltype"] isEqualToString:@"来电"]) {
//                            [weakSelf callUnitysNumber:[dicCallRecord objectForKey:@"hostnumber"]];
//                        } else if ([dicCallRecord[@"calltype"] isEqualToString:@"去电"]) {
//                            [weakSelf callUnitysNumber:[dicCallRecord objectForKey:@"destnumber"]];
//                        } else {
//                            //                HUDNormal(@"无法识别的电话方式")
//                            UNDebugLogVerbose(@"无法识别的电话方式");
//                        }
//                        UNDebugLogVerbose(@"%@", dicCallRecord[@"calltype"]);
//                    }
//                } else {
//                    HUDNormal(INTERNATIONALSTRING(@"设备内sim卡未注册或已掉线"))
//                    if ([[BlueToothDataManager shareManager].homeVCLeftTitle isEqualToString:INTERNATIONALSTRING(HOMESTATUETITLE_SIGNALSTRONG)]) {
//                        [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:INTERNATIONALSTRING(HOMESTATUETITLE_REGISTING)];
//                    }
//                }
//            }
//        };
//        [self.callActionView showActionView];
//    }
//}
//
//- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
//{
//    //获取到用户输入的数据
//    self.searchRecordVC.searchText = searchController.searchBar.text;
//}
//
//#pragma mark - UISearchBarDelegate
//
//- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
//{
//    self.searchRecordVC.arrPhoneRecord = [self.arrPhoneRecord mutableCopy];
//    return YES;
//}
//
//- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
//{
//    self.searchRecordVC.searchText = searchText;
//}

//加载通话记录
- (void)loadPhoneRecord {
    self.checkToken = YES;
    
    [self getBasicHeader];
    
    _arrPhoneRecord = [[NSMutableArray alloc] init];
    
    //Document目录
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    path = [path stringByAppendingPathComponent:@"callrecord2.db"];
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    if (![db open]) {
        [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(@"创建通话记录失败") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil] show];
        return;
    }else{
        //监测数据库中我要需要的表是否已经存在
        NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", @"CallRecord" ];
        FMResultSet *rs = [db executeQuery:existsSql];
        
        if ([rs next]) {
            NSInteger count = [rs intForColumn:@"countNum"];
            UNDebugLogVerbose(@"The table count: %li", count);
            if (count == 1) {
                UNDebugLogVerbose(@"log_keepers table is existed.");
                //升序,将数据插入到最前面,因此最先插入的显示在最后
                NSString *dataSql = @"select * from CallRecord order by calltime asc";
                FMResultSet *rs = [db executeQuery:dataSql];
                while ([rs next]) {
                    //添加数据到arrPhoneCallRecord
                    NSString *jsonStr1 = [rs stringForColumn:@"datas"];
                    NSData *jsonData1 = [jsonStr1 dataUsingEncoding:NSUTF8StringEncoding];
                    NSArray *dataArray=[NSJSONSerialization JSONObjectWithData:jsonData1 options:NSJSONReadingAllowFragments error:nil];
                    [self.arrPhoneRecord insertObject:dataArray atIndex:0];
                    _searchPhoneRecords = nil;
                }
            }
            
            UNDebugLogVerbose(@"log_keepers is not existed.");
        }else{
            //加载数据到列表
            //升序,将数据插入到最前面,因此最先插入的显示在最后
            NSString *dataSql = @"select * from CallRecord order by calltime asc";
            FMResultSet *rs = [db executeQuery:dataSql];
            
            while ([rs next]) {
                //添加数据到arrPhoneCallRecord
                NSString *jsonStr1 = [rs stringForColumn:@"datas"];
                NSData *jsonData1 = [jsonStr1 dataUsingEncoding:NSUTF8StringEncoding];
                NSArray *dataArray=[NSJSONSerialization JSONObjectWithData:jsonData1 options:NSJSONReadingAllowFragments error:nil];
                
                [self.arrPhoneRecord insertObject:dataArray atIndex:0];
                _searchPhoneRecords = nil;
            }
        }
        [rs close];
        [db close];
    }
    
    [self.tableView reloadData];
}

//添加通话记录到数据库(建议封装到工具类中)
- (BOOL)addPhoneRecordWithHostcid:(NSString *)hostcid Destcid:(NSString *)destcid Calltime:(NSDate *)calltime Calltype:(NSString *)calltype CallDuration:(int)duration CallStatus:(NSInteger)callStatu{
    //status,来电是否接听
    NSTimeInterval a = [calltime timeIntervalSince1970];
    NSString *timestemp = [NSString stringWithFormat:@"%ld", (long)a];
    
    NSMutableDictionary *dicPhoneRecord = [[NSMutableDictionary alloc] initWithObjectsAndKeys:timestemp,@"calltime",calltype,@"calltype",[self numberFromCid:hostcid],@"hostnumber",[self numberFromCid:destcid],@"destnumber",@(callStatu),@"status", @(duration),@"callduration", nil];  //时间写入记录时不需要转成字符
    [dicPhoneRecord setObject:@"未知" forKey:@"location"];
    
    NSString *localPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    // 要检查的文件目录
    NSString *path = [localPath  stringByAppendingPathComponent:@"number_location.db"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    FMDatabase *db;
    //判断是否有数据库文件
    if ([fileManager fileExistsAtPath:path]) {
        db = [FMDatabase databaseWithPath:path];
        if (![db open]) {
            UNDebugLogVerbose(@"数据库打开失败！");
        }else{
            NSString *number;
            if ([calltype isEqualToString:@"去电"]) {
                number = [dicPhoneRecord objectForKey:@"destnumber"];
            } else {
                number = [dicPhoneRecord objectForKey:@"hostnumber"];
            }
            
            if ([self isZeroStarted:number]) {
                NSString *prefix;
                if (number.length >= 3) {
                    if ([[number substringToIndex:2] isEqualToString:@"01"]) {
                        prefix = [number substringWithRange:NSMakeRange(1, 2)];
                    }else if ([[number substringToIndex:2] isEqualToString:@"02"]) {
                        prefix = [number substringWithRange:NSMakeRange(1, 2)];
                    }else if ([[number substringToIndex:2] isEqualToString:@"00"]) {
                        if (number.length >= 5) {
                            prefix = [number substringWithRange:NSMakeRange(1, 4)];
                        }
                    }else {
                        if (number.length >= 4) {
                            prefix = [number substringWithRange:NSMakeRange(1, 3)];
                        }else{
                            prefix = number;
                        }
                    }
                }else{
                    prefix = number;
                }
                
                NSString *cityid;
                NSString *provinceid;
                NSString *provinceName = @"";
                NSString *cityName = @"";
                FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM Number_0 where number='%@'",prefix]];
                if ([rs next]) {
                    cityid = [NSString stringWithFormat:@"%zd",[rs longLongIntForColumn:@"city_id"]];
                    provinceid = [NSString stringWithFormat:@"%zd", [rs longLongIntForColumn:@"province_id"]];
                }
                rs = [db executeQuery:[NSString stringWithFormat:@"SELECT name FROM Province where id='%@'",provinceid]];
                if ([rs next]) {
                    provinceName = [rs stringForColumn:@"name"];
                }
                
                if (cityid.length) {
                    rs = [db executeQuery:[NSString stringWithFormat:@"SELECT name FROM City where id='%@'",cityid]];
                    if ([rs next]) {
                        cityName = [rs stringForColumn:@"name"];
                    }
                }
                [dicPhoneRecord setObject:[NSString stringWithFormat:@"%@ %@",provinceName,cityName] forKey:@"location"];
                [rs close];
            }else{
                if ([number length]>=8) {
                    NSString *prefix = [number substringToIndex:3];
                    NSString *center = [number substringWithRange:{3,4}];
                    
                    NSString *cityid;
                    NSString *provinceid;
                    NSString *provinceName = @"";
                    NSString *cityName = @"";
                    
                    FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM Number_%@ where number='%@'",prefix,center]];
                    if ([rs next]) {
                        cityid = [NSString stringWithFormat:@"%zd",[rs longLongIntForColumn:@"city_id"]];
                        provinceid = [NSString stringWithFormat:@"%zd", [rs longLongIntForColumn:@"province_id"]];
                    }
                    
                    rs = [db executeQuery:[NSString stringWithFormat:@"SELECT name FROM Province where id='%@'",provinceid]];
                    if ([rs next]) {
                        provinceName = [rs stringForColumn:@"name"];
                    }
                    if (cityid.length) {
                        rs = [db executeQuery:[NSString stringWithFormat:@"SELECT name FROM City where id='%@'",cityid]];
                        if ([rs next]) {
                            cityName = [rs stringForColumn:@"name"];
                        }
                    }
                    [dicPhoneRecord setObject:[NSString stringWithFormat:@"%@ %@",provinceName,cityName] forKey:@"location"];
                    
                    [rs close];
                }else{
                    NSString *phoneStr = [self checkPhoneNumberIsMobile:number];
                    if (phoneStr) {
                        [dicPhoneRecord setObject:phoneStr forKey:@"location"];
                    }
                }
            }
            [db close];
        }
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    path = [paths objectAtIndex:0];
    //    path = [path stringByAppendingPathComponent:@"callrecord.db"];
    path = [path stringByAppendingPathComponent:@"callrecord2.db"];
    db = [FMDatabase databaseWithPath:path];
    
    if (![db open]) {
        return FALSE;
    }else{
        [self insertSqlData:dicPhoneRecord dataBase:db Calltime:timestemp];
    }
    return YES;
}

//插入数据库
- (void)insertSqlData:(NSDictionary *)dicPhoneRecord dataBase:(FMDatabase *)db Calltime:(NSString *)calltime
{
    NSMutableString *dataId = [NSMutableString string];
    [dataId appendString:[dicPhoneRecord objectForKey:@"hostnumber"]];
    [dataId appendString:[dicPhoneRecord objectForKey:@"destnumber"]];
    [dataId appendString:[dicPhoneRecord objectForKey:@"calltype"]];
    //    NSTimeInterval a = [calltime timeIntervalSince1970];
    //    NSString *timestemp = [NSString stringWithFormat:@"%ld", (long)a];
    NSMutableArray *muteArray = [NSMutableArray array];
    [muteArray addObject:dicPhoneRecord];
    //监测数据库中我要需要的表是否已经存在
    NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", @"CallRecord"];
    FMResultSet *rs = [db executeQuery:existsSql];
    if ([rs next]) {
        NSInteger count = [rs intForColumn:@"countNum"];
        UNDebugLogVerbose(@"The table count: %zd", count);
        if (count == 0) {
            [db executeUpdate:@"CREATE TABLE CallRecord (datas Text, calltime TimeStamp, dataid text)"];
        }
        UNDebugLogVerbose(@"log_keepers table is existed.");
        //添加记录
        
        //查询是否包含数据
        
        rs = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM CallRecord where dataid='%@'",dataId]];
        if ([rs next]) {
            //如果能打开说明已存在,获取数据
            NSString *jsonStr1 = [rs stringForColumn:@"datas"];
            NSData *jsonData1 = [jsonStr1 dataUsingEncoding:NSUTF8StringEncoding];
            NSArray *dataArray=[NSJSONSerialization JSONObjectWithData:jsonData1 options:NSJSONReadingAllowFragments error:nil];
            muteArray = [NSMutableArray arrayWithArray:dataArray];
            [muteArray insertObject:dicPhoneRecord atIndex:0];
            
            NSData *jsonData2 = [NSJSONSerialization dataWithJSONObject:[muteArray copy] options:NSJSONWritingPrettyPrinted error:nil];
            NSString *jsonStr2 = [[NSString alloc] initWithData:jsonData2 encoding:NSUTF8StringEncoding];
            
            BOOL isSuccess = [db executeUpdate:[NSString stringWithFormat:@"UPDATE CallRecord SET datas='%@',calltime='%@' where dataid ='%@'", jsonStr2, calltime, dataId]];
            if (!isSuccess) {
                UNDebugLogVerbose(@"更新通话记录失败！%@",dicPhoneRecord);
            }
        }else{
            NSData *jsonData2 = [NSJSONSerialization dataWithJSONObject:muteArray options:NSJSONWritingPrettyPrinted error:nil];
            NSString *jsonStr2 = [[NSString alloc] initWithData:jsonData2 encoding:NSUTF8StringEncoding];
            BOOL isSuccess = [db executeUpdate:@"INSERT INTO CallRecord (datas, calltime, dataid) VALUES (?, ?, ?)", jsonStr2, calltime, dataId];
            if (!isSuccess) {
                UNDebugLogVerbose(@"添加通话记录失败！%@",dicPhoneRecord);
            }
        }
        UNDebugLogVerbose(@"log_keepers is not existed.");
        //创建表
        //[membersDB executeUpdate:@"CREATE TABLE PersonList (Name text, Age integer, Sex integer,Phone text, Address text, Photo blob)"];
        
    }else{
        //添加记录
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[muteArray copy] options:NSJSONWritingPrettyPrinted error:nil];
        NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        BOOL isSuccess = [db executeUpdate:@"INSERT INTO CallRecord (datas, calltime, dataid) VALUES (?, ?, ?)", jsonStr, calltime, dataId];
        
        if (!isSuccess) {
            UNDebugLogVerbose(@"添加通话记录失败！%@",dicPhoneRecord);
        }
    }
    [rs close];
    [db close];
    [self loadPhoneRecord];
}

- (NSString *)numberFromCid :(NSString *)cid {
    //原本考虑正则，但规则比较简单
    if (([[cid substringToIndex:3] isEqualToString:@"981"])&&[cid rangeOfString:@"#"].length) {
        return [cid substringWithRange:NSMakeRange(3, [cid rangeOfString:@"#"].location-3)];
    } else if ([[cid substringToIndex:3] isEqualToString:@"986"]) {
        return [cid substringFromIndex:8];
    } else {
        return cid;
    }
}


-(NSString *)checkPhoneNumberIsMobile:(NSString *)phoneNumber
{
    NSString *phoneStr;
    if([phoneNumber isEqualToString:@"10000"] || [phoneNumber isEqualToString:@"10001"]){
        phoneStr = @"中国电信";
    }else if([phoneNumber isEqualToString:@"10010"] || [phoneNumber isEqualToString:@"10011"]){
        phoneStr = @"中国联通";
    }else if([phoneNumber isEqualToString:@"10086"]){
        phoneStr = @"中国移动";
    }else if([phoneNumber isEqualToString:@"10039"]){
        phoneStr = @"分享通讯";
    }else{
        phoneStr = nil;
    }
    return phoneStr;
}

//已废弃
- (void)makeCallAction :(NSNotification *)notification {
    NSString *phoneNumber = notification.object;
    if (phoneNumber) {
        [self callNumber:phoneNumber];
    }
}

//手动拨打电话通知
- (void)makeUnitysCallAction:(NSNotification *)notification {
    NSString *phoneNumber = notification.object;
    if (phoneNumber) {
        [self callUnitysNumber:phoneNumber FromCallKit:NO];
    }
}

- (void)getMaxPhoneCall {
    [UNNetworkManager getUrl:apiGetMaxmimumPhoneCallTime parameters:nil success:^(ResponseType type, id  _Nullable responseObj) {
        if (type == ResponseTypeSuccess) {
            self.maxPhoneCall = [[[responseObj objectForKey:@"data"]  objectForKey:@"maximumPhoneCallTime"] intValue];
        }
    } failure:^(NSError * _Nonnull error) {
        UNDebugLogVerbose(@"有异常：%@",[error description]);
    }];
}

//通话状态改变
- (void)callingAction:(NSNotification *)notification {
    if (notification.object) {
        NSString *action = notification.object;
        SipEngine *theSipEngine = [SipEngineManager getSipEngine];
        if ([action isEqualToString:@"Hungup"]) {
            self.speakerStatus = NO;
            //初始化扩音
            theSipEngine->SetLoudspeakerStatus(NO);
            
            if(theSipEngine->InCalling())
                theSipEngine->TerminateCall();
            //挂断系统的通话界面
            if (kSystemVersionValue >= 10.0 && isUseCallKit) {
                [[UNCallKitCenter sharedInstance]  endCall:nil completion:^(NSError * _Nullable error) {
                }];
            }
            self.hostHungup = @"source";
        }else if ([action isEqualToString:@"SwitchSound"]){
            //保存扩音状态,在未接通时修改扩音状态无效,因此保存此状态,在接通时更新.
            if (notification.userInfo) {
                if (notification.userInfo[@"isHandfreeon"]) {
                    self.speakerStatus = [notification.userInfo[@"isHandfreeon"] boolValue];
                }
            }
            UNDebugLogVerbose(@"当前扩音状态:%zd", self.speakerStatus);
            //系统扩音状态会自动更新,无法对系统扩音进行操作,因此不做处理
            theSipEngine->SetLoudspeakerStatus(self.speakerStatus);
            
        }else if ([action isEqualToString:@"MuteSound"]){
            if (notification.userInfo) {
                if (notification.userInfo[@"isMuteon"]) {
                    self.muteStatus = [notification.userInfo[@"isMuteon"] boolValue];
                }
            }
            //对系统的通话界面进行无声
            if (kSystemVersionValue >= 10.0 && isUseCallKit) {
                [[UNCallKitCenter sharedInstance]  mute:self.muteStatus callUUID:nil completion:^(NSError * _Nullable error) {
                }];
            }else{
                theSipEngine->MuteMic(self.muteStatus);
            }
            
            //            self.muteStatus = !self.muteStatus;
            //            theSipEngine->MuteMic(self.muteStatus);
        }else if ([action isEqualToString:@"Answer"]){
            //初始化扩音
            theSipEngine->SetLoudspeakerStatus(NO);
            
            theSipEngine->AnswerCall();
            theSipEngine->StopRinging();
        }else if ([action isEqualToString:@"Refuse"]){
            theSipEngine->TerminateCall();
        }else if ([action isEqualToString:@"SoundValueChange"]){
            UNDebugLogVerbose(@"停止铃声");
//            theSipEngine->StopRinging();
            if (self.callCominginVC) {
                [[SipEngineManager instance] stopCallRing];
            }
        }
    }
}

//在通话界面发送DTMF消息
- (void)callPhoneKeyBoard:(NSNotification *)noti
{
    NSString *numer = [noti object];
    if ([self verificationNumber:numer]) {
        SipEngine *theSipEngine = [SipEngineManager getSipEngine];
        theSipEngine->SendDtmf([numer UTF8String]);
    }
}

//验证dtmf
- (BOOL)verificationNumber:(NSString *)numer
{
    NSArray *allNumber = @[@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"*",@"0",@"#"];
    if ([allNumber containsObject:numer]) {
        return YES;
    }else{
        return NO;
    }
}

-(void) OnNetworkQuality:(int)ms {
    //网络质量提示？
}

-(void)OnSipEngineState:(SipEngineState)code {
    if (code == EngineStarting) {
        UNDebugLogVerbose(@"SIP启动状态---EngineStarting");
    }else if (code == EngineInitialized){
        UNDebugLogVerbose(@"SIP启动状态---EngineInitialized");
    }else if (code == EngineInitializedFailed){
        UNDebugLogVerbose(@"SIP启动状态---EngineInitializedFailed");
    }else if (code == EngineTerminated){
        UNDebugLogVerbose(@"SIP启动状态---EngineTerminated");
    }else {
        UNDebugLogVerbose(@"未知启动状态");
    }
}


//电话拨打进来
- (void)InComingCallWithCallKitName:(NSString *)name PhoneNumber:(NSString *)phoneNumber
{
    self.callCenter.currentCallKitName = name;
    UNContact * contact = [[UNContact alloc]init];
    contact.phoneNumber= phoneNumber;
    contact.displayName= name;
    contact.uniqueIdentifier= @"";
    
    UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUUID * callUUID=[[UNCallKitCenter sharedInstance] reportIncomingCallWithContact:contact completion:^(NSError * _Nullable error) {
                               if (error == nil) {
                                   UNDebugLogVerbose(@"%s success", __func__);
                               }else{
                                   UNDebugLogVerbose(@"arror %@", error);
                               }
                           }];
        UNDebugLogVerbose(@"callUUID==%@", callUUID);
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
    });
}


//来电或去电会调用此代理
-(void) OnNewCall:(CallDir)dir
 withPeerCallerID:(NSString*)cid
        withVideo:(BOOL)video_call{
    [UNSipEngineInitialize sharedInstance].sipCallPhoneStatu = SipCallPhoneStatuNewCall;
    UNLogLBEProcess(@"新呼叫");
    NSString *newcid;
//    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    if (dir == CallIncoming){
        [[UNBlueToothTool shareBlueToothTool] checkNitifiCall];
        //        msg = [NSString stringWithFormat:@"新来电 %@",cid];
        //去掉“+”
        if ([cid containsString:@"+"]) {
            newcid = [cid stringByReplacingOccurrencesOfString:@"+" withString:@""];
            cid = newcid;
        }
        //去掉86
        if ([[cid substringWithRange:NSMakeRange(0, 2)] isEqualToString:@"86"]) {
            newcid = [cid substringFromIndex:2];
            cid = newcid;
        }
        self.currentCid = cid;
        
        if ([[UNDataTools sharedInstance].blackLists containsObject:cid]) {
            UNLogLBEProcess(@"在黑名单内,挂断电话");
            [self hungupPhone];
        }else{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NewCallInComing" object:nil];
            //dismiss手机验证界面
            if (self.nav.presentedViewController) {
                [self.nav.presentedViewController dismissViewControllerAnimated:NO completion:nil];
            }
            
            if (kSystemVersionValue >= 10.0 && isUseCallKit) {
                [self InComingCallWithCallKitName:[self checkLinkNameWithPhoneStr:cid] PhoneNumber:cid];
            }else{
                //电话拨打进来设置扩音
                SipEngine *theSipEngine = [SipEngineManager getSipEngine];
                theSipEngine->SetLoudspeakerStatus(YES);
                
                CallComingInViewController *callCominginVC = [[CallComingInViewController alloc] init];
                self.callCominginVC = callCominginVC;
                self.callCominginVC.nameStr = [self checkLinkNameWithPhoneStr:cid];
                [self.nav presentViewController:self.callCominginVC animated:YES completion:nil];
            }
        }
        
    }else{
        self.currentCid = cid;
    }
}

//挂断电话
- (void)hungupPhone
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.speakerStatus = NO;
        SipEngine *theSipEngine = [SipEngineManager getSipEngine];
        if(theSipEngine->InCalling())
            theSipEngine->TerminateCall();
        self.hostHungup = @"source";
    });
}

-(void) OnCallProcessing{
    UNDebugLogVerbose(@"正在呼叫...============================");
    [UNSipEngineInitialize sharedInstance].sipCallPhoneStatu = SipCallPhoneStatuCallProcessing;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"正在呼叫...")];
}

/*对方振铃*/
-(void) OnCallRinging{
    UNDebugLogVerbose(@"对方振铃...============================");
    [UNSipEngineInitialize sharedInstance].sipCallPhoneStatu = SipCallPhoneStatuCallRinging;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SipEngine *theSipEngine = [SipEngineManager getSipEngine];
        theSipEngine->SetLoudspeakerStatus(self.speakerStatus);
        theSipEngine->MuteMic(self.muteStatus);
    });
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"对方振铃...")];
}

/*呼叫接通*/
-(void) OnCallStreamsRunning:(bool)is_video_call{
    UNDebugLogVerbose(@"正在通话...============================");
    [UNSipEngineInitialize sharedInstance].sipCallPhoneStatu = SipCallPhoneStatuCallStreamsRunning;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"正在通话")];
}

-(void) OnCallMediaStreamsConnected:(MediaTransMode)mode{
    UNDebugLogVerbose(@"呼叫连接类型...============================");
}

-(void) OnCallResume {
    UNDebugLogVerbose(@"继续通话");
}

-(void) onCallResumeByRemote {
    //远程
    UNDebugLogVerbose(@"对方继续通话");
}

-(void) OnCallPaused {
    UNDebugLogVerbose(@"暂停通话");
}

-(void) onCallPausedByRemote {
    UNDebugLogVerbose(@"对方暂停通话");
}

-(void) OnCallRemotePaused {
    UNDebugLogVerbose(@"暂停通话");
}

/*呼叫接通知识*/
-(void) OnCallConnected{
    UNDebugLogVerbose(@"OnCallConnected...============================");
    [UNSipEngineInitialize sharedInstance].sipCallPhoneStatu = SipCallPhoneStatuCallConnected;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"正在通话")];
}

//话单详情
//typedef struct _CallReport{
//    char calling[128];
//    char called[128];
//    CallStatus status;
//    CallDir dir;
//    int duration;
//    bool is_video_call;
//    char start_date[32];
//    char record_file[2048];
//    void *user_ptr;
//}CallReport;

//    typedef enum _CallStatus {
//        CallSuccess, /**< The call was sucessful*/
//        CallAborted, /**< The call was aborted */
//        CallMissed, /**< The call was missed (unanswered)*/
//        CallDeclined /**< The call was declined, either locally or by remote end*/
//    } CallStatus;
/*
 话单
 通话完成会调用此方法
 */
-(void) OnCallReport:(CallReport *)cdr
{
    if (cdr->status == CallSuccess && cdr->dir == CallOutgoing) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateMaximumPhoneCallTime" object:nil userInfo:@{@"CallTime" : @(cdr->duration)}];
    }
    UNDebugLogVerbose(@"话单=====时间:%zd=====状态:%zd", cdr->duration,cdr->status);
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    NSString *destcid, *hostcid, *callType;
    NSInteger callStatu = 1;
//    callin和called不准确,里面包含了端口,分钟数等信息
    if (cdr->dir == CallOutgoing) {
        //呼出(不存在未接)
        hostcid = [userdata objectForKey:@"Tel"];
        destcid = self.currentCid;
        callType = @"去电";
    }else{
        hostcid = self.currentCid;
        destcid = [userdata objectForKey:@"Tel"];
        callType = @"来电";
        //呼入(当时间为0且通话状态为miss时为未接)
        if (cdr->duration == 0 && cdr->status == CallMissed) {
            callStatu = 0;
            [self addMissPhoneRecord];
        }
    }
    //添加通话信息到数据库
    [self addPhoneRecordWithHostcid:hostcid Destcid:destcid Calltime:[NSDate date] Calltype:callType CallDuration:cdr->duration CallStatus:callStatu];
}

/*呼叫结束*/
-(void) OnCallEnded{
    UNDebugLogVerbose(@"结束通话");
    //    [mStatus setText:@"结束通话"];
    [UNSipEngineInitialize sharedInstance].sipCallPhoneStatu = SipCallPhoneStatuCallEnded;
    [self loadPhoneRecord];
    self.speakerStatus = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"通话结束")];
}

/*呼叫失败，并返回错误代码，代码对应的含义，请参考common_types.h*/
-(void) OnCallFailed:(CallErrorCode) error_code{
    [UNSipEngineInitialize sharedInstance].sipCallPhoneStatu = SipCallPhoneStatuCallFailed;
    UNDebugLogVerbose(@"呼叫错误, 代码 %d",error_code);
    //直接挂断
    [self OnCallEnded];
    
//    if (error_code == RequestTimeout || error_code == BusyHere) {
//        //直接挂断
//        [self OnCallEnded];
//    }else{
//        [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"错误提示") message:[NSString stringWithFormat:@"%@", INTERNATIONALSTRING(@"呼叫异常,请确认网络或账号正常")] delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
//    }
}


//注册网络电话
-(void)doRegister{
    SipEngine *theSipEngine = [SipEngineManager getSipEngine];
    
    if(theSipEngine->AccountIsRegstered())
    {
        theSipEngine->DeRegisterSipAccount();
        __block SipEngine *callEngine = theSipEngine;
        
        [UNNetworkManager getUrl:apiGetSecrityConfig parameters:nil success:^(ResponseType type, id  _Nullable responseObj) {
            if (type == ResponseTypeSuccess) {
                if (responseObj[@"data"][@"VswServer"]) {
                    [VSWManager shareManager].vswIp = responseObj[@"data"][@"VswServer"][@"Ip"];
                    [VSWManager shareManager].vswPort = [responseObj[@"data"][@"VswServer"][@"Port"] intValue];
                    [[NSUserDefaults standardUserDefaults] setObject:responseObj[@"data"][@"VswServer"][@"Ip"] forKey:@"VSWServerIp"];
                    [[NSUserDefaults standardUserDefaults] setObject:responseObj[@"data"][@"VswServer"][@"Port"] forKey:@"VSWServerPort"];
                }
                
                NSString *secpwd = [super md5:[[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"PublicPassword"] stringByAppendingString:@"voipcc2015"]];
                
                NSString *thirdpwd = [super md5:secpwd];
                
                NSString *userName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"userData"] objectForKey:@"Tel"];
                
                
                self.outIP = [[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"];
                UNLogLBEProcess(@"注册网络电话secpwd===%@,thirdpwd====%@,userName====%@", secpwd, thirdpwd, userName);
                callEngine->SetEnCrypt(NO, NO);
                //IP地址
                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String], "", [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"] UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue]);
                //域名
                //                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String], "", [@"asterisk.unitoys.com" UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue]);
            }
        } failure:^(NSError * _Nonnull error) {
            UNDebugLogVerbose(@"有异常：%@",[error description]);
        }];
        
    }else{
        __block SipEngine *callEngine = theSipEngine;
        [UNNetworkManager getUrl:apiGetSecrityConfig parameters:nil success:^(ResponseType type, id  _Nullable responseObj) {
            if (type == ResponseTypeSuccess) {
                if (responseObj[@"data"][@"VswServer"]) {
                    [VSWManager shareManager].vswIp = responseObj[@"data"][@"VswServer"][@"Ip"];
                    [VSWManager shareManager].vswPort = [responseObj[@"data"][@"VswServer"][@"Port"] intValue];
                    [[NSUserDefaults standardUserDefaults] setObject:responseObj[@"data"][@"VswServer"][@"Ip"] forKey:@"VSWServerIp"];
                    [[NSUserDefaults standardUserDefaults] setObject:responseObj[@"data"][@"VswServer"][@"Port"] forKey:@"VSWServerPort"];
                }
                
                NSString *secpwd = [super md5:[[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"PublicPassword"] stringByAppendingString:@"voipcc2015"]];
                /*
                 secpwd = [super md5:@"e38632c0f035e45efe57125bd0ebe8cevoipcc2015"];*/
                //去年替换方案
                
                NSString *thirdpwd = [super md5:secpwd];
                
                NSString *userName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"userData"] objectForKey:@"Tel"];
                //[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"PublicPassword"]
                
                //callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String],"", "121.46.3.20", 65061,1800);
                
                self.outIP = [[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"];
                
                callEngine->SetEnCrypt(NO, NO);
                UNLogLBEProcess(@"注册网络电话secpwd===%@,thirdpwd====%@,userName====%@", secpwd, thirdpwd, userName)
                
                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String], "", [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"] UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue]);
            }
        } failure:^(NSError * _Nonnull error) {
            UNDebugLogVerbose(@"有异常：%@",[error description]);
        }];
    }
}

/*帐号注册状态反馈, 失败返回错误代码 代码对应的含义，请参考common_types.h*/
-(void) OnRegistrationState:(RegistrationState) code
              withErrorCode:(RegistrationErrorCode) e_errno{
    NSString *msg=@"";
    if (code == 0) {
        msg = @"未注册";
        [SipEngineManager instance].resignStatue = 0;
        [UNSipEngineInitialize sharedInstance].sipRegisterStatu = SipRegisterStatuNone;
    }else if(code == 1){
        msg = @"正在注册...";
        [SipEngineManager instance].resignStatue = 0;
        [UNSipEngineInitialize sharedInstance].sipRegisterStatu = SipRegisterStatuProgress;
        //        [mBtnRegister setTitle:@"注册中" forState:UIControlStateNormal];
    }else if(code == 2){
        msg = @"注册成功！";
        [SipEngineManager instance].resignStatue = 1;
        [UNSipEngineInitialize sharedInstance].sipRegisterStatu = SipRegisterStatuSuccess;
        //        [mBtnRegister setTitle:@"注销" forState:UIControlStateNormal];
    }else if(code == 3){
        msg = @"您的账号已注销";
        [SipEngineManager instance].resignStatue = 0;
        [UNSipEngineInitialize sharedInstance].sipRegisterStatu = SipRegisterStatuCleared;
        //        [mBtnRegister setTitle:@"注册" forState:UIControlStateNormal];
    }else if(code == 4){
        msg = [NSString stringWithFormat:@"注册失败，错误代码 %d",e_errno];
        [SipEngineManager instance].resignStatue = 0;
        [UNSipEngineInitialize sharedInstance].sipRegisterStatu = SipRegisterStatuFailed;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NetWorkPhoneRegisterFailed" object:nil];
    }
    
    //    [mStatus setText:msg];
    UNLogLBEProcess(@"注册状态：%@",msg);
}

- (NSString *)formatPhoneNum:(NSString *)phone
{
    phone = [phone stringByReplacingOccurrencesOfString:@"-" withString:@""];
    phone = [phone stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([phone hasPrefix:@"86"]) {
        NSString *formatStr = [phone substringWithRange:NSMakeRange(2, [phone length]-2)];
        return formatStr;
    }
    else if ([phone hasPrefix:@"+86"])
    {
        if ([phone hasPrefix:@"+86·"]) {
            NSString *formatStr = [phone substringWithRange:NSMakeRange(4, [phone length]-4)];
            return formatStr;
        }
        else
        {
            NSString *formatStr = [phone substringWithRange:NSMakeRange(3, [phone length]-3)];
            return formatStr;
        }
    }
    return phone;
}

//方法已废弃
- (void)callNumber :(NSString *)strNumber {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
    
    if (storyboard) {
        if (strNumber) {
            self.phoneNumber = strNumber;
        }
        self.calledTelNum = [NSString stringWithFormat:@"981%@",self.phoneNumber];
        //获取最大通话时长后再拨打
        [SSNetworkRequest getRequest:apiGetMaxmimumPhoneCallTime params:nil success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                CallingViewController *callingViewController = [storyboard instantiateViewControllerWithIdentifier:@"callingViewController"];
                if (callingViewController) {
//                    self.callStartTime = [NSDate date];
                    callingViewController.lblCallingInfo.text = [self checkLinkNameWithPhoneStr:self.phoneNumber];
                    [self.nav presentViewController:callingViewController animated:YES completion:^{
                        self.maxPhoneCall = [[[responseObj objectForKey:@"data"]  objectForKey:@"maximumPhoneCallTime"] intValue];
                        SipEngine *theSipEngine = [SipEngineManager getSipEngine];
                        callingViewController.lblCallingInfo.text = [self checkLinkNameWithPhoneStr:self.phoneNumber];
                        theSipEngine->MakeCall([[NSString stringWithFormat:@"981%@#%d",[self formatPhoneNum:self.phoneNumber],self.maxPhoneCall] UTF8String],false,NULL);
                    }];
                }
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
                UNDebugLogVerbose(@"获取最大时长失败");
                //                    HUDNormal(responseObj[@"msg"])
                HUDNormal(INTERNATIONALSTRING(@"获取通话时长失败"))
            }
        } failure:^(id dataObj, NSError *error) {
            UNDebugLogVerbose(@"有异常：%@",[error description]);
            HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        } headers:self.headers];
    }
}


//拨打电话(在拨打电话时需要调用CallKit将通话记录保存到系统中,需要通过fromCallKit判断是否从CallKit回调过来的,如果是,直接拨打电话,否则再次调用CallKit会导致循环调用异常)
- (void)callUnitysNumber:(NSString *)strNumber FromCallKit:(BOOL)fromCallKit{
    kWeakSelf
    //检查麦克风权限
    [self checkMicAuth:^(BOOL isAuthorized) {
        UNDebugLogVerbose(@"是否开启麦克风权限===%d", isAuthorized)
        if (isAuthorized) {
            [weakSelf presentCallPhone:strNumber FromCallKit:fromCallKit];
        }
    }];

}

//判断是否有套餐(此版本已屏蔽网络电话,根据需求开启)
- (void)presentCallPhone:(NSString *)strNumber FromCallKit:(BOOL)fromCallKit
{
    self.maxPhoneCall = -1;
    __block NSString *currentDateStr;
    //是否直接拨打电话
    BOOL isCallPhone = NO;
    //是否有流量套餐
    BOOL isHasPackage = NO;
    NSDictionary *phoneTimeDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"MaxPhoneCallTime"];
    if ([phoneTimeDict[@"maximumPhoneCallTime"] intValue] == -1) {
        //无流量套餐
        isHasPackage = NO;
    }else{
        if ([phoneTimeDict[@"expiredDate"] doubleValue] > [[NSDate date] timeIntervalSince1970]) {
            //套餐在期限内
            isHasPackage= YES;
            if ([phoneTimeDict[@"maximumPhoneCallTime"] intValue] == 0) {
                //无限通话
                self.maxPhoneCall = 36000;
            }else{
                self.maxPhoneCall = [phoneTimeDict[@"maximumPhoneCallTime"] intValue];
            }
        }else{
            //套餐已过期
            isHasPackage= NO;
        }
    }
    
    if (isHasPackage) {
        //有套餐
        isCallPhone = YES;
        //如果有套餐,还需判断号码是否符合座机或手机,如果不符合,则需要使用本机电话
        if (![self phoneNumberIsVerification:strNumber]) {
            UNDebugLogVerbose(@"使用本机电话");
            isHasPackage = NO;
        }
    }else{
        //无套餐
        //判断是否忽略今天提示(查询是否存储过今天的时间)
        isCallPhone = [UNDataTools isSaveTodayDateWithKey:@"HiddenTodayTipWithCallPhone" TodayString:^(NSString *todayStr) {
            currentDateStr = todayStr;
        }];
    }
    //    if (isHasPackage) {
    //        //如果有套餐,还需判断号码是否符合座机或手机,如果不符合,则需要使用本机电话
    //        if (![self phoneNumberIsVerification:strNumber]) {
    //            UNDebugLogVerbose(@"使用本机电话");
    //            isHasPackage = NO;
    //        }
    //    }
    
    //屏蔽省心服务
    if (!ShowConvenienceService) {
        isCallPhone = YES;
        isHasPackage = NO;
    }
    //测试手动设置为NO
    if (isCallPhone) {
        [self showCallPhoneVc:strNumber IsNetWorkCallPhone:isHasPackage FromCallKit:fromCallKit];
    }else{
        [self showTipViewWithCurrentDate:currentDateStr StringNumber:strNumber IsNetWorkCallPhone:isHasPackage FromCallKit:fromCallKit];
    }
}

//判断手机号码是否为座机或手机
- (BOOL)phoneNumberIsVerification:(NSString *)phone
{
    BOOL isVerification = NO;
    if (phone.length >= 5 && ([self isSpecialPhoneNumber:[phone substringToIndex:5]])) {
        UNDebugLogVerbose(@"三大运营商号码");
        return NO;
    }
    if (phone.length >= 9) {
        if ([self isTelPhone:phone]) {
            UNDebugLogVerbose(@"号码为座机号");
            isVerification = YES;
        }else if ([self isMobilePhone:phone]) {
            UNDebugLogVerbose(@"号码为手机号");
            isVerification = YES;
        }else if ([self isOtherPhone:phone]){
            UNDebugLogVerbose(@"号码为特殊号码");
            isVerification = YES;
        }
    }
    return isVerification;
}

//是否为特定号码
- (BOOL)isSpecialPhoneNumber:(NSString *)phone
{
    NSArray *specialNumbers = @[@"10086", @"10010", @"10011", @"10000", @"10060", @"10050", @"10070", @"10039"];
    if ([specialNumbers containsObject:phone]) {
        return YES;
    }else{
        return NO;
    }
}

//检查麦克风权限
- (void)checkMicAuth:(void (^)(BOOL isAuthorized))authResult
{
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (videoAuthStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            if (authResult) {
                authResult(granted);
            }
        }];
    }else if(videoAuthStatus == AVAuthorizationStatusRestricted || videoAuthStatus == AVAuthorizationStatusDenied){
        // 未授权
        if (authResult) {
            authResult(NO);
        }
        UNDebugLogVerbose(@"弹出权限选择")
        [self presentMicPhoneAuthView];
    }else{
        // 已授权
        if (authResult) {
            authResult(YES);
        }
    }
}

//弹出麦克风权限提醒
- (void)presentMicPhoneAuthView
{
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:nil message:@"通话过程\n必须开启麦克风权限" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"去开启" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UNDebugLogVerbose(@"弹出系统界面");
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
//            if (kSystemVersionValue >= 10.0) {
//                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{UIApplicationOpenURLOptionUniversalLinksOnly : @YES} completionHandler:nil];
//            }else{
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
//            }
        }else{
            UNDebugLogVerbose(@"无法弹出系统界面");
        }
    }];
    [alertVc addAction:cancelAction];
    [alertVc addAction:sureAction];
    [self.navigationController presentViewController:alertVc animated:YES completion:nil];
}

//判断是否为固话,仅判断前缀和位数
- (BOOL)isTelPhone:(NSString *)phone
{
    if ([[phone substringToIndex:1] isEqualToString:@"0"] && (phone.length == 11 || phone.length == 12)) {
        return YES;
    }else{
        return NO;
    }
}

//判断是否为手机
- (BOOL)isMobilePhone:(NSString *)phone
{
    if ([[phone substringToIndex:1] isEqualToString:@"1"] && ![[phone substringWithRange:NSMakeRange(1, 1)] isEqualToString:@"0"] && (phone.length == 11)) {
        return YES;
    }else{
        return NO;
    }
}

//判断是否为特殊号码
- (BOOL)isOtherPhone:(NSString *)phone
{
    if ([[phone substringToIndex:3] isEqualToString:@"400"] && phone.length == 10) {
        return YES;
    }else{
        return NO;
    }
}

//弹出提示
- (void)showTipViewWithCurrentDate:(NSString *)currentDateStr StringNumber:(NSString *)phoneNumber IsNetWorkCallPhone:(BOOL)isNetCallPhone FromCallKit:(BOOL)fromCallKit
{
    //如果点击按钮后不再提示为选中,存储今日时间
    kWeakSelf
    [ServiceRecommendView shareServiceRecommendViewWithTitle:@"推荐使用爱小器0元话费体验包,向高额话费说拜拜!" leftString:@"下次" rightString:@"去领取" buttnTap:^(NSInteger index, BOOL isNoTip) {
        if (isNoTip) {
            if (currentDateStr) {
                [[NSUserDefaults standardUserDefaults] setObject:currentDateStr forKey:@"HiddenTodayTipWithCallPhone"];
            }
        }
        if (index == 1) {
            [weakSelf showConvenienceVc];
        }else{
            [weakSelf showCallPhoneVc:phoneNumber IsNetWorkCallPhone:isNetCallPhone FromCallKit:fromCallKit];
        }
    }];
}

//跳转省心服务界面(暂时已屏蔽)
- (void)showConvenienceVc
{
    ConvenienceServiceController *convenienceVC = [[ConvenienceServiceController alloc] init];
    if ([self.nav.parentViewController isKindOfClass:[MainViewController class]]) {
        MainViewController *mainVc = (MainViewController *)self.nav.parentViewController;
        if ([mainVc.selectedViewController isKindOfClass:[UINavigationController class]]) {
            [mainVc.selectedViewController pushViewController:convenienceVC animated:YES];
        }
    }
}

//调用CallKit
- (void)showCallPhoneVc:(NSString *)strNumber IsNetWorkCallPhone:(BOOL)isNetCallPhone  FromCallKit:(BOOL)fromCallKit
{
    if (fromCallKit) {
        UNDebugLogVerbose(@"FromCallKit拨打电话")
        [self willPresentCallPhoneVcAndStartCallPhone:strNumber IsNetWorkCallPhone:isNetCallPhone];
    }else{
        if (kSystemVersionValue >= 10.0) {
            UNDebugLogVerbose(@"iOS10,CallKit拨打电话")
            UNContact *contact = [[UNContact alloc] init];
            contact.phoneNumber = strNumber;
            contact.uniqueIdentifier = @"";
            [[UNCallKitCenter sharedInstance] startRequestCalllWithContact:contact completion:^(NSError * _Nullable error) {
                //如果CallKit出错,直接调用正常流程
                if (error) {
                    //                [self callUnitysNumber:self.currentCallPhone];
                    [self willPresentCallPhoneVcAndStartCallPhone:strNumber IsNetWorkCallPhone:isNetCallPhone];
                }
            }];
        }else{
            [self willPresentCallPhoneVcAndStartCallPhone:strNumber IsNetWorkCallPhone:isNetCallPhone];
        }
    }
}

//调用网络电话SDK
- (void)willPresentCallPhoneVcAndStartCallPhone:(NSString *)strNumber IsNetWorkCallPhone:(BOOL)isNetCallPhone
{
    if (self.nav.presentedViewController && [self.nav.presentedViewController isKindOfClass:[CallingViewController class]]) {
        return;
    }else if (self.nav.presentedViewController){
        [self.nav.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
    if (storyboard) {
        if (strNumber) {
            self.phoneNumber = strNumber;
        }
        CallingViewController *callingViewController = [storyboard instantiateViewControllerWithIdentifier:@"callingViewController"];
        if (callingViewController) {
            [MobClick event:UMeng_Event_Call attributes:@{@"callTimes" : @"1"} counter:1];
            //            callingViewController.lblCallingInfo.text = [self checkLinkNameWithPhoneStr:self.phoneNumber];
            [self.nav presentViewController:callingViewController animated:YES completion:^{
                callingViewController.lblCallingInfo.text = [self checkLinkNameWithPhoneStr:self.phoneNumber];
                SipEngine *theSipEngine = [SipEngineManager getSipEngine];
                if (isNetCallPhone) {
                    //网络电话
                    UNDebugLogVerbose(@"网络电话");
                    theSipEngine->MakeCall([[NSString stringWithFormat:@"981%@#%d",[self formatPhoneNum:self.phoneNumber],self.maxPhoneCall] UTF8String],false,NULL);
                }else{
                    //直接拨打
                    UNDebugLogVerbose(@"直接拨打电话");
                    if ([VSWManager shareManager].callPort) {
                        theSipEngine->MakeCall([[NSString stringWithFormat:@"986%@%@",[VSWManager shareManager].callPort, [self formatPhoneNum:self.phoneNumber]] UTF8String],false,NULL);
                    }else if([[NSUserDefaults standardUserDefaults] objectForKey:@"VSWCallPort"]){
                        [VSWManager shareManager].callPort = [[NSUserDefaults standardUserDefaults] objectForKey:@"VSWCallPort"];
                        theSipEngine->MakeCall([[NSString stringWithFormat:@"986%@%@",[VSWManager shareManager].callPort, [self formatPhoneNum:self.phoneNumber]] UTF8String],false,NULL);
                    }else{
                        HUDNormal(INTERNATIONALSTRING(@"呼叫失败"))
                    }
                }
            }];
        }
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
     _noDataLabel.hidden = YES;
    if (self.isSearchStatu && self.phonePadView.inputedPhoneNumber && self.phonePadView.inputedPhoneNumber.length) {
        self.tableView.backgroundColor = DefualtBackgroundColor;
        return self.searchLists.count;
    }else{
        if (self.arrPhoneRecord.count == 0) {
            _noDataLabel.hidden = NO;
            self.tableView.backgroundColor = [UIColor whiteColor];
        }else{
            _noDataLabel.hidden = YES;
            self.tableView.backgroundColor = DefualtBackgroundColor;
        }
        return self.arrPhoneRecord.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    //判断是否为搜索状态
    if (self.isSearchStatu && self.phonePadView.inputedPhoneNumber && self.phonePadView.inputedPhoneNumber.length) {
        id model;
        if ([self.searchLists count] > indexPath.row ) {
            model = self.searchLists[indexPath.row];
        }
        if ([model isKindOfClass:[ContactModel class]]) {
            //展示搜索信息
            SearchContactsCell *cell = [tableView dequeueReusableCellWithIdentifier:searchContactsCellID];
            [cell updateCellWithModel:model HightText:self.phonePadView.inputedPhoneNumber];
            return cell;
        }else{
            
            PhoneRecordCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"PhoneRecordCell"];
            NSDictionary *dicPhoneRecord = (NSDictionary *)model;
            
            kWeakSelf
            cell.lookDetailsBlock = ^(NSInteger index, NSString *phoneNumber, NSString *nickName) {
                UNDebugLogVerbose(@"当前index---%zd", index);
                [weakSelf.phonePadView hideCallView];
                //开始加载谁
                [weakSelf switchNumberPad:YES];
                [weakSelf.tableView reloadData];
                
                ContactsCallDetailsController *callDetailsVc = [[ContactsCallDetailsController alloc] init];
                callDetailsVc.contactModel = [weakSelf checkContactModelWithPhoneStr:phoneNumber];
                callDetailsVc.nickName = nickName;
                callDetailsVc.phoneNumber = phoneNumber;
                [weakSelf.nav pushViewController:callDetailsVc animated:YES];
            };
            
            cell.lblCallTime.text = [self compareCurrentTimeString:[dicPhoneRecord objectForKey:@"calltime"]];
            //                cell.lblPhoneType.text = [dicPhoneRecord objectForKey:@"type"];
            [cell.lblPhoneNumber setTextColor:UIColorFromRGB(0x333333)];
            cell.currentIndex = indexPath.row;
            NSMutableString *bottomStr = [NSMutableString string];
            if ([[dicPhoneRecord objectForKey:@"calltype"] isEqualToString:@"来电"]) {
                [cell.ivStatus setImage:[UIImage imageNamed:@"from_phone"]];
                NSString *phoneNum = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"hostnumber"]];
                cell.nickName = phoneNum;
                cell.phoneNumber = [dicPhoneRecord objectForKey:@"hostnumber"];
                //高亮号码
                if (![(NSString *)[dicPhoneRecord objectForKey:@"hostnumber"] containsString:phoneNum]) {
                    [bottomStr appendString:(NSString *)[dicPhoneRecord objectForKey:@"hostnumber"]];
                    [bottomStr appendString:@"  "];
                    cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"hostnumber"]];
                }else{
                    NSMutableAttributedString *attriStr = [[NSMutableAttributedString alloc] initWithString:phoneNum attributes:@{NSForegroundColorAttributeName : UIColorFromRGB(0x333333)}];
                    NSRange range = [phoneNum rangeOfString:self.phonePadView.inputedPhoneNumber];
                    if (range.length) {
                        [attriStr setAttributes:@{NSForegroundColorAttributeName : DefultColor} range:range];
                    }
                    cell.lblPhoneNumber.attributedText = attriStr;
                }
                
                //                    if ([[dicPhoneRecord objectForKey:@"status"] intValue]==0){  //如果未接听则显示红色
                //                        [cell.lblPhoneNumber setTextColor:[UIColor redColor]];
                //                    }
            }else{
                [cell.ivStatus setImage:[UIImage imageNamed:@"to_phone"]];
                NSString *phoneNum = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"destnumber"]];
                cell.nickName = phoneNum;
                cell.phoneNumber = [dicPhoneRecord objectForKey:@"destnumber"];
                //高亮号码
                if (![(NSString *)[dicPhoneRecord objectForKey:@"destnumber"] containsString:phoneNum]) {
                    [bottomStr appendString:(NSString *)[dicPhoneRecord objectForKey:@"destnumber"]];
                    [bottomStr appendString:@"  "];
                    cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"destnumber"]];
                }else{
                    NSMutableAttributedString *attriStr = [[NSMutableAttributedString alloc] initWithString:phoneNum attributes:@{NSForegroundColorAttributeName : UIColorFromRGB(0x333333)}];
                    NSRange range = [phoneNum rangeOfString:self.phonePadView.inputedPhoneNumber];
                    if (range.length) {
                        [attriStr setAttributes:@{NSForegroundColorAttributeName : DefultColor} range:range];
                    }
                    cell.lblPhoneNumber.attributedText = attriStr;
                }
            }
            
            [bottomStr appendString:[dicPhoneRecord objectForKey:@"location"]];
            NSMutableAttributedString *attriStr = [[NSMutableAttributedString alloc] initWithString:bottomStr attributes:@{NSForegroundColorAttributeName : UIColorFromRGB(0x999999)}];
            NSRange range = [bottomStr rangeOfString:self.phonePadView.inputedPhoneNumber];
            if (range.length) {
                [attriStr setAttributes:@{NSForegroundColorAttributeName : DefultColor} range:range];
            }
            cell.lblPhoneType.attributedText = attriStr;
            
            return cell;
        }
    }else{
        //正常通话记录
        PhoneRecordCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"PhoneRecordCell"];
        NSArray *records = [self.arrPhoneRecord objectAtIndex:indexPath.row];
        
        kWeakSelf
        cell.lookDetailsBlock = ^(NSInteger index, NSString *phoneNumber, NSString *nickName) {
            [weakSelf.phonePadView hideCallView];
            //开始加载谁
            [weakSelf switchNumberPad:YES];
            
            UNDebugLogVerbose(@"当前index---%zd", index);
            ContactsCallDetailsController *callDetailsVc = [[ContactsCallDetailsController alloc] init];
            callDetailsVc.contactModel = [weakSelf checkContactModelWithPhoneStr:phoneNumber];
            callDetailsVc.nickName = nickName;
            callDetailsVc.phoneNumber = phoneNumber;
            [weakSelf.nav pushViewController:callDetailsVc animated:YES];
        };
        
        NSDictionary *dicPhoneRecord;
        if (records.count) {
            dicPhoneRecord = records[0];
        }
        NSString *phoneCount;
        if (records.count > 1) {
            phoneCount = [NSString stringWithFormat:@" (%zd)", records.count];
        }
        //            NSDictionary *dicPhoneRecord = [self.arrPhoneRecord objectAtIndex:indexPath.row];
        cell.lblCallTime.text = [self compareCurrentTimeString:[dicPhoneRecord objectForKey:@"calltime"]];
//        cell.lblPhoneType.text = [dicPhoneRecord objectForKey:@"type"];
        [cell.lblPhoneNumber setTextColor:UIColorFromRGB(0x333333)];
        cell.currentIndex = indexPath.row;
        NSMutableString *bottomStr = [NSMutableString string];
        
        if ([[dicPhoneRecord objectForKey:@"calltype"] isEqualToString:@"来电"]) {
            [cell.ivStatus setImage:[UIImage imageNamed:@"from_phone"]];
            NSString *phoneStr = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"hostnumber"]];
            cell.nickName = phoneStr;
            cell.phoneNumber = [dicPhoneRecord objectForKey:@"hostnumber"];
            
            if (phoneCount) {
                phoneStr = [phoneStr stringByAppendingString:[NSString stringWithFormat:@"%@", phoneCount]];
            }
            
            cell.lblPhoneNumber.text = phoneStr;
            
            //拼接电话号码
//            if (![(NSString *)[dicPhoneRecord objectForKey:@"hostnumber"] containsString:cell.lblPhoneNumber.text] && ![(NSString *)[dicPhoneRecord objectForKey:@"hostnumber"] isEqualToString:@"anonymous"]) {
//                [bottomStr appendString:(NSString *)[dicPhoneRecord objectForKey:@"hostnumber"]];
//                [bottomStr appendString:@"  "];
//            }
            
            if ([[dicPhoneRecord objectForKey:@"status"] intValue] == 0){  //如果未接听则显示红色
                [cell.lblPhoneNumber setTextColor:[UIColor redColor]];
            }else{
                [cell.lblPhoneNumber setTextColor:UIColorFromRGB(0x333333)];
            }
        }else{
            [cell.ivStatus setImage:[UIImage imageNamed:@"to_phone"]];
            NSString *phoneStr = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"destnumber"]];
            cell.nickName = phoneStr;
            cell.phoneNumber = [dicPhoneRecord objectForKey:@"destnumber"];
            if (phoneCount) {
                phoneStr = [phoneStr stringByAppendingString:[NSString stringWithFormat:@"%@", phoneCount]];
            }
            cell.lblPhoneNumber.text = phoneStr;
            
            //拼接电话号码
//            if (![(NSString *)[dicPhoneRecord objectForKey:@"destnumber"] containsString:cell.lblPhoneNumber.text]) {
//                [bottomStr appendString:(NSString *)[dicPhoneRecord objectForKey:@"destnumber"]];
//                [bottomStr appendString:@"  "];
//            }
        }
        [bottomStr appendString:[dicPhoneRecord objectForKey:@"location"]];
        cell.lblPhoneType.text = bottomStr;
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 65;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isSearchStatu && self.phonePadView.inputedPhoneNumber && self.phonePadView.inputedPhoneNumber.length) {
        //通过点击联系人拨打电话
        id contacts;
        if ([self.searchLists count] > indexPath.row ) {
            contacts = self.searchLists[indexPath.row];
        }
        
        if ([contacts isKindOfClass:[ContactModel class]]) {
            ContactModel *model = (ContactModel *)contacts;
            UNDebugLogVerbose(@"联系结果：%@",model);
            //重置状态
            [self.phonePadView hideCallView];
            [self switchNumberPad:YES];
            //                    self.callView.hidden = YES;
            //清空搜索状态
            self.isSearchStatu = NO;
            [self.searchLists removeAllObjects];
            [self.tableView reloadData];
            
            if ([model.phoneNumber containsString:@","]) {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
                if (storyboard) {
                    ContactsDetailViewController *contactsDetailViewController = [storyboard instantiateViewControllerWithIdentifier:@"contactsDetailViewController"];
                    if (contactsDetailViewController) {
                        contactsDetailViewController.contactModel = model;
                        contactsDetailViewController.contactMan = model.name;
                        contactsDetailViewController.phoneNumbers = model.phoneNumber;
                        contactsDetailViewController.contactHead = model.thumbnailImageData;
                        [contactsDetailViewController.ivContactMan  setImage:[UIImage imageWithData:model.thumbnailImageData]];
                        [self.nav pushViewController:contactsDetailViewController animated:YES];
                    }
                }
            }else{
                ContactsCallDetailsController *callDetailsVc = [[ContactsCallDetailsController alloc] init];
                callDetailsVc.contactModel = model;
                callDetailsVc.nickName = model.name;
                callDetailsVc.phoneNumber = model.phoneNumber;
                [self.nav pushViewController:callDetailsVc animated:YES];
            }
        }else if ([contacts isKindOfClass:[NSDictionary class]]){
            NSDictionary *dicCallRecord = (NSDictionary *)contacts;
            if (dicCallRecord) {
                if ([dicCallRecord[@"calltype"] isEqualToString:@"来电"]) {
                    self.currentCallPhone = [dicCallRecord objectForKey:@"hostnumber"];
                } else if ([dicCallRecord[@"calltype"] isEqualToString:@"去电"]) {
                    self.currentCallPhone = [dicCallRecord objectForKey:@"destnumber"];
                } else {
                    UNDebugLogVerbose(@"无法识别的电话方式");
                }
            }
//            [self.callActionView showActionView];
            [self startCallPhoneAction];
        }
    }else{
        NSArray *records = [self.arrPhoneRecord objectAtIndex:indexPath.row];
        NSDictionary *dicCallRecord;
        if (records.count) {
            dicCallRecord = records[0];
        }
        if (dicCallRecord) {
            if ([dicCallRecord[@"calltype"] isEqualToString:@"来电"]) {
                self.currentCallPhone = [dicCallRecord objectForKey:@"hostnumber"];
            } else if ([dicCallRecord[@"calltype"] isEqualToString:@"去电"]) {
                self.currentCallPhone = [dicCallRecord objectForKey:@"destnumber"];
            } else {
                UNDebugLogVerbose(@"无法识别的电话方式");
            }
            UNDebugLogVerbose(@"%@", dicCallRecord[@"calltype"]);
        }
//        [self.callActionView showActionView];
        [self startCallPhoneAction];
    }
}

//允许左滑删除
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(!self.isSearchStatu){
        return YES;
    }else{
        return NO;
    }
}

//左滑删除
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //删除本地数据库数据
    if(!self.isSearchStatu){
        //删除本地数据库数据
        [self deleteDatabaseWithIndex:indexPath tableView:tableView];
    }
}

//删除数据
- (void)deleteDatabaseWithIndex:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSArray *records = [self.arrPhoneRecord objectAtIndex:indexPath.row];
    NSDictionary *dicPhoneRecord;
    if (records.count) {
        dicPhoneRecord = records[0];
    }else{
        return;
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    path = [path stringByAppendingPathComponent:@"callrecord2.db"];
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    if (![db open]) {
        [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(@"删除通话记录失败") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil] show];
    }else{
        BOOL isDeleteSuccess =[db executeUpdate:@"DELETE FROM CallRecord WHERE calltime = ?",[dicPhoneRecord objectForKey:@"calltime"]];
        if (isDeleteSuccess) {
            [self.arrPhoneRecord removeObjectAtIndex:indexPath.row];
            _searchPhoneRecords = nil;
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [db close];
    }
    
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"错误提示"]) {
        [self OnCallEnded];
    }
}

- (void)setTitleViewIsHidden:(BOOL)isHidden
{
    if (!self.callTitleLabel) {
        UILabel *callTitleLabel = [[UILabel alloc] initWithFrame:self.nav.navigationBar.bounds];
        self.callTitleLabel = callTitleLabel;
        callTitleLabel.text = @"拨打";
        [callTitleLabel setTextAlignment:NSTextAlignmentCenter];
        [callTitleLabel setTextColor:[UIColor whiteColor]];
        [callTitleLabel setBackgroundColor:[UIColor clearColor]];
        [self.nav.navigationBar addSubview:callTitleLabel];
    }
    self.callTitleLabel.hidden = isHidden;
    if (self.isHideTitleViewBlock) {
        self.isHideTitleViewBlock(!isHidden);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)isShowLeftButton
{
    return NO;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addressBookChanged" object:@"addressBook"];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CallingAction" object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MakeCallAction" object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MakeUnitysCallAction" object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CallPhoneKeyBoard" object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateMissCall];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:@"MissPhoneRecord"];
    [self updateMissCall];
}


//增加未接来电
- (void)addMissPhoneRecord
{
    NSString *missNumberStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"MissPhoneRecord"];
    if (missNumberStr) {
        NSInteger missNum = [missNumberStr integerValue] + 1;
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%zd",missNum] forKey:@"MissPhoneRecord"];
    }
    [self updateMissCall];
}

//更新小红点
- (void)updateMissCall
{
    NSString *missNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"MissPhoneRecord"];
    if (missNumber && [missNumber integerValue]) {
        [UNDataTools sharedInstance].isHasMissCall = YES;
    }else{
        [UNDataTools sharedInstance].isHasMissCall = NO;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PhoneUnReadMessageStatuChange" object:nil];
}

@end
