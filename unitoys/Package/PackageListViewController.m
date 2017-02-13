//
//  PackageListViewController.m
//  unitoys
//
//  Created by sumars on 16/9/22.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "PackageListViewController.h"
#import "PackageCell.h"
#import "PackageDetailViewController.h"
#import "UIImageView+WebCache.h"

@implementation PackageListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
/*
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.CountryID,@"CountryID", nil];
    
    [self getBasicHeader];
    NSLog(@"表头：%@",self.headers);
    [SSNetworkRequest getRequest:apiPackageByCountry params:params success:^(id responseObj) {
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            self.arrPackageData = [responseObj objectForKey:@"data"];
        
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
    } headers:self.headers]; */
    
    [self loadData];
//    self.packageListTableView.tableFooterView = [UIView new];
    
}

- (void)loadData {
    [self.ivPic sd_setImageWithURL:[NSURL URLWithString:[self.dicCountry objectForKey:@"Pic"]]];
    
    self.title = [self.dicCountry objectForKey:@"CountryName"];
    
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.CountryID,@"CountryID", nil];
    
    [self getBasicHeader];
    NSLog(@"表头：%@",self.headers);
    [SSNetworkRequest getRequest:apiPackageByCountry params:params success:^(id responseObj) {
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            /*
            NSArray *arrPackage = [responseObj objectForKey:@"data"];
            
            self.dicPackage = [arrPackage firstObject];
            
            if (self.dicCountry) {
                self.lblTitle.text = [self.dicPackage objectForKey:@"PackageName"];
                
                self.lblDescription.text = [self.dicPackage objectForKey:@"Flow"];
                
                self.lblPrice.text = [NSString stringWithFormat:@"￥%.2f",[[self.dicPackage objectForKey:@"Price"] floatValue]];

            }*/
            self.arrPackageData = [responseObj objectForKey:@"data"];
            if (!self.arrPackageData.count) {
                self.noDataView.hidden = NO;
            } else {
                self.noDataView.hidden = YES;
            }
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


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arrPackageData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PackageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PackageCell"];
    
    NSDictionary *dicPackage = [self.arrPackageData objectAtIndex:indexPath.row];
//    cell.ivPic.image = [[UIImage alloc] initWithData:[[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[dicPackage objectForKey:@"Pic"]]]];
    
    cell.lblOrder.text = [NSString stringWithFormat:@"%ld",indexPath.row+1];
    cell.lblFlow.text = [dicPackage objectForKey:@"Flow"];
    cell.lblPackageName.text = [dicPackage objectForKey:@"PackageName"];
    cell.lblPrice.text = [NSString stringWithFormat:@"￥%.2f",[[dicPackage objectForKey:@"Price"] floatValue]];
    
    cell.lblOrder.layer.cornerRadius = 22.5;
    cell.lblOrder.layer.masksToBounds = YES;
//    cell.Operators.text = [dicPackage objectForKey:@"Operators"];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dicPackage = [self.arrPackageData objectAtIndex:indexPath.row];
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Package" bundle:nil];
    PackageDetailViewController *packageDetailViewController = [mainStory instantiateViewControllerWithIdentifier:@"packageDetailViewController"];
    if (packageDetailViewController) {
        packageDetailViewController.idPackage = [dicPackage objectForKey:@"PackageId"];
        [self.navigationController pushViewController:packageDetailViewController animated:YES];
    }
}
/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 
    if (_dicPackage) {
        UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        PackageDetailViewController *packageDetailViewController = [mainStory instantiateViewControllerWithIdentifier:@"packageDetailViewController"];
        if (packageDetailViewController) {
            packageDetailViewController.idPackage = [_dicPackage objectForKey:@"PackageId"];
            [self.navigationController pushViewController:packageDetailViewController animated:YES];
        }
    }
}*/

@end
