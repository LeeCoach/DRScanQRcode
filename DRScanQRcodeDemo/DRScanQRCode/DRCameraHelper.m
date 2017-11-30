//
//  DRCameraHelper.m
//  DRScanQRcodeDemo
//
//  Created by liguizhi on 2017/11/25.
//  Copyright © 2017年 Liguizhi. All rights reserved.
//

#import "DRCameraHelper.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

#define SYSTEM_VERSION_LESS_THAN(version) ([[[UIDevice currentDevice] systemVersion] compare:version options:NSNumericSearch] == NSOrderedAscending)

@interface DRCameraHelper ()<UIAlertViewDelegate>

@end

@implementation DRCameraHelper

+ (BOOL)flashlightOpened
{
    BOOL bOpened = FALSE;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (![device hasTorch])
    {
        bOpened = FALSE;
    }
    else
    {
        bOpened = [device torchMode] == AVCaptureTorchModeOn;
    }
    return bOpened;
}

+ (void)openFlashlight:(BOOL)status
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType: AVMediaTypeVideo];//[self.reader.readerView device];
    if ([device hasTorch])
    {
        if (status)
        {
            // open
            if(device.torchMode != AVCaptureTorchModeOn ||
               device.flashMode != AVCaptureFlashModeOn)
            {
                [device lockForConfiguration:nil];
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
                [device unlockForConfiguration];
            }
        }
        else
        {
            // close
            if(device.torchMode != AVCaptureTorchModeOff ||
               device.flashMode != AVCaptureFlashModeOff)
            {
                [device lockForConfiguration:nil];
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
                [device unlockForConfiguration];
            }
        }
    }
}

+ (BOOL)cameraAuthed
{
    BOOL bAuthed = FALSE;
    if (!SYSTEM_VERSION_LESS_THAN(@"7.0"))
    {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        switch (authStatus) {
            case AVAuthorizationStatusNotDetermined:
            {
                bAuthed = FALSE;
            }
                break;
            case AVAuthorizationStatusAuthorized:
            {
                bAuthed = TRUE;
            }
                break;
            case AVAuthorizationStatusDenied:
            case AVAuthorizationStatusRestricted:
            {
                bAuthed = FALSE;
            }
                break;
            default:
                break;
        }
    }
    return bAuthed;
}

+ (void)cameraAuthStatusWithSuccessCallback:(void(^)())successCallback failedCallback:(void(^)())failedCallback
{
    if (!SYSTEM_VERSION_LESS_THAN(@"7.0"))
    {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        switch (authStatus)
        {
            case AVAuthorizationStatusNotDetermined:
            {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        if (granted) {
                            !successCallback?:successCallback();
                        } else {
                            [DRCameraHelper showTipsAlertView];
                            !failedCallback?:failedCallback();
                        }
                    });
                }];
            }
                break;
            case AVAuthorizationStatusAuthorized:
            {
                !successCallback?:successCallback();
            }
                break;
            case AVAuthorizationStatusDenied:
            case AVAuthorizationStatusRestricted:
            {
                [DRCameraHelper showTipsAlertView];
                !failedCallback?:failedCallback();
            }
                break;
            default:
                break;
        }
    }
}

/// 获取相册是否授权状态
+ (BOOL)photoLibraryAuthed
{
    BOOL bAuthed = FALSE;
    if (!SYSTEM_VERSION_LESS_THAN(@"7.0"))
    {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        switch (status) {
            case PHAuthorizationStatusNotDetermined:
            {
                bAuthed = FALSE;
            }
                break;
            case PHAuthorizationStatusAuthorized:
            {
                bAuthed = TRUE;
            }
                break;
            case PHAuthorizationStatusDenied:
            case PHAuthorizationStatusRestricted:
            {
                bAuthed = FALSE;
            }
                break;
            default:
                break;
        }
    }
    return bAuthed;
}

/// 相册回调授权结果
+ (void)photoLibraryAuthStatusWithSuccessCallback:(void(^)())successCallback failedCallback:(void(^)())failedCallback
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        if (!SYSTEM_VERSION_LESS_THAN(@"7.0")) {
            PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
            if (status == PHAuthorizationStatusNotDetermined) {
                
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                    if (status == PHAuthorizationStatusNotDetermined) {
                        [DRCameraHelper showPhotoTipsAlertView];
                        !failedCallback?:failedCallback();
                    } else if (status == PHAuthorizationStatusRestricted) {
                        [DRCameraHelper showPhotoTipsAlertView];
                        !failedCallback?:failedCallback();
                    } else if (status == PHAuthorizationStatusDenied) {
                        [DRCameraHelper showPhotoTipsAlertView];
                        !failedCallback?:failedCallback();
                    } else {
                        // PHAuthorizationStatusAuthorized
                        !successCallback?:successCallback();
                    }
                }];
                
            } else if (status == PHAuthorizationStatusRestricted) {
                [DRCameraHelper showPhotoTipsAlertView];
                !failedCallback?:failedCallback();
            } else if (status == PHAuthorizationStatusDenied) {
                [DRCameraHelper showPhotoTipsAlertView];
                !failedCallback?:failedCallback();
            } else {
                // PHAuthorizationStatusAuthorized
                !successCallback?:successCallback();
                
            }
        }
    } else {
        
    }
}

#pragma mark - Private Method

+ (void)showTipsAlertView
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"请检查是否允许访问相机" message:@"请到“设置->隐私->相机”中开启【扫一扫】相机访问，以便于扫一扫为你提供更好的使用体验。" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
    [alertView show];
}

+ (void)showPhotoTipsAlertView
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"请检查是否允许访问相册" message:@"请到“设置->隐私->相机”中开启【扫一扫】相机访问，以便于扫一扫为你提供更好的使用体验。" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
    [alertView show];
}

#pragma mark - <UIAlertViewDelegate>

+ (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (1 == buttonIndex)
    {
        // ios8 及以上点击跳转到设置
        if (UIApplicationOpenSettingsURLString != NULL)
        {
            NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:appSettings];
        }
    }
}

@end
