//
//  MessagePhoneDetailController.m
//  unitoys
//
//  Created by 黄磊 on 2017/2/28.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "MessagePhoneDetailController.h"
#import "MessagePhoneDetailCell.h"
#import "MessagePhoneDetailHeaderCell.h"
#import "CallActionView.h"
#import "BlueToothDataManager.h"

@interface MessagePhoneDetailController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (strong, nonatomic) CallActionView *callActionView;

@property (nonatomic, strong) NSMutableArray *phoneDatas;
@property (nonatomic, copy) NSString *phoneName;
@property (nonatomic, assign) CGFloat headerHeight;

@end

@implementation MessagePhoneDetailController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
    [self initSubViews];
}

- (void)initData
{
    self.phoneDatas = [NSMutableArray array];
    self.title = @"详情";
    
    if ([self.toPhoneStr containsString:@","]) {
        self.phoneName = self.toPhoneStr;
        NSArray *phones = [self.toPhoneStr componentsSeparatedByString:@","];
        [self.phoneDatas addObjectsFromArray:phones];
    }else{
        self.phoneName = [self checkLinkNameWithPhoneStr:self.toPhoneStr];
        [self.phoneDatas addObject:self.toPhoneStr];
    }
    
    self.headerHeight = [self.phoneName boundingRectWithSize:CGSizeMake(kScreenWidthValue - 62 - 11, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:16]} context:nil].size.height;
}

- (void)initSubViews
{
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height - 64) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsSelection = NO;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerNib:[UINib nibWithNibName:@"MessagePhoneDetailHeaderCell" bundle:nil] forCellReuseIdentifier:@"MessagePhoneDetailHeaderCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MessagePhoneDetailCell" bundle:nil] forCellReuseIdentifier:@"MessagePhoneDetailCell"];
    [self.view addSubview:self.tableView];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.phoneDatas.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        MessagePhoneDetailHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessagePhoneDetailHeaderCell"];
        cell.phoneLabel.text = self.phoneName;
        return cell;
    }else{
        MessagePhoneDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessagePhoneDetailCell"];
        cell.phoneLabel.text = self.phoneDatas[indexPath.row - 1];
        cell.callButton.tag = indexPath.row - 1;
        [cell.callButton addTarget:self action:@selector(callButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        if (self.headerHeight > 60) {
            return self.headerHeight;
        }else{
            return 60;
        }
    }else{
        return 60;
    }
}

- (void)callButtonAction:(UIButton *)button
{
    NSString *number = self.phoneDatas[button.tag];
    
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
            if (number) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MakeCallAction" object:[weakSelf formatPhoneNum:number]];
            }
        }else if (callType==2){
            //手环电话
            if ([BlueToothDataManager shareManager].isRegisted) {
                if (number) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"MakeUnitysCallAction" object:[weakSelf formatPhoneNum:number]];
                }
            } else {
                HUDNormal(@"手环内sim卡未注册或已掉线")
            }
        }
    };
    [self.callActionView showActionView];
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
    // Dispose of any resources that can be recreated.
}


@end
