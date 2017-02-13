//
//  CountryCell.h
//  unitoys
//
//  Created by sumars on 16/9/22.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CountryCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *ivCountry;
@property (weak, nonatomic) IBOutlet UILabel *lblCountryName;

@property (readwrite) NSString *countryID;
@property (readwrite) NSString *urlPic;

@end
