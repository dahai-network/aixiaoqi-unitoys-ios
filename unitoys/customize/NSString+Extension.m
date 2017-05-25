//
//  NSString+Extension.m
//  unitoys
//
//  Created by sumars on 16/10/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "NSString+Extension.h"
#import "3des.h"

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

//十六进制
+(NSString *)doEncryptBuffer:(unsigned char *)buffer {
    NSLog(@"chaunjinlaide - %s", buffer);
    unsigned char keys[16] = {0x7a,0x3b,0x59,0x64,0xca,0x8e,0x9d,0xf2,0x17,0x2b,0x6d,0x48,0x01,0x39,0xfc,0x88};
    //    unsigned char keys[16] = {0x7a,0x3b,0x59,0x64,0xca,0x8e,0x9d,0xf2,0x7a,0x3b,0x59,0x64,0xca,0x8e,0x9d,0xf2};
//    unsigned char buffer[8] = {0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08};
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"iosSystemBit"]) {
        tdes_encrypt_for_ecb(buffer,sizeof(buffer)*2,keys);
    } else {
        tdes_encrypt_for_ecb(buffer,sizeof(buffer),keys);
    }
    
//    tdes_encrypt_for_ecb(buffer,sizeof(buffer),keys);
    NSData *datas = [NSData dataWithBytes:buffer length:8];
    NSUInteger          len = [datas length];
    char *              chars = (char *)[datas bytes];
    NSMutableString *   hexString = [[NSMutableString alloc] init];
    for(NSUInteger i = 0; i < len; i++ )
        [hexString appendString:[NSString stringWithFormat:@"%0.2hhx", chars[i]]];
    return hexString;
}

@end
