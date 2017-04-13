//
//  CallDetailsNameCell.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CallDetailsNameCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (nonatomic, copy) NSDictionary *cellDatas;

@end
