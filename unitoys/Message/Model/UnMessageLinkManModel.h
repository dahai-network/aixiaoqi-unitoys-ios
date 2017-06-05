//
//  UnMessageLinkManModel.h
//  unitoys
//
//  Created by 黄磊 on 2017/6/3.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BaseModel.h"

@interface UnMessageLinkManModel : BaseModel

- (instancetype)initWithPhone:(NSString *)phone;
- (instancetype)initWithPhone:(NSString *)phone LinkMan:(NSString *)linkMan;

@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, copy) NSString *linkManName;

@end
