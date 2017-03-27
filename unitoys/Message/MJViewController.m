//
//  MJViewController.m
//  unitoys
//
//  Created by sumars on 16/10/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "MJViewController.h"
#import "MJMessage.h"
#import "MJMessageFrame.h"
#import "MJMessageCell.h"
//#import "MJRefresh.h"
#import "CustomRefreshMessageHeader.h"
#import "MessagePhoneDetailController.h"

@interface MJViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *messageFrames;

@property (nonatomic, copy) NSString *cellContent;

@property (nonatomic, assign) NSInteger page;

@end

@implementation MJViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 1.表格的设置
    // 去除分割线
    self.tableView.backgroundColor = [UIColor colorWithRed:235/255.0 green:235/255.0 blue:235/255.0 alpha:1.0];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsSelection = NO; // 不允许选中
    self.tableView.dataSource = self;  //新增
    self.tableView.delegate = self; //控制器成为代理
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:INTERNATIONALSTRING(@"详细信息") style:UIBarButtonItemStyleDone target:self action:@selector(rightBarButtonAction)];
    [self loadMessages];
    
    self.txtSendText.delegate = self;
    
//    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
//        //Call this Block When enter the refresh status automatically
//        self.arrMessageRecord = nil;
//        self.page = 1;
//        [self loadMessage];
//    }];
    self.page = 1;
    self.tableView.mj_header = [CustomRefreshMessageHeader headerWithRefreshingBlock:^{
        [self loadMoreMessage];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewFontChange) name:@"KTAutoHeightTextViewFontChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow) name:@"KeyboardWillShowFinished" object:nil];
    
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"SendMessageStatuFailed" object:@"MessageStatu" userInfo:userInfo];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendMessageStatuChange:) name:@"SendMessageStatuChange" object:@"MessageStatu"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNewSMSAction) name:@"ReceiveNewSMSContentUpdate" object:nil];
    
}

- (void)receiveNewSMSAction
{
    _messageFrames = nil;
    [self loadMessages];
}

- (void)rightBarButtonAction
{
    MessagePhoneDetailController *detailVc = [[MessagePhoneDetailController alloc] init];
    detailVc.toPhoneStr = self.toTelephone;
    [self.navigationController pushViewController:detailVc animated:YES];
}

- (void)keyboardWillShow
{
    NSLog(@"更新inputContainerView");
    NSLog(@"tableView---%@", NSStringFromCGRect(self.tableView.frame));
    NSLog(@"txtSendText---%@", NSStringFromCGRect(self.txtSendText.frame));
//    [self.tableView setNeedsLayout];
//    [self.tableView layoutIfNeeded];
    [self scrollTableViewToBottomWithAnimated:YES];
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
    
}

- (void)loadMessages{
    if (_messageFrames == nil) {
        __block NSMutableArray *dictArray = [NSMutableArray array];
        
        
        self.checkToken = YES;
        
        NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"pageSize",@"1",@"pageNumber",self.toTelephone,@"Tel", nil];
        
        [self getBasicHeader];
        NSLog(@"表演头：%@",self.headers);
        [SSNetworkRequest getRequest:apiSMSByTel params:params success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                //可通过异步处理优化
                NSArray *arrMessages = [responseObj objectForKey:@"data"];
                
//                arrMessages = [arrMessages sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
//                    
//                    NSString *time1 = [obj1 objectForKey:@"SMSTime"];
//                    NSString *time2 = [obj2 objectForKey:@"SMSTime"];
//                    
//                    NSComparisonResult result = [time1 compare:time2];
//                    return result == NSOrderedDescending; // 升序
//                    //        return result == NSOrderedAscending;  // 降序
//                }];
                //将数组倒序
                arrMessages = [[arrMessages reverseObjectEnumerator] allObjects];
                
//                for (NSDictionary *dict in arrMessages){
//                    if ([[dict objectForKey:@"Fm"] isEqualToString:self.toTelephone]) {
//                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[self compareCurrentTime:[self convertDate:[dict objectForKey:@"SMSTime"]]],@"time",@"1",@"type", nil]];
//                    } else {
//                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[self compareCurrentTime:[self convertDate:[dict objectForKey:@"SMSTime"]]],@"time",@"0",@"type", nil]];
//                    }
//                }
                
                for (NSDictionary *dict in arrMessages){
                    NSLog(@"%@", dict[@"SMSID"]);
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
            }
            
            NSLog(@"查询到的消息数据：%@",responseObj);
            
            
        } failure:^(id dataObj, NSError *error) {
            HUDNormalTop(INTERNATIONALSTRING(@"网络貌似有问题"))
            NSLog(@"啥都没：%@",[error description]);
        } headers:self.headers];
        
    }
}

//加载更多数据
- (void)loadMoreMessage
{
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"pageSize",@(self.page+1),@"pageNumber",self.toTelephone,@"Tel", nil];
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    
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
//                    if ([[dict objectForKey:@"Fm"] isEqualToString:self.toTelephone]) {
//                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[self compareCurrentTime:[self convertDate:[dict objectForKey:@"SMSTime"]]],@"time",@"1",@"type",[dict valueForKey:@"Status"], @"Status" ,[dict objectForKey:@"SMSID"],@"SMSID",nil]];
//                        
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
            HUDNormalTop(INTERNATIONALSTRING(@"请求失败"))
            [self.tableView.mj_header endRefreshing];
        }
        
    } failure:^(id dataObj, NSError *error) {
        //        [self.tableView.mj_header endRefreshing];
        [self.tableView.mj_header endRefreshing];
        HUDNormalTop(INTERNATIONALSTRING(@"网络貌似有问题"))
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
    
    // 长按菜单
    cell.longPressCellBlock = ^(NSString *content, UIView *longPressView){
        [weakSelf longPressActionWithContent:content longPressView:longPressView];
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

/**
 *  当开始拖拽表格的时候就会调用
 */
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    // 退出键盘
    [self.view endEditing:YES];
}


- (void)repeatSendMessage:(MJMessageFrame *)messageFrame
{
    self.checkToken = YES;
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:messageFrame.message.SMSID,@"SMSID", nil];
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
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

- (IBAction)sendMessage:(id)sender {
    if ([self.txtSendText.text length]>0) {
        self.btnSend.enabled = NO;
        self.checkToken = YES;
        NSString *receiveNumbers = self.toTelephone;
        
        NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:receiveNumbers,@"To",self.txtSendText.text,@"SMSContent", nil];
        
        [self getBasicHeader];
        NSLog(@"表演头：%@",self.headers);
        [SSNetworkRequest postRequest:apiSMSSend params:params success:^(id responseObj) {
            NSLog(@"查询到的用户数据：%@",responseObj);
            
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                self.txtSendText.text = @"";
                [self.txtSendText resignFirstResponder];
                
                _messageFrames = nil;
                
                [self loadMessages];
                self.btnSend.enabled = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"sendMessageSuccess" object:@"sendMessageSuccess"];
                
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
                self.btnSend.enabled = YES;
            }else{
                //数据请求失败
                HUDNormalTop(responseObj[@"msg"])
                self.btnSend.enabled = YES;
            }
            
        } failure:^(id dataObj, NSError *error) {
            HUDNormalTop(INTERNATIONALSTRING(@"网络貌似有问题"))
            NSLog(@"啥都没：%@",[error description]);
            self.btnSend.enabled = YES;
        } headers:self.headers];
    }
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
- (void)longPressActionWithContent:(NSString *)content longPressView:(UIView *)longPressView
{
    NSArray *menus = [self menusItems];
    if ([menus count] && [self becomeFirstResponder]) {
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        menuController.menuItems = menus;
        _cellContent = content;
        [menuController setTargetRect:longPressView.bounds inView:longPressView];
        [menuController setMenuVisible:YES animated:YES];
    }
}

//获取长按菜单
- (NSArray *)menusItems
{
    NSMutableArray *items = [NSMutableArray array];
    [items addObject:[[UIMenuItem alloc] initWithTitle:INTERNATIONALSTRING(@"复制") action:@selector(copyText:)]];
    return items;
}

//复制
- (void)copyText:(id)sender
{
    if (self.cellContent.length) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        [pasteboard setString:self.cellContent];
    }
}

@end


