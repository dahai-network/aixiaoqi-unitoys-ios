//
//  UNMessageContentController.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/2.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNMessageContentController.h"
#import "UNMessageInputView.h"
#import "UNEditMessageView.h"
#import "CustomRefreshMessageHeader.h"
#import "NotifyTextField.h"
#import "MJMessageFrame.h"
#import "ContactsDetailViewController.h"
#import "ContactsCallDetailsController.h"
#import "UNDatabaseTools.h"
#import "UNDataTools.h"
#import "MJMessageCell.h"
#import "UnMessageLinkManModel.h"
#import "UNConvertFormatTool.h"
#import "ContactsViewController.h"
#import "AddTouchAreaButton.h"
#import "BlueToothDataManager.h"

@interface UNMessageContentController ()<UITableViewDataSource, UITableViewDelegate, NotifyTextFieldDelegate, UIMessageInputViewDelegate,PhoneNumberSelectDelegate>

@property (nonatomic, strong) UIBarButtonItem *defaultLeftItem;
@property (nonatomic, strong) UIBarButtonItem *defaultRightItem;
@property (nonatomic, strong) UIBarButtonItem *editLeftItem;
@property (nonatomic, strong) UIBarButtonItem *editRightItem;

//view
@property (nonatomic, strong) UITableView *myTableView;
@property (nonatomic, strong) UNMessageInputView *myMsgInputView;

//data
@property (nonatomic, strong) NSMutableArray *messageFrames;
@property (nonatomic, assign) NSInteger page;
@property (nonatomic, strong) NSMutableArray *selectRemoveData;
@property (nonatomic, strong) UNEditMessageView *bottomView;

//暂定,优化后长按事件封装到Cell子控件
@property (nonatomic, copy) NSString *cellContent;
@property (nonatomic, assign) NSInteger currentIndex;

//是否当前页码有发送成功短信
@property (nonatomic, assign) BOOL isHasSuccessMsg;
@property (nonatomic, assign) BOOL isFristSend;

//NewMessage
//联系人列表
@property (nonatomic, copy) NSArray *contactsLists;
//短信接收人列表(存储model)
@property (nonatomic, strong) NSMutableArray *arrLinkmans;
//当前textfield显示文字
@property (nonatomic, copy) NSString *currentTextFieldStr;
//顶部控件
@property (nonatomic, strong) UIView *topEditLinkManView;
//输入联系人号码
@property (nonatomic, weak) NotifyTextField *txtLinkman;

@property (nonatomic, assign) CGFloat scrollOffset;
@end

@implementation UNMessageContentController

- (UNEditMessageView *)bottomView
{
    if (!_bottomView) {
        _bottomView = [[UNEditMessageView alloc] initWithFrame:CGRectMake(0, self.view.un_height, kScreenWidthValue, self.myMsgInputView.un_height)];
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

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initAllItems];
    [self loadNavigationBar];
    [self initMessageData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (_myMsgInputView) {
        _myMsgInputView.hidden = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (_myMsgInputView) {
        _myMsgInputView.hidden = NO;
        [_myMsgInputView prepareToShowWithAnimate:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (_myMsgInputView) {
        _myMsgInputView.hidden = YES;
        [_myMsgInputView isAndResignFirstResponder];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (_myMsgInputView) {
        _myMsgInputView.hidden = YES;
        [_myMsgInputView prepareToDismissWithAnimate:YES];
    }
}

- (void)loadNavigationBar
{
    if (self.isNewMessage) {
        self.title = @"新信息";
        self.navigationItem.rightBarButtonItem = nil;
    }else{
        self.title = self.toPhoneName;
        self.navigationItem.rightBarButtonItem = self.defaultRightItem;
    }
}

- (void)initAllItems
{
    self.defaultLeftItem = self.navigationItem.leftBarButtonItem;
    self.defaultRightItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"msg_contacts_nor"] style:UIBarButtonItemStyleDone target:self action:@selector(rightBarButtonAction)];
    
    self.editLeftItem = [[UIBarButtonItem alloc] initWithTitle:INTERNATIONALSTRING(@"取消") style:UIBarButtonItemStyleDone target:self action:@selector(cancelEdit)];
    self.editRightItem = [[UIBarButtonItem alloc] initWithTitle:INTERNATIONALSTRING(@"全选") style:UIBarButtonItemStyleDone target:self action:@selector(selectAllCell)];
}

- (void)initMessageData
{
    _selectRemoveData = [NSMutableArray array];
    self.page = 0;
    [self createTaleView];
    [self createMessageInputView];
    [self loadData];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewFontChange) name:@"KTAutoHeightTextViewFontChange" object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow) name:@"KeyboardWillShowFinished" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendMessageStatuChange:) name:@"SendMessageStatuChange" object:@"MessageStatu"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNewSMSAction) name:@"ReceiveNewSMSContentUpdate" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuControllerDidHide:) name:UIMenuControllerDidHideMenuNotification object:nil];
}

- (void)createTaleView
{
    self.myTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.myTableView.un_height -= 64;
    self.myTableView.backgroundColor = [UIColor whiteColor];
    self.myTableView.dataSource = self;  //新增
    self.myTableView.delegate = self; //控制器成为代理
    self.myTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.myTableView.allowsSelection = NO; // 不允许选中
    self.myTableView.allowsMultipleSelectionDuringEditing = YES;
    [self.view addSubview:self.myTableView];
}

- (void)createMessageInputView
{
    _myMsgInputView = [UNMessageInputView messageInputViewWithPlaceHolder:@"输入短信"];
    _myMsgInputView.delegate = self;
//    [_myMsgInputView prepareToShow];
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0,CGRectGetHeight(_myMsgInputView.frame), 0.0);
    self.myTableView.contentInset = contentInsets;
    self.myTableView.scrollIndicatorInsets = contentInsets;
}

- (void)loadData
{
    if (self.isNewMessage) {
        self.arrLinkmans = [[NSMutableArray alloc] init];
        [self createTxtLinkman];
    }else{
        self.myTableView.mj_header = [CustomRefreshMessageHeader headerWithRefreshingBlock:^{
            [self cancelEdit];
            [self loadMoreMessage];
        }];
        
        if (!_messageFrames) {
            [self loadMessages];
            NSArray *messages = [NSMutableArray arrayWithArray:[[UNDatabaseTools sharedFMDBTools] getMessageContentWithPage:self.page Phone:self.toTelephone]];
            if (messages && messages.count) {
                _messageFrames = [self changeDictToMessage:messages];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.myTableView reloadData];
                    [self scrollTableViewToBottomWithAnimated:NO];
                    [self.myTableView reloadData];
                });
            }
        }
    }
}

- (void)createTxtLinkman
{
    _topEditLinkManView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, 50)];
    _topEditLinkManView.backgroundColor = UIColorFromRGB(0xF5F5F5);
    [self.view addSubview:_topEditLinkManView];
    
    UILabel *leftLabel = [[UILabel alloc] init];
    leftLabel.text = @"收件人:";
    leftLabel.textColor = UIColorFromRGB(0x333333);
    leftLabel.font = [UIFont systemFontOfSize:15];
    [leftLabel sizeToFit];
    leftLabel.un_left = 8;
    leftLabel.un_centerY = _topEditLinkManView.un_height * 0.5;
    [_topEditLinkManView addSubview:leftLabel];

    AddTouchAreaButton *selectManButton = [AddTouchAreaButton buttonWithType:UIButtonTypeCustom];
    [selectManButton setImage:[UIImage imageNamed:@"add_addressee_nor"] forState:UIControlStateNormal];
    [selectManButton setImage:[UIImage imageNamed:@"add_addressee_pre"] forState:UIControlStateHighlighted];
    [selectManButton addTarget:self action:@selector(addLinkManAction:) forControlEvents:UIControlEventTouchUpInside];
    [selectManButton sizeToFit];
    selectManButton.touchEdgeInset = UIEdgeInsetsMake(10, 10, 10, 10);
    selectManButton.un_right = _topEditLinkManView.un_width - 19;
    selectManButton.un_centerY = leftLabel.un_centerY;
    [_topEditLinkManView addSubview:selectManButton];
    
    NotifyTextField *txtLinkman = [[NotifyTextField alloc] initWithFrame:CGRectMake(leftLabel.un_right + 8, 0, kScreenWidthValue - (leftLabel.un_right + 8) - (kScreenWidthValue - selectManButton.un_left + 8), 30)];
    txtLinkman.un_centerY = _topEditLinkManView.un_height * 0.5;
    self.txtLinkman = txtLinkman;
    txtLinkman.font = [UIFont systemFontOfSize:14];
    txtLinkman.notifyTextFieldDelegate = self;
    txtLinkman.textColor = [UIColor blackColor];
    [_topEditLinkManView addSubview:txtLinkman];
}

//添加联系人事件
- (void)addLinkManAction:(UIButton *)button
{
    button.enabled = NO;
    [self.txtLinkman endEditing:YES];
    [self.myMsgInputView isAndResignFirstResponder];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if (storyboard) {
        ContactsViewController *contactsViewController = [storyboard instantiateViewControllerWithIdentifier:@"contactsViewController"];
        if (contactsViewController) {
            contactsViewController.bOnlySelectNumber = YES;
            contactsViewController.delegate = self;
            [self.navigationController pushViewController:contactsViewController animated:YES];
        }
    }
    button.enabled = YES;
}

- (void)selectAllCell
{
    if (self.selectRemoveData.count == self.messageFrames.count) {
        //取消全选
        [self.selectRemoveData removeAllObjects];
        for (int i = 0; i < self.messageFrames.count; i ++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            [self.myTableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }else{
        //全选
        [self.selectRemoveData removeAllObjects];
        for (int i = 0; i < self.messageFrames.count; i ++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            [self.myTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
        [self.selectRemoveData addObjectsFromArray:self.messageFrames];
    }
}

- (void)beComeEditMode
{
//    self.myMsgInputView.hidden = YES;
    kWeakSelf
    [self.myMsgInputView hideInputView:^(BOOL finished) {
        if (finished) {
            [weakSelf showEditViewWithCompletion:nil];
        }
    }];
    
    self.navigationItem.leftBarButtonItem = self.editLeftItem;
    self.navigationItem.rightBarButtonItem = self.editRightItem;
    [self.selectRemoveData removeAllObjects];
    [self.myTableView setEditing:YES animated:YES];
}

- (void)cancelEdit
{
    if (_bottomView == nil) {
        return;
    }
    
//    self.myMsgInputView.hidden = NO;
    kWeakSelf
    [self hideEditViewWithCompletion:^(BOOL finished) {
        if (finished) {
            [weakSelf.myMsgInputView showInputView:nil];
        }
    }];
    
    self.navigationItem.leftBarButtonItem = self.defaultLeftItem;
    self.navigationItem.rightBarButtonItem = self.defaultRightItem;
    [self.selectRemoveData removeAllObjects];
    [self.myTableView setEditing:NO animated:YES];
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

- (void)showEditViewWithCompletion:(void (^ __nullable)(BOOL finished))completion
{
    [self bottomView];
    [UIView animateWithDuration:0.3 animations:^{
        self.bottomView.un_top = self.view.un_height - self.bottomView.un_height;
    } completion:^(BOOL finished) {
        if (completion) {
            completion(finished);
        }
    }];
}

- (void)hideEditViewWithCompletion:(void (^ __nullable)(BOOL finished))completion
{
    [UIView animateWithDuration:0.3 animations:^{
        self.bottomView.un_top = self.view.un_height;
    } completion:^(BOOL finished) {
        if (finished) {
            [_bottomView removeFromSuperview];
            _bottomView = nil;
        }
        if (completion) {
            completion(finished);
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
//        kWeakSelf
        contactsDetailViewController.contactMan = self.toPhoneName;
        contactsDetailViewController.phoneNumbers = self.toTelephone;
        //不更新
//        contactsDetailViewController.contactsInfoUpdateBlock = ^(NSString *nickName, NSString *phoneNumber) {
//            if (nickName) {
//                weakSelf.title = nickName;
//            }else{
//                weakSelf.title = phoneNumber;
//            }
//            self.toPhoneName = weakSelf.title;
//        };
        //        contactsDetailViewController.contactModel = [self checkContactModelWithPhoneStr:self.toTelephone];
        contactsDetailViewController.isMessagePush = YES;
        [self.navigationController pushViewController:contactsDetailViewController animated:YES];
    }else{
//        kWeakSelf
        ContactsCallDetailsController *callDetailsVc = [[ContactsCallDetailsController alloc] init];
//        callDetailsVc.contactsInfoUpdateBlock = ^(NSString *nickName, NSString *phoneNumber) {
//            if (nickName) {
//                weakSelf.title = nickName;
//            }else{
//                weakSelf.title = phoneNumber;
//            }
            //号码不可更改
            //            weakSelf.toTelephone = phoneNumber;
//        };
        callDetailsVc.contactModel = [self checkContactModelWithPhoneStr:self.toTelephone];
        callDetailsVc.nickName = self.title;
        callDetailsVc.phoneNumber = self.toTelephone;
        callDetailsVc.isMessagePush = YES;
        [self.navigationController pushViewController:callDetailsVc animated:YES];
    }
}

//- (void)keyboardWillShow
//{
//    NSLog(@"更新inputContainerView");
//    NSLog(@"tableView---%@", NSStringFromCGRect(self.myTableView.frame));
//    NSLog(@"txtSendText---%@", NSStringFromCGRect(self.myMsgInputView.frame));
//    //    [self.tableView setNeedsLayout];
//    //    [self.tableView layoutIfNeeded];
//    //    [self scrollTableViewToBottomWithAnimated:YES];
//}
//
//- (void)textViewFontChange
//{
//    NSLog(@"更新inputContainerView");
//    NSLog(@"tableView---%@", NSStringFromCGRect(self.myTableView.frame));
//    NSLog(@"txtSendText---%@", NSStringFromCGRect(self.myMsgInputView.frame));
//    [self.myTableView setNeedsLayout];
//    [self.myTableView layoutIfNeeded];
//    [self scrollTableViewToBottomWithAnimated:NO];
//}


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
                [weakSelf.myTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                *stop = YES;
            }
        }
    }];
    [self updateMessageList];
}

- (void)loadMessages{
    if (_messageFrames == nil || !_messageFrames.count || self.toTelephone) {
        NSString *lastTime = [[UNDatabaseTools sharedFMDBTools] getLastTimeMessageContentWithPhone:self.toTelephone];
        NSDictionary *params;
        if (lastTime) {
            params = [[NSDictionary alloc] initWithObjectsAndKeys:@"0",@"pageSize",@"0",@"pageNumber",lastTime,@"beginSMSTime", self.toTelephone,@"Tel",nil];
        }else{
            params = [[NSDictionary alloc] initWithObjectsAndKeys:@"0",@"pageSize",@"0",@"pageNumber", self.toTelephone,@"Tel", nil];
        }
        self.checkToken = YES;
        [self getBasicHeader];
        kWeakSelf
        [SSNetworkRequest getRequest:apiSMSByTel params:params success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                
                if ([responseObj[@"data"] count] && ![[responseObj[@"data"] lastObject][@"SMSTime"] isEqualToString:lastTime]) {
                    [[UNDatabaseTools sharedFMDBTools] insertMessageContentWithMessageContent:responseObj[@"data"] Phone:weakSelf.toTelephone];
                }
                NSArray *arrMessages = [[UNDatabaseTools sharedFMDBTools] getMessageContentWithPage:0 Phone:self.toTelephone];
                _messageFrames = [weakSelf changeDictToMessage:arrMessages];
                
                weakSelf.page = 0;
                [weakSelf.myTableView reloadData];
                if (!weakSelf.isFristSend) {
                    //自动滚动到底部
                    [weakSelf scrollTableViewToBottomWithAnimated:NO];
                    [weakSelf.myTableView reloadData];
                }else{
                    weakSelf.isFristSend = YES;
                }
                //                [self updateMessageList];
                [weakSelf getMessageStatuFromServer:arrMessages];
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
                    [weakSelf.myTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    *stop = YES;
                }
            }
        }];
    }
}

//格式化数据
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

//加载更多数据
- (void)loadMoreMessage
{
    NSArray *pageArray = [[UNDatabaseTools sharedFMDBTools] getMessageContentWithPage:(self.page + 1) Phone:self.toTelephone];
    //更新短信状态
    
    [self getMessageStatuFromServer:pageArray];
    if (pageArray.count) {
        NSArray *mfArray = [self changeDictToMessage:pageArray];
        if (mfArray.count>0) {
            self.page = self.page + 1;
            NSIndexSet *indexs = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, mfArray.count)];
            //                _messageDict = [NSMutableArray arrayWithArray:messages];
            //                [_messageDict insertObjects:pageArray atIndexes:indexs];
            [_messageFrames insertObjects:mfArray atIndexes:indexs];
            
            [self.myTableView.mj_header endRefreshing];
            [self.myTableView reloadData];
            //移动到当前查看位置
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:mfArray.count inSection:0];
            [self.myTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }else{
            [self.myTableView.mj_header endRefreshing];
        }
    }else{
        NSLog(@"无更多数据加载");
        [self.myTableView.mj_header endRefreshing];
    }
}

//自动滚动到底部
- (void)scrollTableViewToBottomWithAnimated:(BOOL)animated
{
    //自动滚动到底部
    if ([self.messageFrames count]) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messageFrames.count - 1 inSection:0];
        [self.myTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
        //         [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height -self.tableView.bounds.size.height) animated:animated];
    }
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
    if (self.myTableView.isEditing) {
        [self.selectRemoveData addObject:self.messageFrames[indexPath.row]];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didDeselectRowAtIndexPath---%ld", indexPath.row);
    if (self.myTableView.isEditing) {
        if ([self.selectRemoveData containsObject:self.messageFrames[indexPath.row]]) {
            [self.selectRemoveData removeObject:self.messageFrames[indexPath.row]];
        }
    }
}

//将要显示
//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
//    scaleAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.9, 0.9, 1)];
//    scaleAnimation.toValue  = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1, 1, 1)];
//    scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
//    [cell.layer addAnimation:scaleAnimation forKey:@"transform"];
//}

//消失
//- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//
//}


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


- (void)repeatSendMessage:(MJMessageFrame *)messageFrame
{
    self.checkToken = YES;
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:messageFrame.message.SMSID,@"SMSID", nil];
    
    [self getBasicHeader];
    [SSNetworkRequest postRequest:apiSendRetryForError params:params success:^(id responseObj) {
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

//点击发送消息
#pragma mark --- 发送消息
- (BOOL)sendMessageActionWithMessage:(NSString *)message
{
    if (![BlueToothDataManager shareManager].isRegisted) {
        HUDNormal(INTERNATIONALSTRING(@"卡注册成功后才能发送短信"))
        return NO;
    }
    if (message && ![message isEqualToString:@""]) {
        if (self.isNewMessage) {
            if (!self.toTelephone || [self.toTelephone isEqualToString:@""]) {
                //只有第一次才会获取
                if (self.arrLinkmans.count) {
                    //先判断号码是否符合规则,拼接号码
                    NSMutableString *phoneNumbers = [NSMutableString string];
                    NSMutableString *linkManName = [NSMutableString string];
                    for (int i = 0; i < self.arrLinkmans.count; i++) {
                        UnMessageLinkManModel *model = self.arrLinkmans[i];
                        [phoneNumbers appendString:model.phoneNumber];
                        [linkManName appendString:model.linkManName];
                        if (i != self.arrLinkmans.count - 1) {
                            [phoneNumbers appendString:@","];
                            [linkManName appendString:@","];
                        }
                    }
                    //获取短信联系人
                    self.toTelephone = phoneNumbers;
                    self.toPhoneName = linkManName;
                }else{
                    HUDNormal(@"请先选择联系人");
                    return NO;
                }
            }
        }
        NSString *receiveNumbers = self.toTelephone;
        NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:receiveNumbers,@"To",message,@"SMSContent", nil];
        self.checkToken = YES;
        [self getBasicHeader];
        [SSNetworkRequest postRequest:apiSMSSend params:params success:^(id responseObj) {
            NSLog(@"查询到的用户数据：%@",responseObj);
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                if (self.isNewMessage) {
                    if (!self.myTableView.mj_header) {
                        self.myTableView.mj_header = [CustomRefreshMessageHeader headerWithRefreshingBlock:^{
                            if (self.toTelephone && self.toTelephone.length) {
                                [self cancelEdit];
                                [self loadMoreMessage];
                            }else{
                                [self.myTableView.mj_header endRefreshing];
                            }
                        }];
                    }
                    if (self.toPhoneName) {
                        self.title = self.toPhoneName;
                    }
                    //隐藏新建短信控件
                    self.topEditLinkManView.hidden = YES;
                    [self.topEditLinkManView removeFromSuperview];
                    self.isNewMessage = NO;
                    if (self.navigationItem.rightBarButtonItem != self.defaultRightItem) {
                        self.navigationItem.rightBarButtonItem = self.defaultRightItem;
                    }
                }
                
                
                [self.myMsgInputView sendMessageSuccess];
                _messageFrames = nil;
                [self loadMessages];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"sendMessageSuccess" object:@"sendMessageSuccess"];
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
                [self.myMsgInputView sendMessageField];
            }else{
                //数据请求失败
                HUDNormalTop(responseObj[@"msg"])
                [self.myMsgInputView sendMessageField];
            }
            
        } failure:^(id dataObj, NSError *error) {
            HUDNormalTop(INTERNATIONALSTRING(@"网络貌似有问题"))
            NSLog(@"啥都没：%@",[error description]);
            [self.myMsgInputView sendMessageField];
        } headers:self.headers];
    }else{
        return NO;
    }
    return YES;
}


#pragma mark ======== NotifyTextFieldDelegate ========
//删除文字
- (BOOL)unTextFieldDeleteBackward:(UITextField *)textField ChangeRange:(NSRange)range
{
    NSLog(@"unTextFieldDeleteBackward--text%@---range%@", textField.text, NSStringFromRange(range));
    BOOL isDelete = NO;
    if (!self.currentTextFieldStr) {
        return YES;
    }
    if (range.length > 1) {
        return NO;
    }
    if ([textField.text containsString:self.currentTextFieldStr]) {
        //数据正常
        //判断截取字符串的位置
        if (range.location + range.length >= self.currentTextFieldStr.length) {
            //截取字符串是否包含了之前字符和之后输入的字符
            if (range.location + range.length == self.currentTextFieldStr.length) {
                if ([textField.text isEqualToString:self.currentTextFieldStr]) {
                    //                    NSMutableArray *mutableArray = [NSMutableArray arrayWithArray:[textField.text componentsSeparatedByString:@"、"]];
                    //                    NSString *sureString;
                    //                    if (mutableArray.count >= 2) {
                    //                        if ([mutableArray.lastObject isEqualToString:@""]) {
                    //                            NSLog(@"最后一个为空");
                    //                            NSString *lastString = [mutableArray objectAtIndex:(mutableArray.count - 2)];
                    //                            if ([textField.text containsString:[NSString stringWithFormat:@"%@、", lastString]]) {
                    //                                sureString = [textField.text stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@、", lastString] withString:@""];
                    //                            }
                    //                        }else{
                    //                            NSLog(@"最后一个为空");
                    //                            NSString *lastString = mutableArray.lastObject;
                    //                            if ([textField.text containsString:[NSString stringWithFormat:@"%@、", lastString]]) {
                    //                                sureString = [textField.text stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@、", lastString] withString:@""];
                    //                            }
                    //                        }
                    //                    }else{
                    //                        sureString = @"";
                    //                    }
                    //                    textField.text = sureString;
                    NSLog(@"从最后面删除");
                    [self.arrLinkmans removeLastObject];
                    [self updateEditLinkManData];
                }
                isDelete = NO;
                NSLog(@"光标位置在符号后面");
            }else{
                isDelete = YES;
            }
            //            if (!self.currentTextFieldStr || range.location > self.currentTextFieldStr.length) {
            //                //位置在后面
            //                isDelete = YES;
            //            }else{
            //                //分别删除
            //                //先不做分别删除,直接不允许删除
            //                isDelete = NO;
            //            }
        }else{
            //暂时只允许从最后面删除
            return NO;
            //            //当前截取字符串
            //            NSString *currentDeleteStr = [textField.text substringWithRange:range];
            //            if ([self.currentTextFieldStr containsString:currentDeleteStr]) {
            //                if ([currentDeleteStr containsString:@"、"]) {
            //                    //删除多个
            //                    isDelete = NO;
            //                }else{
            //                    //删除单个
            //                    NSArray *currentArray = [self.currentTextFieldStr componentsSeparatedByString:@"、"];
            //                    if (currentArray.count) {
            //                        //查找当前
            //                    }
            //                }
            //            }else{
            //                NSLog(@"数据错误");
            //                isDelete = NO;
            //            }
        }
    }else{
        //数据异常
        [self resetLinkManData:textField.text];
        isDelete = NO;
    }
    return isDelete;
}

//结束编辑
- (void)unTextFieldDidEndEditing:(UITextField *)textField
{
    self.txtLinkman.textColor = [UIColor greenColor];
    if (textField.text && textField.text.length && ![textField.text isEqualToString:self.currentTextFieldStr]) {
        if (!self.currentTextFieldStr || [textField.text containsString:self.currentTextFieldStr]) {
            //数据正常
            NSString *currentText;
            if (self.currentTextFieldStr) {
                currentText = [textField.text stringByReplacingOccurrencesOfString:self.currentTextFieldStr withString:@""];
            }else{
                currentText = textField.text;
            }
            
            if ([currentText containsString:@","] || [currentText containsString:@"，"]) {
                NSMutableArray *mutableArray = [NSMutableArray arrayWithArray:[currentText componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",，"]]];
                for (NSString *phone in mutableArray) {
                    if (![phone isEqualToString:@""]) {
                        [self addLinkManWithPhoneStr:phone];
                    }
                }
            }else{
                if (![currentText isEqualToString:@""]) {
                    [self addLinkManWithPhoneStr:currentText];
                }
            }
        }else{
            NSLog(@"数据出现异常===text:%@====currentTextFieldStr:%@", textField.text, self.currentTextFieldStr);
            //数据异常
            [self resetLinkManData:textField.text];
        }
        [self updateEditLinkManData];
    }
}

- (void)addLinkManWithPhoneStr:(NSString *)phone
{
    if (!phone || !phone.length) {
        return;
    }
    NSString *phoneNum = [self getCheckNumberWithPhone:phone];
    //判断是否为重复联系人
    if (self.arrLinkmans.count) {
        for (UnMessageLinkManModel *model in self.arrLinkmans) {
            if ([model.phoneNumber isEqualToString:phoneNum]) {
                HUDNormal(INTERNATIONALSTRING(@"请勿输入重复的号码"))
                return;
            }
        }
    }
    //验证是否为号码
    if (![UNConvertFormatTool isAllNumberWithString:phoneNum]) {
        HUDNormal(INTERNATIONALSTRING(@"请输入正确的号码"))
        return;
    }
    UnMessageLinkManModel *model = [[UnMessageLinkManModel alloc] initWithPhone:phoneNum];
    [self.arrLinkmans addObject:model];
}


//开始编辑
- (void)unTextFieldDidBeginEditing:(UITextField *)textField
{
    self.txtLinkman.textColor = [UIColor blackColor];
}

//、
//根据模型数组更新联系人数据
- (void)updateEditLinkManData
{
    if (self.arrLinkmans.count) {
        NSMutableString *mutableString = [[NSMutableString alloc] init];
        for (UnMessageLinkManModel *model in self.arrLinkmans) {
            //        [mutableString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@、",model.linkManName] attributes:attri]];
            [mutableString appendString:[NSString stringWithFormat:@"%@、",model.linkManName]];
        }
        if (mutableString && mutableString.length) {
            self.currentTextFieldStr = mutableString;
        }
        self.txtLinkman.text = mutableString;
    }else{
        self.currentTextFieldStr = nil;
        self.txtLinkman.text = @"";
    }
    NSLog(@"updateEditLinkManData--arrLinkmans%@", self.arrLinkmans);
}
//、
- (void)resetLinkManData:(NSString *)text
{
    if ([text containsString:@"、"]) {
        NSArray *array = [text componentsSeparatedByString:@"、"];
        NSMutableArray *tempArray = [NSMutableArray array];
        for (NSString *phoneStr in array) {
            NSString *surePhone = [self getCheckNumberWithPhone:phoneStr];
            if (surePhone && surePhone.length && [UNConvertFormatTool isAllNumberWithString:surePhone]) {
                UnMessageLinkManModel *model = [[UnMessageLinkManModel alloc] initWithPhone:surePhone];
                [tempArray addObject:model];
            }
        }
        if (tempArray.count) {
            self.arrLinkmans = tempArray;
        }
    }else{
        NSString *surePhone = [self getCheckNumberWithPhone:text];
        UnMessageLinkManModel *model;
        if (surePhone && surePhone.length && [UNConvertFormatTool isAllNumberWithString:surePhone]) {
            model = [[UnMessageLinkManModel alloc] initWithPhone:surePhone];
        }
        if (model) {
            [self.arrLinkmans removeAllObjects];
            [self.arrLinkmans addObject:model];
        }
    }
}

//删除字符串中的特殊符号("、"除外)
- (NSString *)getCheckNumberWithPhone:(NSString *)phone
{
    if ([phone containsString:@"-"]) {
        phone = [phone stringByReplacingOccurrencesOfString:@"-" withString:@""];
    }
    if ([phone containsString:@" "]) {
        phone = [phone stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
    if ([phone containsString:@"+86"]) {
        phone = [phone stringByReplacingOccurrencesOfString:@"+86" withString:@""];
    }
    if ([phone containsString:@"#"]) {
        phone = [phone stringByReplacingOccurrencesOfString:@"," withString:@""];
    }
    if ([phone containsString:@","]) {
        phone = [phone stringByReplacingOccurrencesOfString:@"," withString:@""];
    }
    if ([phone containsString:@"+"]) {
        phone = [phone stringByReplacingOccurrencesOfString:@"+" withString:@""];
    }
    return phone;
}

#pragma mark --PhoneNumberSelectDelegate
- (void)didSelectPhoneNumber:(NSString *)phoneNumber {
    NSLog(@"选择号码");
    //    NSLog(@"添加联系人：%@",phoneNumber);
    //phoneNumber:name|phone
    NSArray * arrNumberInfo = [phoneNumber componentsSeparatedByString:@"|"];
    if ([arrNumberInfo count]==2) {
        if (![UNConvertFormatTool isAllNumberWithString:arrNumberInfo.lastObject]) {HUDNormal(INTERNATIONALSTRING(@"号码格式错误"))
            return;
        }
        //判断号码是否重复
        if (self.arrLinkmans.count) {
            for (UnMessageLinkManModel *model in self.arrLinkmans) {
                if ([model.phoneNumber isEqualToString:arrNumberInfo.lastObject]) {
                    HUDNormal(INTERNATIONALSTRING(@"请勿选择重复的联系人"))
                    return;
                }
            }
        }
        UnMessageLinkManModel *linkModel = [[UnMessageLinkManModel alloc] initWithPhone:arrNumberInfo.lastObject LinkMan:arrNumberInfo.firstObject];
        [self.arrLinkmans addObject:linkModel];
    }else{
        if ([UNConvertFormatTool isAllNumberWithString:phoneNumber]) {
            UnMessageLinkManModel *linkModel = [[UnMessageLinkManModel alloc] initWithPhone:phoneNumber];
            [self.arrLinkmans addObject:linkModel];
        }
    }
    [self updateEditLinkManData];
}



//设置响应
-(BOOL)canBecomeFirstResponder
{
    return YES;
}

//长按响应
- (void)longPressActionWithIndex:(NSInteger)index Content:(NSString *)content longPressView:(UIView *)longPressView
{
    if (self.myTableView.isEditing) {
        return;
    }
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

//删除短信
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
            [weakSelf.myTableView reloadData];
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
            [weakSelf.myTableView reloadData];
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
            [weakSelf.myTableView reloadData];
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
            [weakSelf.myTableView reloadData];
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

//发送文字
- (BOOL)messageInputView:(UNMessageInputView *)inputView sendText:(NSString *)text
{
    return [self sendMessageActionWithMessage:text];
}
//底部高度改变
- (void)messageInputView:(UNMessageInputView *)inputView BottomViewHeightChanged:(CGFloat)BottomViewHeight
{
    NSLog(@"%.f", BottomViewHeight);
//    [self updateTableViewHeightWithBottomViewHeight:BottomViewHeight];
    
    [self updateTabelViewWithInputView:inputView height:BottomViewHeight];
}

- (void)updateTableViewHeightWithBottomViewHeight:(CGFloat)BottomViewHeight
{
    if (BottomViewHeight > 50) {
        self.myTableView.un_top = - (BottomViewHeight - 50);
    }else{
        if (self.myTableView.un_top != 0) {
            self.myTableView.un_top = 0;
        }
    }
}

- (void)updateTabelViewWithInputView:(UNMessageInputView *)inputView height:(CGFloat)BottomViewHeight
{
    UIEdgeInsets contentInsets= UIEdgeInsetsMake(0.0, 0.0, MAX(CGRectGetHeight(inputView.frame), BottomViewHeight), 0.0);;
    self.myTableView.contentInset = contentInsets;
    self.myTableView.scrollIndicatorInsets = contentInsets;
    //调整内容
    static BOOL keyboard_is_down = YES;
    static CGPoint keyboard_down_ContentOffset;
    static CGFloat keyboard_down_InputViewHeight;
    if (BottomViewHeight > CGRectGetHeight(inputView.frame)) {
        if (keyboard_is_down) {
//            keyboard_down_ContentOffset = self.myTableView.contentOffset;
            keyboard_down_ContentOffset = CGPointMake(self.myTableView.contentOffset.x, self.myTableView.contentOffset.y - self.scrollOffset);
            keyboard_down_InputViewHeight = CGRectGetHeight(inputView.frame);
        }
        keyboard_is_down = NO;
        
        CGPoint contentOffset = keyboard_down_ContentOffset;
        CGFloat spaceHeight = MAX(0, CGRectGetHeight(self.myTableView.frame) - self.myTableView.contentSize.height - keyboard_down_InputViewHeight);
        contentOffset.y += MAX(0, BottomViewHeight - keyboard_down_InputViewHeight - spaceHeight);
        NSLog(@"\nspaceHeight:%.2f heightToBottom:%.2f diff:%.2f Y:%.2f", spaceHeight, BottomViewHeight, MAX(0, BottomViewHeight - CGRectGetHeight(inputView.frame) - spaceHeight), contentOffset.y);
        self.myTableView.contentOffset = contentOffset;
    }else{
        keyboard_is_down = YES;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.myTableView && !self.myTableView.isEditing) {
//        DebugUNLog(@"scrollView====contentOffset%.f=======contentSize%.f========bottomHeight%.f", scrollView.contentOffset.y, scrollView.contentSize.height, self.myMsgInputView.bottomHeight);
        //底部
        //        scrollView.contentSize.height - scrollView.contentOffset.y == kScreenHeightValue - 64 - 50
        //        2850----3304
//        CGFloat newOffset = kScreenHeightValue - 64 - self.myMsgInputView.bottomHeight - (scrollView.contentSize.height - scrollView.contentOffset.y);
        
        CGFloat offset = kScreenHeightValue - 64 - (scrollView.contentSize.height - (scrollView.contentOffset.y - self.myMsgInputView.bottomHeight));
        DebugUNLog(@"offset=======%.4f", offset);
        if (offset > 60 && scrollView.contentSize.height > kScreenHeightValue) {
            self.scrollOffset = offset;
            [self.myMsgInputView notAndBecomeFirstResponder];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.scrollOffset = 0;
    DebugUNLog(@"scrollViewDidEndDecelerating");
}

/**
 *  当开始拖拽表格的时候就会调用
 */
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
//    DebugUNLog(@"scrollView====contentOffset%.4f=======contentSize%.4f========bottomHeight%.4f========InputHeight%.4f", scrollView.contentOffset.y, scrollView.contentSize.height, self.myMsgInputView.bottomHeight, self.myMsgInputView.un_height);
    if (scrollView == self.myTableView) {
//        CGFloat newOffset = kScreenHeightValue - 64 - self.myMsgInputView.bottomHeight - (scrollView.contentSize.height - scrollView.contentOffset.y);
//        DebugUNLog(@"NewOffset=======%.4f", newOffset);
        
        CGFloat offset = kScreenHeightValue - 64 - (scrollView.contentSize.height - (scrollView.contentOffset.y - self.myMsgInputView.bottomHeight));
        DebugUNLog(@"offset=======%.4f", offset);
        if (offset <= 1 && scrollView.contentSize.height > kScreenHeightValue){
            NSLog(@"注销第一响应者");
            if (_myMsgInputView) {
                [_myMsgInputView isAndResignFirstResponder];
            }
            // 退出键盘
            [self.view endEditing:YES];
        }
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
