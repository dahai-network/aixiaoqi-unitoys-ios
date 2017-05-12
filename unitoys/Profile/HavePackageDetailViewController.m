//
//  HavePackageDetailViewController.m
//  unitoys
//
//  Created by 董杰 on 2017/5/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "HavePackageDetailViewController.h"
#import "HavePackageDetailTableViewCell.h"

@interface HavePackageDetailViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation HavePackageDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"账单明细";
    [self checkDetail];
    [self goToRreshWithTableView:self.tableView];
    // Do any additional setup after loading the view from its nib.
}

- (void)checkDetail {
    HUDNoStop1(INTERNATIONALSTRING(@"正在加载..."))
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"PageSize",@(self.CurrentPage),@"PageNumber", self.detailID, @"ParentID", nil];
    
    [self getBasicHeader];
    //    NSLog(@"表头：%@",self.headers);
    [SSNetworkRequest getRequest:apiGetUserBill params:params success:^(id responseObj) {
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSArray *listArr = [[responseObj objectForKey:@"data"] objectForKey:@"list"];
            if (listArr.count) {
                [self.dataSourceArray addObjectsFromArray:listArr];
                if (listArr.count < 20) {
                    [self.tableView.mj_footer endRefreshingWithNoMoreData];
                }
            } else {
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
            }
            
            [self.tableView reloadData];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
        //        NSLog(@"查询到的套餐数据：%@",responseObj);
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

-(void)requesetOfPage:(NSInteger)page{
    [self checkDetail];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSourceArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier=@"HavePackageDetailTableViewCell";
    HavePackageDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell=[[[NSBundle mainBundle] loadNibNamed:@"HavePackageDetailTableViewCell" owner:nil options:nil] firstObject];
    }
    if (self.dataSourceArray.count) {
        NSDictionary *dicAmountDetail = [self.dataSourceArray objectAtIndex:indexPath.row];
        cell.lblFirstStr.text = [dicAmountDetail objectForKey:@"Descr"];
        if ([[dicAmountDetail objectForKey:@"BillType"] intValue]==1) {
            cell.lblSecondStr.text = [NSString stringWithFormat:@"+%.2f",[[dicAmountDetail objectForKey:@"Amount"] floatValue]];
        } else if ([[dicAmountDetail objectForKey:@"BillType"] intValue]==0) {
            cell.lblSecondStr.text = [NSString stringWithFormat:@"-%.2f",[[dicAmountDetail objectForKey:@"Amount"] floatValue]];
        } else {
            cell.lblSecondStr.text = [NSString stringWithFormat:@"%.2f",[[dicAmountDetail objectForKey:@"Amount"] floatValue]];
        }
    }
    return cell;
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
