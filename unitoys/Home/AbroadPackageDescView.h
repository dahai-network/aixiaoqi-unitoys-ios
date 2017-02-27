//
//  AbroadPackageDescView.h
//  unitoys
//
//  Created by 黄磊 on 2017/2/27.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AbroadPackageDescView : UIView

+ (instancetype)showAbroadPackageDescViewWithTitle:(NSString *)title Desc:(NSString *)descString SureButtonTitle:(NSString *)buttonTitle;

- (instancetype)initWithAbroadPackageDescViewWithTitle:(NSString *)title Desc:(NSString *)descString SureButtonTitle:(NSString *)buttonTitle;

@end
