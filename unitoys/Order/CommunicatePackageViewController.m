//
//  CommunicatePackageViewController.m
//  unitoys
//
//  Created by 董杰 on 2017/1/6.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "CommunicatePackageViewController.h"
#import "CommunicatePackageTableViewCell.h"
#import "CommunicateDetailViewController.h"
#import "UNDatabaseTools.h"

@interface CommunicatePackageViewController ()
@property (nonatomic, strong)NSMutableArray *listArray;
@property (weak, nonatomic) IBOutlet UITableView *listTableView;
@end

@implementation CommunicatePackageViewController

- (NSMutableArray *)listArray {
    if (!_listArray) {
        self.listArray = [NSMutableArray array];
    }
    return _listArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = INTERNATIONALSTRING(@"通话套餐");
    [self checkCommunicatePackageList];
    // Do any additional setup after loading the view from its nib.
}

#pragma mark 获取通话套餐列表数据
- (void)checkCommunicatePackageList {
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"pageNumber", @"20",@"pageSize",@"1", @"category", nil];
    NSString *apiNameStr = [NSString stringWithFormat:@"%@category%@", @"apiPackageGet", @"1"];
    [self getBasicHeader];
    NSLog(@"表头：%@",self.headers);
    [SSNetworkRequest getRequest:apiPackageGet params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:apiNameStr dictData:responseObj];
            NSLog(@"获取到的通话套餐:%@", responseObj);
            self.listArray = responseObj[@"data"][@"list"];
            [self.listTableView reloadData];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
    } failure:^(id dataObj, NSError *error) {
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:apiNameStr];
        if (responseObj) {
            self.listArray = responseObj[@"data"][@"list"];
            [self.listTableView reloadData];
        }
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

#pragma mark - tableView代理方法
#pragma mark 返回行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listArray.count;
}

#pragma mark 返回行高
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 63;
}

#pragma mark 返回cell内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier=@"CommunicatePackageTableViewCell";
    CommunicatePackageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell=[[[NSBundle mainBundle] loadNibNamed:@"CommunicatePackageTableViewCell" owner:nil options:nil] firstObject];
    }
    NSDictionary *dict = self.listArray[indexPath.row];
    cell.lblPackageName.text = dict[@"PackageName"];
    cell.lblValideDate.text = [NSString stringWithFormat:@"%@：%@%@", INTERNATIONALSTRING(@"有效期"), dict[@"ExpireDays"], INTERNATIONALSTRING(@"天")];
    cell.lblPackagePrice.text = [NSString stringWithFormat:@"￥%@", dict[@"Price"]];
    return cell;
}

#pragma mark 选中cell,查看动态
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 取消cell的选中效果
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *dict = self.listArray[indexPath.row];
    CommunicateDetailViewController *communicateDetailVC = [[CommunicateDetailViewController alloc] init];
    communicateDetailVC.communicateDetailID = dict[@"PackageId"];
    [self.navigationController pushViewController:communicateDetailVC animated:YES];
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
