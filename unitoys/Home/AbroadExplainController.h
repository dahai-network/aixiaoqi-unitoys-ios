//
//  AbroadExplainController.h
//  unitoys
//
//  Created by 黄磊 on 2017/2/27.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BaseViewController.h"

typedef NS_ENUM(NSUInteger, ExplainType) {
    ExplainTypeAbroad = 1,
    ExplainTypeInternal = 2,
};

@interface AbroadExplainController : BaseViewController

@property (nonatomic, assign) ExplainType currentExplainType;

@property (nonatomic,assign) BOOL isSupport4G;
@property (nonatomic,assign) BOOL isApn;

@end
