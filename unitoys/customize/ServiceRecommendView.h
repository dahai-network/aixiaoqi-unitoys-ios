//
//  ServiceRecommendView.h
//  unitoys
//
//  Created by 黄磊 on 2017/5/12.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ServiceRecommendView : UIView

typedef void(^ButtonTapBlock)(NSInteger index, BOOL isNoTip);

+ (instancetype)shareServiceRecommendViewWithTitle:(NSString *)title leftString:(NSString *)leftName rightString:(NSString *)rightName buttnTap:(ButtonTapBlock)buttonTapBlock;

- (instancetype)initServiceRecommendViewWithTitle:(NSString *)title leftString:(NSString *)leftName rightString:(NSString *)rightName buttnTap:(ButtonTapBlock)buttonTapBlock;

@end
