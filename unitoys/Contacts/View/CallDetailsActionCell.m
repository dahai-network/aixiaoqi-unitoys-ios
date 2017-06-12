//
//  CallDetailsActionCell.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "CallDetailsActionCell.h"
#import "CustomButtonInset.h"

@implementation CallDetailsActionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.messageButton.imageInsetsType = UIButtonImageInsetsTypeTop;
    self.messageButton.imageTop = 20;
    self.messageButton.margin = 10;
    self.CallButton.imageInsetsType = UIButtonImageInsetsTypeTop;
    self.CallButton.imageTop = 20;
    self.CallButton.margin = 10;
    self.defriendButton.imageInsetsType = UIButtonImageInsetsTypeTop;
    self.defriendButton.imageTop = 20;
    self.defriendButton.margin = 10;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (IBAction)messageAction:(UIButton *)sender {
    sender.enabled = NO;
    [self buttonAction:0];
    sender.enabled = YES;
}
- (IBAction)callAction:(UIButton *)sender {
    sender.enabled = NO;
    [self buttonAction:1];
    sender.enabled = YES;
}
- (IBAction)defriendAction:(UIButton *)sender {
    [MobClick event:UMeng_Event_Shield];
    sender.enabled = NO;
    [self buttonAction:2];
    sender.enabled = YES;
}

- (void)setCellDatas:(NSDictionary *)cellDatas
{
    _cellDatas = cellDatas;
    if ([_cellDatas[@"isBlack"] boolValue]) {
        [self.defriendButton setImage:[UIImage imageNamed:@"already_defriend"] forState:UIControlStateNormal];
        [self.defriendButton setTitle:@"已屏蔽" forState:UIControlStateNormal];
    }else{
        [self.defriendButton setImage:[UIImage imageNamed:@"defriend_nor"] forState:UIControlStateNormal];
        [self.defriendButton setTitle:@"屏蔽" forState:UIControlStateNormal];
    }
}

- (void)buttonAction:(NSInteger)type
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(callActionType:)]) {
        [self.delegate callActionType:type];
    }
}


@end
