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

@interface NewMessageViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *messageFrames;

//@property (weak, nonatomic) IBOutlet UITextField *inputView;
@end

@implementation NewMessageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.arrLinkman = [[NSMutableArray alloc] init];
    
    // 1.表格的设置
    // 去除分割线
    self.tableView.backgroundColor = [UIColor colorWithRed:235/255.0 green:235/255.0 blue:235/255.0 alpha:1.0];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsSelection = NO; // 不允许选中
    self.tableView.dataSource = self;  //新增
    self.tableView.delegate = self; //控制器成为代理
    
    /*
     // 2.监听键盘的通知  self表示控制器来监听
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
     
     // 3.设置文本框左边显示的view
     self.inputView.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 0)];
     // 永远显示
     self.inputView.leftViewMode = UITextFieldViewModeAlways;
     
     self.inputView.delegate = self;
     
     self.txtLinkman.delegate = self; */
    
    //    self.messageFrames [self messageFrames];
//    [self.txtLinkman becomeFirstResponder];
    [self loadMessages];
    
    
    self.txtSendText.delegate = self;
    
    self.txtLinkman.notifyTextFieldDelegate = self;
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
            self.title = @"新信息";
        }
        NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"pageSize",@"1",@"pageNumber",self.linkManTele,@"Tel", nil];
        
        [self getBasicHeader];
        NSLog(@"表演头：%@",self.headers);
        [SSNetworkRequest getRequest:apiSMSByTel params:info success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                
                NSArray *arrMessages = [responseObj objectForKey:@"data"];
                
                for (NSDictionary *dict in arrMessages){
                    if ([[dict objectForKey:@"Fm"] isEqualToString:self.title]) {
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
    // 1.创建cell
    MJMessageCell *cell = [MJMessageCell cellWithTableView:tableView];
    
    // 2.给cell传递模型
    cell.messageFrame = self.messageFrames[indexPath.row];
    
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
/*
 - (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
 {
 // 退出键盘
 [self.view endEditing:YES];
 } */

- (IBAction)addLinkman:(id)sender {
    
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
     NSLog(@"表演头：%@",self.headers);
     [SSNetworkRequest postRequest:apiSMSSend params:info success:^(id responseObj) {
     
     
     NSLog(@"查询到的用户数据：%@",responseObj);
     
     if ([[responseObj objectForKey:@"status"] intValue]==1) {
     
//     [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"发送成功" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
//     HUDNormal(@"发送成功")
     
     self.txtSendText.text = @"";
     
     [self.txtSendText resignFirstResponder];
     
     _messageFrames = nil;
     
     [self loadMessages];
    self.btnSend.enabled = YES;
     
     }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
     
     [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
         self.btnSend.enabled = YES;
     }else{
     //数据请求失败
//     [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
         HUDNormal(responseObj[@"msg"])
         self.btnSend.enabled = YES;
     }
     
     
     } failure:^(id dataObj, NSError *error) {
     HUDNormal([error description])
         self.btnSend.enabled = YES;
//     NSLog(@"啥都没：%@",[error description]);
     } headers:self.headers];
     }
}

- (IBAction)editedLinkman:(id)sender {
    
    NSLog(@"编辑结束");
    
    //开始验证文本框中的联系人与数据是否匹配，不匹配则更新
    [self pairLinkman];
    
    //更新联系人列表并修改颜色
    self.txtLinkman.text = [self getLinkmans];
    self.txtLinkman.textColor = [UIColor colorWithRed:43/255.0 green:182/255.0 blue:35/255.0 alpha:1];
    [self.txtLinkman resignFirstResponder];
    
    
}

- (IBAction)beginEditLinkman:(id)sender {
    NSLog(@"开始编辑");
    self.txtLinkman.textColor = [UIColor blackColor];
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
            [self pairLinkman];
        }else if (self.txtLinkman.text.length>0) {
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
                //
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

- (void)pairLinkman {  //配对联系人
    NSLog(@"配对联系");
    if (![[self getLinkmans] isEqualToString:self.txtLinkman.text]) {
        NSArray *numbers = [self.txtLinkman.text componentsSeparatedByString:@" "];
        if (self.arrLinkman.count==0) {
            //添加所有
            NSMutableDictionary *dicNumber = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[numbers firstObject],@"linkman",[numbers firstObject],@"number", nil];
            [self.arrLinkman addObject:dicNumber];
            //            self.txtLinkman.text = [self getLinkmans];
        }else if (numbers.count==self.arrLinkman.count){
            //更新即可
            for (int i=0; i<self.arrLinkman.count; i++) {
                NSMutableDictionary *dicNumber = [self.arrLinkman objectAtIndex:i];
                
                
                if ([[dicNumber objectForKey:@"linkman"] isEqualToString:[dicNumber objectForKey:@"number"]]) {
                    [dicNumber setObject:[numbers objectAtIndex:i] forKey:@"number"];
                    [dicNumber setObject:[numbers objectAtIndex:i] forKey:@"linkman"]; //如果是相同说明是号码，则更新两项，否则只更新号码
                }else{
                    [dicNumber setObject:[numbers objectAtIndex:i] forKey:@"number"];
                }
                
                [self.arrLinkman replaceObjectAtIndex:i withObject:dicNumber];
                
                
                
                //                NSLog(@"更新后的数据：%@",[self getLinkmans]);
            }
        }else{
            //联系人数量有变化？
            
        }
    }
    
    
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
        NSMutableDictionary *dicNumber = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[arrNumberInfo objectAtIndex:0],@"linkman",[arrNumberInfo objectAtIndex:1],@"number", nil];
        [self.arrLinkman addObject:dicNumber];
    }
    
    self.txtLinkman.text = [self getLinkmans];
    
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




@end
