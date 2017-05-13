//
//  ZBRreshViewController.m
//  HongHuaMedical
//
//  Created by Ross Xiao on 15/10/8.
//  Copyright (c) 2015年 Ross Xiao. All rights reserved.
//

#import "ZBRreshViewController.h"

@interface ZBRreshViewController ()

@property(nonatomic,assign)NSInteger lastArrayCount;
@property(retain,nonatomic)UIImageView *imageview;
@end

@implementation ZBRreshViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataSourceArray=[NSMutableArray array];
    self.pageSize = 10;
    self.CurrentPage=1;
  
}

#pragma makr--------刷新用的方法
-(void)goToRreshWithTableView:(UIScrollView *)RreshScrollView{
    self.scrollView = RreshScrollView;
    self.scrollView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.dataSourceArray removeAllObjects];
            self.CurrentPage=1;
            [self.scrollView.mj_footer resetNoMoreData];
            [self requesetOfPage:0];
            [self.scrollView.mj_header endRefreshing];
        });
    }];
    self.scrollView.mj_header.automaticallyChangeAlpha = YES;
    
    self.scrollView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.dataSourceArray.count < 10) {
                [self.scrollView.mj_footer endRefreshingWithNoMoreData];
                return ;
            }
             self.CurrentPage++;
            [self requesetOfPage:self.CurrentPage];
            [self.scrollView.mj_footer endRefreshing];
            
        });
    }];
    self.scrollView.mj_footer.automaticallyChangeAlpha = YES;
}
#pragma mark 加载cell
-(UITableViewCell *)getCellFromNibName:(NSString *)nibName dequeueTableView:(UITableView *)tableView
{
    static NSString * identifier;
    identifier = nibName;
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil][0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

-(void)requesetOfPage:(NSInteger)page{


}

//-(void)ShowNoDataWithMessage:(NSString *)message WithDataArray:(NSMutableArray *)array{
//    if (array.count) {
//           noDataView.hidden=YES;
//    }else{
//        if (noDataView) {
//            noDataView.hidden=NO;
//        }else{
//            noDataView=[[[NSBundle mainBundle] loadNibNamed:@"NoDataView" owner:nil options:nil] firstObject];
//            noDataView.Message.text=message;
//            noDataView.size=self.scrollView.size;
//            [self.scrollView addSubview:noDataView];
//        }
//        
//    }
//   
//}


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
