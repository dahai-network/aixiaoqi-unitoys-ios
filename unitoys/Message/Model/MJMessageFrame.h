//
//  MJMessageFrame.h
//  unitoys
//
//  Created by sumars on 16/10/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

// 正文的字体
#define MJTextFont [UIFont systemFontOfSize:14]

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class MJMessage;

@interface MJMessageFrame : NSObject
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
@property (nonatomic, strong) MJMessage *message;
@end
