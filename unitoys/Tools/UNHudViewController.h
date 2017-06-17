//
//  UNHudViewController.h
//  unitoys
//
//  Created by 黄磊 on 2017/6/16.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNBaseViewController.h"

@interface UNHudViewController : UNBaseViewController

//自定义Loading
- (void)showLoadingView;
- (void)hideLoadingView;

//MBLoading
- (void)showMBLoadingView;
- (void)hideMBLoadingView;

@end
