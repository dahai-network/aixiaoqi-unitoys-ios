//
//  CutomButton.h
//  unitoys
//
//  Created by 董杰 on 2017/3/20.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CutomButton : UIButton
{
    UIColor *lineColor;
}
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, assign) BOOL isHiddenLine;
-(void)setColor:(UIColor*)color;
@end
