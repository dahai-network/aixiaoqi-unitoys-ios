//
//  MJMessageCell.h
//  unitoys
//
//  Created by sumars on 16/10/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UNRichLabel.h"

@class UNMessageFrameModel;

typedef void(^LongPressCellBlock)(NSInteger index, NSString *content, UIView *longPressView);
typedef void(^RepeatSendMessageBlock)(UNMessageFrameModel *messageFrame);

@interface MJMessageCell : UITableViewCell

/**
 *  正文
 */
@property (nonatomic, weak) UNRichLabel *contentLabel;

+ (instancetype)cellWithTableView:(UITableView *)tableView;

@property (nonatomic, strong) UNMessageFrameModel *messageFrame;

@property (nonatomic, copy) LongPressCellBlock longPressCellBlock;

@property (nonatomic, copy) RepeatSendMessageBlock repeatSendMessageBlock;
@end

