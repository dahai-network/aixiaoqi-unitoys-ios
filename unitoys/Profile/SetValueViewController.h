//
//  SetValueViewController.h
//  unitoys
//
//  Created by sumars on 16/11/4.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseViewController.h"

@interface SetValueViewController : BaseViewController
@property (nonatomic, copy) NSString *name;
@property (weak, nonatomic) IBOutlet UITextField *edtValue;
@end
