//
//  AmountDetailViewController.m
//  unitoys
//
//  Created by sumars on 16/11/1.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "AmountDetailViewController.h"
#import "AmountDetailCell.h"

@interface AmountDetailViewController ()

@end

@implementation AmountDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [UIView new];
    // Do any additional setup after loading the view.
    HUDNoStop1(INTERNATIONALSTRING(@"正在加载..."))
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"PageSize",@"1",@"PageNumber", nil];
    
    [self getBasicHeader];
    NSLog(@"表头：%@",self.headers);
    
    
    [SSNetworkRequest getRequest:apiGetUserBill params:params success:^(id responseObj) {
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            self.arrAmountDetail = [[responseObj objectForKey:@"data"] objectForKey:@"list"];
            
            [self.tableView reloadData];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
        NSLog(@"查询到的套餐数据：%@",responseObj);
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
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

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arrAmountDetail.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //获取数据；
    AmountDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AmountDetailCell"];
    
    NSDictionary *dicAmountDetail = [self.arrAmountDetail objectAtIndex:indexPath.row];
    
    cell.lblPayTips.text = [dicAmountDetail objectForKey:@"Descr"];
    cell.lblCreateDate.text =  [self formatTime: [self convertDate:[[dicAmountDetail objectForKey:@"CreateDate"] stringValue]]];
    if ([[dicAmountDetail objectForKey:@"BillType"] intValue]==1) {
        cell.lblAmount.text = [NSString stringWithFormat:@"+￥%.2f",[[dicAmountDetail objectForKey:@"Amount"] floatValue]];
        [cell.lblAmount setTextColor:[UIColor greenColor]];
    } else {
        cell.lblAmount.text = [NSString stringWithFormat:@"-￥%.2f",[[dicAmountDetail objectForKey:@"Amount"] floatValue]];
        [cell.lblAmount setTextColor:[UIColor blackColor]];
    }
    return cell;
    
    
}

@end
