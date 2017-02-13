//
//  PhoneRecordCell.h
//  unitoys
//
//  Created by sumars on 16/10/7.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhoneRecordCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *ivStatus;
@property (weak, nonatomic) IBOutlet UILabel *lblPhoneNumber;
@property (weak, nonatomic) IBOutlet UILabel *lblPhoneType;
@property (weak, nonatomic) IBOutlet UILabel *lblCallTime;

@end
