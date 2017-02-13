//
//  BrowserViewController.h
//  unitoys
//
//  Created by sumars on 16/9/26.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseViewController.h"

@interface BrowserViewController : BaseViewController
@property (strong,nonatomic) NSString *loadUrl;
@property (weak, nonatomic) IBOutlet UIWebView *webview;
@end
