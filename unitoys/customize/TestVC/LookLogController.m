//
//  LookLogController.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/17.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "LookLogController.h"
#import "LookLogContentController.h"
#import "MBProgressHUD+UNTip.h"

@interface LookLogController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, copy) NSArray *datas;

@end

@implementation LookLogController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"上传" style:UIBarButtonItemStyleDone target:self action:@selector(presentVc)];
    [self initDatas];
    [self initTableView];
    
}

- (void)initDatas
{
    _datas = [[UNDDLogManager sharedInstance] getAllLogLists];
}

- (void)initTableView
{
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];
//    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tableView setBackgroundColor:[UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:1]];
    UIView *v = [[UIView alloc] init];
    [_tableView setTableFooterView:v];
    [self.view addSubview:_tableView];
    [_tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = _datas[indexPath.row][@"name"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSData *data = self.datas[indexPath.row][@"data"];
    NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    LookLogContentController *logContentVc = [[LookLogContentController alloc] init];
    logContentVc.text = dataStr;
    [self.navigationController pushViewController:logContentVc animated:YES];
}


- (void)presentVc
{
    [self updateLogAction];
}

- (void)updateLogAction
{
    [MBProgressHUD showLoading];
    [[UNDDLogManager sharedInstance] updateLogToServerWithLogCount:2 Finished:^(BOOL isSuccess) {
        if (isSuccess) {
            [MBProgressHUD showSuccess:@"上传成功"];
        }else{
            [MBProgressHUD showSuccess:@"上传失败"];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
