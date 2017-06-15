//
//  UNReadyActivateController.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/7.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNReadyActivateController.h"
#import "UITableView+RegisterNib.h"
#import "UNReadyActivateCell.h"
#import "UNMobileActivateController.h"
#import "UNConvertFormatTool.h"
#import "UNDatabaseTools.h"

@interface UNReadyActivateController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSString *selectDate;

//@property (nonatomic, weak) UIPickerView *pickerView;
@property (weak, nonatomic) UIView *valueView;
//@property (nonatomic, weak) UILabel *titleLabel;

@property (nonatomic, weak) UIDatePicker *datePicker;
@property (nonatomic, weak) UIButton *activeButton;
@end

static NSString *activateCellID = @"UNReadyActivateCell";
@implementation UNReadyActivateController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"在手机内激活";
    [self initTableView];
    if (!self.defaultDate) {
        [self initPickerView];
    }else{
        self.selectDate = self.defaultDate;
    }
}

//初始化tableView
- (void)initTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.tableView registerNibWithNibId:activateCellID];
    self.tableView.un_height -= 64;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = UIColorFromRGB(0xf5f5f5);
    self.tableView.rowHeight = 55;
    
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, 10)];
    self.tableView.tableHeaderView = topView;
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, 100)];
    UIButton *activeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.activeButton = activeButton;
    activeButton.backgroundColor = DefultColor;
    activeButton.layer.cornerRadius = 25;
    activeButton.layer.masksToBounds = YES;
    activeButton.frame = CGRectMake(15, 25, kScreenWidthValue - 30, 50);
    [activeButton setTitle:@"立即激活" forState:UIControlStateNormal];
    [activeButton addTarget:self action:@selector(activeAction:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:activeButton];
    
    self.tableView.tableFooterView = bottomView;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
    
    [self.tableView reloadData];
}

- (void)initPickerView
{
    UIView *valueView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    valueView.un_height -= 64;
    valueView.backgroundColor = [UIColor colorWithRed:32/255 green:34/255 blue:42/255 alpha:0.2];
    
    UIButton *btnOK = [[UIButton alloc] initWithFrame:CGRectMake(0,valueView.un_height - 35 - 1, self.view.bounds.size.width, 35)];
    btnOK.hidden = NO;
    [btnOK setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnOK setTitle:INTERNATIONALSTRING(@"确定") forState:UIControlStateNormal];
    [btnOK setBackgroundColor:[UIColor whiteColor]];
    [btnOK addTarget:self action:@selector(selectValue) forControlEvents:UIControlEventTouchUpInside];
    [valueView addSubview:btnOK];
    

    UIDatePicker *datePicker = [[UIDatePicker alloc]init];
    self.datePicker = datePicker;
    datePicker.frame = CGRectMake(0, valueView.un_height - 180 - 40, kScreenWidthValue, 180);
    datePicker.backgroundColor = [UIColor whiteColor];
    datePicker.locale = [NSLocale localeWithLocaleIdentifier:@"zh"];
    datePicker.datePickerMode = UIDatePickerModeDate;
    datePicker.minimumDate = [NSDate date];
    if (self.lastActivateDate) {
        //最晚激活日期
        datePicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:self.lastActivateDate];
    }
    [valueView addSubview:datePicker];
    
    [self.view addSubview:valueView];
    valueView.hidden = YES;
    self.valueView = valueView;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self.valueView addGestureRecognizer:tap];
    
}

- (void)selectValue
{
    NSLog(@"%@", self.datePicker);
    NSDate *date = self.datePicker.date;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    self.selectDate = [dateFormatter stringFromDate:date];
    
    [self.valueView setHidden:YES];
    self.tableView.scrollEnabled = self.valueView.hidden;
    
    [self.tableView reloadData];
}

- (void)tapAction {
    if (!self.valueView.hidden) {
        self.valueView.hidden = YES;
        self.tableView.scrollEnabled = self.valueView.hidden;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UNReadyActivateCell *cell = [tableView dequeueReusableCellWithIdentifier:activateCellID];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.row == 0) {
        if (self.defaultDate) {
            cell.nameLabel.text = @"生效时间";
        }else{
            cell.nameLabel.text = @"选择生效时间";
        }
        cell.dateLabel.hidden = NO;
        cell.iconImageView.hidden = NO;
        cell.dayLabel.hidden = YES;
        if (self.selectDate) {
            cell.dateLabel.text = self.selectDate;
        }
    }else{
        cell.nameLabel.text = @"有效时长";
        cell.dateLabel.hidden = YES;
        cell.iconImageView.hidden = YES;
        cell.dayLabel.hidden = NO;
        if (self.defaultDay) {
            cell.dayLabel.text = [NSString stringWithFormat:@"%@天", self.defaultDay];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row == 0) {
        //弹出选择日期控件
        if (!self.defaultDate) {
            if (self.valueView) {
                self.valueView.hidden = NO;
            }
        }
    }
}

- (void)activeAction:(UIButton *)button
{
    if (!self.selectDate || [self.selectDate isEqualToString:@""]) {
        HUDNormal(@"请选择生效时间");
        return;
    }
    if (!self.isAlreadyActivate) {
        //直接获取卡数据
        NSLog(@"激活");
        HUDNoStop1(@"")
        self.checkToken = YES;
        NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:self.orderID,@"OrderID", self.selectDate,@"BeginDateTime", nil];
        NSString *apiNameStr = [NSString stringWithFormat:@"%@OrderID%@", @"apiOrderActivation", self.orderID];
        [self getBasicHeader];
        //            NSLog(@"表演头：%@",self.headers);
        [SSNetworkRequest postRequest:apiOrderActivation params:info success:^(id responseObj) {
            NSLog(@"查询到的用户数据：%@",responseObj);
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:apiNameStr dictData:responseObj];
                [self activitySuccess];
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                HUDStop
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
                HUDStop
                HUDNormal(responseObj[@"msg"])
                [self.activeButton setTitle:INTERNATIONALSTRING(@"重新激活") forState:UIControlStateNormal];
            }
            
        } failure:^(id dataObj, NSError *error) {
            NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:apiNameStr];
            if (responseObj) {
                [self activitySuccess];
                HUDStop
            }else{
                [self.activeButton setTitle:INTERNATIONALSTRING(@"重新激活") forState:UIControlStateNormal];
                HUDNormal(@"激活失败")
            }
            NSLog(@"啥都没：%@",[error description]);
            
        } headers:self.headers];
    }else{
        //获取激活码
        [self getActivateCode];
    }
}

#pragma mark 激活成功
- (void)activitySuccess {
    HUDNoStop1(@"")
    self.checkToken = YES;
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.orderID, @"OrderID", nil];
    [self getBasicHeader];
    
    NSString *apiNameStr = [NSString stringWithFormat:@"%@OrderID%@", @"apiActivationLocalCompleted", self.orderID];
    [SSNetworkRequest postRequest:apiActivationLocalCompleted params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:apiNameStr dictData:responseObj];
            HUDStop
            //获取激活码
            [self getActivateCode];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            HUDStop
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            HUDStop
        }
    } failure:^(id dataObj, NSError *error) {
        HUDStop
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:apiNameStr];
        if (responseObj) {
            [self getActivateCode];
        }
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

#pragma mark 查询订单卡数据
- (void)getActivateCode
{
    HUDNoStop1(@"")
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.orderID, @"OrderID", nil];
    self.checkToken = YES;
    [self getBasicHeader];
    NSString *apiNameStr = [NSString stringWithFormat:@"%@OrderID%@", @"apiQueryOrderData", self.orderID];
    [SSNetworkRequest postRequest:apiQueryOrderData params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:apiNameStr dictData:responseObj];
            NSLog(@"%@", responseObj);
            HUDStop
            //粘贴激活码
            NSString *code = [self convertActivationCode:responseObj[@"data"][@"Data"]];
            [self pasteCode:code];
            
            UNMobileActivateController * activateVc = [[UNMobileActivateController alloc] init];
            [self.navigationController pushViewController:activateVc animated:YES];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            HUDStop
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            HUDStop
            //数据请求失败
            NSLog(@"请求失败：%@", responseObj[@"msg"]);
        }
    } failure:^(id dataObj, NSError *error) {
//        HUDNormal(@"网络貌似有问题")
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:apiNameStr];
        if (responseObj) {
            NSString *code = [self convertActivationCode:responseObj[@"data"][@"Data"]];
            [self pasteCode:code];
            UNMobileActivateController * activateVc = [[UNMobileActivateController alloc] init];
            [self.navigationController pushViewController:activateVc animated:YES];
        }
        
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

//转换激活码
//76372b2f6c35546856465972786a71686e6c43457a704f61367973624263776736717549544238424d3363784a476547304664674b726b465a716c3943556873336578693862337254476f3673686758424a6553383548754c6d737838504149532b3973
- (NSString *)convertActivationCode:(NSString *)code
{
    if (!code || [code isEqualToString:@""]) {
        return nil;
    }
    return [UNConvertFormatTool stringFromHexString:code];
}

//粘贴激活码
- (void)pasteCode:(NSString *)code
{
    if (code) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        [pasteboard setString:code];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

@end
