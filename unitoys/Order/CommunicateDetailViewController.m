//
//  CommunicateDetailViewController.m
//  unitoys
//
//  Created by 董杰 on 2017/1/6.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "CommunicateDetailViewController.h"
#import "CommunicateDetailTableViewCell.h"
#import "OrderCommitViewController.h"

@interface CommunicateDetailViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong)NSDictionary *communicateDetailInfo;
@property (nonatomic, strong)CommunicateDetailTableViewCell *firstCell;
@property (nonatomic, strong)CommunicateDetailTableViewCell *secondCell;
@property (strong, nonatomic) IBOutlet UIView *footView;

@end

@implementation CommunicateDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"套餐详情";
    
    self.communicateDetailInfo = [[NSDictionary alloc] init];
    self.tableView.tableFooterView = self.footView;
    
    //cell高度自适应
    self.tableView.estimatedRowHeight = 44.0f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self checkCommunicateDetailById];
    // Do any additional setup after loading the view from its nib.
}

#pragma mark 根据ID查询套餐详情
- (void)checkCommunicateDetailById {
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.communicateDetailID,@"id", nil];
    
    [self getBasicHeader];
    NSLog(@"表头：%@",self.headers);
    [SSNetworkRequest getRequest:apiPackageByID params:params success:^(id responseObj) {
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            self.communicateDetailInfo = responseObj[@"data"][@"list"];
            [self.tableView reloadData];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            HUDNormal(responseObj[@"msg"])
        }
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

#pragma mark - tableView代理方法
#pragma mark 返回行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

//#pragma mark 返回行高
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    return 63;
//}

#pragma mark 返回cell内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        static NSString *identifier=@"CommunicateDetailTableViewCell";
        self.firstCell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!self.firstCell) {
            self.firstCell=[[[NSBundle mainBundle] loadNibNamed:@"CommunicateDetailTableViewCell" owner:nil options:nil] firstObject];
        }
        setImage(self.firstCell.imgCommunicatePhoto, self.communicateDetailInfo[@"LogoPic"])
        self.firstCell.lblCommunicateName.text = self.communicateDetailInfo[@"PackageName"];
        self.firstCell.lblCommunicatePrice.text = [NSString stringWithFormat:@"￥%@", self.communicateDetailInfo[@"Price"]];
        return self.firstCell;
    } else if (indexPath.row == 1) {
        static NSString *identifier=@"ContentTableViewCell";
        self.secondCell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!self.secondCell) {
            self.secondCell=[[NSBundle mainBundle] loadNibNamed:@"CommunicateDetailTableViewCell" owner:nil options:nil] [1];
        }
        self.secondCell.lblFirstName.text = @"使用介绍:";
        self.secondCell.lblContent.text = self.communicateDetailInfo[@"Features"];
        return self.secondCell; 
    } else {
        static NSString *identifier=@"ContentTableViewCell";
        self.secondCell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!self.secondCell) {
            self.secondCell=[[NSBundle mainBundle] loadNibNamed:@"CommunicateDetailTableViewCell" owner:nil options:nil][1];
        }
        self.secondCell.lblFirstName.text = @"注意事项:";
        self.secondCell.lblContent.text = self.communicateDetailInfo[@"Details"];
        return self.secondCell;
    }
}

#pragma mark 点击购买按钮点击事件
- (IBAction)bitToBuyAction:(UIButton *)sender {
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Order" bundle:nil];
    OrderCommitViewController *orderCommitViewController = [mainStory instantiateViewControllerWithIdentifier:@"orderCommitViewController"];
    if (orderCommitViewController) {
        orderCommitViewController.dicPackage = self.communicateDetailInfo;
        [self.navigationController pushViewController:orderCommitViewController animated:YES];
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
