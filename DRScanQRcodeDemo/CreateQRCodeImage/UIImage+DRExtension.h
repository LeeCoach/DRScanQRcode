//
//  UIImage+DRExtension.h
//  DRScanQRcodeDemo
//
//  Created by liguizhi on 2017/11/27.
//  Copyright © 2017年 Liguizhi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (DRExtension)


/**
 根据字符串生成二维码

 @param str 字符串
 @param size 二维码图片大小
 @return 图片
 */
+ (UIImage *)QRCodeFromString:(NSString *)str size:(CGFloat)size;

/**
 *  生成自定义的二维码 （中间带图片,背景为二维码）
 *  @return 自定义二维码图片
 */
+ (UIImage *)QRCodeFromString:(NSString *)str size:(CGFloat)size iconImage:(UIImage *)iconImage iconImageSize:(CGFloat)iconImageSize;

/**
 两张图片合成一张
 
 @param bgImage 大图
 @param iconImage 小图
 @param iconImageSize 小图大小
 @return 返回图片
 */
+ (UIImage *)createNewImageWithBg:(UIImage *)bgImage iconImage:(UIImage *)iconImage iconImageSize:(CGFloat)iconImageSize;

@end
