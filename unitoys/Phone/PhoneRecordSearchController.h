//
//  PhoneRecordSearchController.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BaseTableController.h"

typedef void(^DidSelectSearchCellBlock)(id contacts);
@interface PhoneRecordSearchController : BaseTableController

@property (nonatomic, copy) NSString *searchText;
@property (strong,nonatomic) NSMutableArray *arrPhoneRecord;

@property (nonatomic, copy) DidSelectSearchCellBlock didSelectSearchCellBlock;

@end
