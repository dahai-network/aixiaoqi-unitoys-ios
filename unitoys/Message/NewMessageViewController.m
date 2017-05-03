//
//  NewMessageViewController.m
//  unitoys
//
//  Created by sumars on 16/11/9.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "NewMessageViewController.h"
#import "MJMessage.h"
#import "MJMessageFrame.h"
#import "MJMessageCell.h"
#import "NSString+Addition.h"

#import "CustomRefreshMessageHeader.h"
#import "AddressBookManager.h"

#import "MessagePhoneDetailController.h"
#import "UNEditMessageView.h"
#import "ContactsCallDetailsController.h"

@interface NewMessageViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *messageFrames;

//@property (weak, nonatomic) IBOutlet UITextField *inputView;

@property (nonatomic, copy) NSString *cellContent;

@property (nonatomic, assign) NSInteger page;

@property (nonatomic, copy) NSArray *contactsLists;


@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, strong) NSMutableArray *selectRemoveData;


@property (nonatomic, strong) UIBarButtonItem *defaultLeftItem;
@property (nonatomic, strong) UIBarButtonItem *defaultRightItem;

@property (nonatomic, strong) UIBarButtonItem *editLeftItem;
@property (nonatomic, strong) UIBarButtonItem *editRightItem;

@property (nonatomic, strong) UNEditMessageView *bottomView;

@property (nonatomic, copy) NSString *toTelephone;
@end

@implementation NewMessageViewController

- (UNEditMessageView *)bottomView
{
    if (!_bottomView) {
        _bottomView = [[UNEditMessageView alloc] initWithFrame:CGRectMake(0, self.view.un_height, kScreenWidthValue, 50)];
        _bottomView.backgroundColor = [UIColor clearColor];
        kWeakSelf
        _bottomView.editMessageActionBlock = ^(NSInteger buttonTag) {
            if (buttonTag == 0) {
                [weakSelf deleteSelectSMS];
            }else if (buttonTag == 1){
                [weakSelf cancelEdit];
            }
        };
        [self.view addSubview:_bottomView];
    }
    return _bottomView;
}


- (NSArray *)contactsLists
{
    if (!_contactsLists) {
        //获取联系人信息
        _contactsLists = [[AddressBookManager shareManager].dataArr copy];
    }
    return _contactsLists;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initAllItems];
     _selectRemoveData = [NSMutableArray array];
    
    self.arrLinkman = [[NSMutableArray alloc] init];
    
    // 1.表格的设置
    // 去除分割线
//    self.tableView.backgroundColor = [UIColor colorWithRed:235/255.0 green:235/255.0 blue:235/255.0 alpha:1.0];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsSelection = NO; // 不允许选中
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.dataSource = self;  //新增
    self.tableView.delegate = self; //控制器成为代理
    
//    [self loadMessages];
    
    self.txtSendText.delegate = self;
    
    self.page = 1;
    self.tableView.mj_header = [CustomRefreshMessageHeader headerWithRefreshingBlock:^{
        [self cancelEdit];
        [self loadMoreMessage];
    }];
    
    self.txtLinkman.notifyTextFieldDelegate = self;
    [self.txtLinkman addTarget:self action:@selector(textFieldValueChange:) forControlEvents:UIControlEventEditingChanged];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewFontChange) name:@"KTAutoHeightTextViewFontChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow) name:@"KeyboardWillShowFinished" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendMessageStatuChange:) name:@"SendMessageStatuChange" object:@"MessageStatu"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNewSMSAction) name:@"ReceiveNewSMSContentUpdate" object:nil];
}

- (void)initAllItems
{
    self.defaultLeftItem = self.navigationItem.leftBarButtonItem;
//    self.defaultRightItem = [[UIBarButtonItem alloc] initWithTitle:INTERNATIONALSTRING(@"详细信息") style:UIBarButtonItemStyleDone target:self action:@selector(rightBarButtonAction)];
    self.defaultRightItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"msg_contacts_nor"] style:UIBarButtonItemStyleDone target:self action:@selector(rightBarButtonAction)];
    self.editLeftItem = [[UIBarButtonItem alloc] initWithTitle:INTERNATIONALSTRING(@"取消") style:UIBarButtonItemStyleDone target:self action:@selector(cancelEdit)];
    self.editRightItem = [[UIBarButtonItem alloc] initWithTitle:INTERNATIONALSTRING(@"全选") style:UIBarButtonItemStyleDone target:self action:@selector(selectAllCell)];
}

- (void)selectAllCell
{
    if (self.selectRemoveData.count == self.messageFrames.count) {
        return;
    }
    [self.selectRemoveData removeAllObjects];
    for (int i = 0; i < self.messageFrames.count; i ++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    [self.selectRemoveData addObjectsFromArray:self.messageFrames];
}

- (void)beComeEditMode
{
    self.bottomInputView.hidden = YES;
    [self showEditView];
    self.navigationItem.leftBarButtonItem = self.editLeftItem;
    self.navigationItem.rightBarButtonItem = self.editRightItem;
    [self.selectRemoveData removeAllObjects];
    [self.tableView setEditing:YES animated:YES];
}

- (void)cancelEdit
{
    self.bottomInputView.hidden = NO;
    [self hideEditView];
    self.navigationItem.leftBarButtonItem = self.defaultLeftItem;
    self.navigationItem.rightBarButtonItem = self.defaultRightItem;
    [self.selectRemoveData removeAllObjects];
    [self.tableView setEditing:NO animated:YES];
}

- (void)deleteSelectSMS
{
    if (self.selectRemoveData.count) {
        NSLog(@"删除多条短信---%@", self.selectRemoveData);
        NSMutableArray *smsArray = [NSMutableArray array];
        for (MJMessageFrame *messageFrame in self.selectRemoveData) {
            [smsArray addObject:messageFrame.message.SMSID];
        }
        [self deleteMessageSWithDatas:[self.selectRemoveData copy] SMSIds:[smsArray copy]];
        
        [self cancelEdit];
    }
}

- (void)showEditView
{
    [self bottomView];
    [UIView animateWithDuration:0.3 animations:^{
        self.bottomView.un_top = self.view.un_height - self.bottomView.un_height;
    }];
}

- (void)hideEditView
{
    [UIView animateWithDuration:0.3 animations:^{
        self.bottomView.un_top = self.view.un_height;
    } completion:^(BOOL finished) {
        if (finished) {
            [_bottomView removeFromSuperview];
            _bottomView = nil;
        }
    }];
}


- (void)receiveNewSMSAction
{
    _messageFrames = nil;
    [self loadMessages];
}

- (void)rightBarButtonAction
{
    if ([self.toTelephone containsString:@","]) {
        MessagePhoneDetailController *detailVc = [[MessagePhoneDetailController alloc] init];
        detailVc.toPhoneStr = self.toTelephone;
        [self.navigationController pushViewController:detailVc animated:YES];
    }else{
        kWeakSelf
        ContactsCallDetailsController *callDetailsVc = [[ContactsCallDetailsController alloc] init];
        callDetailsVc.contactsInfoUpdateBlock = ^(NSString *nickName, NSString *phoneNumber) {
            if (nickName) {
                weakSelf.title = nickName;
            }else{
                weakSelf.title = phoneNumber;
            }
            //号码不可更改
//            weakSelf.toTelephone = phoneNumber;
        };
        callDetailsVc.contactModel = [self checkContactModelWithPhoneStr:self.toTelephone];
        callDetailsVc.nickName = self.title;
        callDetailsVc.phoneNumber = self.toTelephone;
        [self.navigationController pushViewController:callDetailsVc animated:YES];
    }
}

- (void)textViewFontChange
{
    NSLog(@"更新inputContainerView");
    NSLog(@"tableView---%@", NSStringFromCGRect(self.tableView.frame));
    NSLog(@"txtSendText---%@", NSStringFromCGRect(self.txtSendText.frame));
    [self.tableView setNeedsLayout];
    [self.tableView layoutIfNeeded];
    [self scrollTableViewToBottomWithAnimated:NO];
}

- (void)keyboardWillShow
{
    NSLog(@"更新inputContainerView");
    NSLog(@"tableView---%@", NSStringFromCGRect(self.tableView.frame));
    NSLog(@"txtSendText---%@", NSStringFromCGRect(self.txtSendText.frame));
//    [self.tableView layoutIfNeeded];
    [self scrollTableViewToBottomWithAnimated:NO];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.navigationController.hidesBottomBarWhenPushed = NO;
}

- (void)sendMessageStatuChange:(NSNotification *)noti
{
    NSDictionary *userInfo = noti.userInfo;
    NSDictionary *extras = [userInfo valueForKey:@"extras"];
    NSString *smsId = [extras valueForKey:@"SMSID"];
    __block MJMessageStatu statu = (MJMessageStatu)[[extras valueForKey:@"Status"] integerValue];
    kWeakSelf
    [_messageFrames enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(MJMessageFrame *messageFrame, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([messageFrame.message.SMSID isEqualToString:smsId]) {
            if (statu != messageFrame.message.Status) {
                NSLog(@"短信状态改变");
                messageFrame.message.Status = statu;
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
                [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                *stop = YES;
            }
        }
    }];
    [self updateMessageList];
}

- (void)loadMessages{
    if (_messageFrames == nil) {
        __block NSMutableArray *dictArray = [[NSMutableArray alloc] init];
        
        self.checkToken = YES;
        if (self.linkManTele) {
            NSString *name = [self getLinkmans];
//            if ([name containsString:@" "]) {
//                NSString *teleStr = [name substringToIndex:[name rangeOfString:@" "].location];
//                self.title = teleStr;
//            } else {
//              self.title = name;
//            }
            self.title = name;
        } else {
            self.title = INTERNATIONALSTRING(@"新信息");
        }
        NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"pageSize",@"1",@"pageNumber",self.linkManTele,@"Tel", nil];
        
        [self getBasicHeader];
//        NSLog(@"表演头：%@",self.headers);
        kWeakSelf
        [SSNetworkRequest getRequest:apiSMSByTel params:info success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                
                NSArray *arrMessages = [responseObj objectForKey:@"data"];
                weakSelf.toTelephone = weakSelf.linkManTele;
                weakSelf.navigationItem.rightBarButtonItem = weakSelf.defaultRightItem;
                //排序
//                arrMessages = [arrMessages sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
//                    
//                    NSString *time1 = [obj1 objectForKey:@"SMSTime"];
//                    NSString *time2 = [obj2 objectForKey:@"SMSTime"];
//                    
//                    NSComparisonResult result = [time1 compare:time2];
//                    return result == NSOrderedDescending; // 升序
//                    //        return result == NSOrderedAscending;  // 降序
//                }];
                arrMessages = [[arrMessages reverseObjectEnumerator] allObjects];
                
                for (NSDictionary *dict in arrMessages){
//                    if ([[dict objectForKey:@"Fm"] isEqualToString:self.title]) {
//                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[self compareCurrentTime:[self convertDate:[dict objectForKey:@"SMSTime"]]],@"time",@"1",@"type",dict[@"Status"], @"Status" ,[dict objectForKey:@"SMSID"],@"SMSID",nil]];
//                    } else {
//                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[self compareCurrentTime:[self convertDate:[dict objectForKey:@"SMSTime"]]],@"time",@"0",@"type",dict[@"Status"],@"Status", [dict objectForKey:@"SMSID"],@"SMSID",nil]];
//                    }
                    if ([[dict objectForKey:@"IsSend"] boolValue]) {
                        //己方发送
                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[self compareCurrentTime:[self convertDate:[dict objectForKey:@"SMSTime"]]],@"time",@"0",@"type",dict[@"Status"],@"Status", [dict objectForKey:@"SMSID"],@"SMSID",nil]];
                    }else{
                        //对方发送
                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[self compareCurrentTime:[self convertDate:[dict objectForKey:@"SMSTime"]]],@"time",@"1",@"type",dict[@"Status"], @"Status" ,[dict objectForKey:@"SMSID"],@"SMSID",nil]];
                    }
                }
                
                NSMutableArray *mfArray = [NSMutableArray array];
                
                for (NSDictionary *dict in dictArray) {
                    // 消息模型
                    MJMessage *msg = [MJMessage messageWithDict:dict];
                    
                    // 取出上一个模型
                    MJMessageFrame *lastMf = [mfArray lastObject];
                    MJMessage *lastMsg = lastMf.message;
                    
                    // 判断两个消息的时间是否一致
                    msg.hideTime = [msg.time isEqualToString:lastMsg.time];
                    
                    // frame模型
                    MJMessageFrame *mf = [[MJMessageFrame alloc] init];
                    mf.message = msg;
                    
                    // 添加模型
                    [mfArray addObject:mf];
                }
                
                _messageFrames = mfArray;
                self.page = 1;
                [self.tableView reloadData];
                
                //自动滚动到底部
                [self scrollTableViewToBottomWithAnimated:NO];
                
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
            }
            
            NSLog(@"查询到的消息数据：%@",responseObj);
            
            
        } failure:^(id dataObj, NSError *error) {
            //
            NSLog(@"啥都没：%@",[error description]);
        } headers:self.headers];
        
        /*[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"messages.plist" ofType:nil]];*/
    }
}


//加载更多数据
- (void)loadMoreMessage
{
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"pageSize",@(self.page+1),@"pageNumber",self.linkManTele,@"Tel", nil];
    
    [self getBasicHeader];
//    NSLog(@"表演头：%@",self.headers);
    
    [SSNetworkRequest getRequest:apiSMSByTel params:params success:^(id responseObj) {
        
        NSLog(@"查询到的用户数据：%@",responseObj);
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            NSMutableArray *dictArray = [NSMutableArray array];
            NSArray *arrNewMessages = [responseObj objectForKey:@"data"];
            if (arrNewMessages.count) {
                //将数组倒序
                arrNewMessages = [[arrNewMessages reverseObjectEnumerator] allObjects];
                
                //                for (NSDictionary *dict in arrNewMessages){
                //                    if ([[dict objectForKey:@"Fm"] isEqualToString:self.toTelephone]) {
                //                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[self compareCurrentTime:[self convertDate:[dict objectForKey:@"SMSTime"]]],@"time",@"1",@"type", nil]];
                //                    } else {
                //                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[self compareCurrentTime:[self convertDate:[dict objectForKey:@"SMSTime"]]],@"time",@"0",@"type", nil]];
                //                    }
                //                }
                
                for (NSDictionary *dict in arrNewMessages){
//                    if ([[dict objectForKey:@"Fm"] isEqualToString:self.linkManTele]) {
//                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[self compareCurrentTime:[self convertDate:[dict objectForKey:@"SMSTime"]]],@"time",@"1",@"type",[dict valueForKey:@"Status"], @"Status" ,[dict objectForKey:@"SMSID"],@"SMSID",nil]];
//                    } else {
//                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[self compareCurrentTime:[self convertDate:[dict objectForKey:@"SMSTime"]]],@"time",@"0",@"type", [dict valueForKey:@"Status"], @"Status",[dict objectForKey:@"SMSID"],@"SMSID", nil]];
//                    }
                    if ([[dict objectForKey:@"IsSend"] boolValue]) {
                        //己方发送
                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[self compareCurrentTime:[self convertDate:[dict objectForKey:@"SMSTime"]]],@"time",@"0",@"type",dict[@"Status"],@"Status", [dict objectForKey:@"SMSID"],@"SMSID",nil]];
                    }else{
                        //对方发送
                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[self compareCurrentTime:[self convertDate:[dict objectForKey:@"SMSTime"]]],@"time",@"1",@"type",dict[@"Status"], @"Status" ,[dict objectForKey:@"SMSID"],@"SMSID",nil]];
                    }
                }
                
                NSMutableArray *mfArray = [NSMutableArray array];
                for (NSDictionary *dict in dictArray) {
                    // 消息模型
                    MJMessage *msg = [MJMessage messageWithDict:dict];
                    // 取出上一个模型
                    MJMessageFrame *lastMf = [mfArray lastObject];
                    MJMessage *lastMsg = lastMf.message;
                    // 判断两个消息的时间是否一致
                    msg.hideTime = [msg.time isEqualToString:lastMsg.time];
                    // frame模型
                    MJMessageFrame *mf = [[MJMessageFrame alloc] init];
                    mf.message = msg;
                    // 添加模型
                    [mfArray addObject:mf];
                }
                
                if (mfArray.count>0) {
                    self.page = self.page + 1;
                    NSIndexSet *indexs = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, mfArray.count)];
                    [_messageFrames insertObjects:mfArray atIndexes:indexs];
                    
                    [self.tableView.mj_header endRefreshing];
                    [self.tableView reloadData];
                    
                    //移动到当前查看位置
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:mfArray.count inSection:0];
                    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
                }else{
                    [self.tableView.mj_header endRefreshing];
                }
            }else{
                NSLog(@"无更多数据加载");
                [self.tableView.mj_header endRefreshing];
            }
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            [self.tableView.mj_header endRefreshing];
        }
        
    } failure:^(id dataObj, NSError *error) {
        //        [self.tableView.mj_header endRefreshing];
        [self.tableView.mj_header endRefreshing];
    } headers:self.headers];
    
}

//自动滚动到底部
- (void)scrollTableViewToBottomWithAnimated:(BOOL)animated
{
    //自动滚动到底部
    if ([self.messageFrames count]) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messageFrames.count - 1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

- (NSMutableArray *)messageFrames
{
    return _messageFrames;
}

#pragma mark - 数据源方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messageFrames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    kWeakSelf
    // 1.创建cell
    MJMessageCell *cell = [MJMessageCell cellWithTableView:tableView];
    
    // 2.给cell传递模型
    cell.messageFrame = self.messageFrames[indexPath.row];
    cell.tag = indexPath.row;
    cell.longPressCellBlock = ^(NSInteger index, NSString *content, UIView *longPressView){
//        [weakSelf longPressActionWithContent:content longPressView:longPressView];
        [weakSelf longPressActionWithIndex:index Content:content longPressView:longPressView];
    };
    //重发短信
    cell.repeatSendMessageBlock = ^(MJMessageFrame *messageFrame){
        [weakSelf repeatSendMessage:messageFrame];
    };
    // 3.返回cell
    return cell;
}

#pragma mark - 代理方法
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MJMessageFrame *mf = self.messageFrames[indexPath.row];
    return mf.cellHeight;
}

//禁止编辑状态缩进
- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    MJMessageFrame *messageFrame = self.messageFrames[indexPath.row];
    if (messageFrame.message.type == MJMessageTypeOther) {
        return YES;
    }else{
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRowAtIndexPath---%ld", indexPath.row);
    if (self.tableView.isEditing) {
        [self.selectRemoveData addObject:self.messageFrames[indexPath.row]];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didDeselectRowAtIndexPath---%ld", indexPath.row);
    if (self.tableView.isEditing) {
        if ([self.selectRemoveData containsObject:self.messageFrames[indexPath.row]]) {
            [self.selectRemoveData removeObject:self.messageFrames[indexPath.row]];
        }
    }
}

#pragma mark - 编辑状态
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
}


- (void)repeatSendMessage:(MJMessageFrame *)messageFrame
{
    self.checkToken = YES;
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:messageFrame.message.SMSID,@"SMSID", nil];
    
    [self getBasicHeader];
//    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest postRequest:apiSendRetryForError params:params success:^(id responseObj) {
        //
        //KV来存放数组，所以要用枚举器来处理
        /*
         NSEnumerator *enumerator = [[responseObj objectForKey:@"data"] keyEnumerator];
         id key;
         while ((key = [enumerator nextObject])) {
         [manager.requestSerializer setValue:[headers objectForKey:key] forHTTPHeaderField:key];
         }*/
        
        NSLog(@"查询到的用户数据：%@",responseObj);
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            //                [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"发送成功" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
            //                HUDNormal(@"发送成功")
            _messageFrames = nil;
            
            [self loadMessages];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"sendMessageSuccess" object:@"sendMessageSuccess"];
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            HUDNormalTop(responseObj[@"msg"])
        }
        
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}


/**
 *  当开始拖拽表格的时候就会调用
 */

 - (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
 {
 // 退出键盘
 [self.view endEditing:YES];
 }

- (IBAction)addLinkman:(id)sender {
    [self.txtLinkman endEditing:YES];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if (storyboard) {
        
        ContactsViewController *contactsViewController = [storyboard instantiateViewControllerWithIdentifier:@"contactsViewController"];
        if (contactsViewController) {
            contactsViewController.bOnlySelectNumber = YES;
            contactsViewController.delegate = self;
            [self.navigationController pushViewController:contactsViewController animated:YES];
        }
    }
    
}

//- (IBAction)messageChange:(id)sender {
//    if ([self.txtSendText.text length]) {
//        [_btnSend setTitleColor:[UIColor colorWithRed:43/255.0 green:182/255.0 blue:35/255.0 alpha:1] forState:UIControlStateNormal];
//    }else{
//        [_btnSend setTitleColor:[UIColor colorWithRed:159/255.0 green:159/255.0 blue:159/255.0 alpha:1] forState:UIControlStateNormal];
//    }
//}

- (IBAction)sendMessage:(id)sender {
    NSString *receiveNumbers;
     if ([self.txtSendText.text length]>0) {
         self.btnSend.enabled = NO;
         self.checkToken = YES;
         if (![self.txtLinkman.text isValidateMobile]) {
             receiveNumbers = [self getNumbers];
         } else {
             receiveNumbers = self.txtLinkman.text;
         }
//         if ([receiveNumbers containsString:@","]) {
//             NSString *firstStr = [receiveNumbers substringWithRange:NSMakeRange(0, 11)];
//             self.linkManTele = firstStr;
//         } else {
//             self.linkManTele = receiveNumbers;
//         }
         self.linkManTele = receiveNumbers;
         NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:receiveNumbers,@"To",self.txtSendText.text,@"SMSContent", nil];
         
         [self getBasicHeader];
         [SSNetworkRequest postRequest:apiSMSSend params:info success:^(id responseObj) {
             NSLog(@"查询到的用户数据：%@",responseObj);
             
             if ([[responseObj objectForKey:@"status"] intValue]==1) {
            //     [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"发送成功" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
            //     HUDNormal(@"发送成功")
                 self.txtSendText.text = @"";
                 [self.txtSendText resignFirstResponder];
                 _messageFrames = nil;
                 
                 //隐藏发送textfield
                 self.topEditMessageViewHeight.constant = 0;
                 self.topEditMessageView.hidden = YES;
                 
                 [self loadMessages];
                self.btnSend.enabled = YES;
             [[NSNotificationCenter defaultCenter] postNotificationName:@"sendMessageSuccess" object:@"sendMessageSuccess"];
                 
             }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
                 self.btnSend.enabled = YES;
             }else{
             //数据请求失败
        //     [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
                 HUDNormalTop(responseObj[@"msg"])
                 self.btnSend.enabled = YES;
             }
         } failure:^(id dataObj, NSError *error) {
             HUDNormalTop(INTERNATIONALSTRING(@"网络貌似有问题"))
            self.btnSend.enabled = YES;
         } headers:self.headers];
     }
}

- (IBAction)editedLinkman:(id)sender {
    
    NSLog(@"编辑结束");
    //开始验证文本框中的联系人与数据是否匹配，不匹配则更新
    [self pairLinkman];
    
    //更新联系人列表并修改颜色
//    self.txtLinkman.text = [self getLinkmans];
    self.txtLinkman.text = [self checkLinkmans];
    self.txtLinkman.textColor = [UIColor colorWithRed:43/255.0 green:182/255.0 blue:35/255.0 alpha:1];
    [self.txtLinkman resignFirstResponder];
}

//- (void)checkInputNumber
//{
//    if (self.txtLinkman.text.length) {
//        if ([self.txtLinkman.text containsString:@" "]) {
//            NSMutableString *linkName = [NSMutableString string];
//            NSArray *strArray = [self.txtLinkman.text componentsSeparatedByString:@" "];
//            for (NSString *string in strArray) {
//                if (string.length) {
//                    
//                }
//            }
//        }else{
//            
//        }
//    }
//}

- (IBAction)beginEditLinkman:(id)sender {
    NSLog(@"开始编辑");
    self.txtLinkman.textColor = [UIColor blackColor];
    if (self.txtLinkman.text.length && ![self.txtLinkman.text isEqualToString:@" "]) {
       self.txtLinkman.text = [self.txtLinkman.text stringByAppendingString:@" "];
    }
}

- (void)deleteBackward {  //删除响应
    //如果是名字则删除联系人，如果是号码则可以部份删除
    NSLog(@"删除号码");
    
    if (self.txtLinkman.selectedRange.location==self.txtLinkman.text.length) {
        //删除最后一个人
        NSString *initLinkman = self.txtLinkman.text;
        
        NSMutableArray *mans = [[NSMutableArray alloc] initWithArray:[initLinkman componentsSeparatedByString:@" "]];
        
        
        if ([self isPureInt:[mans lastObject]]) {
            //删除号位，更新数据
            [self.arrLinkman removeLastObject];
            [self pairLinkman];
        }else
        if (self.txtLinkman.text.length>0) {
            [self.arrLinkman removeLastObject];
            self.txtLinkman.text = [self getLinkmans];
        }
    }else if ([[self.txtLinkman.text substringWithRange:NSMakeRange(self.txtLinkman.selectedRange.location, 1)] isEqualToString:@" "]){
        //检查前一个人是不是号码，如果是号码则仅删除数字，否则删除联系人和文本修改设定光标
        if (self.txtLinkman.text.length>0) {
            //            NSString *prevLinkman = [self.txtLinkman.text substringWithRange:NSMakeRange(0, self.txtLinkman.selectedRange.location)];
            
            NSString *initLinkman = [[self getLinkmans] substringWithRange:NSMakeRange(0, self.txtLinkman.selectedRange.location)];
            
            NSMutableArray *mans = [[NSMutableArray alloc] initWithArray:[initLinkman componentsSeparatedByString:@" "]];
            
            
            if ([self isPureInt:[mans lastObject]]) {
                //删除号位，更新数据
                [self pairLinkman];
            }else{
                //删除这个联系人..要好看就处理下光标
                [self.arrLinkman removeObjectAtIndex:mans.count-1];
                self.txtLinkman.text = [self getLinkmans];

                [mans removeLastObject];
                
                [self.txtLinkman setSelectedRange:NSMakeRange([[mans componentsJoinedByString:@" "] length], 0)];
            }
            
            
        }
    }else if ([[self.txtLinkman.text substringWithRange:NSMakeRange(self.txtLinkman.selectedRange.location-1, 1)] isEqualToString:@" "]){
        //检查前一个人是不是号码，如果是号码则仅删除数字，否则删除联系人和文本修改设定光标
        if (self.txtLinkman.text.length>0) {
            //            NSString *prevLinkman = [self.txtLinkman.text substringWithRange:NSMakeRange(0, self.txtLinkman.selectedRange.location)];
            
            NSString *initLinkman = [[self getLinkmans] substringWithRange:NSMakeRange(0, self.txtLinkman.selectedRange.location-1)];
            
            NSMutableArray *mans = [[NSMutableArray alloc] initWithArray:[initLinkman componentsSeparatedByString:@" "]];
            
            
            if ([self isPureInt:[mans lastObject]]) {
                //删除号位，更新数据
                //                [self pairLinkman];
                self.txtLinkman.text = [self getLinkmans];
                [self.txtLinkman setSelectedRange:NSMakeRange([[mans componentsJoinedByString:@" "] length], 0)];
            }else{
                //删除这个联系人..要好看就处理下光标
                [self.arrLinkman removeObjectAtIndex:mans.count-1];
                self.txtLinkman.text = [self getLinkmans];
                //
                [mans removeLastObject];
                
                [self.txtLinkman setSelectedRange:NSMakeRange([[mans componentsJoinedByString:@" "] length], 0)];
            }
            
        }
    }
}

- (void)updateLinkmanWithDelete
{
    [self.arrLinkman removeAllObjects];
    [self pairLinkman];
}

- (void)pairLinkman {  //配对联系人
    NSLog(@"配对联系");
    if (![[self getLinkmans] isEqualToString:self.txtLinkman.text]) {
        NSArray *numbers = [self.txtLinkman.text componentsSeparatedByString:@" "];
//        if (self.arrLinkman.count==0) {
        if (numbers.count==1) {
            //添加所有
            NSMutableDictionary *dicNumber = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[numbers firstObject],@"linkman",[numbers firstObject],@"number", nil];
            [self.arrLinkman addObject:dicNumber];
            //            self.txtLinkman.text = [self getLinkmans];
        }else if (numbers.count==self.arrLinkman.count){
            //更新即可
//            for (int i=0; i<self.arrLinkman.count; i++) {
//                NSMutableDictionary *dicNumber = [self.arrLinkman objectAtIndex:i];
//                
//                if ([[dicNumber objectForKey:@"linkman"] isEqualToString:[dicNumber objectForKey:@"number"]]) {
//                    [dicNumber setObject:[numbers objectAtIndex:i] forKey:@"number"];
//                    [dicNumber setObject:[numbers objectAtIndex:i] forKey:@"linkman"]; //如果是相同说明是号码，则更新两项，否则只更新号码
//                }else{
//                    [dicNumber setObject:[numbers objectAtIndex:i] forKey:@"number"];
//                }
//                
//                [self.arrLinkman replaceObjectAtIndex:i withObject:dicNumber];
//                //                NSLog(@"更新后的数据：%@",[self getLinkmans]);
//            }
        }else if (numbers.count > self.arrLinkman.count){
            
            NSMutableArray *tempArray = [NSMutableArray array];
            
            for (NSInteger i = self.arrLinkman.count; i < numbers.count; i++) {
                //联系人数量有变化？
                NSString *phoneNum = [numbers objectAtIndex:i];
                if (phoneNum.length && ![phoneNum isEqualToString:@" "]) {
                    BOOL isRepeat = NO;
                    for (NSDictionary *dict in self.arrLinkman) {
                        if ([[dict objectForKey:@"number"] isEqualToString:phoneNum]) {
                            isRepeat = YES;
                            break;
                        }
                    }
                    if (!isRepeat) {
                        NSMutableDictionary *dicNumber = [[NSMutableDictionary alloc] initWithObjectsAndKeys:phoneNum,@"linkman",phoneNum,@"number", nil];
                        [tempArray addObject:dicNumber];
                    }
                }
            }
            if (tempArray.count) {
               [self.arrLinkman addObjectsFromArray:tempArray];
            }
        }
    }
}

- (void)textFieldValueChange:(UITextField *)textField
{
    NSLog(@"%@", textField.text);
}

- (BOOL)isPureInt:(NSString*)string{
    NSScanner* scan = [NSScanner scannerWithString:string];
    int val;
    return[scan scanInt:&val] && [scan isAtEnd];
}



#pragma mark --PhoneNumberSelectDelegate
- (void)didSelectPhoneNumber:(NSString *)phoneNumber {
    NSLog(@"选择号码");
    //    NSLog(@"添加联系人：%@",phoneNumber);
    NSArray * arrNumberInfo = [phoneNumber componentsSeparatedByString:@"|"];
    if ([arrNumberInfo count]==2) {
        //判断号码是否重复
        for (NSDictionary *dict in self.arrLinkman) {
            if ([[arrNumberInfo objectAtIndex:1] isEqualToString:[dict objectForKey:@"number"]]) {
                HUDNormal(INTERNATIONALSTRING(@"请勿选择重复的联系人"))
                return;
            }
        }
        
        NSMutableDictionary *dicNumber = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[arrNumberInfo objectAtIndex:0],@"linkman",[arrNumberInfo objectAtIndex:1],@"number", nil];
        [self.arrLinkman addObject:dicNumber];
    }
    
//    self.txtLinkman.text = [self getLinkmans];
    self.txtLinkman.text = [self checkLinkmans];
    [self editedLinkman:self];
}

- (NSString *)getLinkmans {
    NSString *linkmans = @"";
    for (NSDictionary *dicNumber in self.arrLinkman) {
        if ([linkmans isEqualToString:@""]) {
            linkmans = [dicNumber objectForKey:@"linkman"];
        }else {
            linkmans = [NSString stringWithFormat:@"%@ %@",linkmans,[dicNumber objectForKey:@"linkman"]];
        }
    }
    return linkmans;
}

- (NSString *)checkLinkmans
{
    NSString *linkmans = @"";
    for (NSMutableDictionary *dicNumber in self.arrLinkman) {
        if ([[dicNumber objectForKey:@"linkman"] isEqualToString:[dicNumber objectForKey:@"number"]]) {
            NSString *matchingName = [self getMatchingName:[dicNumber objectForKey:@"number"]];
            if (![[dicNumber objectForKey:@"number"] isEqualToString:matchingName]) {
                [dicNumber setObject:matchingName forKey:@"linkman"];
            }
        }
        
        if ([linkmans isEqualToString:@""]) {
            linkmans = [dicNumber objectForKey:@"linkman"];
        }else {
            linkmans = [NSString stringWithFormat:@"%@ %@",linkmans,[dicNumber objectForKey:@"linkman"]];
        }
    }
    return linkmans;
}

- (NSString *)getMatchingName:(NSString *)phoneNumber
{
    return [self checkLinkNameWithPhoneStr:phoneNumber];
}

- (NSString *)getNumbers {
    NSString *numbers = @"";
    for (NSDictionary *dicNumber in self.arrLinkman) {
        if ([numbers isEqualToString:@""]) {
            numbers = [dicNumber objectForKey:@"number"];
            if ([numbers containsString:@"-"]) {
                NSString *newNumber = [numbers stringByReplacingOccurrencesOfString:@"-" withString:@""];
                numbers = newNumber;
            }
            if ([numbers containsString:@" "]) {
                NSString *newNumber = [numbers stringByReplacingOccurrencesOfString:@" " withString:@""];
                numbers = newNumber;
            }
            if ([numbers containsString:@"+86"]) {
                NSString *newNumber = [numbers stringByReplacingOccurrencesOfString:@"+86" withString:@""];
                numbers = newNumber;
            }
        }else {
            numbers = [NSString stringWithFormat:@"%@,%@",numbers,[dicNumber objectForKey:@"number"]];
            
        }
    }
    return numbers;
}



- (void)textViewDidChange:(UITextView *)textView {
    if ([self.txtSendText.text length]) {
        [_btnSend setTitleColor:[UIColor colorWithRed:43/255.0 green:182/255.0 blue:35/255.0 alpha:1] forState:UIControlStateNormal];
    }else{
        [_btnSend setTitleColor:[UIColor colorWithRed:159/255.0 green:159/255.0 blue:159/255.0 alpha:1] forState:UIControlStateNormal];
    }
}

//设置响应
-(BOOL)canBecomeFirstResponder
{
    return YES;
}

//长按响应
- (void)longPressActionWithIndex:(NSInteger)index Content:(NSString *)content longPressView:(UIView *)longPressView
{
    NSArray *menus = [self menusItems];
    if ([menus count] && [self becomeFirstResponder]) {
        UIWindow *window = [[UIApplication sharedApplication].delegate window];
        if ([window isKeyWindow] == NO)
        {
            [window becomeKeyWindow];
            [window makeKeyAndVisible];
        }
        
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        menuController.menuItems = menus;
        _cellContent = content;
        _currentIndex = index;
        [menuController setTargetRect:longPressView.bounds inView:longPressView];
        [menuController setMenuVisible:YES animated:YES];
    }
}

//获取长按菜单
- (NSArray *)menusItems
{
    NSMutableArray *items = [NSMutableArray array];
    [items addObject:[[UIMenuItem alloc] initWithTitle:INTERNATIONALSTRING(@"复制") action:@selector(copyText:)]];
    [items addObject:[[UIMenuItem alloc] initWithTitle:INTERNATIONALSTRING(@"删除") action:@selector(deleteText:)]];
    [items addObject:[[UIMenuItem alloc] initWithTitle:INTERNATIONALSTRING(@"更多") action:@selector(deleteSelectText:)]];
    return items;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender{
    if (action == @selector(copyText:) || action == @selector(deleteText:) || action == @selector(deleteSelectText:)){
        return YES;
    }
    return NO;//隐藏系统默认的菜单项
}

//复制
- (void)copyText:(id)sender
{
    if (self.cellContent.length) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        [pasteboard setString:self.cellContent];
    }
}

- (void)deleteText:(id)sender
{
    NSLog(@"当前删除短信%@", self.messageFrames[_currentIndex]);
    if (_currentIndex < self.messageFrames.count) {
        MJMessageFrame *messageFrame = self.messageFrames[_currentIndex];
        [self deleteMessageWithSMSId:messageFrame.message.SMSID Index:_currentIndex];
    }
}

- (void)deleteSelectText:(id)sender
{
    [self beComeEditMode];
}

- (void)deleteMessageWithSMSId:(NSString *)smsId Index:(NSInteger)index
{
    kWeakSelf
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys: @[smsId] ,@"Ids",nil];
    [self getBasicHeader];
    [SSNetworkRequest postRequest:apiDeletes params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"删除单条短信成功");
//            [weakSelf.messageFrames removeObjectAtIndex:index];
//            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
//            [weakSelf.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            if ((weakSelf.messageFrames.count == index + 1) || weakSelf.messageFrames.count == 1) {
                //刷新外部界面
                [weakSelf updateMessageList];
            }
            NSLog(@"删除单条短信成功");
            if (weakSelf.messageFrames.count > index) {
                [weakSelf.messageFrames removeObjectAtIndex:index];
            }
            [weakSelf.tableView reloadData];
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

- (void)deleteMessageSWithDatas:(NSArray *)Datas SMSIds:(NSArray *)smsIds
{
    kWeakSelf
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys: smsIds ,@"Ids",nil];
    [self getBasicHeader];
    [SSNetworkRequest postRequest:apiDeletes params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"删除多条短信成功");
//            NSMutableArray *indexPathsArray = [NSMutableArray array];
//            for (MJMessageFrame *messageFrame in Datas) {
//                //刷新外部界面
//                [weakSelf updateMessageList];
//                
//                NSInteger row = [weakSelf.messageFrames indexOfObject:messageFrame];
//                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
//                [indexPathsArray addObject:indexPath];
//            }
//            if (indexPathsArray.count) {
//                [weakSelf.messageFrames removeObjectsInArray:Datas];
//                [weakSelf.tableView deleteRowsAtIndexPaths:indexPathsArray withRowAnimation:UITableViewRowAnimationAutomatic];
//            }
            //刷新外部界面
            [weakSelf updateMessageList];
            
            [weakSelf.messageFrames removeObjectsInArray:Datas];
            [weakSelf.tableView reloadData];
            //自动滚动到底部
            [self scrollTableViewToBottomWithAnimated:NO];
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            NSLog(@"删除多条短信失败");
        }
    } failure:^(id dataObj, NSError *error) {
        NSLog(@"删除单条短信异常：%@",[error description]);
    } headers:self.headers];
}

- (void)updateMessageList
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateMessageRecordLists" object:nil];
}
@end
