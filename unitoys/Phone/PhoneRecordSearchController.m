//
//  PhoneRecordSearchController.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "PhoneRecordSearchController.h"
#import "AddressBookManager.h"
#import "SearchContactsCell.h"
#import "ContactModel.h"
#import "PhoneRecordCell.h"

@interface PhoneRecordSearchController ()

//处理过的拨打记录列表
@property (nonatomic, copy) NSArray *searchPhoneRecords;
//联系人列表
@property (nonatomic, copy) NSArray *contactsLists;
//搜索列表
@property (nonatomic, strong) NSMutableArray *searchLists;

@end

static NSString *searchContactsCellID = @"SearchContactsCell";

@implementation PhoneRecordSearchController

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



- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:searchContactsCellID bundle:nil] forCellReuseIdentifier:searchContactsCellID];
    NSString *strPhoneRecordCell = @"PhoneRecordCell";
    UINib * phoneRecordNib = [UINib nibWithNibName:strPhoneRecordCell bundle:nil];
    [self.tableView registerNib:phoneRecordNib forCellReuseIdentifier:strPhoneRecordCell];
    
    self.tableView.rowHeight = 60;
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



- (void)setSearchText:(NSString *)searchText
{
    if ([searchText isEqualToString:@""] || !searchText) {
        return;
    }
    _searchText = searchText;
    [self searchInfoWithString:searchText];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchLists.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id model;
    if ([self.searchLists count] > indexPath.row ) {
        model = self.searchLists[indexPath.row];
    }
    if ([model isKindOfClass:[ContactModel class]]) {
        //展示搜索信息
        SearchContactsCell *cell = [tableView dequeueReusableCellWithIdentifier:searchContactsCellID];
        [cell updateCellWithModel:model HightText:_searchText];
        return cell;
    }else{
        PhoneRecordCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"PhoneRecordCell"];
        NSDictionary *dicPhoneRecord = (NSDictionary *)model;
        cell.lblCallTime.text = [self compareCurrentTimeString:[dicPhoneRecord objectForKey:@"calltime"]];
        //                cell.lblPhoneType.text = [dicPhoneRecord objectForKey:@"type"];
        [cell.lblPhoneNumber setTextColor:[UIColor blackColor]];
        NSMutableString *bottomStr = [NSMutableString string];
        if ([[dicPhoneRecord objectForKey:@"calltype"] isEqualToString:@"来电"]) {
            [cell.ivStatus setImage:[UIImage imageNamed:@"tel_callin"]];
            
            NSString *phoneNum = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"hostnumber"]];
            
            //                    cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"hostnumber"]];
            if (![(NSString *)[dicPhoneRecord objectForKey:@"hostnumber"] containsString:phoneNum]) {
                [bottomStr appendString:(NSString *)[dicPhoneRecord objectForKey:@"hostnumber"]];
                [bottomStr appendString:@"  "];
                cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"hostnumber"]];
            }else{
                NSMutableAttributedString *attriStr = [[NSMutableAttributedString alloc] initWithString:phoneNum attributes:@{NSForegroundColorAttributeName : [UIColor blackColor]}];
                NSRange range = [phoneNum rangeOfString:_searchText];
                if (range.length) {
                    [attriStr setAttributes:@{NSForegroundColorAttributeName : [UIColor blueColor]} range:range];
                }
                cell.lblPhoneNumber.attributedText = attriStr;
            }
            
            if ([cell.lblCallTime.text isEqualToString:@"刚刚"]) {
                UNDebugLogVerbose(@"有了：%@",dicPhoneRecord);
            }
            //                    if ([[dicPhoneRecord objectForKey:@"status"] intValue]==0){  //如果未接听则显示红色
            //                        [cell.lblPhoneNumber setTextColor:[UIColor redColor]];
            //                    }
        }else{
            [cell.ivStatus setImage:[UIImage imageNamed:@"tel_callout"]];
            NSString *phoneNum = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"destnumber"]];
            
//            cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"destnumber"]];
            if (![(NSString *)[dicPhoneRecord objectForKey:@"destnumber"] containsString:phoneNum]) {
                [bottomStr appendString:(NSString *)[dicPhoneRecord objectForKey:@"destnumber"]];
                [bottomStr appendString:@"  "];
                cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"destnumber"]];
            }else{
                NSMutableAttributedString *attriStr = [[NSMutableAttributedString alloc] initWithString:phoneNum attributes:@{NSForegroundColorAttributeName : [UIColor blackColor]}];
                NSRange range = [phoneNum rangeOfString:_searchText];
                if (range.length) {
                    [attriStr setAttributes:@{NSForegroundColorAttributeName : [UIColor blueColor]} range:range];
                }
                cell.lblPhoneNumber.attributedText = attriStr;
            }
        }
        [bottomStr appendString:[dicPhoneRecord objectForKey:@"location"]];
        NSMutableAttributedString *attriStr = [[NSMutableAttributedString alloc] initWithString:bottomStr attributes:@{NSForegroundColorAttributeName : [UIColor lightGrayColor]}];
        NSRange range = [bottomStr rangeOfString:_searchText];
        if (range.length) {
            [attriStr setAttributes:@{NSForegroundColorAttributeName : [UIColor blueColor]} range:range];
        }
        cell.lblPhoneType.attributedText = attriStr;
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //通过点击联系人拨打电话
    id contacts;
    if ([self.searchLists count] > indexPath.row ) {
        contacts = self.searchLists[indexPath.row];
    }
    if (self.didSelectSearchCellBlock) {
        self.didSelectSearchCellBlock(contacts);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
