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

@interface ConvenienceServiceController ()<UITableViewDelegate, UITableViewDataSource>

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

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"省心服务";
    [self initSubViews];
}

- (void)initSubViews
{
    [self initTableView];
    [self initData];
    [self.tableView reloadData];
}

//初始化展示数据
- (void)initData
{
    self.cellDatas = @[
                       @{
                           @"imageUrl":@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1494397069257&di=8ddbdaf3fc2d0149880be9abd985cb30&imgtype=0&src=http%3A%2F%2Fimg27.51tietu.net%2Fpic%2F2017-011500%2F20170115001256mo4qcbhixee164299.jpg",
                           @"type":@"1",
                           },
                       @{
                           @"imageUrl":@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1494397069257&di=8ddbdaf3fc2d0149880be9abd985cb30&imgtype=0&src=http%3A%2F%2Fimg27.51tietu.net%2Fpic%2F2017-011500%2F20170115001256mo4qcbhixee164299.jpg",
                           @"type":@"2",
                           },
                       ];
    [self.tableView reloadData];
    
    
    self.checkToken = YES;
    [self getBasicHeader];
    [SSNetworkRequest getRequest:@"" params:nil success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            self.cellDatas = @[];
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
    self.tableView.rowHeight = 194;
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
    ConvenienceServiceCell *cell = [tableView dequeueReusableCellWithIdentifier:convenienceServiceCellID];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.bgimageView sd_setImageWithURL:[NSURL URLWithString:self.cellDatas[indexPath.row][@"imageUrl"]] placeholderImage:nil];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSDictionary *dict = self.cellDatas[indexPath.row];
    if ([dict[@"type"] isEqualToString:@"1"]) {
        ReceivePhoneTimeController *receiveVc = [[ReceivePhoneTimeController alloc] init];
        [self.navigationController pushViewController:receiveVc animated:YES];
    }else if ([dict[@"type"] isEqualToString:@"2"]){
        NSString *phoneStr;
        if ([UNPushKitMessageManager shareManager].iccidString) {
            phoneStr = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"ValidateICCID%@",[UNPushKitMessageManager shareManager].iccidString]];
        }
        if (!phoneStr) {
            //验证号码
            VerificationPhoneController *verificationVc = [[VerificationPhoneController alloc] init];
            [self.navigationController presentViewController:verificationVc animated:YES completion:nil];
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
