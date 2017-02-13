//
//  AlarmListViewController.m
//  unitoys
//
//  Created by 董杰 on 2017/1/12.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "AlarmListViewController.h"
#import "AlarmListTableViewCell.h"
#import "YBPopupMenu.h"

#define TITLES @[@"修改", @"添加"]
#define ICONS  @[@"alarm_edit",@"alarm_add"]

@interface AlarmListViewController ()<YBPopupMenuDelegate>
@property (strong, nonatomic) IBOutlet UIView *footView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation AlarmListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"手环闹钟";
    self.tableView.tableFooterView = self.footView;
    
    //右边选项按钮
    UIButton *rightButton = [[UIButton alloc]initWithFrame:CGRectMake(0,0,30,30)];
    [rightButton setImage:[UIImage imageNamed:@"alarm_editOrAdd"] forState:UIControlStateNormal];
    [rightButton addTarget:self action:@selector(rightButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    self.navigationItem.rightBarButtonItem = right;
    
    // Do any additional setup after loading the view from its nib.
}

- (void)rightButtonAction:(UIButton *)sender {
    [YBPopupMenu showRelyOnView:sender titles:TITLES icons:ICONS menuWidth:100 delegate:self];
}

#pragma mark - YBPopupMenuDelegate
- (void)ybPopupMenuDidSelectedAtIndex:(NSInteger)index ybPopupMenu:(YBPopupMenu *)ybPopupMenu {
    switch (index) {
        case 0:
            HUDNormal(@"修改")
            break;
        case 1:
            HUDNormal(@"添加")
            break;
        default:
            break;
    }
}

#pragma mark - tableView代理方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier=@"AlarmListTableViewCell";
    AlarmListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell=[[[NSBundle mainBundle] loadNibNamed:@"AlarmListTableViewCell" owner:nil options:nil] firstObject];
    }
    cell.lblTimeNoon.text = @"下午";
    cell.lblTimeDetail.text = @"10:35";
    cell.lblDescription.text = @"闹钟，周一 周二 周三";
    [cell.swOffOrOn setOn:YES];
    return cell;
}

#pragma mark 选中cell,查看动态
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 取消cell的选中效果
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
