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

#import "UNEditMessageView.h"
#import "ContactsCallDetailsController.h"
#import "ContactsDetailViewController.h"
#import "UNDataTools.h"
#import "UNDatabaseTools.h"
#import "UNConvertFormatTool.h"

@interface MJViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *messageFrames;
@property (nonatomic, strong) NSMutableArray *messageDict;

@property (nonatomic, copy) NSString *cellContent;

@property (nonatomic, assign) NSInteger page;

@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, strong) NSMutableArray *selectRemoveData;


@property (nonatomic, strong) UIBarButtonItem *defaultLeftItem;
@property (nonatomic, strong) UIBarButtonItem *defaultRightItem;

@property (nonatomic, strong) UIBarButtonItem *editLeftItem;
@property (nonatomic, strong) UIBarButtonItem *editRightItem;

@property (nonatomic, strong) UNEditMessageView *bottomView;

//是否当前页码有发送成功短信
@property (nonatomic, assign) BOOL isHasSuccessMsg;
@property (nonatomic, assign) BOOL isFristSend;
@end

@implementation MJViewController

- (UNEditMessageView *)bottomView
{
    if (!_bottomView) {
        _bottomView = [[UNEditMessageView alloc] initWithFrame:CGRectMake(0, self.view.un_height, kScreenWidthValue, self.bottomInputView.un_height)];
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


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initAllItems];
    
    _selectRemoveData = [NSMutableArray array];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsSelection = NO; // 不允许选中
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.dataSource = self;  //新增
    self.tableView.delegate = self; //控制器成为代理
    
    self.navigationItem.rightBarButtonItem = self.defaultRightItem;
    
    self.page = 0;
    if (!_messageFrames) {
        [self loadMessages];
        NSArray *messages = [NSMutableArray arrayWithArray:[[UNDatabaseTools sharedFMDBTools] getMessageContentWithPage:self.page Phone:self.toTelephone]];
        if (messages && messages.count) {
            _messageFrames = [self changeDictToMessage:messages];
            _messageDict = [NSMutableArray arrayWithArray:[[messages reverseObjectEnumerator] allObjects]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [self scrollTableViewToBottomWithAnimated:NO];
                [self.tableView reloadData];
            });
        }
    }
    
    self.txtSendText.delegate = self;
    
    self.tableView.mj_header = [CustomRefreshMessageHeader headerWithRefreshingBlock:^{
        [self cancelEdit];
        [self loadMoreMessage];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewFontChange) name:@"KTAutoHeightTextViewFontChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow) name:@"KeyboardWillShowFinished" object:nil];
    
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"SendMessageStatuFailed" object:@"MessageStatu" userInfo:userInfo];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendMessageStatuChange:) name:@"SendMessageStatuChange" object:@"MessageStatu"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNewSMSAction) name:@"ReceiveNewSMSContentUpdate" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuControllerDidHide:) name:UIMenuControllerDidHideMenuNotification object:nil];
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
        //取消全选
        [self.selectRemoveData removeAllObjects];
        for (int i = 0; i < self.messageFrames.count; i ++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }else{
        //全选
        [self.selectRemoveData removeAllObjects];
        for (int i = 0; i < self.messageFrames.count; i ++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
        [self.selectRemoveData addObjectsFromArray:self.messageFrames];
    }
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
    if (_bottomView == nil) {
        return;
    }
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
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
        if (!storyboard) {
            return;
        }
        ContactsDetailViewController *contactsDetailViewController = [storyboard instantiateViewControllerWithIdentifier:@"contactsDetailViewController"];
        if (!contactsDetailViewController) {
            return;
        }
        kWeakSelf
        contactsDetailViewController.contactMan = self.titleName;
        contactsDetailViewController.phoneNumbers = self.toTelephone;
        //不更新
        contactsDetailViewController.contactsInfoUpdateBlock = ^(NSString *nickName, NSString *phoneNumber) {
            if (nickName) {
                weakSelf.title = nickName;
            }else{
                weakSelf.title = phoneNumber;
            }
            self.titleName = weakSelf.title;
        };
//        contactsDetailViewController.contactModel = [self checkContactModelWithPhoneStr:self.toTelephone];
        contactsDetailViewController.isMessagePush = YES;
        [self.navigationController pushViewController:contactsDetailViewController animated:YES];
    }else{
        kWeakSelf
        ContactsCallDetailsController *callDetailsVc = [[ContactsCallDetailsController alloc] init];
        callDetailsVc.contactsInfoUpdateBlock = ^(NSString *nickName, NSString *phoneNumber) {
//            if ([phoneNumber isEqualToString:self.toTelephone]) {
//                if (![weakSelf.title isEqualToString:nickName]) {
//                    weakSelf.title = nickName;
//                }
//            }else{
//                weakSelf.title = self.toTelephone;
//            }
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
        callDetailsVc.isMessagePush = YES;
        [self.navigationController pushViewController:callDetailsVc animated:YES];
    }
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
}

- (void)sendMessageStatuChange:(NSNotification *)noti
{
    NSDictionary *userInfo = noti.userInfo;
    NSDictionary *extras = [userInfo valueForKey:@"extras"];
    NSString *smsId = [extras valueForKey:@"SMSID"];
    NSLog(@"extras---%@", extras);
//    [[UNDatabaseTools sharedFMDBTools] updateMessageStatuWithSMSIDDictArray:@[extras]];
//    if (self.messageDict) {
//        for (NSDictionary *dict in self.messageDict) {
//            if ([dict[@"SMSID"] isEqualToString:smsId]) {
//                NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:dict];
//                mutableDict[@"Status"] = extras[@"Status"];
//                [[UNDatabaseTools sharedFMDBTools] insertMessageContentWithMessageContent:@[mutableDict] Phone:self.toTelephone];
//            }
//        }
//    }
    __block MJMessageStatu statu = (MJMessageStatu)[[extras valueForKey:@"Status"] integerValue];
    kWeakSelf
    [self.messageFrames enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(MJMessageFrame *messageFrame, NSUInteger idx, BOOL * _Nonnull stop) {
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

//- (void)loadMessages{
//    if (_messageFrames == nil) {
//        __block NSMutableArray *dictArray = [NSMutableArray array];
//        self.checkToken = YES;
//        NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"pageSize",@"1",@"pageNumber",self.toTelephone,@"Tel", nil];
//        
//        [self getBasicHeader];
////        NSLog(@"表演头：%@",self.headers);
//        [SSNetworkRequest getRequest:apiSMSByTel params:params success:^(id responseObj) {
//            if ([[responseObj objectForKey:@"status"] intValue]==1) {
//                //可通过异步处理优化
//                NSArray *arrMessages = [responseObj objectForKey:@"data"];
//                
//                //将数组倒序
//                arrMessages = [[arrMessages reverseObjectEnumerator] allObjects];
//                
//                for (NSDictionary *dict in arrMessages){
//                    NSLog(@"%@", dict[@"SMSID"]);
//                    if ([[dict objectForKey:@"IsSend"] boolValue]) {
//                        //己方发送
//                        //                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[self compareCurrentTime:[self convertDate:[dict objectForKey:@"SMSTime"]]],@"time",@"0",@"type",dict[@"Status"],@"Status", [dict objectForKey:@"SMSID"],@"SMSID",nil]];
//                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[[UNDataTools sharedInstance] compareCurrentTimeStringWithRecord:dict[@"SMSTime"]],@"time",@"0",@"type",dict[@"Status"],@"Status", [dict objectForKey:@"SMSID"],@"SMSID",nil]];
//                    }else{
//                        //对方发送
//                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[[UNDataTools sharedInstance] compareCurrentTimeStringWithRecord:dict[@"SMSTime"]],@"time",@"1",@"type",dict[@"Status"], @"Status" ,[dict objectForKey:@"SMSID"],@"SMSID",nil]];
//                    }
//                }
//                
//                NSMutableArray *mfArray = [NSMutableArray array];
//                for (NSDictionary *dict in dictArray) {
//                    // 消息模型
//                    MJMessage *msg = [MJMessage messageWithDict:dict];
//                    
//                    // 取出上一个模型
//                    MJMessageFrame *lastMf = [mfArray lastObject];
//                    MJMessage *lastMsg = lastMf.message;
//                    
//                    // 判断两个消息的时间是否一致
//                    msg.hideTime = [msg.time isEqualToString:lastMsg.time];
//                    
//                    // frame模型
//                    MJMessageFrame *mf = [[MJMessageFrame alloc] init];
//                    mf.message = msg;
//                    
//                    // 添加模型
//                    [mfArray addObject:mf];
//                }
//                _messageFrames = mfArray;
//                self.page = 1;
//                [self.tableView reloadData];
//                
//                //自动滚动到底部
//                [self scrollTableViewToBottomWithAnimated:NO];
//                
//            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
//                
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
//            }else{
//            }
//            NSLog(@"查询到的消息数据：%@",responseObj);
//        } failure:^(id dataObj, NSError *error) {
//            HUDNormalTop(INTERNATIONALSTRING(@"网络貌似有问题"))
//            NSLog(@"啥都没：%@",[error description]);
//        } headers:self.headers];
//    }
//}

- (void)loadMessages{
    if (_messageFrames == nil || !_messageFrames.count) {
//        __block NSMutableArray *dictArray = [NSMutableArray array];
        
//        NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"pageSize",@"1",@"pageNumber",self.toTelephone,@"Tel", nil];
        
        NSString *lastTime = [[UNDatabaseTools sharedFMDBTools] getLastTimeMessageContentWithPhone:self.toTelephone];
        NSDictionary *params;
        if (lastTime) {
            params = [[NSDictionary alloc] initWithObjectsAndKeys:@"0",@"pageSize",@"0",@"pageNumber",lastTime,@"beginSMSTime", self.toTelephone,@"Tel",nil];
        }else{
            params = [[NSDictionary alloc] initWithObjectsAndKeys:@"0",@"pageSize",@"0",@"pageNumber", self.toTelephone,@"Tel", nil];
        }
        self.checkToken = YES;
        [self getBasicHeader];
        [SSNetworkRequest getRequest:apiSMSByTel params:params success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                if ([responseObj[@"data"] count] && ![[responseObj[@"data"] lastObject][@"SMSTime"] isEqualToString:lastTime]) {
                    [[UNDatabaseTools sharedFMDBTools] insertMessageContentWithMessageContent:responseObj[@"data"] Phone:self.toTelephone];
//                    NSArray *arrMessages = [[UNDatabaseTools sharedFMDBTools] getMessageContentWithPage:0 Phone:self.toTelephone];
//                    _messageDict = [NSMutableArray arrayWithArray:[[arrMessages reverseObjectEnumerator] allObjects]];
//                    _messageFrames = [self changeDictToMessage:arrMessages];
//                    
//                    self.page = 0;
//                    [self.tableView reloadData];
//                    //自动滚动到底部
//                    [self scrollTableViewToBottomWithAnimated:NO];
//                    [self.tableView reloadData];
                }
                NSArray *arrMessages = [[UNDatabaseTools sharedFMDBTools] getMessageContentWithPage:0 Phone:self.toTelephone];
                _messageDict = [NSMutableArray arrayWithArray:[[arrMessages reverseObjectEnumerator] allObjects]];
                _messageFrames = [self changeDictToMessage:arrMessages];
                
                self.page = 0;
                [self.tableView reloadData];
                if (!self.isFristSend) {
                    //自动滚动到底部
                    [self scrollTableViewToBottomWithAnimated:NO];
                    [self.tableView reloadData];
                }else{
                    self.isFristSend = YES;
                }
//                [self updateMessageList];
                [self getMessageStatuFromServer:arrMessages];
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


//从服务器更新短信状态
- (void)getMessageStatuFromServer:(NSArray *)messageArray
{
//    if (self.isHasSuccessMsg) {
//        return;
//    }
    NSMutableArray *smsIdArray = [NSMutableArray array];
    for (NSDictionary *dict in messageArray) {
        if ([dict[@"Status"] isEqualToString:@"0"]) {
            [smsIdArray addObject:dict[@"SMSID"]];
//            [messageStatus addObject:@{@"SMSID" : dict[@"SMSID"] , @"Status" : dict[@"Status"]}];
        }
    }
    if (smsIdArray.count) {
        //从服务器更新
        self.checkToken = YES;
        [self getBasicHeader];
        NSDictionary *params = @{@"Ids" : smsIdArray};
        [SSNetworkRequest getJsonRequest:apiSMSGets params:params success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                if ([responseObj[@"data"][@"list"] count]) {
                    [[UNDatabaseTools sharedFMDBTools] updateMessageStatuWithSMSIDDictArray:responseObj[@"data"][@"list"]];
                    [self updateCellMessageStatu:responseObj[@"data"][@"list"]];
                }
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

- (void)updateCellMessageStatu:(NSArray *)statuArray
{
    for (NSDictionary *dict in statuArray) {
        if ([dict[@"Status"] isEqualToString:@"0"]) {
            continue;
        }
        NSString *smsId = [dict valueForKey:@"SMSID"];
        if (!smsId) {
            continue;
        }
        __block MJMessageStatu statu = (MJMessageStatu)[[dict valueForKey:@"Status"] integerValue];
        kWeakSelf
        [self.messageFrames enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(MJMessageFrame *messageFrame, NSUInteger idx, BOOL * _Nonnull stop) {
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
}

- (NSMutableArray *)changeDictToMessage:(NSArray *)tempArray
{
    NSMutableArray *resultArray = [NSMutableArray array];
    NSArray *arrMessages = [[tempArray reverseObjectEnumerator] allObjects];
    for (NSDictionary *dict in arrMessages){
        NSLog(@"%@", dict[@"SMSID"]);
        if ([[dict objectForKey:@"IsSend"] boolValue]) {
            //己方发送
            [resultArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[[UNDataTools sharedInstance] compareCurrentTimeStringWithRecord:dict[@"SMSTime"]],@"time",@"0",@"type",dict[@"Status"],@"Status", [dict objectForKey:@"SMSID"],@"SMSID",nil]];
        }else{
            //对方发送
            [resultArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[[UNDataTools sharedInstance] compareCurrentTimeStringWithRecord:dict[@"SMSTime"]],@"time",@"1",@"type",dict[@"Status"], @"Status" ,[dict objectForKey:@"SMSID"],@"SMSID",nil]];
        }
    }
    
    NSMutableArray *mfArray = [NSMutableArray array];
    for (NSDictionary *dict in resultArray) {
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
    return mfArray;
}


////加载更多数据
//- (void)loadMoreMessage
//{
//    self.checkToken = YES;
//
//    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"pageSize",@(self.page+1),@"pageNumber",self.toTelephone,@"Tel", nil];
//
//    [self getBasicHeader];
////    NSLog(@"表演头：%@",self.headers);
//
//    [SSNetworkRequest getRequest:apiSMSByTel params:params success:^(id responseObj) {
//
//        NSLog(@"查询到的用户数据：%@",responseObj);
//
//        if ([[responseObj objectForKey:@"status"] intValue]==1) {
//            
//            NSMutableArray *dictArray = [NSMutableArray array];
//            
//            NSArray *arrNewMessages = [responseObj objectForKey:@"data"];
//            if (arrNewMessages.count) {
//                //将数组倒序
//                arrNewMessages = [[arrNewMessages reverseObjectEnumerator] allObjects];
//                
//                
//                for (NSDictionary *dict in arrNewMessages){
//                    if ([[dict objectForKey:@"IsSend"] boolValue]) {
//                        //己方发送
////                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[self compareCurrentTime:[self convertDate:[dict objectForKey:@"SMSTime"]]],@"time",@"0",@"type",dict[@"Status"],@"Status", [dict objectForKey:@"SMSID"],@"SMSID",nil]];
//                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[[UNDataTools sharedInstance] compareCurrentTimeStringWithRecord:dict[@"SMSTime"]],@"time",@"0",@"type",dict[@"Status"],@"Status", [dict objectForKey:@"SMSID"],@"SMSID",nil]];
//                    }else{
//                        //对方发送
//                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[[UNDataTools sharedInstance] compareCurrentTimeStringWithRecord:dict[@"SMSTime"]],@"time",@"1",@"type",dict[@"Status"], @"Status" ,[dict objectForKey:@"SMSID"],@"SMSID",nil]];
//                    }
//                }
//                
//                
//                
//                NSMutableArray *mfArray = [NSMutableArray array];
//                for (NSDictionary *dict in dictArray) {
//                    // 消息模型
//                    MJMessage *msg = [MJMessage messageWithDict:dict];
//                    
//                    // 取出上一个模型
////                    MJMessageFrame *lastMf = [mfArray lastObject];
////                    MJMessage *lastMsg = lastMf.message;
////                    // 判断两个消息的时间是否一致
////                    msg.hideTime = [msg.time isEqualToString:lastMsg.time];
////                    //需要判断多久之内为同一时间
//                    
//                    // frame模型
//                    MJMessageFrame *mf = [[MJMessageFrame alloc] init];
//                    mf.message = msg;
//                    
//                    // 添加模型
//                    [mfArray addObject:mf];
//                }
//                
//                if (mfArray.count>0) {
//                    self.page = self.page + 1;
//                    NSIndexSet *indexs = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, mfArray.count)];
//                    [_messageFrames insertObjects:mfArray atIndexes:indexs];
//                    
//                    [self.tableView.mj_header endRefreshing];
//                    [self.tableView reloadData];
//                    
//                    //移动到当前查看位置
//                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:mfArray.count inSection:0];
//                    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
//                }else{
//                    [self.tableView.mj_header endRefreshing];
//                }
//            }else{
//                NSLog(@"无更多数据加载");
//                [self.tableView.mj_header endRefreshing];
//            }
//            
//        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
//        }else{
//            //数据请求失败
//            HUDNormalTop(INTERNATIONALSTRING(@"请求失败"))
//            [self.tableView.mj_header endRefreshing];
//        }
//        
//    } failure:^(id dataObj, NSError *error) {
//        //        [self.tableView.mj_header endRefreshing];
//        [self.tableView.mj_header endRefreshing];
//        HUDNormalTop(INTERNATIONALSTRING(@"网络貌似有问题"))
//    } headers:self.headers];
//
//}

//加载更多数据
- (void)loadMoreMessage
{
    NSArray *pageArray = [[UNDatabaseTools sharedFMDBTools] getMessageContentWithPage:(self.page + 1) Phone:self.toTelephone];
    //更新短信状态

    [self getMessageStatuFromServer:pageArray];
    if (pageArray.count) {
        //将数组倒序
//            arrNewMessages = [[arrNewMessages reverseObjectEnumerator] allObjects];
//            for (NSDictionary *dict in arrNewMessages){
//                if ([[dict objectForKey:@"IsSend"] boolValue]) {
//                    //己方发送
//                    [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[[UNDataTools sharedInstance] compareCurrentTimeStringWithRecord:dict[@"SMSTime"]],@"time",@"0",@"type",dict[@"Status"],@"Status", [dict objectForKey:@"SMSID"],@"SMSID",nil]];
//                }else{
//                    //对方发送
//                    [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[[UNDataTools sharedInstance] compareCurrentTimeStringWithRecord:dict[@"SMSTime"]],@"time",@"1",@"type",dict[@"Status"], @"Status" ,[dict objectForKey:@"SMSID"],@"SMSID",nil]];
//                }
//            }
//            NSMutableArray *mfArray = [NSMutableArray array];
//            for (NSDictionary *dict in dictArray) {
//                // 消息模型
//                MJMessage *msg = [MJMessage messageWithDict:dict];
//                // frame模型
//                MJMessageFrame *mf = [[MJMessageFrame alloc] init];
//                mf.message = msg;
//                // 添加模型
//                [mfArray addObject:mf];
//            }
        NSIndexSet *dictIndexs = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, pageArray.count)];
        [_messageDict insertObjects:[[pageArray reverseObjectEnumerator] allObjects] atIndexes:dictIndexs];
        
        NSArray *mfArray = [self changeDictToMessage:pageArray];
        if (mfArray.count>0) {
            self.page = self.page + 1;
            NSIndexSet *indexs = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, mfArray.count)];
//                _messageDict = [NSMutableArray arrayWithArray:messages];
//                [_messageDict insertObjects:pageArray atIndexes:indexs];
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

    
//    self.checkToken = YES;
//    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"pageSize",@(self.page+1),@"pageNumber",self.toTelephone,@"Tel", nil];
//    
//    [self getBasicHeader];
//    //    NSLog(@"表演头：%@",self.headers);
//    
//    [SSNetworkRequest getRequest:apiSMSByTel params:params success:^(id responseObj) {
//        
//        NSLog(@"查询到的用户数据：%@",responseObj);
//        
//        if ([[responseObj objectForKey:@"status"] intValue]==1) {
//            
//            NSMutableArray *dictArray = [NSMutableArray array];
//            
//            NSArray *arrNewMessages = [responseObj objectForKey:@"data"];
//            if (arrNewMessages.count) {
//                //将数组倒序
//                arrNewMessages = [[arrNewMessages reverseObjectEnumerator] allObjects];
//                
//                
//                for (NSDictionary *dict in arrNewMessages){
//                    if ([[dict objectForKey:@"IsSend"] boolValue]) {
//                        //己方发送
//                        //                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[self compareCurrentTime:[self convertDate:[dict objectForKey:@"SMSTime"]]],@"time",@"0",@"type",dict[@"Status"],@"Status", [dict objectForKey:@"SMSID"],@"SMSID",nil]];
//                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[[UNDataTools sharedInstance] compareCurrentTimeStringWithRecord:dict[@"SMSTime"]],@"time",@"0",@"type",dict[@"Status"],@"Status", [dict objectForKey:@"SMSID"],@"SMSID",nil]];
//                    }else{
//                        //对方发送
//                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[[UNDataTools sharedInstance] compareCurrentTimeStringWithRecord:dict[@"SMSTime"]],@"time",@"1",@"type",dict[@"Status"], @"Status" ,[dict objectForKey:@"SMSID"],@"SMSID",nil]];
//                    }
//                }
//                
//                
//                
//                NSMutableArray *mfArray = [NSMutableArray array];
//                for (NSDictionary *dict in dictArray) {
//                    // 消息模型
//                    MJMessage *msg = [MJMessage messageWithDict:dict];
//                    
//                    // 取出上一个模型
//                    //                    MJMessageFrame *lastMf = [mfArray lastObject];
//                    //                    MJMessage *lastMsg = lastMf.message;
//                    //                    // 判断两个消息的时间是否一致
//                    //                    msg.hideTime = [msg.time isEqualToString:lastMsg.time];
//                    //                    //需要判断多久之内为同一时间
//                    
//                    // frame模型
//                    MJMessageFrame *mf = [[MJMessageFrame alloc] init];
//                    mf.message = msg;
//                    
//                    // 添加模型
//                    [mfArray addObject:mf];
//                }
//                
//                if (mfArray.count>0) {
//                    self.page = self.page + 1;
//                    NSIndexSet *indexs = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, mfArray.count)];
//                    [_messageFrames insertObjects:mfArray atIndexes:indexs];
//                    
//                    [self.tableView.mj_header endRefreshing];
//                    [self.tableView reloadData];
//                    
//                    //移动到当前查看位置
//                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:mfArray.count inSection:0];
//                    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
//                }else{
//                    [self.tableView.mj_header endRefreshing];
//                }
//            }else{
//                NSLog(@"无更多数据加载");
//                [self.tableView.mj_header endRefreshing];
//            }
//            
//        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
//        }else{
//            //数据请求失败
//            HUDNormalTop(INTERNATIONALSTRING(@"请求失败"))
//            [self.tableView.mj_header endRefreshing];
//        }
//        
//    } failure:^(id dataObj, NSError *error) {
//        //        [self.tableView.mj_header endRefreshing];
//        [self.tableView.mj_header endRefreshing];
//        HUDNormalTop(INTERNATIONALSTRING(@"网络貌似有问题"))
//    } headers:self.headers];
    
}


//自动滚动到底部
- (void)scrollTableViewToBottomWithAnimated:(BOOL)animated
{
    //自动滚动到底部
    if ([self.messageFrames count]) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messageFrames.count - 1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
//         [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height -self.tableView.bounds.size.height) animated:animated];
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
    cell.selectedBackgroundView = [[UIView alloc]init];
    cell.tag = indexPath.row;
    // 长按菜单
    cell.longPressCellBlock = ^(NSInteger index, NSString *content, UIView *longPressView){
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
//    if (editingStyle == (UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert)) {
//        
//    }
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
        [SSNetworkRequest postRequest:apiSMSSend params:params success:^(id responseObj) {
            NSLog(@"查询到的用户数据：%@",responseObj);
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                self.txtSendText.text = @"";
                [self.txtSendText resignFirstResponder];
                _messageFrames = nil;
                [self loadMessages];
                self.btnSend.enabled = YES;
//                [self updateMessageList];
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
    if (_currentIndex < self.messageFrames.count) {
        MJMessageFrame *messageFrame = self.messageFrames[_currentIndex];
        NSLog(@"当前删除短信%@", messageFrame);
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
            [[UNDatabaseTools sharedFMDBTools] deteleMessageContentWithSMSIDLists:@[smsId] WithPhone:self.toTelephone];
            if ((weakSelf.messageFrames.count == index + 1) || weakSelf.messageFrames.count == 1) {
                //刷新外部界面
                [weakSelf updateMessageList];
            }
            NSLog(@"删除单条短信成功");
            if (weakSelf.messageFrames.count > index) {
                [weakSelf.messageFrames removeObjectAtIndex:index];
            }
            [weakSelf.tableView reloadData];
            if (!weakSelf.messageFrames.count) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                });
            }
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            NSLog(@"删除单条短信失败--%@", responseObj[@"msg"]);
            
            [[UNDatabaseTools sharedFMDBTools] deteleMessageContentWithSMSIDLists:@[smsId] WithPhone:self.toTelephone];
            if ((weakSelf.messageFrames.count == index + 1) || weakSelf.messageFrames.count == 1) {
                //刷新外部界面
                [weakSelf updateMessageList];
            }
            NSLog(@"删除单条短信成功");
            if (weakSelf.messageFrames.count > index) {
                [weakSelf.messageFrames removeObjectAtIndex:index];
            }
            [weakSelf.tableView reloadData];
            if (!weakSelf.messageFrames.count) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                });
            }
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
            [[UNDatabaseTools sharedFMDBTools] deteleMessageContentWithSMSIDLists:smsIds WithPhone:self.toTelephone];
            //刷新外部界面
            [weakSelf updateMessageList];
            
            //防止数据不同步
            NSMutableArray *tempArray = [NSMutableArray array];
            for (MJMessageFrame *messageFrame in Datas) {
                if ([weakSelf.messageFrames containsObject:messageFrame]) {
                    [tempArray addObject:messageFrame];
                }
            }
            if (tempArray.count) {
                [weakSelf.messageFrames removeObjectsInArray:tempArray];
            }
            [weakSelf.tableView reloadData];
            //自动滚动到底部
//            [self scrollTableViewToBottomWithAnimated:NO];
            if (!weakSelf.messageFrames.count) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                });
            }
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            NSLog(@"删除多条短信失败--%@", responseObj[@"msg"]);
            [[UNDatabaseTools sharedFMDBTools] deteleMessageContentWithSMSIDLists:smsIds WithPhone:self.toTelephone];
            //刷新外部界面
            [weakSelf updateMessageList];
            
            //防止数据不同步
            NSMutableArray *tempArray = [NSMutableArray array];
            for (MJMessageFrame *messageFrame in Datas) {
                if ([weakSelf.messageFrames containsObject:messageFrame]) {
                    [tempArray addObject:messageFrame];
                }
            }
            if (tempArray.count) {
                [weakSelf.messageFrames removeObjectsInArray:tempArray];
            }
            [weakSelf.tableView reloadData];
            //自动滚动到底部
            //            [self scrollTableViewToBottomWithAnimated:NO];
            if (!weakSelf.messageFrames.count) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                });
            }
        }
    } failure:^(id dataObj, NSError *error) {
        NSLog(@"删除单条短信异常：%@",[error description]);
    } headers:self.headers];
}

- (void)menuControllerDidHide:(NSNotification *)noti
{
    [self deleteMenuController];
}

- (void)deleteMenuController
{
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    if (menuController.menuItems) {
        menuController.menuItems = nil;
    }
}

- (void)updateMessageList
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateMessageRecordLists" object:nil];
}

@end


