//
//  UNTestTableViewController.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/19.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNTestTableViewController.h"
#import "MessageRecordCell.h"
#import "UNDataTools.h"
#import "UITableView+RegisterNib.h"

static NSString *strMessageRecordCell = @"MessageRecordCell";
@interface UNTestTableViewController ()

@end

@implementation UNTestTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerNibWithNibId:strMessageRecordCell];
    self.tableView.rowHeight = 90;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)createRefreshWithStyle:(RefreshStyle)style
{
    [super createRefreshWithStyle:RefreshStyleBoth];
}

- (void)requestForRefreshFinishStatu:(ResponseType)type response:(id)responseData
{
    UNDebugLogVerbose(@"responseData===%@", responseData)
    if (type == ResponseTypeSuccess) {
        self.dataSource = [NSMutableArray arrayWithArray:responseData[@"data"]];
        [self.tableView reloadData];
    }
}

- (void)reqeustForNextPageFinishStatu:(ResponseType)type response:(id)responseData
{
    if (type == ResponseTypeSuccess) {
        [self.dataSource addObjectsFromArray:responseData[@"data"]];
        [self.tableView reloadData];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    MessageRecordCell *cell = [self.tableView dequeueReusableCellWithIdentifier:strMessageRecordCell];
    NSDictionary *dicMessageRecord = [self.dataSource objectAtIndex:indexPath.row];
    NSString *currentPhone;
    if ([[dicMessageRecord objectForKey:@"IsSend"] boolValue]) {
        //己方发送
        currentPhone = [dicMessageRecord objectForKey:@"To"];
    }else{
        //对方发送
        currentPhone = [dicMessageRecord objectForKey:@"Fm"];
    }
    if (currentPhone) {
        cell.lblPhoneNumber.text = currentPhone;
    }
    NSString *textStr = [[UNDataTools sharedInstance] compareCurrentTimeStringWithRecord:dicMessageRecord[@"SMSTime"]];
    cell.lblMessageDate.text = textStr;
    cell.lblContent.text = [dicMessageRecord objectForKey:@"SMSContent"];
    if (![dicMessageRecord[@"IsRead"] boolValue]) {
        cell.unreadMsgLabel.hidden = NO;
    }else{
        cell.unreadMsgLabel.hidden = YES;
    }
    return cell;
}

@end
