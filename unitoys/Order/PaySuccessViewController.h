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
@property (weak, nonatomic) IBOutlet UIButton *paySuccessButton;

@property (readwrite) NSString *strHintInfo;
@property (readwrite) NSString *strPayMethod;
@property (readwrite) NSString *strPayAmount;
@property (nonatomic, copy) NSString *orderID;
@property (nonatomic, assign) int packageCategory;

- (IBAction)resultConfrim:(id)sender;

//禁止点击详情
@property (nonatomic, assign) BOOL isNoClickDetail;
@property (nonatomic, assign) BOOL isConvenienceOrder;
@end
