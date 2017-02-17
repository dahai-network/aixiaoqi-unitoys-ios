//
//  SearchContactsCell.m
//  unitoys
//
//  Created by 黄磊 on 2017/2/16.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "SearchContactsCell.h"
#import "ContactModel.h"



@implementation SearchContactsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)updateCellWithModel:(ContactModel *)model HightText:(NSString *)hightText
{
    if (!model || !hightText) {
        return;
    }
    self.iconImageView.image = [UIImage imageNamed:model.portrait];
    if (model.name) {
        self.nameLabel.text = model.name;
        NSMutableAttributedString *attriStr = [[NSMutableAttributedString alloc] initWithString:model.phoneNumber attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:13], NSForegroundColorAttributeName : [UIColor lightGrayColor]}];
        NSRange range = [model.phoneNumber rangeOfString:hightText];
        if (range.length) {
            [attriStr setAttributes:@{NSForegroundColorAttributeName : [UIColor blueColor]} range:range];
        }
        self.phoneLabel.attributedText = attriStr;
    }else{
        self.nameLabel.text = model.phoneNumber;
    }
}



- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
