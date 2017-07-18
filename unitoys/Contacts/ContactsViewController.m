//
//  ContactsViewController.m
//  unitoys
//
//  Created by sumars on 16/9/23.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "ContactsViewController.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <Contacts/Contacts.h>
#import "ContactModel.h"
#import "ContactTableViewCell.h"
#import "ContactDataHelper.h"//根据拼音A~Z~#进行排序的tool

#import "ContactsDetailViewController.h"
#import "AddressBookManager.h"

#import "ContactsCallDetailsController.h"
#import <ContactsUI/ContactsUI.h>
#import "BlueToothDataManager.h"
#import "StatuesViewDetailViewController.h"
#import "UIImage+Extension.h"
#import "BindDeviceViewController.h"
//#import "UNPresentImageView.h"
//#import "UNConvertFormatTool.h"
//#import "ConvenienceServiceController.h"

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface ContactsViewController ()
<UITableViewDelegate,UITableViewDataSource,
UISearchBarDelegate,UISearchDisplayDelegate,ABNewPersonViewControllerDelegate, CNContactViewControllerDelegate>
{
    NSArray *_rowArr;//row arr
    NSArray *_sectionArr;//section arr
}

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSArray *contactsDataArr;//数据源
@property (nonatomic,strong) NSMutableArray *dataArr;
@property (nonatomic,strong) UISearchBar *searchBar;//搜索框
@property (nonatomic,strong) UISearchDisplayController *searchDisplayController;//搜索VC

@property (nonatomic, strong)UIView *statuesView;
@property (nonatomic, strong)UILabel *statuesLabel;
@property (nonatomic, strong)UIView *registProgressView;

@end

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@implementation ContactsViewController{
    NSMutableArray *_searchResultArr;//搜索结果Arr
}

#pragma mark - dataArr(模拟从服务器获取到的数据)
//- (NSArray *)contactsDataArr{
//    if (!_contactsDataArr) {
//        if (SYSTEM_VERSION_LESS_THAN(@"9")) {
//            [self fetchAddressBookBeforeIOS9];
//        }else {
//            [self fetchAddressBookOnIOS9AndLater];
//        }
//    }
//    return _contactsDataArr;
//    
//}


//- (BOOL)isShowLeftButton
//{
//    if (self.bOnlySelectNumber) {
//        return YES;
//    }else{
//        return NO;
//    }
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    [self.view addSubview:self.statuesView];
    if (![self isNeedToShowBLEStatue]) {
        self.statuesView.un_height = 0;
        self.registProgressView.un_width = 0;
        self.statuesView.hidden = YES;
    }
    
    if (![AddressBookManager shareManager].isOpenedAddress && !self.bOnlySelectNumber) {
        self.navigationItem.leftBarButtonItem = nil;
        [AddressBookManager shareManager].isOpenedAddress = YES;
//        [self.view addSubview:self.searchBar];
//        self.tableView.frame = CGRectMake(0, self.statuesView.frame.size.height+self.searchBar.frame.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64 - 49 - self.statuesView.frame.size.height-self.searchBar.frame.size.height);
        self.tableView.frame = CGRectMake(0, self.statuesView.frame.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64 - 49 - self.statuesView.frame.size.height);
        self.tableView.tableHeaderView = self.searchBar;
    }else{
        self.tableView.un_height -= 15;
    }
    
    // Do any additional setup after loading the view, typically from a nib.
    //[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navBar_bg"] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];

    if (!self.dataArr) {
        self.dataArr=[NSMutableArray array];
    }
    if (!self.contactsDataArr) {
        self.contactsDataArr = [[NSArray alloc] init];
    }
    if (!_rowArr) {
        _rowArr = [[NSArray alloc] init];
    }
    if (!_sectionArr) {
        _sectionArr = [[NSArray alloc] init];
    }
    
    self.contactsDataArr = [AddressBookManager shareManager].contactsDataArr;
    _rowArr = [AddressBookManager shareManager].rowArr;
    _sectionArr = [AddressBookManager shareManager].sectionArr;
    self.dataArr = [AddressBookManager shareManager].dataArr;
    
//    for (NSDictionary *subDic in self.contactsDataArr) {
//        ContactModel *model=[[ContactModel alloc]initWithDic:subDic];
//        [self.dataArr addObject:model];
//    }
    
    _rowArr=[ContactDataHelper getFriendListDataBy:self.dataArr];
    _sectionArr=[ContactDataHelper getFriendListSectionBy:[_rowArr mutableCopy]];
    
    //设置Nav
    [self configNav];
    //布局View
    [self setUpView];
    
    _searchDisplayController=[[UISearchDisplayController alloc]initWithSearchBar:self.searchBar contentsController:self];
    [_searchDisplayController setDelegate:self];
    [_searchDisplayController setSearchResultsDataSource:self];
    [_searchDisplayController setSearchResultsDelegate:self];
    
    _searchResultArr=[NSMutableArray array];
    [self.tableView reloadData];
    
    //添加通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAddressBook) name:@"addressBookChanged" object:@"addressBook"];
    //处理状态栏文字及高度
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactsViewChangeStatuesView:) name:@"changeStatuesViewLable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showRegistProgress:) name:@"changeStatue" object:nil];//改变状态和百分比
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentStatueChangeAndChangeHeight) name:@"currentStatueChangedAndHeightChange" object:@"currentStatueChangedAndHeightChange"];
}


- (void)currentStatueChangeAndChangeHeight {
    [self changeStatueViewHeightWithString:[BlueToothDataManager shareManager].statuesTitleString];
}

- (void)viewWillAppear:(BOOL)animated {
    [self changeStatueViewHeightWithString:[BlueToothDataManager shareManager].statuesTitleString];
}

- (void)changeStatueViewHeightWithString:(NSString *)statueStr {
    [self changeBleStatue];
    [self setStatuesLabelTextWithLabel:self.statuesLabel String:[BlueToothDataManager shareManager].statuesTitleString];
//    [self setStatuesLabelTextWithLabel:self.statuesLabel String:statueStr];
    if (![self isNeedToShowBLEStatue]) {
        if (self.statuesView.un_height == STATUESVIEWHEIGHT) {
            _searchBar.frame = CGRectOffset(_searchBar.frame, 0, -STATUESVIEWHEIGHT);
            _tableView.frame = CGRectOffset(_tableView.frame, 0, -STATUESVIEWHEIGHT);
            _tableView.un_height += STATUESVIEWHEIGHT;
        }
        self.statuesView.un_height = 0;
        self.registProgressView.un_width = 0;
        self.statuesView.hidden = YES;
    } else {
        if (![statueStr isEqualToString:HOMESTATUETITLE_REGISTING]) {
            self.registProgressView.un_width = 0;
        }
        if (self.statuesView.un_height == 0) {
            _searchBar.frame = CGRectOffset(_searchBar.frame, 0, STATUESVIEWHEIGHT);
            _tableView.frame = CGRectOffset(_tableView.frame, 0, STATUESVIEWHEIGHT);
            _tableView.un_height -= STATUESVIEWHEIGHT;
        }
        self.statuesView.un_height = STATUESVIEWHEIGHT;
        if (self.statuesView.isHidden) {
            self.statuesView.hidden = NO;
        }
    }
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

- (void)contactsViewChangeStatuesView:(NSNotification *)sender {
    UNDebugLogVerbose(@"状态栏文字 --> %@, %s, %d", sender.object, __FUNCTION__, __LINE__);
    [self changeStatueViewHeightWithString:sender.object];
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

- (void)refreshAddressBook {
    self.contactsDataArr = [AddressBookManager shareManager].contactsDataArr;
    _rowArr = [AddressBookManager shareManager].rowArr;
    _sectionArr = [AddressBookManager shareManager].sectionArr;
    self.dataArr = [AddressBookManager shareManager].dataArr;
    [self.tableView reloadData];
}

- (void)configNav{
//    UIButton *btn=[UIButton buttonWithType:UIButtonTypeCustom];
//    [btn setFrame:CGRectMake(0.0, 0.0, 30.0, 30.0)];
////    [btn setBackgroundImage:[UIImage imageNamed:@"contacts_add_friend"] forState:UIControlStateNormal];
//    [btn setImage:[UIImage imageNamed:@"alarm_add"] forState:UIControlStateNormal];
//    [btn addTarget:self action:@selector(addContactsAction:) forControlEvents:UIControlEventTouchUpInside];
//    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc]initWithCustomView:btn]];
    
    if (!self.bOnlySelectNumber) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add_addressee_nor"] style:UIBarButtonItemStyleDone target:self action:@selector(addContactsAction:)];
    }
}

- (void)addContactsAction:(UIButton *)button
{
    UNDebugLogVerbose(@"添加联系人");
    if ([[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
        ABNewPersonViewController *newPersonVc = [[ABNewPersonViewController alloc] init];
        newPersonVc.newPersonViewDelegate = self;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:newPersonVc];
        [self presentViewController:nav animated:YES completion:nil];
    }else{
        CNContactViewController *contactVc = [CNContactViewController viewControllerForNewContact:nil];
        contactVc.allowsEditing = YES;
        contactVc.allowsActions = YES;
        contactVc.delegate = self;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:contactVc];
        [self presentViewController:nav animated:YES completion:nil];
    }

}

#pragma mark - ABNewPersonViewControllerDelegate
- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(nullable ABRecordRef)person
{
    if (person) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"addressBookChanged" object:@"addressBookChanged"];
    }
    [newPersonView.navigationController dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark - CNContactViewControllerDelegate
- (BOOL)contactViewController:(CNContactViewController *)viewController shouldPerformDefaultActionForContactProperty:(CNContactProperty *)property
{
    return YES;
}

- (void)contactViewController:(CNContactViewController *)viewController didCompleteWithContact:(nullable CNContact *)contact
{
    UNDebugLogVerbose(@"%@", contact);
    if (contact) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"addressBookChanged" object:@"addressBookChanged"];
    }
    [viewController.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - setUpView
- (void)setUpView{
    UIImageView *imageView=[[UIImageView alloc]initWithFrame:CGRectMake(0.0, kScreenHeight-49.0, kScreenWidth, 49.0)];
    [imageView setImage:[UIImage imageNamed:@"footerImage"]];
    [imageView setContentMode:UIViewContentModeScaleToFill];
    [self.view addSubview:imageView];
    [self.view insertSubview:self.tableView belowSubview:imageView];
}
- (UISearchBar *)searchBar{
    if (!_searchBar) {
//        _searchBar=[[UISearchBar alloc]initWithFrame:CGRectMake(0, self.statuesView.frame.size.height, kScreenWidth, 44)];
        _searchBar=[[UISearchBar alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, 44)];
        [_searchBar sizeToFit];
        [_searchBar setPlaceholder:INTERNATIONALSTRING(@"搜索")];
        [_searchBar.layer setBorderWidth:0.5];
        [_searchBar.layer setBorderColor:[UIColor colorWithRed:229.0/255 green:229.0/255 blue:229.0/255 alpha:1].CGColor];
        [_searchBar setDelegate:self];
        [_searchBar setKeyboardType:UIKeyboardTypeDefault];
//        [_searchBar setBarTintColor:UIColorFromRGB(0xf5f5f5)];
//        [_searchBar setBackgroundColor:UIColorFromRGB(0xf5f5f5)];
        [_searchBar setBackgroundImage:[UIImage createImageWithColor:UIColorFromRGB(0xf5f5f5)]];
//        for (UIView *subview in _searchBar.subviews.firstObject.subviews)
//        {
//            if ([subview isKindOfClass:NSClassFromString(@"UISearchBarBackground")])
//            {
//                [subview removeFromSuperview];
//                break;
//            }
//        }
    }
    return _searchBar;
}
- (UITableView *)tableView{
    if (!_tableView) {
        _tableView=[[UITableView alloc]initWithFrame:CGRectMake(0.0, 0.0, kScreenWidth, kScreenHeight-49.0-self.statuesView.frame.size.height) style:UITableViewStylePlain];
        [_tableView setDelegate:self];
        [_tableView setDataSource:self];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [_tableView setSectionIndexBackgroundColor:[UIColor clearColor]];
        [_tableView setSectionIndexColor:[UIColor darkGrayColor]];
        [_tableView setBackgroundColor:[UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:1]];
//        _tableView.tableHeaderView=self.searchBar;
        //cell无数据时，不显示间隔线
//        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
        UIView *v = [[UIView alloc] init];
        [_tableView setTableFooterView:v];
    }
    return _tableView;
}

#pragma mark - UITableView delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    //section
    if (tableView==_searchDisplayController.searchResultsTableView) {
        return 1;
    }else{
        return _rowArr.count;
    }
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    //row
    if (tableView==_searchDisplayController.searchResultsTableView) {
        return _searchResultArr.count;
    }else{
        return [_rowArr[section] count];
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60.0;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    //viewforHeader
    id label = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"headerView"];
    if (!label) {
        label = [[UILabel alloc] init];
        [label setFont:[UIFont systemFontOfSize:14.5f]];
        [label setTextColor:UIColorFromRGB(0x999999)];
        [label setBackgroundColor:UIColorFromRGB(0xf5f5f5)];
    }
    [label setText:[NSString stringWithFormat:@"  %@",_sectionArr[section+1]]];
    return label;
}
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView{
    if (tableView!=_searchDisplayController.searchResultsTableView) {
        return _sectionArr;
    }else{
        return nil;
    }
}
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index{
    return index-1;
}
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (tableView==_searchDisplayController.searchResultsTableView) {
        return 0;
    }else{
        return 22.0;
    }
}

#pragma mark - UITableView dataSource
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIde=@"cellIde";
    ContactTableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:cellIde];
    if (cell==nil) {
        cell=[[ContactTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIde];
    }
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    if (tableView==_searchDisplayController.searchResultsTableView){
//        [cell.headImageView setImage:[UIImage imageNamed:[_searchResultArr[indexPath.row] valueForKey:@"portrait"]]];
        ContactModel *model = _searchResultArr[indexPath.row];
        [cell.headImageView setImage:[UIImage imageWithData:model.thumbnailImageData]];
        [cell.nameLabel setText:model.name];
        if (indexPath.row == _searchResultArr.count - 1) {
            cell.lineView.hidden = YES;
        }else{
            cell.lineView.hidden = NO;
        }
    }else{
        ContactModel *model=_rowArr[indexPath.section][indexPath.row];
        
//        [cell.headImageView setImage:[UIImage imageNamed:model.portrait]];
        [cell.headImageView setImage:[UIImage imageWithData:model.thumbnailImageData]];
        [cell.nameLabel setText:model.name];
        
        if (indexPath.row == [_rowArr[indexPath.section] count] - 1) {
            cell.lineView.hidden = YES;
        }else{
            cell.lineView.hidden = NO;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView==_searchDisplayController.searchResultsTableView){
            ContactModel *contact = _searchResultArr[indexPath.row];
        if ([contact.phoneNumber containsString:@","]) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
            if (!storyboard) {
                return;
            }
            ContactsDetailViewController *contactsDetailViewController = [storyboard instantiateViewControllerWithIdentifier:@"contactsDetailViewController"];
            if (!contactsDetailViewController) {
                return;
            }
            contactsDetailViewController.bOnlySelectNumber = self.bOnlySelectNumber;
            
            if (self.bOnlySelectNumber) {
                if ([[contact.phoneNumber componentsSeparatedByString:@","] count]==1) {
                    if (self.delegate) {
                        if (self.delegate&&[self.delegate respondsToSelector:@selector(didSelectPhoneNumber:)]) {
                            [self.delegate didSelectPhoneNumber:[NSString stringWithFormat:@"%@|%@",contact.name,contact.phoneNumber]];
                            [self.navigationController popToViewController:self.delegate animated:YES];
                        }
                    }
                    return;
                }
            }
            contactsDetailViewController.contactModel = contact;
            contactsDetailViewController.contactMan = contact.name;
            contactsDetailViewController.phoneNumbers = contact.phoneNumber;
            contactsDetailViewController.contactHead = contact.thumbnailImageData;
            [contactsDetailViewController.ivContactMan  setImage:[UIImage imageWithData:contact.thumbnailImageData] ];
            
            if (self.delegate) {
                contactsDetailViewController.delegate = self.delegate; //设置选择后的委托
            }
            [self.navigationController pushViewController:contactsDetailViewController animated:YES];
        }
        else{
            ContactsCallDetailsController *callDetailsVc = [[ContactsCallDetailsController alloc] init];
            callDetailsVc.nickName = contact.name;
            callDetailsVc.phoneNumber = contact.phoneNumber;
            callDetailsVc.contactModel = contact;
            [self.navigationController pushViewController:callDetailsVc animated:YES];
        }
    }else{
        ContactModel *model=_rowArr[indexPath.section][indexPath.row];
        UNDebugLogVerbose(@"联系结果：%@",model);
        if ([model.phoneNumber containsString:@","] || self.bOnlySelectNumber) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
            if (!storyboard) {
                return;
            }
            ContactsDetailViewController *contactsDetailViewController = [storyboard instantiateViewControllerWithIdentifier:@"contactsDetailViewController"];
            if (!contactsDetailViewController) {
                return;
            }
            contactsDetailViewController.bOnlySelectNumber = self.bOnlySelectNumber;
            
            if (self.bOnlySelectNumber) {
                if ([[model.phoneNumber componentsSeparatedByString:@","] count]==1) {
                    if (self.delegate) {
                        if (self.delegate&&[self.delegate respondsToSelector:@selector(didSelectPhoneNumber:)]) {
                            [self.delegate didSelectPhoneNumber:[NSString stringWithFormat:@"%@|%@",model.name,model.phoneNumber]];
                            [self.navigationController popToViewController:self.delegate animated:YES];
                        }
                    }
                    return;
                }
            }
            
            contactsDetailViewController.contactMan = model.name;
            contactsDetailViewController.phoneNumbers = model.phoneNumber;
            contactsDetailViewController.contactHead = model.thumbnailImageData;
            [contactsDetailViewController.ivContactMan  setImage:[UIImage imageWithData:model.thumbnailImageData]];
            contactsDetailViewController.contactModel = model;
            if (self.delegate) {
                contactsDetailViewController.delegate = self.delegate; //设置选择后的委托
            }
            [self.navigationController pushViewController:contactsDetailViewController animated:YES];
        }else{
            ContactsCallDetailsController *callDetailsVc = [[ContactsCallDetailsController alloc] init];
            callDetailsVc.contactModel = model;
            callDetailsVc.nickName = model.name;
            callDetailsVc.phoneNumber = model.phoneNumber;
            [self.navigationController pushViewController:callDetailsVc animated:YES];
        }
    }
    
}

#pragma mark searchBar delegate
//searchBar开始编辑时改变取消按钮的文字
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
//    NSArray *subViews;
//    subViews = [(searchBar.subviews[0]) subviews];
//    for (id view in subViews) {
//        if ([view isKindOfClass:[UIButton class]]) {
//            UIButton* cancelbutton = (UIButton* )view;
//            [cancelbutton setTitle:INTERNATIONALSTRING(@"取消") forState:UIControlStateNormal];
//            break;
//        }
//    }
//    searchBar.showsCancelButton = YES;
}
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
//    _searchBar.frame = CGRectOffset(_searchBar.frame, 0, 20-self.statuesView.frame.size.height);
//    _tableView.frame = CGRectOffset(_tableView.frame, 0, 20-self.statuesView.frame.size.height);
//
//    self.bFinishedEdit = NO;
    return YES;
}
- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar{
    
//    if (!self.bFinishedEdit) {
//        _searchBar.frame = CGRectOffset(_searchBar.frame, 0, -20+self.statuesView.frame.size.height);
//        _tableView.frame = CGRectOffset(_tableView.frame, 0, -20+self.statuesView.frame.size.height);
//    }
    
    return YES;
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    //取消
//    _searchBar.frame = CGRectOffset(_searchBar.frame, 0, -20+self.statuesView.frame.size.height);
//    _tableView.frame = CGRectOffset(_tableView.frame, 0, -20+self.statuesView.frame.size.height);
//    
//    self.bFinishedEdit = YES;
    [searchBar resignFirstResponder];
    searchBar.showsCancelButton = NO;
}

#pragma mark searchDisplayController delegate
- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView{
    //cell无数据时，不显示间隔线
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    [tableView setTableFooterView:v];
    
}
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
    [self filterContentForSearchText:searchString
                               scope:[self.searchBar scopeButtonTitles][self.searchBar.selectedScopeButtonIndex]];
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption{
    [self filterContentForSearchText:self.searchBar.text
                               scope:self.searchBar.scopeButtonTitles[searchOption]];
    return YES;
}

#pragma mark - 源字符串内容是否包含或等于要搜索的字符串内容
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    NSMutableArray *tempResults = [NSMutableArray array];
    NSUInteger searchOptions = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch;
    
    for (int i = 0; i < self.dataArr.count; i++) {
        ContactModel *contact = self.dataArr[i];
        NSString *storeString = [contact name];
//        NSString *storeNumber = [contact phoneNumber];
//        NSString *storeImageString=[(ContactModel *)self.dataArr[i] portrait]?[(ContactModel *)self.dataArr[i] portrait]:@"";
//        NSData *storeImageString=[contact thumbnailImageData]?[contact thumbnailImageData]:nil;
        
        NSRange storeRange = NSMakeRange(0, storeString.length);
        
        NSRange foundRange = [storeString rangeOfString:searchText options:searchOptions range:storeRange];
        if (foundRange.length) {
//            NSDictionary *dic=@{@"name":storeString,@"thumbnailImageData":storeImageString,@"phoneNumber":storeNumber};
            
            [tempResults addObject:contact];
        }
        
    }
    [_searchResultArr removeAllObjects];
    [_searchResultArr addObjectsFromArray:tempResults];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(int)getRandomNumber:(int)from to:(int)to
{
    return (int)(from + (arc4random() % (to-from + 1)));
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addressBookChanged" object:@"addressBook"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"changeStatuesViewLable" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"changeStatue" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"currentStatueChangedAndHeightChange" object:@"currentStatueChangedAndHeightChange"];
}



@end
