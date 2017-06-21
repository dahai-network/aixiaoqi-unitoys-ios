//
//  PackageDetailViewController.h
//  unitoys
//
//  Created by sumars on 16/9/22.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseTableController.h"
#import "ThroughLineLabel.h"

@interface PackageDetailViewController : BaseTableController

@property (readwrite) NSString *idPackage;

@property (nonatomic, assign) BOOL isAbroadMessage;
@property (nonatomic, copy) NSString *currentTitle;

@property (nonatomic,assign) BOOL isSupport4G;
@property (nonatomic,assign) BOOL isApn;
@property (weak, nonatomic) IBOutlet UIButton *buyButton;

@property (weak, nonatomic) IBOutlet UIImageView *ivPic;
@property (weak, nonatomic) IBOutlet UILabel *lblPackageName;
@property (weak, nonatomic) IBOutlet UILabel *lblPrice;
@property (weak, nonatomic) IBOutlet ThroughLineLabel *lblOldPrice;
@property (weak, nonatomic) IBOutlet UILabel *lblFeatures;
@property (weak, nonatomic) IBOutlet UILabel *lblDetails;
@property (weak, nonatomic) IBOutlet UILabel *paymentOfTerms;
@property (weak, nonatomic) IBOutlet UILabel *howToUse;
@property (weak, nonatomic) IBOutlet UIButton *firstButton;
@property (weak, nonatomic) IBOutlet UIButton *secondButton;
@property (weak, nonatomic) IBOutlet UIButton *thirdButton;
@property (weak, nonatomic) IBOutlet UIView *firstButtonView;
@property (weak, nonatomic) IBOutlet UIView *secondButtonView;
@property (weak, nonatomic) IBOutlet UIView *thirdButtonView;
@property (nonatomic, assign) int chooseButtonIndex;

@property (readwrite) NSDictionary *dicPackage;

- (IBAction)buyPackage:(id)sender;


@end
