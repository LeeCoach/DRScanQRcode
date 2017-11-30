//
//  ViewController.m
//  DRScanQRcodeDemo
//
//  Created by liguizhi on 2017/11/24.
//  Copyright © 2017年 Liguizhi. All rights reserved.
//

#define DRLog(FORMAT, ...) fprintf(stderr,"\n打印方法-------------->%s \n打印行数-------------->:%d \n打印内容-------------->:%s\n", __FUNCTION__, __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

#import "ViewController.h"
#import "DRScanQRCodeViewController.h"
#import "DRCreateQRCodeImageViewController.h"
#import <SVProgressHUD.h>

@interface ViewController () <DRScanQRCodeDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)startScan:(UIButton *)sender {
    DRScanQRCodeViewController *vc = [[DRScanQRCodeViewController alloc] init];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}
- (IBAction)generateCode:(UIButton *)sender {
//    DRCreateQRCodeImageViewController *vc = [[DRCreateQRCodeImageViewController alloc] init];
//    [self.navigationController pushViewController:vc animated:YES];
}
- (void)dr_QRCodeScancaptureOutputMetadataObject:(AVMetadataObject *)Objects
{
    AVMetadataMachineReadableCodeObject *obj = (AVMetadataMachineReadableCodeObject *)Objects;
    self.textView.text = obj.stringValue;
    DRLog(@"%@",obj);
    if (obj.type == AVMetadataObjectTypeQRCode) {
        DRLog(@"二维码");
    } else {
        DRLog(@"条形码");
    }
}

- (void)dr_QRCodeAlbumChooseWithResult:(NSString *)result
{
    if (result) {
        self.textView.text = result;
    } else {
        [SVProgressHUD showSuccessWithStatus:@"无法识别图中二维码"];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
