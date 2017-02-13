//
//  WriteMessageViewController.h
//  unitoys
//
//  Created by sumars on 16/10/9.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseViewController.h"
#import "KTAutoHeightTextView.h"

@interface WriteMessageViewController : BaseViewController
@property (weak, nonatomic) IBOutlet UITextField *txtReceiveMan;
@property (weak, nonatomic) IBOutlet KTAutoHeightTextView *txtMessageContent;
- (IBAction)addReceiveMan:(id)sender;
- (IBAction)sendMessage:(id)sender;

@end
