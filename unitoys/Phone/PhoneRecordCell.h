//
//  PhoneRecordCell.h
//  unitoys
//
//  Created by sumars on 16/10/7.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AddTouchAreaButton;

typedef void(^LookDetailsBlock)(NSInteger index, NSString *phoneNumber, NSString *nickName);
@interface PhoneRecordCell : UITableViewCell

@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, copy) NSString *nickName;

@property (weak, nonatomic) IBOutlet UIImageView *ivStatus;
@property (weak, nonatomic) IBOutlet UILabel *lblPhoneNumber;
@property (weak, nonatomic) IBOutlet UILabel *lblPhoneType;
@property (weak, nonatomic) IBOutlet UILabel *lblCallTime;
@property (weak, nonatomic) IBOutlet AddTouchAreaButton *detailsButton;

@property (nonatomic, copy) LookDetailsBlock lookDetailsBlock;

@property (nonatomic, assign) NSInteger currentIndex;

@end
