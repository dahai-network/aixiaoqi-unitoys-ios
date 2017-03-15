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
@property (nonatomic, strong) NSMutableArray *listArr;
@property (nonatomic, assign) BOOL isEditing;//是否是编辑状态

@end

@implementation AlarmListViewController

//- (NSMutableArray *)listArr {
//    if (!_listArr) {
//        self.listArr = [NSMutableArray array];
//    }
//    return _listArr;
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = INTERNATIONALSTRING(@"手环闹钟");
    self.tableView.tableFooterView = self.footView;
    [self loadData];
    
    //右边选项按钮
    UIButton *rightButton = [[UIButton alloc]initWithFrame:CGRectMake(0,0,30,30)];
    [rightButton setImage:[UIImage imageNamed:@"alarm_editOrAdd"] forState:UIControlStateNormal];
    [rightButton addTarget:self action:@selector(rightButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    self.navigationItem.rightBarButtonItem = right;
    
    self.tableView.allowsSelectionDuringEditing = YES;
    // Do any additional setup after loading the view from its nib.
}

- (void)loadData {
    NSDictionary *dic1 = @{@"noon":@"上午",@"time":@"10:35",@"repetition":@"闹钟，周一"};
    NSDictionary *dic2 = @{@"noon":@"下午",@"time":@"5:35",@"repetition":@"约会，周一"};
    NSDictionary *dic3 = @{@"noon":@"上午",@"time":@"9:35",@"repetition":@"闹钟，周一"};
    NSDictionary *dic4 = @{@"noon":@"下午",@"time":@"1:35",@"repetition":@"闹钟，周一周二周三"};
    self.listArr = [NSMutableArray arrayWithObjects:dic1, dic2, dic3, dic4, nil];
    [self.tableView reloadData];
}

- (void)rightButtonAction:(UIButton *)sender {
    [YBPopupMenu showRelyOnView:sender titles:TITLES icons:ICONS menuWidth:100 delegate:self];
}

#pragma mark - YBPopupMenuDelegate
- (void)ybPopupMenuDidSelectedAtIndex:(NSInteger)index ybPopupMenu:(YBPopupMenu *)ybPopupMenu {
    switch (index) {
        case 0:
//            HUDNormal(@"修改")
            self.isEditing = YES;
            [self setLeftButton:INTERNATIONALSTRING(@"完成")];
            //设置可编辑
            [self.tableView setEditing:YES animated:YES];
            [self.tableView reloadData];
            break;
        case 1:
            HUDNormal(@"添加")
            break;
        default:
            break;
    }
}

- (void)leftButtonClick {
    if (self.isEditing) {
        //设置不可编辑
        self.isEditing = NO;
        [self.tableView reloadData];
        [self.tableView setEditing:NO animated:YES];
        [self setLeftButton:[UIImage imageNamed:@"btn_back"]];

    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - tableView代理方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.listArr.count;
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
    if (self.isEditing) {
        cell.swOffOrOn.hidden = YES;
    } else {
        cell.swOffOrOn.hidden = NO;
    }
    cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
    NSDictionary *dic = self.listArr[indexPath.row];
    cell.lblTimeNoon.text = dic[@"noon"];
    cell.lblTimeDetail.text = dic[@"time"];
    cell.lblDescription.text = dic[@"repetition"];
//    [cell.swOffOrOn setOn:YES];
    return cell;
}

#pragma mark 选中cell,查看动态
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 取消cell的选中效果
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.isEditing) {
        [self.tableView setEditing:NO animated:YES];
        [self setLeftButton:[UIImage imageNamed:@"btn_back"]];
        self.isEditing = NO;
        UIViewController *vc = [[UIViewController alloc] init];
        vc.view.backgroundColor = [UIColor blueColor];
        vc.title = [NSString stringWithFormat:@"row==%zd", indexPath.row];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark 指定哪些可以进行编辑
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark 指定编辑的样式
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    //    指定编辑样式默认的是删除样式
    return UITableViewCellEditingStyleDelete;
}

#pragma mark 提交编辑请求
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (self.editstyle == UITableViewCellEditingStyleInsert) {
//        //        1.更新数据源
//        [self.data insertObject:@"甄姬" atIndex:indexPath.row + 1];
//        //        2.刷新界面
//        //        NSIndexPath *path = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
//        //        [self.rv.table insertRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationBottom]; // 更新单个row
//    }
//    [self.rv.table reloadData]; // 重新加载数据，强制整个界面重新加载（刷新）
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.listArr removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
    }
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
