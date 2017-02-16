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

@interface MJViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *messageFrames;

@property (nonatomic, copy) NSString *cellContent;

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

    [self loadMessages];
    
    self.txtSendText.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewFontChange) name:@"KTAutoHeightTextViewFontChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewFontChange) name:@"KeyboardWillShowFinished" object:nil];
}

- (void)textViewFontChange
{
    NSLog(@"更新inputContainerView");
    NSLog(@"tableView---%@", NSStringFromCGRect(self.tableView.frame));
    NSLog(@"txtSendText---%@", NSStringFromCGRect(self.txtSendText.frame));
    [self.tableView layoutIfNeeded];
    [self scrollTableViewToBottomWithAnimated:NO];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.navigationController.hidesBottomBarWhenPushed = NO;
}


- (void)loadMessages{
    if (_messageFrames == nil) {
        __block NSMutableArray *dictArray = [[NSMutableArray alloc] init];
        
        
        self.checkToken = YES;
        
        NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"pageSize",@"1",@"pageNumber",self.toTelephone,@"Tel", nil];
        
        [self getBasicHeader];
        NSLog(@"表演头：%@",self.headers);
        [SSNetworkRequest getRequest:apiSMSByTel params:params success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                //可通过异步处理优化
                NSArray *arrMessages = [responseObj objectForKey:@"data"];
                
                arrMessages = [arrMessages sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    
                    NSString *time1 = [obj1 objectForKey:@"SMSTime"];
                    NSString *time2 = [obj2 objectForKey:@"SMSTime"];
                    
                    NSComparisonResult result = [time1 compare:time2];
                    return result == NSOrderedDescending; // 升序
                    //        return result == NSOrderedAscending;  // 降序
                }];
                
                for (NSDictionary *dict in arrMessages){
                    if ([[dict objectForKey:@"Fm"] isEqualToString:self.toTelephone]) {
                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[self compareCurrentTime:[self convertDate:[dict objectForKey:@"SMSTime"]]],@"time",@"1",@"type", nil]];
                    } else {
                        [dictArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"SMSContent"],@"text",[self compareCurrentTime:[self convertDate:[dict objectForKey:@"SMSTime"]]],@"time",@"0",@"type", nil]];
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
    
    cell.longPressCellBlock = ^(NSString *content, UIView *longPressView){
        [weakSelf longPressActionWithContent:content longPressView:longPressView];
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


- (IBAction)sendMessage:(id)sender {
    if ([self.txtSendText.text length]>0) {
        self.btnSend.enabled = NO;
        self.checkToken = YES;
        NSString *receiveNumbers = self.toTelephone;
        
        NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:receiveNumbers,@"To",self.txtSendText.text,@"SMSContent", nil];
        
        [self getBasicHeader];
        NSLog(@"表演头：%@",self.headers);
        [SSNetworkRequest postRequest:apiSMSSend params:params success:^(id responseObj) {
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
                HUDNormal(@"发送成功")
                
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
//                [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
                HUDNormal(responseObj[@"msg"])
                self.btnSend.enabled = YES;
            }
            
        } failure:^(id dataObj, NSError *error) {
            //
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
    [items addObject:[[UIMenuItem alloc] initWithTitle:@"复制" action:@selector(copyText:)]];
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


