//
//  ConvenienceOrderDetailController.m
//  unitoys
//
//  Created by 黄磊 on 2017/5/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "ConvenienceOrderDetailController.h"
#import <Masonry/Masonry.h>
#import "ConvenienceOrderCell.h"
#import "ConvenienceOrder2Cell.h"
#import "UITableView+RegisterNib.h"
#import "ConvenienceServiceController.h"
#import "UNDatabaseTools.h"

@interface ConvenienceOrderDetailController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *cellDatas;
//@property (nonatomic, copy) NSDictionary *dicOrderDetail;
@property (nonatomic, copy) NSDictionary *orderData;
@end

static NSString *convenienceOrderCellID = @"ConvenienceOrderCell";
static NSString *convenienceOrder2CellID = @"ConvenienceOrder2Cell";
@implementation ConvenienceOrderDetailController

- (NSArray *)cellDatas
{
    if (!_cellDatas) {
        _cellDatas = [NSArray array];
    }
    return _cellDatas;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"订单详情";
    [self initTableView];
    [self initDatas];
}

- (void)initTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.backgroundColor = UIColorFromRGB(0xf5f5f5);
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
    [self.tableView registerNibWithNibId:convenienceOrderCellID];
    [self.tableView registerNibWithNibId:convenienceOrder2CellID];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.bottom.equalTo(self.view);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
    }];
}

- (void)initDatas
{
    HUDNoStop1(INTERNATIONALSTRING(@"正在加载..."))
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.orderDetailId,@"id", nil];
    NSString *apiNameStr = [NSString stringWithFormat:@"%@OrderId%@", @"apiOrderById", [self.orderDetailId stringByReplacingOccurrencesOfString:@"-" withString:@""]];
    [self getBasicHeader];
    //    NSLog(@"表头：%@",self.headers);
    [SSNetworkRequest getRequest:apiOrderById params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:apiNameStr dictData:responseObj];
            NSLog(@"apiOrderById==responseObj");
            self.orderData = [responseObj objectForKey:@"data"][@"list"];
            [self initCellDatas];
            [self.tableView reloadData];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
    } failure:^(id dataObj, NSError *error) {
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:apiNameStr];
        if (responseObj) {
            NSLog(@"apiOrderById==responseObj");
            self.orderData = [responseObj objectForKey:@"data"][@"list"];
            [self.tableView reloadData];
        }else{
            HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        }
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

- (void)initCellDatas
{
    NSString *payMode;
    if ([self.orderData[@"PaymentMethod"] isEqualToString:@"1"]) {
        payMode = @"支付宝";
    }else if ([self.orderData[@"PaymentMethod"] isEqualToString:@"2"]){
        payMode = @"微信";
    }else if ([self.orderData[@"PaymentMethod"] isEqualToString:@"3"]){
        payMode = @"余额";
    }else{
        payMode = @"官方赠送";
    }
    _cellDatas = @[
                       @{
                           @"cellName":@"订单编号",
                           @"cellText":self.orderData[@"OrderNum"],
                         },
                       @{
                           @"cellName":@"支付费用",
                           @"cellText":[NSString stringWithFormat:@"￥%@", self.orderData[@"TotalPrice"]],
                           },
                       @{
                           @"cellName":@"支付时间",
                           @"cellText":[self convertDateWithString:self.orderData[@"OrderDate"]],
                           },
                       @{
                           @"cellName":@"支付方式",
                           @"cellText":payMode,
                           },
                       @{
                           @"cellName":@"服务时间",
                           @"cellText":self.orderData[@"ExpireDays"] ? self.orderData[@"ExpireDays"] : @"",
                           },
                       ];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.orderData) {
        if (section == 0) {
            return 1;
        }else if (section == 1){
            return self.cellDatas.count;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        ConvenienceOrderCell *cell = [tableView dequeueReusableCellWithIdentifier:convenienceOrderCellID];
        setImage(cell.imgCommunicatePhoto, self.orderData[@"LogoPic"])
        cell.lblCommunicateName.text = self.orderData[@"PackageName"];
        if ([self.orderData[@"RemainingCallMinutes"] isEqualToString:@"0"]) {
            cell.lblValidity.text = @"通话无限制";
        }else{
            cell.lblValidity.text = [NSString stringWithFormat:@"%@分钟", self.orderData[@"RemainingCallMinutes"]];
        }
        [cell.lblCommunicatePrice changeLabelTexeFontWithString:[NSString stringWithFormat:@"￥%@", self.orderData[@"TotalPrice"]]];
        return cell;
    }else if (indexPath.section == 1){
        ConvenienceOrder2Cell *cell = [tableView dequeueReusableCellWithIdentifier:convenienceOrder2CellID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.nameLabel.text = self.cellDatas[indexPath.row][@"cellName"];
        if (self.cellDatas[indexPath.row][@"cellText"]) {
            cell.detailLabel.text = self.cellDatas[indexPath.row][@"cellText"];
        }
        return cell;
    }else{
        ConvenienceOrder2Cell *cell = [tableView dequeueReusableCellWithIdentifier:convenienceOrder2CellID];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == 0) {
        if (self.isNoClickDetail) {
            return;
        }
        ConvenienceServiceController *convenienceVc = [[ConvenienceServiceController alloc] init];
        [self.navigationController pushViewController:convenienceVc animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 120;
    }else{
        return 44;
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
