//
//  PackageListViewController.h
//  unitoys
//
//  Created by sumars on 16/9/22.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseTableController.h"

@interface PackageListViewController : BaseTableController


@property (strong,nonatomic) NSString *CountryID;

@property (readwrite) NSDictionary *dicCountry;

//@property (readwrite) NSDictionary *dicPackage; //只有一个套餐

@property (strong,nonatomic) NSMutableArray *arrPackageData;
@property (weak, nonatomic) IBOutlet UIImageView *ivPic;
@property (strong, nonatomic) IBOutlet UITableView *packageListTableView;
@property (weak, nonatomic) IBOutlet UIView *noDataView;

/*
@property (weak, nonatomic) IBOutlet UILabel *lblOrder;

@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblDescription;
@property (weak, nonatomic) IBOutlet UILabel *lblPrice;*/

@end
