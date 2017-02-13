//
//  SettingViewController.h
//  unitoys
//
//  Created by sumars on 16/9/21.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseTableController.h"

@interface SettingViewController : BaseTableController
@property (weak, nonatomic) IBOutlet UILabel *lblVersionNumber;//版本号
@property (nonatomic, copy) NSString *versionNumberStr;//记录版本号

- (IBAction)logout:(id)sender;

@end
