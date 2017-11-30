//
//  DRCreateQRCodeImageViewController.m
//  DRScanQRcodeDemo
//
//  Created by liguizhi on 2017/11/27.
//  Copyright © 2017年 Liguizhi. All rights reserved.
//

#import "DRCreateQRCodeImageViewController.h"
#import "TPKeyboardAvoidingScrollView.h"
#import "UIImage+DRExtension.h"
#import <SVProgressHUD.h>
#import <Masonry.h>

#define DXSCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define DXSCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)

@interface DRCreateQRCodeImageViewController () <UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIImageView *showQRImage;
@property (weak, nonatomic) IBOutlet TPKeyboardAvoidingScrollView *scrollView;

@end

@implementation DRCreateQRCodeImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"生成二维码";
    
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
    
    [self.showQRImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.scrollView.mas_top).offset(30);
        make.centerX.mas_equalTo(self.scrollView.mas_centerX);
        make.size.mas_equalTo(CGSizeMake(200, 200));
    }];
    
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.showQRImage.mas_bottom).offset(30);
        make.leading.mas_equalTo(self.scrollView.mas_leading).offset(20);
        make.trailing.mas_equalTo(self.scrollView.mas_trailing).offset(-20);
        make.bottom.mas_equalTo(self.scrollView.mas_bottom).offset(-30);
        make.width.mas_equalTo(DXSCREEN_WIDTH - 40);
        make.height.mas_equalTo(150);
    }];
}


- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self.showQRImage setImage:[UIImage QRCodeFromString:self.textView.text size:200.0]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
