//
//  UNPresentTool.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/21.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UNPresentTool : NSObject

//- (void)presentContentView:(UIView *)contentView duration:(NSTimeInterval)duration;
- (void)presentContentView:(UIView *)contentView duration:(NSTimeInterval)duration inView:(UIView *)superView;

- (void)dismissDuration:(NSTimeInterval)duration;

@end
