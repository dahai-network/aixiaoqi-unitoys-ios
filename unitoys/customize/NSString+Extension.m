//
//  NSString+Extension.m
//  unitoys
//
//  Created by sumars on 16/10/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "NSString+Extension.h"

@implementation NSString (Extension)
- (CGSize)sizeWithFont:(UIFont *)font maxSize:(CGSize)maxSize
{
    NSDictionary *attrs = @{NSFontAttributeName : font};
    return [self boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
}


+(NSString *)stringFromHexString:(NSString *)hexString {
    char *myBuffer = (char *)malloc((int)[hexString length] / 2 +1);
    
    bzero(myBuffer, [hexString length] / 2 + 1);
    
    for (int i =0; i < [hexString length] - 1; i += 2) {
        
        unsigned int anInt;
        
        NSString * hexCharStr = [hexString substringWithRange:NSMakeRange(i, 2)];
        
        NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr] ;
        
        [scanner scanHexInt:&anInt];
        
        myBuffer[i / 2] = (char)anInt;
        
        NSLog(@"myBuffer is %c",myBuffer[i /2] );
        
    }
    
    NSString *unicodeString = [NSString stringWithCString:myBuffer encoding:4];
//    NSString *unicodeString = [[NSString alloc] initWithUTF8String:myBuffer];
    
    NSLog(@"———字符串=======%@",unicodeString);
    
    return unicodeString; 
    
}
@end
