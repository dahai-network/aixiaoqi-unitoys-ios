//
//  MessageRecordController.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "MessageRecordController.h"
#import "MJRefresh.h"
#import "NewMessageViewController.h"
#import "MessageRecordCell.h"
#import "MJViewController.h"
#import "AddTouchAreaButton.h"
#import "UITableView+RegisterNib.h"
#import "UNDataTools.h"

@interface MessageRecordController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) AddTouchAreaButton *createMsgButton;

@property (nonatomic, strong) UILabel *noDataLabel;
@end

static NSString *strMessageRecordCell = @"MessageRecordCell";
@implementation MessageRecordController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initTableView];
    [self initNoDataLabel];
    [self initRefresh];
    
    self.page = 1;
    if (!_arrMessageRecord) {
        [self loadMessage];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSMSContentAction) name:@"ReceiveNewSMSContentUpdate" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadMessage) name:@"sendMessageSuccess" object:@"sendMessageSuccess"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactsInfoChange) name:@"ContactsInfoChange" object:nil];
    [self createButton];
}

- (void)initTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.backgroundColor = UIColorFromRGB(0xf5f5f5);
//    self.tableView.height -= (64 + 49);
//    self.tableView.height = self.parentViewController.view.height;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, 10)];
    self.tableView.tableHeaderView = topView;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.rowHeight = 90;
    [self.view addSubview:self.tableView];
    [self.tableView registerNibWithNibId:strMessageRecordCell];
}

- (void)initNoDataLabel
{
    if (!_noDataLabel) {
        _noDataLabel = [[UILabel alloc] init];
        _noDataLabel.text = [NSString stringWithFormat:@"暂无通话记录\n您还没有打过电话"];
        _noDataLabel.font = [UIFont systemFontOfSize:16];
        _noDataLabel.textColor = UIColorFromRGB(0xcccccc);
        _noDataLabel.numberOfLines = 2;
        _noDataLabel.textAlignment = NSTextAlignmentCenter;
        [_noDataLabel sizeToFit];
        _noDataLabel.un_centerX = kScreenWidthValue * 0.5;
        _noDataLabel.un_centerY = (kScreenHeightValue - 64 - 49 - 50) * 0.5;
        [self.view addSubview:_noDataLabel];
        _noDataLabel.hidden = YES;
    }
}


- (void)contactsInfoChange
{
    [self.tableView reloadData];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
    _createMsgButton.un_right = self.view.un_width - 10;
    _createMsgButton.un_bottom = self.view.un_height;
}

- (void)updateSMSContentAction
{
    [self loadMessage];
}

- (void)initRefresh
{
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        self.page = 1;
        [self.tableView.mj_footer resetNoMoreData];
        [self loadMessage];
    }];
    
    //刷新尾部
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreMessage)];
    self.tableView.mj_footer.hidden = YES;
}

- (void)createButton{
    if (_createMsgButton) {
        return;
    }
    _createMsgButton = [AddTouchAreaButton buttonWithType:UIButtonTypeCustom];
    [_createMsgButton setImage:[UIImage imageNamed:@"edit_Msg_nor"] forState:UIControlStateNormal];
    [_createMsgButton setImage:[UIImage imageNamed:@"edit_Msg_pre"] forState:UIControlStateSelected];
    [_createMsgButton addTarget:self action:@selector(createMsgAction:) forControlEvents:UIControlEventTouchUpInside];
    [_createMsgButton sizeToFit];
//    _createMsgButton.un_right = kScreenWidthValue - 10;
//    _createMsgButton.un_bottom = self.view.un_height - _createMsgButton.un_height - 49 - 24;
    
    [self.view addSubview:_createMsgButton];
}

- (void)createMsgAction:(AddTouchAreaButton *)button
{
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
    NewMessageViewController *newMessageViewController = [mainStory instantiateViewControllerWithIdentifier:@"newMessageViewController"];
    if (newMessageViewController) {
        [self.nav pushViewController:newMessageViewController animated:YES];
    }
}

- (void)loadMessage {
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"pageSize",@"1",@"pageNumber", nil];
    
    [self getBasicHeader];
    //    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest getRequest:apiSMSLast params:params success:^(id responseObj) {
        NSLog(@"查询到的用户数据：%@",responseObj);
        [self.tableView.mj_header endRefreshing];
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            _arrMessageRecord = [responseObj objectForKey:@"data"];
            if (_arrMessageRecord.count>=20) {
                self.tableView.mj_footer.hidden = NO;
            }else{
                self.tableView.mj_footer.hidden = YES;
            }
            
            [self.tableView reloadData];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            NSLog(@"请求短信数据失败");
        }
    } failure:^(id dataObj, NSError *error) {
        [self.tableView.mj_header endRefreshing];
    } headers:self.headers];
}

//短信加载更多数据
- (void)loadMoreMessage {
    
    if (self.tableView.mj_header.isRefreshing) {
        [self.tableView.mj_footer endRefreshing];
        return;
    }
    
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"pageSize",@(self.page+1),@"pageNumber", nil];
    
    [self getBasicHeader];
    
    [SSNetworkRequest getRequest:apiSMSLast params:params success:^(id responseObj) {
        NSLog(@"查询到的用户数据：%@",responseObj);
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSArray *arrNewMessages = [responseObj objectForKey:@"data"];
            if (arrNewMessages.count>0) {
                self.page = self.page + 1;
                _arrMessageRecord = [_arrMessageRecord arrayByAddingObjectsFromArray:arrNewMessages];
                [self.tableView.mj_footer endRefreshing];
            }else{
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
            }
            
            [self.tableView reloadData];
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            HUDNormal(INTERNATIONALSTRING(@"请求失败"))
            [self.tableView.mj_footer endRefreshing];
        }
        
    } failure:^(id dataObj, NSError *error) {
        [self.tableView.mj_footer endRefreshing];
        HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
    } headers:self.headers];
}

- (void)writeMessage
{
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
    NewMessageViewController *newMessageViewController = [mainStory instantiateViewControllerWithIdentifier:@"newMessageViewController"];
    if (newMessageViewController) {
        //writeMessageViewController.destNumber = [dicPackage objectForKey:@"PackageId"];
        [self.nav pushViewController:newMessageViewController animated:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.arrMessageRecord.count == 0) {
        _noDataLabel.hidden = NO;
        self.tableView.backgroundColor = [UIColor whiteColor];
    }else{
        _noDataLabel.hidden = YES;
        self.tableView.backgroundColor = DefualtBackgroundColor;
    }
    return self.arrMessageRecord.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    MessageRecordCell *cell = [self.tableView dequeueReusableCellWithIdentifier:strMessageRecordCell];
    NSDictionary *dicMessageRecord = [self.arrMessageRecord objectAtIndex:indexPath.row];
    if ([[dicMessageRecord objectForKey:@"IsSend"] boolValue]) {
        //己方发送
        cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStrMergeGroupName:[dicMessageRecord objectForKey:@"To"]];
    }else{
        //对方发送
        cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStrMergeGroupName:[dicMessageRecord objectForKey:@"Fm"]];
    }
//    NSString *textStr = [NSString stringWithFormat:@"%@", [self compareCurrentTime:[self convertDate:[dicMessageRecord objectForKey:@"SMSTime"]]]];
    NSString *textStr = [[UNDataTools sharedInstance] compareCurrentTimeStringWithRecord:dicMessageRecord[@"SMSTime"]];
    cell.lblMessageDate.text = textStr;
    cell.lblContent.text = [dicMessageRecord objectForKey:@"SMSContent"];
    return cell;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    return 80;
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //消息记录，显示消息
    NSDictionary *dicMessageRecord = [_arrMessageRecord objectAtIndex:indexPath.row];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
    if (storyboard) {
        //            self.phoneNumber= self.phonePadView.lblPhoneNumber.text;
        MJViewController *mjViewController = [storyboard instantiateViewControllerWithIdentifier:@"MJViewController"];
        if (mjViewController) {
            
            if ([[dicMessageRecord objectForKey:@"IsSend"] boolValue]) {
                //己方发送
                NSString *titleName = [self checkLinkNameWithPhoneStrMergeGroupName:[dicMessageRecord objectForKey:@"To"]];
                mjViewController.title = titleName;
                mjViewController.titleName = titleName;
                mjViewController.toTelephone = [dicMessageRecord objectForKey:@"To"];
            }else{
                //对方发送
                NSString *titleName = [self checkLinkNameWithPhoneStrMergeGroupName:[dicMessageRecord objectForKey:@"Fm"]];
                mjViewController.title = titleName;
                mjViewController.titleName = titleName;
                mjViewController.toTelephone = [dicMessageRecord objectForKey:@"Fm"];
            }
            
            mjViewController.hidesBottomBarWhenPushed = YES;
            [self.nav pushViewController:mjViewController animated:YES];
        }
    }
}

//允许左滑删除
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

//左滑删除
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *dicMessageRecord = [_arrMessageRecord objectAtIndex:indexPath.row];
        NSMutableArray *tempArray = [NSMutableArray arrayWithArray:_arrMessageRecord];
        [tempArray removeObjectAtIndex:indexPath.row];
        _arrMessageRecord = [tempArray copy];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        //从服务器删除数据
        if ([[dicMessageRecord objectForKey:@"IsSend"] boolValue]) {
            //己方发送
            [self deleteMessageWithPhoneNumber:dicMessageRecord[@"To"]];
        }else{
            //对方发送
            [self deleteMessageWithPhoneNumber:dicMessageRecord[@"Fm"]];
        }
    }
}

- (void)deleteMessageWithPhoneNumber:(NSString *)phoneNumber
{
    NSDictionary *params = @{@"Tels" : @[phoneNumber]};
    [self getBasicHeader];
    [SSNetworkRequest postRequest:apiDeletesByTels params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"删除单条短信成功");
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            NSLog(@"删除单条短信失败");
        }
    } failure:^(id dataObj, NSError *error) {
        NSLog(@"删除单条短信异常：%@",[error description]);
    } headers:self.headers];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"sendMessageSuccess" object:@"sendMessageSuccess"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ReceiveNewSMSContentUpdate" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)isShowLeftButton
{
    return NO;
}


@end
