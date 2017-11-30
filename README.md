

# DRScanQRcode

iOS原生源码扫描识别二维码及条形码，任意字符串生成二维码

![IMG_0201](/Users/coach/Downloads/IMG_0201.PNG)

### 注意

* 扫描会要求访问摄像头权限，如果从图片识别就要访问相册权限了

  ```
  <key>NSCameraUsageDescription</key>
      <string>为您提供更好的使用体验，扫一扫需要使用您的相册</string>
  <key>NSPhotoLibraryUsageDescription</key>
      <string>为您提供更好的使用体验，扫一扫需要使用您的相机</string>
  ```

  ​

> 必须真机测试，而且已经设置上面两项，否则会闪退



### 判断是否开启访问权限

```
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
```

