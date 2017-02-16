//
//  ContactsViewController.m
//  unitoys
//
//  Created by sumars on 16/9/23.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "ContactsViewController.h"
#import <AddressBook/AddressBook.h>
#import <Contacts/Contacts.h>
#import "ContactModel.h"
#import "ContactTableViewCell.h"
#import "ContactDataHelper.h"//根据拼音A~Z~#进行排序的tool

#import "ContactsDetailViewController.h"
#import "AddressBookManager.h"

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface ContactsViewController ()
<UITableViewDelegate,UITableViewDataSource,
UISearchBarDelegate,UISearchDisplayDelegate>
{
    NSArray *_rowArr;//row arr
    NSArray *_sectionArr;//section arr
}

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSArray *contactsDataArr;//数据源
@property (nonatomic,strong) NSMutableArray *dataArr;
@property (nonatomic,strong) UISearchBar *searchBar;//搜索框
@property (nonatomic,strong) UISearchDisplayController *searchDisplayController;//搜索VC

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

- (void)viewDidLoad {
    [super viewDidLoad];
    if (![AddressBookManager shareManager].isOpenedAddress) {
        self.navigationItem.leftBarButtonItem = nil;
        [AddressBookManager shareManager].isOpenedAddress = YES;
        
        [self.view addSubview:self.searchBar];
        self.tableView.frame = CGRectMake(0, 44, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64 - 49 - 44);
//        self.tableView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 65);
    }
    // Do any additional setup after loading the view, typically from a nib.
    //[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navBar_bg"] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    
//    if (self.dataArr) {
//        [self.dataArr removeAllObjects];
//    }
//    if (self.contactsDataArr) {
//        self.contactsDataArr = nil;
//    }
//    if (_rowArr) {
//        _rowArr = nil;
//    }
//    if (_sectionArr) {
//        _sectionArr = nil;
//    }
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
    
    //configNav
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
}

- (void)refreshAddressBook {
    self.contactsDataArr = [AddressBookManager shareManager].contactsDataArr;
    _rowArr = [AddressBookManager shareManager].rowArr;
    _sectionArr = [AddressBookManager shareManager].sectionArr;
    self.dataArr = [AddressBookManager shareManager].dataArr;
    [self.tableView reloadData];
}

- (void)configNav{
    UIButton *btn=[UIButton buttonWithType:UIButtonTypeCustom];
    [btn setFrame:CGRectMake(0.0, 0.0, 30.0, 30.0)];
    [btn setBackgroundImage:[UIImage imageNamed:@"contacts_add_friend"] forState:UIControlStateNormal];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc]initWithCustomView:btn]];
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
        _searchBar=[[UISearchBar alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, 44)];
//        [_searchBar setBackgroundImage:[UIImage imageNamed:@"ic_searchBar_bgImage"]];
        
        [_searchBar sizeToFit];
        [_searchBar setPlaceholder:@"搜索"];
        [_searchBar.layer setBorderWidth:0.5];
        [_searchBar.layer setBorderColor:[UIColor colorWithRed:229.0/255 green:229.0/255 blue:229.0/255 alpha:1].CGColor];
        [_searchBar setDelegate:self];
        [_searchBar setKeyboardType:UIKeyboardTypeDefault];
    }
    return _searchBar;
}
- (UITableView *)tableView{
    if (!_tableView) {
        _tableView=[[UITableView alloc]initWithFrame:CGRectMake(0.0, 0.0, kScreenWidth, kScreenHeight-49.0) style:UITableViewStylePlain];
        [_tableView setDelegate:self];
        [_tableView setDataSource:self];
        [_tableView setSectionIndexBackgroundColor:[UIColor clearColor]];
        [_tableView setSectionIndexColor:[UIColor darkGrayColor]];
        [_tableView setBackgroundColor:[UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:1]];
//        _tableView.tableHeaderView=self.searchBar;
        
        //cell无数据时，不显示间隔线
        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
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
        [label setTextColor:[UIColor grayColor]];
        [label setBackgroundColor:[UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:1]];
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
        [cell.headImageView setImage:[UIImage imageNamed:[_searchResultArr[indexPath.row] valueForKey:@"portrait"]]];
        [cell.nameLabel setText:[_searchResultArr[indexPath.row] valueForKey:@"name"]];
    }else{
        ContactModel *model=_rowArr[indexPath.section][indexPath.row];
        
        [cell.headImageView setImage:[UIImage imageNamed:model.portrait]];
        [cell.nameLabel setText:model.name];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
    if (storyboard) {
//        self.tabBarController.tabBar.hidden = YES;
        ContactsDetailViewController *contactsDetailViewController = [storyboard instantiateViewControllerWithIdentifier:@"contactsDetailViewController"];
        if (contactsDetailViewController) {
            
            contactsDetailViewController.bOnlySelectNumber = self.bOnlySelectNumber;
            
            
            if (tableView==_searchDisplayController.searchResultsTableView){
                NSDictionary *dicResult = _searchResultArr[indexPath.row];
                NSLog(@"搜索结果：%@",dicResult);
                
                if (self.bOnlySelectNumber) {
                    if ([[[dicResult objectForKey:@"phoneNumber"] componentsSeparatedByString:@","] count]==1) {
                        if (self.delegate) {
                            if (self.delegate&&[self.delegate respondsToSelector:@selector(didSelectPhoneNumber:)]) {
                                [self.delegate didSelectPhoneNumber:[NSString stringWithFormat:@"%@|%@",[dicResult objectForKey:@"name"],[dicResult objectForKey:@"phoneNumber"]]];
                                [self.navigationController popToViewController:self.delegate animated:YES];
                            }
                        }
                        return;
                    }
                }
                
                contactsDetailViewController.contactMan = [dicResult objectForKey:@"name"];
                
                contactsDetailViewController.phoneNumbers = [dicResult objectForKey:@"phoneNumber"];
                
                contactsDetailViewController.contactHead = [dicResult objectForKey:@"portrait"];
                
                [contactsDetailViewController.ivContactMan  setImage:[UIImage imageNamed:[dicResult objectForKey:@"portrait"]] ];
                
    
                
            }else{
                ContactModel *model=_rowArr[indexPath.section][indexPath.row];
                NSLog(@"联系结果：%@",model);
                
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
            
                contactsDetailViewController.contactHead = model.portrait;
                
                [contactsDetailViewController.ivContactMan  setImage:[UIImage imageNamed:model.portrait]];
            }
            
            if (self.delegate) {
                contactsDetailViewController.delegate = self.delegate; //设置选择后的委托
            }
            
            
            [self.navigationController pushViewController:contactsDetailViewController animated:YES];
        }
    }
    
}

#pragma mark searchBar delegate
//searchBar开始编辑时改变取消按钮的文字
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    NSArray *subViews;
    subViews = [(searchBar.subviews[0]) subviews];
    for (id view in subViews) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton* cancelbutton = (UIButton* )view;
            [cancelbutton setTitle:@"取消" forState:UIControlStateNormal];
            break;
        }
    }
    searchBar.showsCancelButton = YES;
}
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
    _searchBar.frame = CGRectOffset(_searchBar.frame, 0, 20);
    _tableView.frame = CGRectOffset(_tableView.frame, 0, 20);

    self.bFinishedEdit = NO;
    return YES;
}
- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar{
    
    if (!self.bFinishedEdit) {
        _searchBar.frame = CGRectOffset(_searchBar.frame, 0, -20);
        _tableView.frame = CGRectOffset(_tableView.frame, 0, -20);
    }
    
    return YES;
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    //取消
    _searchBar.frame = CGRectOffset(_searchBar.frame, 0, -20);
    _tableView.frame = CGRectOffset(_tableView.frame, 0, -20);
    
    self.bFinishedEdit = YES;
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
        NSString *storeString = [(ContactModel *)self.dataArr[i] name];
        
        NSString *storeNumber = [(ContactModel *)self.dataArr[i] phoneNumber];
        
        NSString *storeImageString=[(ContactModel *)self.dataArr[i] portrait]?[(ContactModel *)self.dataArr[i] portrait]:@"";
        
        NSRange storeRange = NSMakeRange(0, storeString.length);
        
        NSRange foundRange = [storeString rangeOfString:searchText options:searchOptions range:storeRange];
        if (foundRange.length) {
            NSDictionary *dic=@{@"name":storeString,@"portrait":storeImageString,@"phoneNumber":storeNumber};
            
            [tempResults addObject:dic];
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
}



@end
