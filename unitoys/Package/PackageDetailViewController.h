//
//  PackageDetailViewController.h
//  unitoys
//
//  Created by sumars on 16/9/22.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseTableController.h"

@interface PackageDetailViewController : BaseTableController

@property (readwrite) NSString *idPackage;

@property (weak, nonatomic) IBOutlet UIImageView *ivPic;
@property (weak, nonatomic) IBOutlet UILabel *lblPackageName;
@property (weak, nonatomic) IBOutlet UILabel *lblPrice;
@property (weak, nonatomic) IBOutlet UILabel *lblFeatures;
@property (weak, nonatomic) IBOutlet UILabel *lblDetails;
@property (weak, nonatomic) IBOutlet UILabel *paymentOfTerms;
@property (weak, nonatomic) IBOutlet UILabel *howToUse;

@property (readwrite) NSDictionary *dicPackage;

- (IBAction)buyPackage:(id)sender;

@end
