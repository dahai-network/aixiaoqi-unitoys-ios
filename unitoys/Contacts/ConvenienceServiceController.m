//
//  ConvenienceServiceController.m
//  unitoys
//
//  Created by 黄磊 on 2017/5/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "ConvenienceServiceController.h"
#import <Masonry/Masonry.h>
#import "UITableView+RegisterNib.h"
#import "ConvenienceServiceCell.h"
#import "ConvenienceServiceDetailController.h"
#import "ReceivePhoneTimeController.h"
#import "UNPushKitMessageManager.h"
#import "VerificationPhoneController.h"
#import "navHomeViewController.h"

@interface ConvenienceServiceController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy) NSArray *serverDatas;
@property (nonatomic, copy) NSArray *cellDatas;
@property (nonatomic, strong) UITableView *tableView;

@end

static NSString *convenienceServiceCellID = @"ConvenienceServiceCell";
@implementation ConvenienceServiceController

- (NSArray *)cellDatas
{
    if (!_cellDatas) {
        _cellDatas = [NSArray array];
    }
    return _cellDatas;
}

- (NSArray *)serverDatas
{
    if (!_serverDatas) {
        _serverDatas = [NSArray array];
    }
    return _serverDatas;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"省心服务";
    [self initSubViews];
}

- (void)initSubViews
{
    [self initTableView];
    [self initData];
}
//初始化展示数据
- (void)initData
{
    self.checkToken = YES;
    [self getBasicHeader];
    [SSNetworkRequest getRequest:apiPackageGetRelaxed params:nil success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"%@", responseObj);
            self.cellDatas = responseObj[@"data"][@"list"];
            [self.tableView reloadData];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }
    } failure:^(id dataObj, NSError *error) {
        HUDNormal(INTERNATIONALSTRING(@"网络连接失败"))
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

- (void)initTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.backgroundColor = UIColorFromRGB(0xf5f5f5);
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = 10 + (kScreenWidthValue - 30)/(691.0/370);
    [self.view addSubview:self.tableView];
    [self.tableView registerNibWithNibId:convenienceServiceCellID];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.bottom.equalTo(self.view);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.cellDatas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dict = self.cellDatas[indexPath.row];
    ConvenienceServiceCell *cell = [tableView dequeueReusableCellWithIdentifier:convenienceServiceCellID];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if ([dict[@"Haveed"] boolValue]) {
        [cell.bgimageView sd_setImageWithURL:[NSURL URLWithString:dict[@"PicHaveed"]] placeholderImage:nil];
    }else{
        [cell.bgimageView sd_setImageWithURL:[NSURL URLWithString:dict[@"Pic"]] placeholderImage:nil];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSDictionary *dict = self.cellDatas[indexPath.row];
    if ([dict[@"Haveed"] boolValue]) {
        return;
    }
    if ([dict[@"Category"] isEqualToString:@"4"]) {
        ReceivePhoneTimeController *receiveVc = [[ReceivePhoneTimeController alloc] init];
        [self.navigationController pushViewController:receiveVc animated:YES];
    }else if ([dict[@"Category"] isEqualToString:@"5"]){
        NSString *phoneStr;
        if ([UNPushKitMessageManager shareManager].iccidString) {
            phoneStr = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"ValidateICCID%@",[UNPushKitMessageManager shareManager].iccidString]];
        }
        if (!phoneStr) {
            //验证号码
            VerificationPhoneController *verificationVc = [[VerificationPhoneController alloc] init];
            navHomeViewController *nav = [[navHomeViewController alloc] initWithRootViewController:verificationVc];
            [self.navigationController presentViewController:nav animated:YES completion:nil];
        }else{
            NSLog(@"省心服务");
            ConvenienceServiceDetailController *convenienceDetailVc = [[ConvenienceServiceDetailController alloc] init];
            [self.navigationController pushViewController:convenienceDetailVc animated:YES];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
