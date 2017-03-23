//
//  AbroadPackageExplainController.h
//  unitoys
//
//  Created by 黄磊 on 2017/2/27.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BaseTableController.h"

@interface AbroadPackageExplainController :BaseTableController
@property (nonatomic,assign) BOOL isSupport4G;
@property (nonatomic,assign) BOOL isApn;
@property (nonatomic, copy) NSString *apnName;
@end
