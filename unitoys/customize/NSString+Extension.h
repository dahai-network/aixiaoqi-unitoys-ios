//
//  NSString+Extension.h
//  unitoys
//
//  Created by sumars on 16/10/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonCrypto.h>

@interface NSString (Extension)
- (CGSize)sizeWithFont:(UIFont *)font maxSize:(CGSize)maxSize;
+(NSString *)stringFromHexString:(NSString *)hexString;
+(NSString *)doEncryptBuffer:(unsigned char *)buffer;
@end
