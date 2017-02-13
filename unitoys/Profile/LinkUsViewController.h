//
//  LinkUsViewController.h
//  unitoys
//
//  Created by sumars on 16/9/22.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseViewController.h"
#import "ConerView.h"
#import <MessageUI/MessageUI.h>

@interface LinkUsViewController : BaseViewController<MFMailComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet ConerView *vwLink;

@end
