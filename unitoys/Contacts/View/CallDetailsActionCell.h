//
//  CallDetailsActionCell.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CustomButtonInset;

@protocol CallDetailsActionCellDelegate <NSObject>  //号码选择协议
@optional
- (void)callActionType:(NSInteger)type;
@end

@interface CallDetailsActionCell : UITableViewCell
@property (weak, nonatomic) IBOutlet CustomButtonInset *messageButton;
@property (weak, nonatomic) IBOutlet CustomButtonInset *CallButton;
@property (weak, nonatomic) IBOutlet CustomButtonInset *defriendButton;

@property (nonatomic, weak) id<CallDetailsActionCellDelegate> delegate;

//@property (nonatomic, copy) NSDictionary *cellDatas;

@end

