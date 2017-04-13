//
//  UNEditMessageView.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/12.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^EditMessageActionBlock)(NSInteger buttonTag);
@interface UNEditMessageView : UIView

@property (nonatomic, copy) EditMessageActionBlock editMessageActionBlock;

@end
