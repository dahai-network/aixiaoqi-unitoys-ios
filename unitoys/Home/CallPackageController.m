//
//  CallPackageController.m
//  unitoys
//
//  Created by 黄磊 on 2017/2/27.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "CallPackageController.h"
#import "CallPackageListCell.h"
#import "CallPackageDetailsController.h"

@interface CallPackageController ()

@property (nonatomic, copy) NSArray *dataArray;

@end

@implementation CallPackageController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)initData
{
    self.title = @"通话套餐";
    [self.tableView registerNib:[UINib nibWithNibName:@"CallPackageListCell" bundle:nil] forCellReuseIdentifier:@"CallPackageListCell"];
    self.tableView.rowHeight = 60;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CallPackageListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CallPackageListCell"];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    CallPackageDetailsController
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Package" bundle:nil];
    CallPackageDetailsController *callPackageDetailsController = [mainStory instantiateViewControllerWithIdentifier:@"CallPackageDetailsController"];
    if (callPackageDetailsController) {
//        callPackageDetailsController.loadUrl = @"http://www.baidu.com";
//        callPackageDetailsController.titleStr = @"双卡双待使用教程";
        
        [self.navigationController pushViewController:callPackageDetailsController animated:YES];
    }
}

@end
