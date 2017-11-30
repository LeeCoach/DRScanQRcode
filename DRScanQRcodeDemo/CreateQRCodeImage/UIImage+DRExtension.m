//
//  UIImage+DRExtension.m
//  DRScanQRcodeDemo
//
//  Created by liguizhi on 2017/11/27.
//  Copyright © 2017年 Liguizhi. All rights reserved.
//

#import "UIImage+DRExtension.h"

@implementation UIImage (DRExtension)

+ (UIImage *)QRCodeFromString:(NSString *)str size:(CGFloat)size
{
    // 1.创建过滤器
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    // 2.恢复默认
    [filter setDefaults];
    
    // 3.给过滤器添加数据(正则表达式/账号和密码)
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKeyPath:@"inputMessage"];
    
    // 4.获取输出的二维码
    CIImage *outputImage = [filter outputImage];
    
    // 5.返回二维码
    return [self createNonInterpolatedUIImageFormCIImage:outputImage withSize:size];
}

/**
 *  生成自定义的二维码 （中间带图片,背景为二维码）
 *  @return 自定义二维码图片
 */
+ (UIImage *)QRCodeFromString:(NSString *)str size:(CGFloat)size iconImage:(UIImage *)iconImage iconImageSize:(CGFloat)iconImageSize
{
    // 背景为普通二维码
    UIImage *bgImage = [self QRCodeFromString:str size:size];

    UIImage *newImage = [UIImage createNewImageWithBg:bgImage iconImage:iconImage iconImageSize:iconImageSize];
    return newImage;
    
    
}


/**
 两张图片合成一张

 @param bgImage 大图
 @param iconImage 小图
 @param iconImageSize 小图大小
 @return 返回图片
 */
+ (UIImage *)createNewImageWithBg:(UIImage *)bgImage iconImage:(UIImage *)iconImage iconImageSize:(CGFloat)iconImageSize
{
    // 1.开启图片上下文
    UIGraphicsBeginImageContext(bgImage.size);
    // 2.绘制背景
    [bgImage drawInRect:CGRectMake(0, 0, bgImage.size.width, bgImage.size.height)];
    
    // 3.绘制图标
    CGFloat imageW = iconImageSize;
    CGFloat imageH = iconImageSize;
    CGFloat imageX = (bgImage.size.width - imageW) * 0.5;
    CGFloat imageY = (bgImage.size.height - imageH) * 0.5;
    [iconImage drawInRect:CGRectMake(imageX, imageY, imageW, imageH)];
    
    // 4.取出绘制好的图片
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    // 5.关闭上下文
    UIGraphicsEndImageContext();
    // 6.返回生成好得图片
    return newImage;
}

+ (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat)size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}



@end
