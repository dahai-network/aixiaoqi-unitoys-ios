//
//  MJMessageCell.h
//  unitoys
//
//  Created by sumars on 16/10/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MJMessageFrame;

typedef void(^LongPressCellBlock)(NSString *content, UIView *longPressView);
typedef void(^RepeatSendMessageBlock)(MJMessageFrame *messageFrame);

@interface MJMessageCell : UITableViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableView;

@property (nonatomic, strong) MJMessageFrame *messageFrame;

@property (nonatomic, copy) LongPressCellBlock longPressCellBlock;

@property (nonatomic, copy) RepeatSendMessageBlock repeatSendMessageBlock;
@end

