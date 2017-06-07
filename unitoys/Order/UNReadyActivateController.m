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

@interface UNReadyActivateController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSString *selectDate;

@end

static NSString *activateCellID = @"UNReadyActivateCell";
@implementation UNReadyActivateController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"在手机内激活";
    [self initTableView];
}

//初始化tableView
- (void)initTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.tableView registerNibWithNibId:activateCellID];
//    [self.tableView registerNibWithNibId:callDetailsNumberCellId];
//    [self.tableView registerNibWithNibId:callDetailsActionCellId];
    
    self.tableView.un_height -= 64;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = UIColorFromRGB(0xf5f5f5);
    
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, 10)];
    self.tableView.tableHeaderView = topView;
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, 94)];
    UIButton *activeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    activeButton.backgroundColor = DefultColor;
    activeButton.layer.cornerRadius = 22;
    activeButton.layer.masksToBounds = YES;
    activeButton.frame = CGRectMake(15, 25, kScreenWidthValue - 30, 44);
    [activeButton setTitle:@"立即激活" forState:UIControlStateNormal];
    [bottomView addSubview:activeButton];
    
    self.tableView.tableFooterView = bottomView;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
    
    [self.tableView reloadData];
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
        cell.nameLabel.text = @"选择生效时间";
        cell.dateLabel.hidden = NO;
        cell.iconImageView.hidden = NO;
        cell.dayLabel.hidden = YES;
        cell.dateLabel.text = self.defaultDate;
    }else{
        cell.nameLabel.text = @"有效时长";
        cell.dateLabel.hidden = YES;
        cell.iconImageView.hidden = YES;
        cell.dayLabel.hidden = NO;
        cell.dayLabel.text = self.defaultDay;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row == 0) {
        //弹出选择日期控件
        
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

@end
