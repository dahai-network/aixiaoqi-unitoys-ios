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
#import "CallActionView.h"
#import "BlueToothDataManager.h"
#import "UNDataTools.h"

@interface ContactsCallDetailsController ()<UITableViewDelegate, UITableViewDataSource, CallDetailsActionCellDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *phoneRecords;
@property (nonatomic, copy) NSArray *cellData;

@property (strong,nonatomic) CallActionView *callActionView;

@property (nonatomic, copy) NSString *lastTime;
@property (nonatomic, copy) NSString *phoneLocation;
@property (nonatomic, assign) NSInteger currentRecordPage;
@end

static NSString *callDetailsNameCellId = @"CallDetailsNameCell";
static NSString *callDetailsNumberCellId = @"CallDetailsNumberCell";
static NSString *callDetailsActionCellId = @"CallDetailsActionCell";

static NSString *callDetailsRecordCellId = @"CallDetailsRecordCell";
static NSString *callDetailsLookAllCellId = @"CallDetailsLookAllCell";

@implementation ContactsCallDetailsController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"拨打详情";
    self.currentRecordPage = 1;
    [self getPhoneRecords];
    [self initData];
    [self initTableView];
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
                      }
                  ];
}

//初始化tableView
- (void)initTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.height -= 64;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = UIColorFromRGB(0xf5f5f5);
    
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, 10)];
    self.tableView.tableHeaderView = topView;
    self.tableView.tableFooterView = topView;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];

    [self.tableView registerNibWithNibId:callDetailsNameCellId];
    [self.tableView registerNibWithNibId:callDetailsNumberCellId];
    [self.tableView registerNibWithNibId:callDetailsActionCellId];
    if (self.phoneRecords.count) {
        [self.tableView registerNibWithNibId:callDetailsRecordCellId];
        [self.tableView registerNibWithNibId:callDetailsLookAllCellId];
    }
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
            }else{
                [cell setValue:dict forKeyPath:@"cellDatas"];
            }
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
        [self callPhone];
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

- (void)callPhone
{
    if (!self.callActionView){
        self.callActionView = [[CallActionView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, kScreenHeightValue)];
    }
    
    __weak typeof(self) weakSelf = self;
    
    self.callActionView.cancelBlock = ^(){
        [weakSelf.callActionView hideActionView];
    };
    self.callActionView.actionBlock = ^(NSInteger callType){
        [weakSelf.callActionView hideActionView];
        if (callType==1) {
            //网络电话
            //电话记录，拨打电话
            if (weakSelf.phoneNumber) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MakeCallAction" object:[weakSelf formatPhoneNum:weakSelf.phoneNumber]];
            }
        }else if (callType==2){
            //手环电话
            if ([BlueToothDataManager shareManager].isRegisted) {
                if (weakSelf.phoneNumber) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"MakeUnitysCallAction" object:[weakSelf formatPhoneNum:weakSelf.phoneNumber]];
                }
            } else {
                HUDNormal(INTERNATIONALSTRING(@"设备内sim卡未注册或已掉线"))
            }
        }
    };
    [self.callActionView showActionView];
}

- (void)defriend
{
    NSLog(@"屏蔽");
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
