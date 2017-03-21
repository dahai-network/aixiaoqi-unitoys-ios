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
@property (nonatomic, copy) NSString *orderID;
@property (nonatomic, assign) int packageCategory;

- (IBAction)resultConfrim:(id)sender;
@end
