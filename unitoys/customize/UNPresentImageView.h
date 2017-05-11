//
//  UNPresentImageView.h
//  unitoys
//
//  Created by 黄磊 on 2017/5/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UNPresentImageView : UIView
typedef void(^ImageViewTapBlock)();

+ (instancetype)sharePresentImageViewWithImageUrl:(NSString *)imageUrl cancelImageName:(NSString *)cancelName imageTap:(ImageViewTapBlock)imageBlock;

- (instancetype)initPresentImageViewWithImageUrl:(NSString *)imageUrl cancelImageName:(NSString *)cancelName imageTap:(ImageViewTapBlock)imageBlock;

@end
