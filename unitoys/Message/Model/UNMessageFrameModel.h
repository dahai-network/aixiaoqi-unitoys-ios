//
//  UNMessageFrameModel.h
//  unitoys
//
//  Created by 黄磊 on 2017/6/26.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BaseModel.h"
#import "UNMessageModel.h"

#define MJTextFont [UIFont systemFontOfSize:14]
@interface UNMessageFrameModel : BaseModel

+ (UNMessageFrameModel *)modelWithMessage:(UNMessageModel *)message lastMessage:(UNMessageModel *)lastMessage;

/**
 *  头像的frame
 */
@property (nonatomic, assign, readonly) CGRect iconF;
/**
 *  时间的frame
 */
@property (nonatomic, assign, readonly) CGRect timeF;
/**
 *  正文的frame
 */
@property (nonatomic, assign, readonly) CGRect textF;
/**
 *  cell的高度
 */
@property (nonatomic, assign, readonly) CGFloat cellHeight;

/**
 *  容器的frame
 */
@property (nonatomic, assign, readonly) CGRect containerViewF;

@property (nonatomic, assign, readonly) UIEdgeInsets contentEdge;

/**
 *  数据模型
 */
@property (nonatomic, strong) UNMessageModel *message;

@end
