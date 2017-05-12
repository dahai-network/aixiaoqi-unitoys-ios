//
//  ZBRreshViewController.h
//  HongHuaMedical
//
//  Created by Ross Xiao on 15/10/8.
//  Copyright (c) 2015年 Ross Xiao. All rights reserved.
//

#import "BaseTableController.h"

@interface ZBTableRreshViewController : BaseTableController
@property(nonatomic,assign)NSInteger CurrentPage;
@property(nonatomic,strong)NSMutableArray *dataSourceArray;
@property (nonatomic, strong)UIScrollView *scrollView;
-(void)goToRreshWithTableView:(UIScrollView *)RreshScrollView;
-(UITableViewCell *)getCellFromNibName:(NSString *)nibName dequeueTableView:(UITableView *)tableView;
//-(void)ShowNoDataWithMessage:(NSString *)message WithDataArray:(NSMutableArray *)array;
@property(nonatomic,assign)NSInteger pageSize;


@end
