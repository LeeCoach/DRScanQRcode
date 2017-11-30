//
//  DRCameraHelper.h
//  DRScanQRcodeDemo
//
//  Created by liguizhi on 2017/11/25.
//  Copyright © 2017年 Liguizhi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DRCameraHelper : NSObject

/// 闪光灯开启状态
+ (BOOL)flashlightOpened;

/// 控制闪光灯动态
+ (void)openFlashlight:(BOOL)status;

/// 获取相机是否授权状态
+ (BOOL)cameraAuthed;

/// 回调授权结果
+ (void)cameraAuthStatusWithSuccessCallback:(void(^)())successCallback failedCallback:(void(^)())failedCallback;

/// 获取相册是否授权状态
+ (BOOL)photoLibraryAuthed;

/// 相册回调授权结果
+ (void)photoLibraryAuthStatusWithSuccessCallback:(void(^)())successCallback failedCallback:(void(^)())failedCallback;


@end
