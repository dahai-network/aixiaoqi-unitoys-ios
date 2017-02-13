//
//  LoginViewController.h
//  unitoys
//
//  Created by sumars on 16/9/16.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseViewController.h"
#import "UnderlineField.h"

@interface LoginViewController : BaseViewController<UITextFieldDelegate>


@property (readwrite) BOOL bSecure;

@property (weak, nonatomic) IBOutlet UnderlineField *edtUserName;
@property (weak, nonatomic) IBOutlet UnderlineField *edtPassText;
@property (weak, nonatomic) IBOutlet UIButton *btnSecure;

@end
