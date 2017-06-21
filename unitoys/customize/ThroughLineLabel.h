//
//  ThroughLineLabel.h
//  unitoys
//
//  Created by 董杰 on 2017/6/21.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ThroughLineLabel : UILabel
@property (assign, nonatomic) BOOL strikeThroughEnabled; // 是否画线

@property (strong, nonatomic) UIColor *strikeThroughColor; // 画线颜色

@end
