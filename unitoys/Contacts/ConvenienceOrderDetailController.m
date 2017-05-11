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

@interface ConvenienceOrderDetailController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *cellDatas;
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
    [self initTableView];
    [self initCellDatas];
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

- (void)initCellDatas
{
    self.cellDatas = @[
                       @{
                           @"cellName":@"订单编号",
                           @"cellText":@"123456",
                         },
                       @{
                           @"cellName":@"支付费用",
                           @"cellText":[NSString stringWithFormat:@"￥%@", @"100"],
                           },
                       @{
                           @"cellName":@"支付时间",
                           @"cellText":@"2017-01-01 10:00",
                           },
                       @{
                           @"cellName":@"支付方式",
                           @"cellText":@"支付宝",
                           },
                       @{
                           @"cellName":@"服务时间",
                           @"cellText":@"2017年10月-2017年11月",
                           },
                       
                       ];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    }else if (section == 1){
        return self.cellDatas.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        ConvenienceOrderCell *cell = [tableView dequeueReusableCellWithIdentifier:convenienceOrderCellID];
        cell.imgCommunicatePhoto.image = [UIImage imageNamed:@"icon_iphone"];
        cell.lblCommunicateName.text = @"省心服务";
        cell.lblValidity.text = @"通话无限制";
        [cell.lblCommunicatePrice changeLabelTexeFontWithString:@"￥0.00"];
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
