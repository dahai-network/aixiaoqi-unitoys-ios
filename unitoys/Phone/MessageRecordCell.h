//
//  MessageRecordCell.h
//  unitoys
//
//  Created by sumars on 16/10/7.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "TopLeftLabel.h"

@interface MessageRecordCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *unreadMsgLabel;

@property (weak, nonatomic) IBOutlet UILabel *lblPhoneNumber;
@property (weak, nonatomic) IBOutlet UILabel *lblMessageDate;
@property (weak, nonatomic) IBOutlet UILabel *lblContent;
@end
