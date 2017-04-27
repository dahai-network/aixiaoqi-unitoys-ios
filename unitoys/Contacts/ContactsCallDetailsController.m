//
//  ContactsCallDetailsController.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "ContactsCallDetailsController.h"
#import "UITableView+RegisterNib.h"
#import "CallDetailsActionCell.h"
#import "CallDetailsNumberCell.h"
#import "CallDetailsNameCell.h"
#import "CallDetailsRecordCell.h"
#import "CallDetailsLookAllCell.h"
#import "UNPhoneRecordDataTool.h"
#import "MJViewController.h"
//#import "CallActionView.h"
#import "BlueToothDataManager.h"
#import "UNDataTools.h"

#import "UNDatabaseTools.h"
#import <AddressBookUI/AddressBookUI.h>
#import "global.h"
#import "ContactModel.h"
#import <ContactsUI/ContactsUI.h>

@interface ContactsCallDetailsController ()<UITableViewDelegate, UITableViewDataSource, CallDetailsActionCellDelegate, ABPersonViewControllerDelegate,CNContactViewControllerDelegate,ABNewPersonViewControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *phoneRecords;
@property (nonatomic, copy) NSArray *cellData;

//@property (strong,nonatomic) CallActionView *callActionView;

@property (nonatomic, copy) NSString *lastTime;
@property (nonatomic, copy) NSString *phoneLocation;
@property (nonatomic, assign) NSInteger currentRecordPage;

@property (nonatomic, assign) BOOL isInBlackLists;
@end

static NSString *callDetailsNameCellId = @"CallDetailsNameCell";
static NSString *callDetailsNumberCellId = @"CallDetailsNumberCell";
static NSString *callDetailsActionCellId = @"CallDetailsActionCell";

static NSString *callDetailsRecordCellId = @"CallDetailsRecordCell";
static NSString *callDetailsLookAllCellId = @"CallDetailsLookAllCell";

@implementation ContactsCallDetailsController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 10.0){
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        self.navigationController.navigationBar.translucent = NO;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"详情";
    
    if (!self.contactModel) {
        self.contactModel = [self checkContactModelWithPhoneStr:self.phoneNumber];
    }
    
    [self setUpNav];
    self.currentRecordPage = 1;
    [self getPhoneRecords];
    [self initData];
    [self initTableView];
}

- (void)setUpNav
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"edit_info_nor"] style:UIBarButtonItemStyleDone target:self action:@selector(editContactInfo)];
}

- (void)editContactInfo
{
    if ([[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
        if (self.contactModel && self.contactModel.recordRefId) {
            ABPersonViewController *personVc = [[ABPersonViewController alloc] init];
            ABAddressBookRef addressBook = ABAddressBookCreate();
            ABRecordRef recordRef = ABAddressBookGetPersonWithRecordID(addressBook, self.contactModel.recordRefId);
            personVc.displayedPerson = recordRef;
            CFRelease(recordRef);
            personVc.allowsActions = NO;
            personVc.allowsEditing = YES;
            personVc.personViewDelegate = self;
            [self.navigationController pushViewController:personVc animated:YES];
            self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        }else{
            [self addContactsAction];
        }
    }else{
        if (self.contactModel && self.contactModel.contactId) {
            CNContactStore *contactStore = [[CNContactStore alloc] init];
            CNContact *contact = [contactStore unifiedContactWithIdentifier:self.contactModel.contactId keysToFetch:@[[CNContactViewController descriptorForRequiredKeys]] error:nil];
            CNContactViewController *contactVc = [CNContactViewController viewControllerForContact:contact];
            contactVc.view.tag = 100;
            contactVc.contactStore = contactStore;
            contactVc.allowsEditing = YES;
//            contactVc.allowsActions = YES;
            contactVc.allowsActions = NO;
            contactVc.delegate = self;
            if ([[UIDevice currentDevice] systemVersion].floatValue >= 10.0) {
                //修改导航栏颜色
                self.navigationController.navigationBar.tintColor = DefultColor;
                self.navigationController.navigationBar.translucent = YES;
                self.navigationController.interactivePopGestureRecognizer.enabled = NO;
            }
            [self.navigationController pushViewController:contactVc animated:YES];
        }else{
            CNMutableContact *contact = [[CNMutableContact alloc] init];
            contact.phoneNumbers = @[[CNLabeledValue labeledValueWithLabel:CNLabelPhoneNumberMobile value:[CNPhoneNumber phoneNumberWithStringValue:self.phoneNumber]]];
            CNContactViewController *contactVc = [CNContactViewController viewControllerForNewContact:contact];
            contactVc.view.tag = 200;
            contactVc.allowsEditing = YES;
            contactVc.allowsActions = NO;
            contactVc.delegate = self;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:contactVc];
            [self presentViewController:nav animated:YES completion:nil];
        }
    }
}

- (void)addContactsAction
{
    NSLog(@"添加联系人");
    CFErrorRef error = NULL;
    ABRecordRef person = ABPersonCreate ();
    // Add phone number
    ABMutableMultiValueRef multiValue = ABMultiValueCreateMutable(kABStringPropertyType);
    //mainTitle.text是你要添加的手机号
    ABMultiValueAddValueAndLabel(multiValue, (__bridge CFTypeRef)(self.phoneNumber), kABPersonPhoneMobileLabel,
                                 NULL);
    ABRecordSetValue(person, kABPersonPhoneProperty, multiValue, &error);
    
    ABNewPersonViewController *newPersonVc = [[ABNewPersonViewController alloc] init];
    newPersonVc.displayedPerson = person;
    newPersonVc.newPersonViewDelegate = self;
    CFRelease(person);
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:newPersonVc];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - ABNewPersonViewControllerDelegate
- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(nullable ABRecordRef)person
{
    if (person) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"addressBookChanged" object:@"addressBookChanged"];
    }
    [newPersonView dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ABPersonViewControllerDelegate
- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    return YES;
}

#pragma mark - CNContactViewControllerDelegate
- (BOOL)contactViewController:(CNContactViewController *)viewController shouldPerformDefaultActionForContactProperty:(CNContactProperty *)property
{
    return YES;
}

- (void)contactViewController:(CNContactViewController *)viewController didCompleteWithContact:(nullable CNContact *)contact
{
    NSLog(@"%@", contact);
    if (contact) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"addressBookChanged" object:@"addressBookChanged"];
        
        NSString *givenName = contact.givenName;
        NSString *familyName = contact.familyName;
        NSString *phoneNumber = ((CNPhoneNumber *)(contact.phoneNumbers.firstObject.value)).stringValue;

        NSString *nickName;
        if ((phoneNumber)&&([familyName stringByAppendingString:givenName])&&![[familyName stringByAppendingString:givenName] isEqualToString:@""]) {
            nickName = [familyName stringByAppendingString:givenName];
        } else {
            NSLog(@"9.0以后的系统，通讯录数据格式不正确");
            nickName = phoneNumber;
        }
        phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
        self.nickName = nickName;
        self.phoneNumber = phoneNumber;
        self.contactModel.contactId = contact.identifier;
        if (_contactsInfoUpdateBlock) {
            _contactsInfoUpdateBlock(nickName, phoneNumber);
        }
        [self reloadTableView];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ContactsInfoChange" object:nil];
    }
    if (viewController.view.tag == 200) {
        [viewController dismissViewControllerAnimated:YES completion:nil];
    }
}

//获取通话记录
- (void)getPhoneRecords
{
    //获取到的数据为多条数组,以来去电分组,需要手动排序
    NSArray *myRecords = [[UNPhoneRecordDataTool sharedPhoneRecordDataTool] getRecordsWithPhoneNumber:self.phoneNumber];
    //抽取数据并排序
    if (myRecords.count) {
        NSMutableArray *totalRecords = [NSMutableArray array];
        for (NSArray *tempArray in myRecords) {
            [totalRecords addObjectsFromArray:tempArray];
        }
        NSArray *array = [totalRecords sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
            return [obj2[@"calltime"] compare:obj1[@"calltime"]];
        }];
        self.phoneRecords = array;
        if (self.phoneRecords.count) {
            self.lastTime = [[UNDataTools sharedInstance] compareCurrentTimeStringWithRecord:self.phoneRecords.firstObject[@"calltime"]];
            self.phoneLocation = self.phoneRecords.firstObject[@"location"];
        }
        NSLog(@"通话记录数据%@", array);
    }else{
        self.lastTime = @"";
        self.phoneLocation =@"";
        self.phoneRecords= [NSArray array];
    }
    
    if ([[UNDataTools sharedInstance].blackLists containsObject:self.phoneNumber]) {
        _isInBlackLists = YES;
    }else{
        _isInBlackLists = NO;
    }
}

//初始化展示数据
- (void)initData
{
    _cellData = @[
                  @{
                      @"cellName" : callDetailsNameCellId,
                      @"cellTitle" : self.nickName,
                      },
                  @{
                      @"cellName" : callDetailsNumberCellId,
                      @"cellTitle" : self.phoneNumber,
                      @"cellDetailTitle" : self.lastTime,
                      @"cellLastTitle" : self.phoneLocation,
                      },
                  @{
                      @"cellName" : callDetailsActionCellId,
                      @"isBlack" : @(_isInBlackLists),
                      }
                  ];
}

- (void)reloadTableView
{
    if ([[UNDataTools sharedInstance].blackLists containsObject:self.phoneNumber]) {
        _isInBlackLists = YES;
    }else{
        _isInBlackLists = NO;
    }
    [self initData];
    [self.tableView reloadData];
}

//初始化tableView
- (void)initTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.tableView registerNibWithNibId:callDetailsNameCellId];
    [self.tableView registerNibWithNibId:callDetailsNumberCellId];
    [self.tableView registerNibWithNibId:callDetailsActionCellId];
    if (self.phoneRecords.count) {
        [self.tableView registerNibWithNibId:callDetailsRecordCellId];
        [self.tableView registerNibWithNibId:callDetailsLookAllCellId];
    }
    
    self.tableView.un_height -= 64;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = UIColorFromRGB(0xf5f5f5);
    
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, 10)];
    self.tableView.tableHeaderView = topView;
    self.tableView.tableFooterView = topView;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];

    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.phoneRecords.count) {
        return 2;
    }else{
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 3;
    }else if (section == 1){
        if (self.phoneRecords.count > self.currentRecordPage * 10) {
            return self.currentRecordPage * 10 + 1;
        }else{
            return self.phoneRecords.count;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row < self.cellData.count) {
            NSDictionary *dict = self.cellData[indexPath.row];
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:dict[@"cellName"]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:dict[@"cellName"]];
            }
            if ([cell isKindOfClass:[CallDetailsActionCell class]]) {
                CallDetailsActionCell *actionCell = (CallDetailsActionCell *)cell;
                actionCell.delegate = self;
            }
            [cell setValue:dict forKeyPath:@"cellDatas"];
            return cell;
        }else{
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
            }
            return cell;
        }
    }else if (indexPath.section == 1){
        if (indexPath.row == self.currentRecordPage * 10) {
            CallDetailsLookAllCell *cell = [tableView dequeueReusableCellWithIdentifier:callDetailsLookAllCellId];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            return cell;
        }else{
            CallDetailsRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:callDetailsRecordCellId];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.cellDatas = self.phoneRecords[indexPath.row];
            return cell;
        }
    }else{
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        }
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == 1) {
        if (indexPath.row == self.currentRecordPage * 10) {
            NSLog(@"查看更多");
            self.currentRecordPage++;
            [self.tableView reloadData];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == 2) {
            return 96;
        }else{
            return 70;
        }
    }else if (indexPath.section == 1){
        return 52;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, 35)];
        titleView.backgroundColor = UIColorFromRGB(0xf5f5f5);
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, kScreenWidthValue - 15, 35)];
        titleLabel.font = [UIFont systemFontOfSize:14];
        titleLabel.text = @"拨打记录";
        titleLabel.textColor = UIColorFromRGB(0xcccccc);
        [titleView addSubview:titleLabel];
        return titleView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        return 35;
    }
    return 0;
}

- (void)callActionType:(NSInteger)type
{
    NSLog(@"点击类型---%ld", type);
    if (type == 0) {
        [self sendMessage];
    }else if (type == 1){
        [self startCallPhoneAction];
    }else if(type == 2){
        [self defriend];
    }
}

- (void)sendMessage
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
    if (storyboard) {
        MJViewController *MJViewController = [storyboard instantiateViewControllerWithIdentifier:@"MJViewController"];
        if (MJViewController) {
            MJViewController.title = [self checkLinkNameWithPhoneStr:[self formatPhoneNum:self.phoneNumber]];
            MJViewController.toTelephone = self.phoneNumber;
            MJViewController.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:MJViewController animated:YES];
        }
    }
}

//- (void)callPhone
//{
//    if (!self.callActionView){
//        self.callActionView = [[CallActionView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, kScreenHeightValue)];
//    }
//    
//    __weak typeof(self) weakSelf = self;
//    
//    self.callActionView.cancelBlock = ^(){
//        [weakSelf.callActionView hideActionView];
//    };
//    self.callActionView.actionBlock = ^(NSInteger callType){
//        [weakSelf.callActionView hideActionView];
//        if (callType==1) {
//            //网络电话
//            //电话记录，拨打电话
//            if (weakSelf.phoneNumber) {
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"MakeCallAction" object:[weakSelf formatPhoneNum:weakSelf.phoneNumber]];
//            }
//        }else if (callType==2){
//            //手环电话
//            if ([BlueToothDataManager shareManager].isRegisted) {
//                if (weakSelf.phoneNumber) {
//                    [[NSNotificationCenter defaultCenter] postNotificationName:@"MakeUnitysCallAction" object:[weakSelf formatPhoneNum:weakSelf.phoneNumber]];
//                }
//            } else {
//                HUDNormal(INTERNATIONALSTRING(@"设备内sim卡未注册或已掉线"))
//            }
//        }
//    };
//    [self.callActionView showActionView];
//}

- (void)startCallPhoneAction
{
    //手环电话
    if ([BlueToothDataManager shareManager].isRegisted) {
        if (self.phoneNumber) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MakeUnitysCallAction" object:[self formatPhoneNum:self.phoneNumber]];
        }
    } else {
        HUDNormal(INTERNATIONALSTRING(@"设备内sim卡未注册或已掉线"))
    }
}


- (void)defriend
{
    if (_isInBlackLists) {
        NSLog(@"解除屏蔽");
        self.checkToken = YES;
        NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.phoneNumber,@"BlackNum", nil];
        [self getBasicHeader];
        kWeakSelf
        [SSNetworkRequest postRequest:apiBlackListDelete params:params success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                [weakSelf deleteBlickList:weakSelf.phoneNumber];
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else if ([[responseObj objectForKey:@"status"] intValue]==9946){
                NSLog(@"不在黑名单内");
                [weakSelf deleteBlickList:weakSelf.phoneNumber];
            }else{
            }
            NSLog(@"查询到的消息数据：%@",responseObj);
        } failure:^(id dataObj, NSError *error) {
            HUDNormalTop(INTERNATIONALSTRING(@"解除屏蔽失败"))
            NSLog(@"啥都没：%@",[error description]);
        } headers:self.headers];
    }else{
        NSLog(@"屏蔽");
        self.checkToken = YES;
        NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.phoneNumber,@"BlackNum", nil];
        [self getBasicHeader];
        kWeakSelf
        [SSNetworkRequest postRequest:apiBlackListAdd params:params success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                [weakSelf addBlackList:weakSelf.phoneNumber];
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else if ([[responseObj objectForKey:@"status"] intValue]==9946){
                NSLog(@"已经在黑名单内");
                [weakSelf addBlackList:weakSelf.phoneNumber];
            }else{
            }
            NSLog(@"查询到的消息数据：%@",responseObj);
        } failure:^(id dataObj, NSError *error) {
            HUDNormalTop(INTERNATIONALSTRING(@"屏蔽失败"))
            NSLog(@"啥都没：%@",[error description]);
        } headers:self.headers];
    }
}

- (void)deleteBlickList:(NSString *)phone
{
    if (![[UNDatabaseTools sharedFMDBTools] deleteBlackListWithPhoneString:phone]) {
        NSLog(@"删除黑名单失败");
        //从服务器获取黑名单
        self.checkToken = YES;
        [self getBasicHeader];
        kWeakSelf
        [SSNetworkRequest getRequest:apiBlackListGet params:nil success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                [weakSelf addBlackLists:responseObj[@"data"]];
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
            }
            NSLog(@"查询到的消息数据：%@",responseObj);
            
        } failure:^(id dataObj, NSError *error) {
            
        } headers:self.headers];
    }else{
        HUDNormalTop(INTERNATIONALSTRING(@"解除屏蔽成功"))
        if ([[UNDataTools sharedInstance].blackLists containsObject:phone]) {
            [[UNDataTools sharedInstance].blackLists removeObject:phone];
        }
        [self reloadTableView];
    }
}

- (void)addBlackList:(NSString *)phone
{
    if (![[UNDatabaseTools sharedFMDBTools] insertBlackListWithPhoneString:phone]) {
        NSLog(@"插入黑名单失败");
        //从服务器获取黑名单
        self.checkToken = YES;
        [self getBasicHeader];
        kWeakSelf
        [SSNetworkRequest getRequest:apiBlackListGet params:nil success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                [weakSelf addBlackLists:responseObj[@"data"]];
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
            }
            NSLog(@"查询到的消息数据：%@",responseObj);
        } failure:^(id dataObj, NSError *error) {
            
        } headers:self.headers];
    }else{
        HUDNormalTop(INTERNATIONALSTRING(@"屏蔽成功"))
        if (![[UNDataTools sharedInstance].blackLists containsObject:phone]) {
            [[UNDataTools sharedInstance].blackLists addObject:phone];
        }
        [self reloadTableView];
    }
}

- (void)addBlackLists:(NSArray *)phoneList
{
    [[UNDatabaseTools sharedFMDBTools] insertBlackListWithPhoneLists:phoneList];
    [UNDataTools sharedInstance].blackLists = nil;
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


@end
