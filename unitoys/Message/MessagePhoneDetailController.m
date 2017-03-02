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
//@property (nonatomic, copy) NSString *phoneName;
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
//        self.phoneName = [self checkLinkNameWithPhoneStrMergeGroupName:self.toPhoneStr];
        NSArray *phones = [self.toPhoneStr componentsSeparatedByString:@","];
        NSMutableArray *tempPhone = [NSMutableArray array];
        for (NSString *phone in phones) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            NSString *phoneName = [self checkLinkNameWithPhoneStr:phone];
            dict[@"phone"] = phone;
            dict[@"phoneName"] = phoneName;
            [tempPhone addObject:dict];
        }
        [self.phoneDatas addObjectsFromArray:tempPhone];
    }else{
//        self.phoneName = [self checkLinkNameWithPhoneStr:self.toPhoneStr];
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        NSString *phoneName = [self checkLinkNameWithPhoneStr:self.toPhoneStr];
        dict[@"phone"] = self.toPhoneStr;
        dict[@"phoneName"] = phoneName;
        [self.phoneDatas addObject:dict];
    }
    
//    self.headerHeight = [self.phoneName boundingRectWithSize:CGSizeMake(kScreenWidthValue - 62 - 11, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:16]} context:nil].size.height;
}

- (void)initSubViews
{
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height - 64) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsSelection = NO;
    [self.tableView registerNib:[UINib nibWithNibName:@"MessagePhoneDetailCell" bundle:nil] forCellReuseIdentifier:@"MessagePhoneDetailCell"];
    self.tableView.tableFooterView = [UIView new];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = 80;
//    [self.tableView registerNib:[UINib nibWithNibName:@"MessagePhoneDetailHeaderCell" bundle:nil] forCellReuseIdentifier:@"MessagePhoneDetailHeaderCell"];
    [self.view addSubview:self.tableView];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.phoneDatas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessagePhoneDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessagePhoneDetailCell"];
    NSDictionary *dict = self.phoneDatas[indexPath.row];
    cell.nameLabel.text = dict[@"phoneName"];
    cell.phoneLabel.text = dict[@"phone"];
    cell.callButton.tag = indexPath.row;
    [cell.callButton addTarget:self action:@selector(callButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}


- (void)callButtonAction:(UIButton *)button
{
    NSDictionary *dict = self.phoneDatas[button.tag];
    NSString *number = dict[@"phone"];
    
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
