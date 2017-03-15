//
//  PackageDetailViewController.m
//  unitoys
//
//  Created by sumars on 16/9/22.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "PackageDetailViewController.h"
#import "OrderCommitViewController.h"
#import "AbroadPackageExplainController.h"
#import "UNDatabaseTools.h"

@implementation PackageDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.isAbroadMessage) {
//        self.title = self.currentTitle;
        [self setRightButton:INTERNATIONALSTRING(@"使用教程")];
    }else{
        self.title = INTERNATIONALSTRING(@"套餐详情");
    }
    
    self.tableView.estimatedRowHeight = 10;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.idPackage,@"id", nil];
    
    NSString *apiNameStr = [NSString stringWithFormat:@"%@idPackage%@", @"apiPackageByID", self.idPackage];
    
    [self getBasicHeader];
    NSLog(@"表头：%@",self.headers);
    [SSNetworkRequest getRequest:apiPackageByID params:params success:^(id responseObj) {
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:apiNameStr dictData:responseObj];
            
            self.lblPrice.text = [NSString stringWithFormat:@"￥%.2f",[[[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"Price"] floatValue]];
            self.lblPackageName.text = [[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"PackageName"];
            self.ivPic.image = [[UIImage alloc] initWithData:[[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"Pic"]]]];
            self.dicPackage = [[responseObj objectForKey:@"data"] objectForKey:@"list"];
            
            self.lblFeatures.text = [[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"Features"];
            self.lblDetails.text = [[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"Details"];
            self.paymentOfTerms.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"paymentOfTerms"];
//            self.howToUse.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"howToUse"];
            self.howToUse.text = [[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"UseDescr"];
            
            [self.tableView reloadData];
//            [self.tableView needsUpdateConstraints];
            
            if (self.isAbroadMessage) {
                self.title = responseObj[@"data"][@"list"][@"CountryName"];
            }
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
        
        NSLog(@"查询到的套餐详情数据：%@",responseObj);
    } failure:^(id dataObj, NSError *error) {
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:apiNameStr];
        if (responseObj) {
            self.lblPrice.text = [NSString stringWithFormat:@"￥%.2f",[[[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"Price"] floatValue]];
            self.lblPackageName.text = [[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"PackageName"];
            self.ivPic.image = [[UIImage alloc] initWithData:[[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"Pic"]]]];
            self.dicPackage = [[responseObj objectForKey:@"data"] objectForKey:@"list"];
            self.lblFeatures.text = [[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"Features"];
            self.lblDetails.text = [[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"Details"];
            self.paymentOfTerms.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"paymentOfTerms"];
            self.howToUse.text = [[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"UseDescr"];
            
            [self.tableView reloadData];
        
            if (self.isAbroadMessage) {
                self.title = responseObj[@"data"][@"list"][@"CountryName"];
            }
        }
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(payConfrim) name:@"BuyConfrim" object:nil];
}

- (void)rightButtonClick
{
    if (self.isAbroadMessage) {
        NSLog(@"使用教程");
        AbroadPackageExplainController *abroadVc = [[AbroadPackageExplainController alloc] init];
        abroadVc.isSupport4G = self.isSupport4G;
        abroadVc.isApn = self.isApn;
        [self .navigationController pushViewController:abroadVc animated:YES];
    }
}

- (void)payConfrim {
    [self.navigationController popToViewController:self animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row==0) {
        return 300*[UIScreen mainScreen].bounds.size.width/375;
    } else {
        return UITableViewAutomaticDimension;
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 10;
}

- (IBAction)buyPackage:(id)sender {
    
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Order" bundle:nil];
    OrderCommitViewController *orderCommitViewController = [mainStory instantiateViewControllerWithIdentifier:@"orderCommitViewController"];
    if (orderCommitViewController) {
        orderCommitViewController.dicPackage = self.dicPackage;
        [self.navigationController pushViewController:orderCommitViewController animated:YES];
    }
    
}
@end
