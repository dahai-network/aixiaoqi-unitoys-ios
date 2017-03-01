//
//  CountryListViewController.m
//  unitoys
//
//  Created by sumars on 16/9/21.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "CountryListViewController.h"
#import "CountryCell.h"
#import "UIImageView+WebCache.h"
#import "PackageListViewController.h"
#import "headCollectionReusableView.h"
#import "UNDatabaseTools.h"

@implementation CountryListViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    self.checkToken = YES;
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"headCollectionReusableView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"headCollectionReusableView"];
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"100",@"pageSize", nil];
    NSString *apiNameStr = [NSString stringWithFormat:@"%@pageSize%@", @"apiCountryGet", @"100"];
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest getRequest:apiCountryGet params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:apiNameStr dictData:responseObj];
            self.continentIndex = [responseObj objectForKey:@"data"];
            NSLog(@"查询到的用户数据：%@",responseObj);
    
            [self.collectionView reloadData];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
        
        NSLog(@"查询到的用户数据：%@",responseObj);
    } failure:^(id dataObj, NSError *error) {
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:apiNameStr];
        if (responseObj) {
            self.continentIndex = [responseObj objectForKey:@"data"];
            NSLog(@"查询到的用户数据：%@",responseObj);
            [self.collectionView reloadData];
        }
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger size=[UIScreen mainScreen].bounds.size.width/4;
    return CGSizeMake(size, size);
}

-(CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (self.continentIndex.count) {
        if (self.continentIndex.count - 1 == section) {
            return CGSizeMake([UIScreen mainScreen].bounds.size.width, 0);
        } else {
            return CGSizeMake([UIScreen mainScreen].bounds.size.width, 30);
        }
    } else {
        return CGSizeMake([UIScreen mainScreen].bounds.size.width, 0);
    }
}

//-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section{
//    //635:435
//    return CGSizeMake([UIScreen mainScreen].bounds.size.width, 0.1);
//}
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    
    NSString *identifier =@"headCollectionReusableView";
    
    NSArray *arr = [[NSArray alloc] init];
    if (self.continentIndex.count) {
        arr = self.continentIndex[indexPath.section];
    }
    if (kind==UICollectionElementKindSectionHeader) {
        headCollectionReusableView *headView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:identifier forIndexPath:indexPath];
        if (arr.count) {
            headView.headViewLabel.text = arr[0][@"ContinentsDescr"];
            headView.headViewLabel.hidden = NO;
        } else {
            headView.headViewLabel.hidden = YES;
        }
        return headView;
    }
    return nil;
}



- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    //先获取数据
    
    return [self.continentIndex count];
    
}



- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
//    NSArray *arrCountry = [self.dicCountryData objectForKey:[self.continentIndex objectAtIndex:section]];
    NSArray *arrCountry = [self.continentIndex objectAtIndex:section];
    return  [arrCountry count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
//    return nil;
    
    CountryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CountryCell" forIndexPath:indexPath];
    
    NSArray *arrCountry = [self.continentIndex objectAtIndex:indexPath.section];
//    NSArray *arrCountry = [self.dicCountryData objectForKey:[self.continentIndex objectAtIndex:indexPath.section]];
    
    NSDictionary *dicCountry = [arrCountry objectAtIndex:indexPath.row];
    
    
    cell.lblCountryName.text = [dicCountry objectForKey:@"CountryName"];
//    cell.ivCountry.image = [[UIImage alloc] initWithData:[[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[dicCountry objectForKey:@"LogoPic"]]]];
    [cell.ivCountry sd_setImageWithURL:[dicCountry objectForKey:@"LogoPic"]];
    cell.urlPic = [dicCountry objectForKey:@"Pic"];
    cell.countryID = [dicCountry objectForKey:@"CountryID"];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //开始弹弹弹
//    NSArray *arrCountry = [self.dicCountryData objectForKey:[self.continentIndex objectAtIndex:indexPath.section]];
    NSArray *arrCountry = [self.continentIndex objectAtIndex:indexPath.section];
    NSDictionary *dicCountry = [arrCountry objectAtIndex:indexPath.row];
    
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Package" bundle:nil];
    PackageListViewController *packageListViewController = [mainStory instantiateViewControllerWithIdentifier:@"packageListViewController"];
    if (packageListViewController) {
        packageListViewController.CountryID = [dicCountry objectForKey:@"CountryID"];
        packageListViewController.dicCountry = dicCountry;
        [self.navigationController pushViewController:packageListViewController animated:YES];
    }
}

@end
