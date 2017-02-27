//
//  CountryListViewController.h
//  unitoys
//
//  Created by sumars on 16/9/21.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseViewController.h"

@interface CountryListViewController : BaseViewController<UICollectionViewDataSource,UICollectionViewDelegate>

@property (strong,nonatomic) NSMutableArray *continentIndex;
@property (nonatomic, strong) NSArray *sectionHeadArr;
@property (nonatomic, strong) NSMutableDictionary *listDict;
@property (strong,nonatomic) NSDictionary *dicCountryData;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end
