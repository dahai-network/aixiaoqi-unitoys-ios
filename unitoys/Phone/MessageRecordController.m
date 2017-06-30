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
//#import "MJViewController.h"
#import "AddTouchAreaButton.h"
#import "UITableView+RegisterNib.h"
#import "UNDataTools.h"
#import "UNDatabaseTools.h"
#import "UNMessageContentController.h"

@interface MessageRecordController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) AddTouchAreaButton *createMsgButton;
@property (nonatomic, strong) UILabel *noDataLabel;

@property (nonatomic, copy) NSString *currentSelectPhone;
@end

static NSString *strMessageRecordCell = @"MessageRecordCell";
@implementation MessageRecordController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _currentSelectPhone = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UNLogLBEProcess(@"MessageRecordController-")
    
    [self initTableView];
    [self initNoDataLabel];
    [self initRefresh];
    
    self.page = 0;
    if (!_arrMessageRecord) {
        _arrMessageRecord = [[UNDatabaseTools sharedFMDBTools] getMessageListsWithPage:self.page];
        if (_arrMessageRecord && _arrMessageRecord.count) {
            [self.tableView reloadData];
        }
        [self loadMessage];
    }

//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMessageStatu) name:@"ReceiveNewSMSContentUpdate" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMessageStatu) name:@"ReceiveNewSMSContentUpdateFromPhoneIndex" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMessageStatu) name:@"sendMessageSuccess" object:@"sendMessageSuccess"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactsInfoChange) name:@"ContactsInfoChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addressBookDidChange) name:@"addressBookChanged" object:@"addressBookChanged"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMessageStatu) name:@"UpdateMessageRecordLists" object:nil];
    
    //进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMessageStatu) name:@"appEnterForeground" object:@"appEnterForeground"];
    [self createButton];
}

//更新未读短信状态
- (void)loadUnreadMessageStatu
{
    if ([UNDataTools sharedInstance].currentUnreadSMSPhones.count) {
        [UNDataTools sharedInstance].isHasUnreadSMS = YES;
    }else{
        [UNDataTools sharedInstance].isHasUnreadSMS = NO;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PhoneUnReadMessageStatuChange" object:nil];
}

- (void)updateMessageStatu
{
    [self.tableView.mj_footer resetNoMoreData];
    [self reloadDataFromDatabase];
    [self loadMessage];
}

//- (void)updateUnReadMessageStatu
//{
//    [self.tableView.mj_footer resetNoMoreData];
//    [self reloadDataFromDatabase];
//}

//从数据库更新数据
- (void)reloadDataFromDatabase
{
    self.page = 0;
    _arrMessageRecord = [[UNDatabaseTools sharedFMDBTools] getMessageListsWithPage:self.page];
    //添加未读短信
    for (NSDictionary *dicMessageRecord in _arrMessageRecord) {
        if (![dicMessageRecord[@"IsRead"] boolValue]) {
            NSString *currentPhone;
            if ([[dicMessageRecord objectForKey:@"IsSend"] boolValue]) {
                //己方发送
                currentPhone = [dicMessageRecord objectForKey:@"To"];
            }else{
                //对方发送
                currentPhone = [dicMessageRecord objectForKey:@"Fm"];
            }
            if (_currentSelectPhone && [_currentSelectPhone isEqualToString:currentPhone]) {
                if ([[UNDataTools sharedInstance].currentUnreadSMSPhones containsObject:currentPhone]) {
                    [[UNDataTools sharedInstance].currentUnreadSMSPhones removeObject:currentPhone];
                }
                NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:dicMessageRecord];
                [mutableDict setObject:@(1) forKey:@"IsRead"];
                [[UNDatabaseTools sharedFMDBTools] insertMessageListWithMessageLists:@[mutableDict]];
            }else{
                if (![[UNDataTools sharedInstance].currentUnreadSMSPhones containsObject:currentPhone]) {
                    [[UNDataTools sharedInstance].currentUnreadSMSPhones addObject:currentPhone];
                }
            }
        }
    }
    
    if (_arrMessageRecord && _arrMessageRecord.count) {
        if (_arrMessageRecord.count >= 20) {
            self.tableView.mj_footer.hidden = NO;
        }else{
            self.tableView.mj_footer.hidden = YES;
        }
        [self.tableView reloadData];
    }
}

//- (void)updateMessgeList
//{
////    self.page = 1;
//    self.page = 0;
//    [self.tableView.mj_footer resetNoMoreData];
//    [self loadMessage];
//}

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

- (void)addressBookDidChange
{
    [self.tableView reloadData];
}

- (void)initNoDataLabel
{
    if (!_noDataLabel) {
        _noDataLabel = [[UILabel alloc] init];
        _noDataLabel.text = [NSString stringWithFormat:@"暂无短信记录\n您还没有发过短信"];
        _noDataLabel.font = [UIFont systemFontOfSize:16];
        _noDataLabel.textColor = UIColorFromRGB(0xcccccc);
        _noDataLabel.numberOfLines = 2;
        _noDataLabel.textAlignment = NSTextAlignmentCenter;
        [_noDataLabel sizeToFit];
        _noDataLabel.un_centerX = kScreenWidthValue * 0.5;
        _noDataLabel.un_centerY = (kScreenHeightValue - 64 - 49 - STATUESVIEWHEIGHT - 50) * 0.5;
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

//- (void)updateSMSContentAction
//{
//    [self loadMessage];
//}

- (void)initRefresh
{
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
//        self.page = 1;
        self.page = 0;
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
//    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
//    NewMessageViewController *newMessageViewController = [mainStory instantiateViewControllerWithIdentifier:@"newMessageViewController"];
//    if (newMessageViewController) {
//        [self.nav pushViewController:newMessageViewController animated:YES];
//    }
    
    UNMessageContentController *messageVc = [[UNMessageContentController alloc] init];
    messageVc.isNewMessage = YES;
//    CATransition *transition = [[CATransition alloc] init];
//    transition.duration =0.3f;
//    transition.type = kCATransitionMoveIn;
//    transition.subtype = kCATransitionFromTop;
//    [self.nav.view.layer addAnimation:transition forKey:kCATransition];
    [self.nav pushViewController:messageVc animated:YES];
}

//- (void)loadMessage {
//    self.checkToken = YES;
//    
//    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"pageSize",@"1",@"pageNumber", nil];
//    
//    [self getBasicHeader];
//    //    UNDebugLogVerbose(@"表演头：%@",self.headers);
//    [SSNetworkRequest getRequest:apiSMSLast params:params success:^(id responseObj) {
//        UNDebugLogVerbose(@"查询到的用户数据：%@",responseObj);
//        [self.tableView.mj_header endRefreshing];
//        if ([[responseObj objectForKey:@"status"] intValue]==1) {
//            _arrMessageRecord = [responseObj objectForKey:@"data"];
//            if (_arrMessageRecord.count>=20) {
//                self.tableView.mj_footer.hidden = NO;
//            }else{
//                self.tableView.mj_footer.hidden = YES;
//            }
//            [self.tableView reloadData];
//        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
//        }else{
//            //数据请求失败
//            UNDebugLogVerbose(@"请求短信数据失败");
//        }
//    } failure:^(id dataObj, NSError *error) {
//        [self.tableView.mj_header endRefreshing];
//    } headers:self.headers];
//}



- (void)loadMessage {
    NSString *lastTime = [[UNDatabaseTools sharedFMDBTools] getLastTimeWithMessageList];
    NSDictionary *params;
    if (lastTime) {
        params = [[NSDictionary alloc] initWithObjectsAndKeys:@"0",@"pageSize",@"0",@"pageNumber",lastTime,@"beginSMSTime", nil];
    }else{
        params = [[NSDictionary alloc] initWithObjectsAndKeys:@"0",@"pageSize",@"0",@"pageNumber", nil];
    }
    [UNNetworkManager getUrl:apiSMSLast parameters:params success:^(ResponseType type, id  _Nullable responseObj) {
        [self.tableView.mj_header endRefreshing];
        if (type == ResponseTypeSuccess) {
            if ([responseObj[@"data"] count] && ![[responseObj[@"data"] lastObject][@"SMSTime"] isEqualToString:lastTime]) {
                NSMutableArray *messageArray = [NSMutableArray arrayWithArray:responseObj[@"data"]];
                for (NSDictionary *dicMessageRecord in responseObj[@"data"]) {
                    
                    if (![dicMessageRecord[@"IsRead"] boolValue]) {
                        NSString *currentPhone;
                        if ([[dicMessageRecord objectForKey:@"IsSend"] boolValue]) {
                            //己方发送
                            currentPhone = [dicMessageRecord objectForKey:@"To"];
                        }else{
                            //对方发送
                            currentPhone = [dicMessageRecord objectForKey:@"Fm"];
                        }
                        if (_currentSelectPhone && [_currentSelectPhone isEqualToString:currentPhone]) {
                            NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:dicMessageRecord];
                            [mutableDict setObject:@(1) forKey:@"IsRead"];
                            if ([messageArray containsObject:dicMessageRecord]) {
                                [messageArray removeObject:dicMessageRecord];
                            }
                            [messageArray addObject:mutableDict];
                            
                            if ([[UNDataTools sharedInstance].currentUnreadSMSPhones containsObject:currentPhone]) {
                                [[UNDataTools sharedInstance].currentUnreadSMSPhones removeObject:currentPhone];
                            }
                        }else{
                            if (![[UNDataTools sharedInstance].currentUnreadSMSPhones containsObject:currentPhone]) {
                                [[UNDataTools sharedInstance].currentUnreadSMSPhones addObject:currentPhone];
                            }
                        }
                    }
                }
                [[UNDatabaseTools sharedFMDBTools] insertMessageListWithMessageLists:messageArray];
            }
            [self reloadDataFromDatabase];
            
            [self loadUnreadMessageStatu];
        }else if (type == ResponseTypeFailed){
            //数据请求失败
            UNDebugLogVerbose(@"请求短信数据失败");
        }
    } failure:^(NSError * _Nonnull error) {
        [self.tableView.mj_header endRefreshing];
    }];
    
//    self.checkToken = YES;
//    [self getBasicHeader];
//    [SSNetworkRequest getRequest:apiSMSLast params:params success:^(id responseObj) {
//        UNDebugLogVerbose(@"查询到的用户数据：%@",responseObj);
//        [self.tableView.mj_header endRefreshing];
//        if ([[responseObj objectForKey:@"status"] intValue]==1) {
//            if ([responseObj[@"data"] count] && ![[responseObj[@"data"] lastObject][@"SMSTime"] isEqualToString:lastTime]) {
//                NSMutableArray *messageArray = [NSMutableArray arrayWithArray:responseObj[@"data"]];
//                for (NSDictionary *dicMessageRecord in responseObj[@"data"]) {
//                    
//                    if (![dicMessageRecord[@"IsRead"] boolValue]) {
//                        NSString *currentPhone;
//                        if ([[dicMessageRecord objectForKey:@"IsSend"] boolValue]) {
//                            //己方发送
//                            currentPhone = [dicMessageRecord objectForKey:@"To"];
//                        }else{
//                            //对方发送
//                            currentPhone = [dicMessageRecord objectForKey:@"Fm"];
//                        }
//                        if (_currentSelectPhone && [_currentSelectPhone isEqualToString:currentPhone]) {
//                            NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:dicMessageRecord];
//                            [mutableDict setObject:@(1) forKey:@"IsRead"];
//                            if ([messageArray containsObject:dicMessageRecord]) {
//                                [messageArray removeObject:dicMessageRecord];
//                            }
//                            [messageArray addObject:mutableDict];
//                            
//                            if ([[UNDataTools sharedInstance].currentUnreadSMSPhones containsObject:currentPhone]) {
//                                [[UNDataTools sharedInstance].currentUnreadSMSPhones removeObject:currentPhone];
//                            }
//                        }else{
//                            if (![[UNDataTools sharedInstance].currentUnreadSMSPhones containsObject:currentPhone]) {
//                                [[UNDataTools sharedInstance].currentUnreadSMSPhones addObject:currentPhone];
//                            }
//                        }
//                    }
//                }
//                [[UNDatabaseTools sharedFMDBTools] insertMessageListWithMessageLists:messageArray];
//            }
//            [self reloadDataFromDatabase];
//            
//            [self loadUnreadMessageStatu];
//        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
//        }else{
//            //数据请求失败
//            UNDebugLogVerbose(@"请求短信数据失败");
//        }
//    } failure:^(id dataObj, NSError *error) {
//        [self.tableView.mj_header endRefreshing];
//    } headers:self.headers];
}

//短信加载更多数据
- (void)loadMoreMessage {
    if (self.tableView.mj_header.isRefreshing) {
        [self.tableView.mj_footer endRefreshing];
        return;
    }
    NSArray *pageArray = [[UNDatabaseTools sharedFMDBTools] getMessageListsWithPage:(self.page + 1)];
    if (pageArray.count > 0) {
        self.page++;
        _arrMessageRecord = [_arrMessageRecord arrayByAddingObjectsFromArray:pageArray];
        [self.tableView.mj_footer endRefreshing];
        [self.tableView reloadData];
    }else{
        [self.tableView.mj_footer endRefreshingWithNoMoreData];
    }
    
//    self.checkToken = YES;
//    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"pageSize",@(self.page+1),@"pageNumber", nil];
//    
//    [self getBasicHeader];
//    
//    [SSNetworkRequest getRequest:apiSMSLast params:params success:^(id responseObj) {
//        UNDebugLogVerbose(@"查询到的用户数据：%@",responseObj);
//        if ([[responseObj objectForKey:@"status"] intValue]==1) {
//            NSArray *arrNewMessages = [responseObj objectForKey:@"data"];
//            if (arrNewMessages.count>0) {
//                self.page = self.page + 1;
//                _arrMessageRecord = [_arrMessageRecord arrayByAddingObjectsFromArray:arrNewMessages];
//                [self.tableView.mj_footer endRefreshing];
//            }else{
//                [self.tableView.mj_footer endRefreshingWithNoMoreData];
//            }
//            
//            [self.tableView reloadData];
//            
//        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
//        }else{
//            //数据请求失败
//            HUDNormal(INTERNATIONALSTRING(@"请求失败"))
//            [self.tableView.mj_footer endRefreshing];
//        }
//        
//    } failure:^(id dataObj, NSError *error) {
//        [self.tableView.mj_footer endRefreshing];
//        HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
//    } headers:self.headers];
}

//- (void)writeMessage
//{
//    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
//    NewMessageViewController *newMessageViewController = [mainStory instantiateViewControllerWithIdentifier:@"newMessageViewController"];
//    if (newMessageViewController) {
//        //writeMessageViewController.destNumber = [dicPackage objectForKey:@"PackageId"];
//        [self.nav pushViewController:newMessageViewController animated:YES];
//    }
//}

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
    NSString *currentPhone;
    if ([[dicMessageRecord objectForKey:@"IsSend"] boolValue]) {
        //己方发送
        currentPhone = [dicMessageRecord objectForKey:@"To"];
    }else{
        //对方发送
        currentPhone = [dicMessageRecord objectForKey:@"Fm"];
    }
//    NSString *textStr = [NSString stringWithFormat:@"%@", [self compareCurrentTime:[self convertDate:[dicMessageRecord objectForKey:@"SMSTime"]]]];
    if (currentPhone) {
        cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStrMergeGroupName:currentPhone];
    }
    NSString *textStr = [[UNDataTools sharedInstance] compareCurrentTimeStringWithRecord:dicMessageRecord[@"SMSTime"]];
    cell.lblMessageDate.text = textStr;
    cell.lblContent.text = [dicMessageRecord objectForKey:@"SMSContent"];
    if (_currentSelectPhone && [_currentSelectPhone isEqualToString:currentPhone]) {
        
//        [cell.lblPhoneNumber setTextColor:UIColorFromRGB(0x333333)];
        cell.unreadMsgLabel.hidden = YES;
        if (![dicMessageRecord[@"IsRead"] boolValue]) {
            NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:dicMessageRecord];
            [mutableDict setObject:@(1) forKey:@"IsRead"];
            dicMessageRecord = mutableDict;
            [[UNDatabaseTools sharedFMDBTools] insertMessageListWithMessageLists:@[dicMessageRecord]];
        }
    }else{
        if (![dicMessageRecord[@"IsRead"] boolValue]) {
//            [cell.lblPhoneNumber setTextColor:[UIColor redColor]];
            cell.unreadMsgLabel.hidden = NO;
        }else{
//            [cell.lblPhoneNumber setTextColor:UIColorFromRGB(0x333333)];
            cell.unreadMsgLabel.hidden = YES;
        }
    }
    return cell;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    return 80;
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //消息记录，显示消息
    NSDictionary *dicMessageRecord = [_arrMessageRecord objectAtIndex:indexPath.row];
    if (![dicMessageRecord[@"IsRead"] boolValue]) {
        NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:dicMessageRecord];
        [mutableDict setObject:@(1) forKey:@"IsRead"];
        dicMessageRecord = mutableDict;
        MessageRecordCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//        [cell.lblPhoneNumber setTextColor:UIColorFromRGB(0x333333)];
        cell.unreadMsgLabel.hidden = YES;
        [[UNDatabaseTools sharedFMDBTools] insertMessageListWithMessageLists:@[dicMessageRecord]];
        [self reloadDataFromDatabase];
    }
    
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
//    if (storyboard) {
//        //            self.phoneNumber= self.phonePadView.lblPhoneNumber.text;
//        MJViewController *mjViewController = [storyboard instantiateViewControllerWithIdentifier:@"MJViewController"];
//        if (mjViewController) {
//            NSString *currentPhone;
//            if ([[dicMessageRecord objectForKey:@"IsSend"] boolValue]) {
//                //己方发送
//                currentPhone = [dicMessageRecord objectForKey:@"To"];
//            }else{
//                //对方发送
//                currentPhone = [dicMessageRecord objectForKey:@"Fm"];
//            }
//            self.currentSelectPhone = currentPhone;
//            NSString *titleName = [self checkLinkNameWithPhoneStrMergeGroupName:currentPhone];
//            mjViewController.title = titleName;
//            mjViewController.titleName = titleName;
//            mjViewController.toTelephone = currentPhone;
//            mjViewController.hidesBottomBarWhenPushed = YES;
//            [self.nav pushViewController:mjViewController animated:YES];
//        }
//    }
    
    UNMessageContentController *messageVc = [[UNMessageContentController alloc] init];
    NSString *currentPhone;
    if ([[dicMessageRecord objectForKey:@"IsSend"] boolValue]) {
        //己方发送
        currentPhone = [dicMessageRecord objectForKey:@"To"];
    }else{
        //对方发送
        currentPhone = [dicMessageRecord objectForKey:@"Fm"];
    }
    self.currentSelectPhone = currentPhone;
    NSString *titleName = [self checkLinkNameWithPhoneStrMergeGroupName:currentPhone];
    messageVc.title = titleName;
    messageVc.toPhoneName = titleName;
    messageVc.toTelephone = currentPhone;
    messageVc.hidesBottomBarWhenPushed = YES;
    [self.nav pushViewController:messageVc animated:YES];
    
    if ([[UNDataTools sharedInstance].currentUnreadSMSPhones containsObject:currentPhone]) {
        [[UNDataTools sharedInstance].currentUnreadSMSPhones removeObject:currentPhone];
    }
    [self loadUnreadMessageStatu];
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
    [UNNetworkManager postUrl:apiDeletesByTels parameters:params success:^(ResponseType type, id  _Nullable responseObj) {
        if (type == ResponseTypeSuccess) {
            [[UNDatabaseTools sharedFMDBTools] deteleMessageListWithPhoneLists:@[phoneNumber]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateUnReadForDatabase" object:nil];
            UNDebugLogVerbose(@"删除单条短信成功");
        }else if (type == ResponseTypeFailed){
            //数据请求失败
            UNDebugLogVerbose(@"删除单条短信失败");
        }
    } failure:^(NSError * _Nonnull error) {
        UNDebugLogVerbose(@"删除单条短信异常：%@",[error description]);
    }];
    
//    [self getBasicHeader];
//    [SSNetworkRequest postRequest:apiDeletesByTels params:params success:^(id responseObj) {
//        if ([[responseObj objectForKey:@"status"] intValue]==1) {
//            [[UNDatabaseTools sharedFMDBTools] deteleMessageListWithPhoneLists:@[phoneNumber]];
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateUnReadForDatabase" object:nil];
//            UNDebugLogVerbose(@"删除单条短信成功");
//        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
//        }else{
//            //数据请求失败
//            UNDebugLogVerbose(@"删除单条短信失败");
//        }
//    } failure:^(id dataObj, NSError *error) {
//        UNDebugLogVerbose(@"删除单条短信异常：%@",[error description]);
//    } headers:self.headers];
}

- (void)dealloc {
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"sendMessageSuccess" object:@"sendMessageSuccess"];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ReceiveNewSMSContentUpdate" object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addressBookChanged" object:@"addressBookChanged"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
