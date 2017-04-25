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


@interface PhoneRecordController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong)NSDictionary *userInfo;
@property (nonatomic, strong)CallComingInViewController *callCominginVC;

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
    [self initTableView];
    //解压联系人数据库
    [self unZipNumberPhoneDB];
    
    
    if (!_arrPhoneRecord) {
        [self loadPhoneRecord];
    }
    
    kWeakSelf
    self.phonePadView = [[UCallPhonePadView alloc] initWithFrame:CGRectMake(0, kScreenHeightValue - 64, kScreenWidthValue, 225)];
    [self.view addSubview:self.phonePadView];
    
    self.phonePadView.completeBlock = ^(NSString *btnText, NSString *currentNum){
        
        if (btnText.length>0) {
            //当前为搜索状态
            weakSelf.isSearchStatu = YES;
            weakSelf.phonePadView.hidden = NO;
//            weakSelf.tableView.height = kScreenHeightValue - (64 + 100) - 225 - 70;
            weakSelf.tableView.height = weakSelf.view.height - (100 - 49) - 225 - 70;
            //搜索电话并展示
            [weakSelf searchInfoWithString:btnText];
        }else{
            //当前不为搜索状态
            weakSelf.isSearchStatu = NO;
            weakSelf.isSearchStatu = NO;
//            weakSelf.tableView.height = kScreenHeightValue - (64 + 100) - 225;
            weakSelf.tableView.height = weakSelf.view.height - (100 - 49) - 225;
            [weakSelf.tableView reloadData];
        }
        
    };
    
    //    [self initCallActionView];
    
    [self showWindow];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarHeightChange) name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
    
//    self.tabbarTop = self.tabBarController.tabBar.frame;
    NSLog(@"statusBarHeight--------%@", NSStringFromCGRect(self.tabBarController.tabBar.frame));
}


- (BOOL)initEngine {
    [[SipEngineManager instance] Init];
    [[SipEngineManager instance] LoadConfig];
    
    [[SipEngineManager instance] setCallDelegate:self];
    
    [[SipEngineManager instance] setRegistrationDelegate:self];
    
    [self doRegister];
    
    [self getMaxPhoneCall];
    
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
                    weakSelf.callCominginVC                    = [[CallComingInViewController alloc] init];
                    if (weakSelf.callCenter.currentCallKitName) {
                        weakSelf.callCominginVC.nameStr            = [weakSelf checkLinkNameWithPhoneStr:weakSelf.callCenter.currentCallKitName];
                    }
                    weakSelf.callCominginVC.isPresentInCallKit = YES;
                    [weakSelf.nav presentViewController:weakSelf.callCominginVC animated:NO completion:^{
                    }];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        NSNotification *noti = [[NSNotification alloc] initWithName:@"CallingAction" object:@"Answer" userInfo:nil];
                        [weakSelf callingAction:noti];
                    });
                    
                    //                SipEngine *theSipEngine = [SipEngineManager getSipEngine];
                    //                theSipEngine->AnswerCall();
                    //                theSipEngine->StopRinging();
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
                    weakSelf.callStopTime = [NSDate date];
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
                    NSLog(@"发起通话");
                    if ([action isKindOfClass:[CXStartCallAction class]]) {
                        CXStartCallAction *startAction = (CXStartCallAction *)action;
                        //手环电话
                        if ([BlueToothDataManager shareManager].isRegisted) {
                            if (startAction.handle.value) {
                                [weakSelf callUnitysNumber:startAction.handle.value];
                            }
                        } else {
                            HUDNormal(INTERNATIONALSTRING(@"设备内sim卡未注册或已掉线"))
                            if ([[BlueToothDataManager shareManager].homeVCLeftTitle isEqualToString:INTERNATIONALSTRING(HOMESTATUETITLE_SIGNALSTRONG)]) {
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
    NSLog(@"StatusBarHeight--------%.f", kStatusBarHeight);
    NSLog(@"statusBarHeight--------%@", NSStringFromCGRect(self.tabBarController.tabBar.frame));
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
        NSLog(@"数据库文件不存在");
        //判断是否有解压文件
        if ([fileManager fileExistsAtPath:zipPath]) {
            NSLog(@"解压文件存在");
            NSError *error;
            //解压文件
            if ([SSZipArchive unzipFileAtPath:zipPath toDestination:localPath overwrite:YES password:nil error:&error]) {
                if (error) {
                    NSLog(@"error---%@", error);
                }else{
                    NSLog(@"解压成功");
                }
            }else{
                NSLog(@"解压失败");
            }
        }
    }
    
}





//- (void)initCallActionView
//{
//    if (!self.callActionView){
//        self.callActionView = [[CallActionView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, kScreenHeightValue)];
//        __weak typeof(self) weakSelf = self;
//        
//        self.callActionView.cancelBlock = ^(){
//            [weakSelf.callActionView hideActionView];
//        };
//        
//        self.callActionView.actionBlock = ^(NSInteger callType){
//            [weakSelf.callActionView hideActionView];
//            
//            [weakSelf.phonePadView hideCallView];
//            [weakSelf switchNumberPad:YES];
//            
//            //        weakSelf.callView.hidden = YES;
//            //清空搜索状态
//            weakSelf.isSearchStatu = NO;
//            [weakSelf.searchLists removeAllObjects];
//            [weakSelf.tableView reloadData];
//            
//            if (callType==1) {
//                //网络电话
//                //电话记录，拨打电话
//                if (weakSelf.currentCallPhone) {
//                    [weakSelf callNumber:weakSelf.currentCallPhone];
//                }else{
//                    NSLog(@"当前拨打号码为空");
//                }
//            }else if (callType==2){
//                //手环电话
//                if ([BlueToothDataManager shareManager].isRegisted) {
//                    //电话记录，拨打电话
//                    if (weakSelf.currentCallPhone) {
//                        [weakSelf callUnitysNumber:weakSelf.currentCallPhone];
//                    }else{
//                        NSLog(@"当前拨打号码为空");
//                    }
//                } else {
//                    HUDNormal(INTERNATIONALSTRING(@"设备内sim卡未注册或已掉线"))
//                    if ([[BlueToothDataManager shareManager].homeVCLeftTitle isEqualToString:INTERNATIONALSTRING(HOMESTATUETITLE_SIGNALSTRONG)]) {
//                        [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:INTERNATIONALSTRING(HOMESTATUETITLE_REGISTING)];
//                    }
//                }
//            }
//        };
//        
//    }
//}

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
            
            [self callUnitysNumber:self.currentCallPhone];
        }else{
            NSLog(@"当前拨打号码为空");
        }
    } else {
        HUDNormal(INTERNATIONALSTRING(@"设备内sim卡未注册或已掉线"))
        if ([[BlueToothDataManager shareManager].homeVCLeftTitle isEqualToString:INTERNATIONALSTRING(HOMESTATUETITLE_SIGNALSTRONG)]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"homeStatueChanged" object:INTERNATIONALSTRING(HOMESTATUETITLE_REGISTING)];
        }
    }
}


- (void)initTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.height -= (64 + 49 + 24);
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

- (void)createButton{
    if (_phonePadButton) {
        return;
    }
    _phonePadButton = [HLDragButton buttonWithType:UIButtonTypeCustom];
    [_phonePadButton setImage:[UIImage imageNamed:@"phonepad_btn_nor"] forState:UIControlStateNormal];
//    [_phonePadButton setImage:[UIImage imageNamed:@"phonepad_btn_pre"] forState:UIControlStateSelected];
    [_phonePadButton addTarget:self action:@selector(showPhonePadView:) forControlEvents:UIControlEventTouchUpInside];
    [_phonePadButton sizeToFit];
    _phonePadButton.right = kScreenWidthValue - 10;
    _phonePadButton.bottom = self.view.height - _phonePadButton.height - 49 - 24;
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
//        [callView setFrame:self.nav.tabBarController.tabBar.bounds];
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
    //    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[c] %@", searchString];
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
//    [self.callActionView showActionView];
    [self startCallPhoneAction];
}


- (void)switchNumberPad :(BOOL)hidden {
//    [self.tableView setNeedsLayout];
//    [self.tableView layoutIfNeeded];
    if (hidden) {
        NSLog(@"关闭键盘");
        self.phonePadButton.hidden = NO;
//        self.phonePadView.top = kScreenHeightValue - 64 - 49;
//        self.phonePadView.top = kScreenHeightValue - 64;
        self.phonePadView.top = self.view.height;
        self.callView.hidden = YES;
        self.isSearchStatu = NO;
        self.phonePadView.inputedPhoneNumber = nil;
        [self setTitleViewIsHidden:YES];
//        self.tableView.height = kScreenHeightValue - (64 + 49);
        self.tableView.height = self.view.height;
    }else{
        NSLog(@"打开键盘");
        self.phonePadButton.hidden = YES;
//        self.phonePadView.top = kScreenHeightValue - 64 - 49 - 225;
//        self.phonePadView.top = kScreenHeightValue - 64 - 100 - 225;
        self.phonePadView.top = self.view.height - (100 - 49) - 225;
        [self showOperation];
        self.isSearchStatu = YES;
        [self setTitleViewIsHidden:NO];
//        self.tableView.height = kScreenHeightValue - (64 + 49) - 225 - 70;
//        self.tableView.height = kScreenHeightValue - (64 + 100) - 225;
        self.tableView.height = self.phonePadView.top;
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
//                NSLog(@"联系结果：%@",model);
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
//                        NSLog(@"无法识别的电话方式");
//                    }
//                    NSLog(@"%@", dicCallRecord[@"calltype"]);
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
//                            NSLog(@"无法识别的电话方式");
//                        }
//                        NSLog(@"%@", dicCallRecord[@"calltype"]);
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


- (void)loadPhoneRecord {
    self.checkToken = YES;
    
    [self getBasicHeader];
    
    _arrPhoneRecord = [[NSMutableArray alloc] init];
    
    //Document目录
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    //    path = [path stringByAppendingPathComponent:@"callrecord.db"];
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
            NSLog(@"The table count: %li", count);
            if (count == 1) {
                NSLog(@"log_keepers table is existed.");
                //升序,将数据插入到最前面,因此最先插入的显示在最后
                NSString *dataSql = @"select * from CallRecord order by calltime asc";
                FMResultSet *rs = [db executeQuery:dataSql];
                while ([rs next]) {
                    //添加数据到arrPhoneCallRecord
                    //                    (datas, calltime, dataid)
                    NSString *jsonStr1 = [rs stringForColumn:@"datas"];
                    NSData *jsonData1 = [jsonStr1 dataUsingEncoding:NSUTF8StringEncoding];
                    NSArray *dataArray=[NSJSONSerialization JSONObjectWithData:jsonData1 options:NSJSONReadingAllowFragments error:nil];
                    [self.arrPhoneRecord insertObject:dataArray atIndex:0];
                    _searchPhoneRecords = nil;
                }
            }
            
            NSLog(@"log_keepers is not existed.");
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

- (BOOL)addPhoneRecordWithHostcid:(NSString *)hostcid Destcid:(NSString *)destcid Calltime:(NSDate *)calltime Calltype:(NSString *)calltype {
    //status,来电是否接听
    NSTimeInterval a = [calltime timeIntervalSince1970];
    NSString *timestemp = [NSString stringWithFormat:@"%ld", (long)a];
    //    NSTimeInterval callTimeNumber = [calltime timeIntervalSince1970];
    
    NSMutableDictionary *dicPhoneRecord = [[NSMutableDictionary alloc] initWithObjectsAndKeys:timestemp,@"calltime",calltype,@"calltype",[self numberFromCid:hostcid],@"hostnumber",[self numberFromCid:destcid],@"destnumber",@0,@"status", nil];  //时间写入记录时不需要转成字符
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
            NSLog(@"数据库打开失败！");
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
        [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(@"创建通话记录失败") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil] show];
        return FALSE;
    }else{
        [self insertSqlData:dicPhoneRecord dataBase:db Calltime:timestemp];
    }
    return YES;
}

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
        NSLog(@"The table count: %zd", count);
        if (count == 1) {
            NSLog(@"log_keepers table is existed.");
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
                    NSLog(@"更新通话记录失败！%@",dicPhoneRecord);
                }
            }else{
                NSData *jsonData2 = [NSJSONSerialization dataWithJSONObject:muteArray options:NSJSONWritingPrettyPrinted error:nil];
                NSString *jsonStr2 = [[NSString alloc] initWithData:jsonData2 encoding:NSUTF8StringEncoding];
                BOOL isSuccess = [db executeUpdate:@"INSERT INTO CallRecord (datas, calltime, dataid) VALUES (?, ?, ?)", jsonStr2, calltime, dataId];
                if (!isSuccess) {
                    NSLog(@"添加通话记录失败！%@",dicPhoneRecord);
                }
            }
            
            //            BOOL success = [db executeUpdate:@"INSERT INTO CallRecord (hostnumber, destnumber, calltime, calltype, location, status) VALUES (?, ?, ?, ?, ?, ?)", [dicPhoneRecord objectForKey:@"hostnumber"], [dicPhoneRecord objectForKey:@"destnumber"], timestemp,[dicPhoneRecord objectForKey:@"calltype"],[dicPhoneRecord objectForKey:@"location"],[dicPhoneRecord objectForKey:@"status"]];
            //            if (!success) {
            //                NSLog(@"添加通话记录失败！%@",dicPhoneRecord);
            //            }
            //return TRUE;
        }
        NSLog(@"log_keepers is not existed.");
        //创建表
        //[membersDB executeUpdate:@"CREATE TABLE PersonList (Name text, Age integer, Sex integer,Phone text, Address text, Photo blob)"];
        
        [db executeUpdate:@"CREATE TABLE CallRecord (datas Text, calltime TimeStamp, dataid text)"];
    }else{
        //添加记录
        //        NSInteger a=[calltime timeIntervalSince1970];
        //        NSString *timestemp = [NSString stringWithFormat:@"%ld", (long)a];
        //        BOOL success = [db executeUpdate:@"INSERT INTO CallRecord (datas, calltime, dataid) VALUES (?, ?, ?)", [dicPhoneRecord objectForKey:@"hostnumber"], [dicPhoneRecord objectForKey:@"destnumber"], timestemp,[dicPhoneRecord objectForKey:@"calltype"],[dicPhoneRecord objectForKey:@"location"],[dicPhoneRecord objectForKey:@"status"]];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[muteArray copy] options:NSJSONWritingPrettyPrinted error:nil];
        NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        BOOL isSuccess = [db executeUpdate:@"INSERT INTO CallRecord (datas, calltime, dataid) VALUES (?, ?, ?)", jsonStr, calltime, dataId];
        
        if (!isSuccess) {
            NSLog(@"添加通话记录失败！%@",dicPhoneRecord);
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

- (void)makeCallAction :(NSNotification *)notification {
    NSString *phoneNumber = notification.object;
    if (phoneNumber) {
        [self callNumber:phoneNumber];
    }
}

- (void)makeUnitysCallAction:(NSNotification *)notification {
    NSString *phoneNumber = notification.object;
    
    if (phoneNumber) {
        [self callUnitysNumber:phoneNumber];
    }
}

- (void)getMaxPhoneCall {
    self.checkToken = YES;
    [SSNetworkRequest getRequest:apiGetMaxmimumPhoneCallTime params:nil success:^(id responseObj) {
        //        NSLog(@"有数据：%@",responseObj);
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            self.maxPhoneCall = [[[responseObj objectForKey:@"data"]  objectForKey:@"maximumPhoneCallTime"] intValue];
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
    } failure:^(id dataObj, NSError *error) {
        NSLog(@"有异常：%@",[error description]);
    } headers:self.headers];
}

- (void)callingAction:(NSNotification *)notification {
    if (notification.object) {
        NSString *action = notification.object;
        
        SipEngine *theSipEngine = [SipEngineManager getSipEngine];
        if ([action isEqualToString:@"Hungup"]) {
            self.speakerStatus = NO;
            if(theSipEngine->InCalling())
                theSipEngine->TerminateCall();
//            [self.tabBarController.tabBar setNeedsLayout];
//            [self.tabBarController.tabBar layoutIfNeeded];
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [self.tabBarController.tabBar setNeedsLayout];
//                [self.tabBarController.tabBar layoutIfNeeded];
//            });
            
            //挂断系统的通话界面
            if (kSystemVersionValue >= 10.0 && isUseCallKit) {
                [[UNCallKitCenter sharedInstance]  endCall:nil completion:^(NSError * _Nullable error) {
                }];
            }
            self.callStopTime = [NSDate date];
            self.hostHungup = @"source";
            //            [self endingCallOut];
        }else if ([action isEqualToString:@"SwitchSound"]){
            //保存扩音状态,在未接通时修改扩音状态无效,因此保存此状态,在接通时更新.
            if (notification.userInfo) {
                if (notification.userInfo[@"isHandfreeon"]) {
                    self.speakerStatus = [notification.userInfo[@"isHandfreeon"] boolValue];
                }
            }
            NSLog(@"当前扩音状态:%zd", self.speakerStatus);
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
            //选择最后一条，更新为
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *path = [paths objectAtIndex:0];
            
            //            path = [path stringByAppendingPathComponent:@"callrecord.db"];
            path = [path stringByAppendingPathComponent:@"callrecord2.db"];
            
            FMDatabase *db = [FMDatabase databaseWithPath:path];
            if (![db open]) {
                [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(@"创建通话记录失败") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil] show];
            }else{
                //查找出错
                //                FMResultSet *rs = [db executeQuery:@"select * from CallRecord order by calltime asc limit 0,1"];
                //降序,更新最后一条数据
                FMResultSet *rs = [db executeQuery:@"select * from CallRecord order by calltime desc limit 0,1"];
                if ([rs next]) {
                    //如果能打开说明已存在,获取数据
                    NSString *jsonStr1 = [rs stringForColumn:@"datas"];
                    NSData *jsonData1 = [jsonStr1 dataUsingEncoding:NSUTF8StringEncoding];
                    NSArray *dataArray=[NSJSONSerialization JSONObjectWithData:jsonData1 options:NSJSONReadingAllowFragments error:nil];
                    NSMutableArray *muteArray = [NSMutableArray arrayWithArray:dataArray];
                    NSMutableDictionary *dictRecord;
                    if (dataArray.count) {
                        dictRecord = [NSMutableDictionary dictionaryWithDictionary:dataArray.firstObject];
                    }
                    [dictRecord setObject:@1 forKey:@"status"];
                    [muteArray replaceObjectAtIndex:0 withObject:dictRecord];
                    
                    NSData *jsonData2 = [NSJSONSerialization dataWithJSONObject:[muteArray copy] options:NSJSONWritingPrettyPrinted error:nil];
                    NSString *jsonStr2 = [[NSString alloc] initWithData:jsonData2 encoding:NSUTF8StringEncoding];
                    [db executeUpdate:[NSString stringWithFormat:@"update CallRecord SET datas='%@' WHERE calltime='%@'", jsonStr2, [rs stringForColumn:@"calltime"]]];
                    //                    BOOL isSuccess = [db executeUpdate:@"UPDATE CallRecord set datas='%@' calltime='%@' where dataid ='%@'", jsonStr2, timestemp, dataId];
                    //                    if (!isSuccess) {
                    //                        NSLog(@"更新通话记录失败！%@",dicPhoneRecord);
                    //                    }
                    //                    [db executeUpdate:@"update CallRecord set status=1 where calltime=?",[rs stringForColumn:@"calltime"]];
                    [rs close];
                    [db close];
                }
                
            }
            [self loadPhoneRecord];
            [self.tableView reloadData];
            
            theSipEngine->AnswerCall();
            theSipEngine->StopRinging();
        }else if ([action isEqualToString:@"Refuse"]){
            theSipEngine->TerminateCall();
        }
    }
}

- (void)callPhoneKeyBoard:(NSNotification *)noti
{
    NSString *numer = [noti object];
    if ([self verificationNumber:numer]) {
        SipEngine *theSipEngine = [SipEngineManager getSipEngine];
        theSipEngine->SendDtmf([numer UTF8String]);
    }
}

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
    if (code==0) {
        //
    } else {
        //
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
        
        NSUUID * callUUID=[[UNCallKitCenter sharedInstance] reportIncomingCallWithContact:contact completion:^(NSError * _Nullable error)
                           {
                               if (error == nil) {
                                   NSLog(@"%s success", __func__);
                               }else{
                                   NSLog(@"arror %@", error);
                               }
                           }];
        NSLog(@"callUUID==%@", callUUID);
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
    });
}


-(void) OnNewCall:(CallDir)dir
 withPeerCallerID:(NSString*)cid
        withVideo:(BOOL)video_call{
    NSLog(@"新呼叫");
    //    NSString *msg = @"";
    NSString *newcid;
    
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    
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
        
        [self addPhoneRecordWithHostcid:cid Destcid:[userdata objectForKey:@"Tel"] Calltime:[NSDate date] Calltype:@"来电"];
        
        if ([[UNDataTools sharedInstance].blackLists containsObject:cid]) {
            NSLog(@"在黑名单内,挂断电话");
            [self hungupPhone];
        }else{
            if (kSystemVersionValue >= 10.0 && isUseCallKit) {
                [self InComingCallWithCallKitName:[self checkLinkNameWithPhoneStr:cid] PhoneNumber:cid];
            }else{
                self.callCominginVC = [[CallComingInViewController alloc] init];
                self.callCominginVC.nameStr = [self checkLinkNameWithPhoneStr:cid];
                [self.nav presentViewController:self.callCominginVC animated:YES completion:nil];
            }
        }
        
        /*
         SipEngine *theSipEngine = [SipEngineManager getSipEngine];
         theSipEngine->start*/
        //[mBtnDial setTitle:@"接听" forState:UIControlStateNormal];
    }else{
        //        msg = [NSString stringWithFormat:@"新去电 %@",cid];
        [self addPhoneRecordWithHostcid:[userdata objectForKey:@"Tel"] Destcid:cid Calltime:[NSDate date] Calltype:@"去电"];
    }
    //    [mStatus setText:msg];
}

- (void)hungupPhone
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.speakerStatus = NO;
        SipEngine *theSipEngine = [SipEngineManager getSipEngine];
        if(theSipEngine->InCalling())
            theSipEngine->TerminateCall();
        self.callStopTime = [NSDate date];
        self.hostHungup = @"source";
    });
}

-(void) OnCallProcessing{
    //    NSLog(@"正在接续...");
    //    [mStatus setText:@"正在接续..."];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"正在呼叫...")];
}

/*对方振铃*/
-(void) OnCallRinging{
    //        NSLog(@"对方振铃...");
    //    [mStatus setText:@"对方振铃..."];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"对方振铃...")];
}

/*呼叫接通*/
-(void) OnCallStreamsRunning:(bool)is_video_call{
    NSLog(@"接通...");
    //    [mStatus setText:@"呼叫接通"];
    //在接通时更新扩音状态
    SipEngine *theSipEngine = [SipEngineManager getSipEngine];
    theSipEngine->SetLoudspeakerStatus(self.speakerStatus);
    theSipEngine->MuteMic(self.muteStatus);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"正在通话")];
}

-(void) OnCallMediaStreamsConnected:(MediaTransMode)mode{
    //    NSLog(@"接通...");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"正在呼叫...")];
    //    [mStatus setText:@"媒体接通"];
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
    //    [mStatus setText:@"结束通话"];
    
    [self loadPhoneRecord];
    self.speakerStatus = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"通话结束")];
    /*
     //移除来电页面
     if (self.callCominginVC) {
     [self.callCominginVC dismissViewControllerAnimated:YES completion:nil];
     }*/
}

/*呼叫失败，并返回错误代码，代码对应的含义，请参考common_types.h*/
-(void) OnCallFailed:(CallErrorCode) error_code{
    NSLog([NSString stringWithFormat:@"呼叫错误, 代码 %d",error_code],nil);
    [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"错误提示") message:[NSString stringWithFormat:@"%@", INTERNATIONALSTRING(@"呼叫异常,请确认网络或账号正常")] delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
    //    [mStatus setText:[NSString stringWithFormat:@"呼叫错误, 代码 %d",error_code]];
    
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
-(void)doRegister{
    SipEngine *theSipEngine = [SipEngineManager getSipEngine];
    
    if(theSipEngine->AccountIsRegstered())
    {
        theSipEngine->DeRegisterSipAccount();
        __block SipEngine *callEngine = theSipEngine;
        
        self.checkToken = YES;
        [self getBasicHeader];
        [SSNetworkRequest getRequest:apiGetSecrityConfig params:nil success:^(id responseObj) {
            //            NSLog(@"有数据：%@",responseObj);
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
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
            //            NSLog(@"有数据：%@",responseObj);
            
            
            
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
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
                
                //                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String],"", [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"] UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue],1800);
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
        
        /*
         #define CRYPT
         
         #ifdef CRYPT
         theSipEngine->RegisterSipAccount([@"18850161016" UTF8String], [@"18850161016" UTF8String],"", "121.46.3.20", 65061,1800);
         #else
         theSipEngine->RegisterSipAccount([@"18850161016" UTF8String], [@"18850161016" UTF8String],"", "121.46.3.20", 65060,1800);
         #endif */
    }
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


- (void)callNumber :(NSString *)strNumber {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
    
    if (storyboard) {
        if (strNumber) {
            self.phoneNumber = strNumber;
        }
        self.calledTelNum = [NSString stringWithFormat:@"981%@",self.phoneNumber];
        
        //获取最大通话时长后再拨打
        [SSNetworkRequest getRequest:apiGetMaxmimumPhoneCallTime params:nil success:^(id responseObj) {
            //            NSLog(@"有数据：%@",responseObj);
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                
                CallingViewController *callingViewController = [storyboard instantiateViewControllerWithIdentifier:@"callingViewController"];
                if (callingViewController) {
                    self.callStartTime = [NSDate date];
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
                NSLog(@"获取最大时长失败");
                //                    HUDNormal(responseObj[@"msg"])
                HUDNormal(INTERNATIONALSTRING(@"获取通话时长失败"))
            }
        } failure:^(id dataObj, NSError *error) {
            NSLog(@"有异常：%@",[error description]);
            HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        } headers:self.headers];
        
    }
    
}


- (void)callUnitysNumber :(NSString *)strNumber {
    if ([UNNetWorkStatuManager shareManager].currentStatu == NotReachable) {
        HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        return;
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
    if (storyboard) {
        if (strNumber) {
            self.phoneNumber = strNumber;
        }
        if (self.phoneNumber) {
            self.calledTelNum = [NSString stringWithFormat:@"986%@",self.phoneNumber];
        }
        
        CallingViewController *callingViewController = [storyboard instantiateViewControllerWithIdentifier:@"callingViewController"];
        if (callingViewController) {
            self.callStartTime = [NSDate date];
            callingViewController.lblCallingInfo.text = [self checkLinkNameWithPhoneStr:self.phoneNumber];
            [self.nav presentViewController:callingViewController animated:YES completion:^{
                SipEngine *theSipEngine = [SipEngineManager getSipEngine];
                callingViewController.lblCallingInfo.text = [self checkLinkNameWithPhoneStr:self.phoneNumber];
                if ([VSWManager shareManager].callPort) {
                    theSipEngine->MakeCall([[NSString stringWithFormat:@"986%@%@",[VSWManager shareManager].callPort, [self formatPhoneNum:self.phoneNumber]] UTF8String],false,NULL);
                }else if([[NSUserDefaults standardUserDefaults] objectForKey:@"VSWCallPort"]){
                    [VSWManager shareManager].callPort = [[NSUserDefaults standardUserDefaults] objectForKey:@"VSWCallPort"];
                    theSipEngine->MakeCall([[NSString stringWithFormat:@"986%@%@",[VSWManager shareManager].callPort, [self formatPhoneNum:self.phoneNumber]] UTF8String],false,NULL);
                }else{
                    HUDNormal(INTERNATIONALSTRING(@"呼叫失败"))
                }
            }];
        }
    }
}

- (void)endingCallOut {
    self.checkToken = YES;
    int dat = [self.callStopTime timeIntervalSinceReferenceDate]-[self.callStartTime timeIntervalSinceReferenceDate];
    
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:[userdata objectForKey:@"Tel"],@"DeviceName",self.calledTelNum,@"calledTelNum",[self formatTime:self.callStartTime],@"callStartTime", [self formatTime:self.callStopTime],@"callStopTime",[NSString stringWithFormat:@"%d",dat],@"callSessionTime",self.outIP,@"callSourceIp",self.outIP,@"callServerIp",self.hostHungup,@"acctterminatedirection",nil];
    
    [self getBasicHeader];
    //    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest postRequest:apiAddSpeakRecord params:params success:^(id responseObj) {
        
        
        NSLog(@"查询到的记录添加：%@",responseObj);
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            //            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
            NSLog(@"通话记录添加成功");
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isSearchStatu && self.phonePadView.inputedPhoneNumber && self.phonePadView.inputedPhoneNumber.length) {
        return self.searchLists.count;
    }else{
        return self.arrPhoneRecord.count;
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
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
                NSLog(@"当前index---%ld", index);
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
            [cell.lblPhoneNumber setTextColor:[UIColor blackColor]];
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
                    NSMutableAttributedString *attriStr = [[NSMutableAttributedString alloc] initWithString:phoneNum attributes:@{NSForegroundColorAttributeName : [UIColor blackColor]}];
                    NSRange range = [phoneNum rangeOfString:self.phonePadView.inputedPhoneNumber];
                    if (range.length) {
                        [attriStr setAttributes:@{NSForegroundColorAttributeName : [UIColor blueColor]} range:range];
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
                    NSMutableAttributedString *attriStr = [[NSMutableAttributedString alloc] initWithString:phoneNum attributes:@{NSForegroundColorAttributeName : [UIColor blackColor]}];
                    NSRange range = [phoneNum rangeOfString:self.phonePadView.inputedPhoneNumber];
                    if (range.length) {
                        [attriStr setAttributes:@{NSForegroundColorAttributeName : [UIColor blueColor]} range:range];
                    }
                    cell.lblPhoneNumber.attributedText = attriStr;
                }
            }
            
            [bottomStr appendString:[dicPhoneRecord objectForKey:@"location"]];
            NSMutableAttributedString *attriStr = [[NSMutableAttributedString alloc] initWithString:bottomStr attributes:@{NSForegroundColorAttributeName : [UIColor lightGrayColor]}];
            NSRange range = [bottomStr rangeOfString:self.phonePadView.inputedPhoneNumber];
            if (range.length) {
                [attriStr setAttributes:@{NSForegroundColorAttributeName : [UIColor blueColor]} range:range];
            }
            cell.lblPhoneType.attributedText = attriStr;
            
            return cell;
            
        }
    }else{
        PhoneRecordCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"PhoneRecordCell"];
        NSArray *records = [self.arrPhoneRecord objectAtIndex:indexPath.row];
        
        kWeakSelf
        cell.lookDetailsBlock = ^(NSInteger index, NSString *phoneNumber, NSString *nickName) {
            [weakSelf.phonePadView hideCallView];
            //开始加载谁
            [weakSelf switchNumberPad:YES];
            
            NSLog(@"当前index---%ld", index);
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
        [cell.lblPhoneNumber setTextColor:[UIColor blackColor]];
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
                [cell.lblPhoneNumber setTextColor:[UIColor blackColor]];
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
            NSLog(@"联系结果：%@",model);
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
                    NSLog(@"无法识别的电话方式");
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
                NSLog(@"无法识别的电话方式");
            }
            NSLog(@"%@", dicCallRecord[@"calltype"]);
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addressBookChanged" object:@"addressBook"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CallingAction" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MakeCallAction" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MakeUnitysCallAction" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CallPhoneKeyBoard" object:nil];
}

@end
