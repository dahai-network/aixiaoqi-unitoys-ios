//
//  PaySuccessViewController.h
//  unitoys
//
//  Created by sumars on 16/11/5.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseViewController.h"

@interface PaySuccessViewController : BaseViewController
@property (weak, nonatomic) IBOutlet UIButton *btnHintInfo;
@property (weak, nonatomic) IBOutlet UILabel *lblPayMethod;
@property (weak, nonatomic) IBOutlet UILabel *lblPayAmount;

@property (readwrite) NSString *strHintInfo;
@property (readwrite) NSString *strPayMethod;
@property (readwrite) NSString *strPayAmount;

- (IBAction)resultConfrim:(id)sender;
@end
