//
//  AgreementViewController.h
//  unitoys
//
//  Created by sumars on 16/9/22.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseViewController.h"

@interface AgreementViewController : BaseViewController
@property (weak, nonatomic) IBOutlet UIWebView *loadWebView;
@property (nonatomic, copy) NSString *lastControllerName;//上一个界面的名称

@end
