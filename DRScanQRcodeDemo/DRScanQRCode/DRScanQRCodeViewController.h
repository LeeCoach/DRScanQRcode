//
//  DRScanQRCodeViewController.h
//  DRScanQRcodeDemo
//
//  Created by liguizhi on 2017/11/24.
//  Copyright © 2017年 Liguizhi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@protocol DRScanQRCodeDelegate;


@interface DRScanQRCodeViewController : UIViewController

@property (nonatomic, assign) id<DRScanQRCodeDelegate> delegate;

@end

@protocol DRScanQRCodeDelegate <NSObject>

- (void)dr_QRCodeScancaptureOutputMetadataObject:(AVMetadataObject *)Objects;

- (void)dr_QRCodeAlbumChooseWithResult:(NSString *)result;

@end
