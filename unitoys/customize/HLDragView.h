//
//  HLDragView.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/17.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "AddTouchAreaButton.h"

@interface HLDragButton : AddTouchAreaButton
//开始拖拽位置
@property (nonatomic, assign) CGPoint startPoint;
//中心位置
@property (nonatomic, assign) CGPoint startCenter;

@end
