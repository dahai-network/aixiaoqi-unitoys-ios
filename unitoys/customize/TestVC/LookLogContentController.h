//
//  LookLogContentController.h
//  unitoys
//
//  Created by 黄磊 on 2017/6/19.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LookLogContentController : UIViewController
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;
@property (nonatomic, copy) NSString *text;
@end
