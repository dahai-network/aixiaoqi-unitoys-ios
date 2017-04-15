//
//  MainViewController.h
//  unitoys
//
//  Created by sumars on 16/9/19.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UITabBarController<UITabBarControllerDelegate>
@property (nonatomic, strong) UIWindow *registProgress;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, copy) NSString *showLabelStr;
@property (nonatomic, assign) BOOL isMainView;
@property (nonatomic, assign) BOOL isNetworkCanUse;
@property (nonatomic, copy) NSString *currentViewType;

@end
