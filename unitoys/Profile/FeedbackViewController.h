//
//  FeedbackViewController.h
//  unitoys
//
//  Created by sumars on 16/9/22.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseViewController.h"
#import "UIPlaceHolderTextView.h"

@interface FeedbackViewController : BaseViewController<UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIPlaceHolderTextView *contentFeedback;
- (IBAction)feedback:(id)sender;

@end
