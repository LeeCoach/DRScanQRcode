//
//  DRScanQRCodeViewController.m
//  DRScanQRcodeDemo
//
//  Created by liguizhi on 2017/11/24.
//  Copyright © 2017年 Liguizhi. All rights reserved.
//

#import "DRScanQRCodeViewController.h"
#import <AudioToolbox/AudioToolbox.h>

#import "DRCameraHelper.h"
#import "DRWeakProxy.h"

static const CGFloat HMLHQRCodeScanSize = 231.0f;            ///< 扫描范围
static const CGFloat HMLHScanLineHeight = 5.0f;              ///< 扫描线高度
static const CGFloat HMLHScanLineTopMargin = 20.0f;          ///< 扫描线顶部误差距离
static const CGFloat HMLHScanLineStep = 1.6f;                ///< 扫描线每步距离
static const CGFloat HMLHExceediPhone6ScanBgFrameY = 179.0f;
static const CGFloat HMLHLessiPhone5ScanBgFrameY = 80.0f;
static const CGFloat HMLHiPhone5ScanBgFrameY = 120.0f;
// --- 提示文本
#define DRLHScanPromptedText @"将二维码放入框内，即可自动扫描"
// --- 设备Id参数字段名
#define DRLHScanDeviceIDQueryItemName @"id"


#define DRHEXRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define DXSCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define DXSCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define DXSCREEN_MAX_LENGTH (MAX(DXSCREEN_WIDTH, DXSCREEN_HEIGHT))
#define DXSCREEN_MIN_LENGTH (MIN(DXSCREEN_WIDTH, DXSCREEN_HEIGHT))

/// 这里的判断宏比较特殊，就不强制使用规范文档命名规则，请理解
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_4_OR_LESS (IS_IPHONE && DXSCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5 (IS_IPHONE && DXSCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && DXSCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && DXSCREEN_MAX_LENGTH == 736.0)

/// 判断屏幕宽度是6p以下的机型, 宽度<414的机型
#define IS_SCREEN_WIDTH_6p_LESS (IS_IPHONE && DXSCREEN_WIDTH < 414.0)
/// 判断屏幕宽度是6以下的机型, 宽度<375的机型
#define IS_SCREEN_WIDTH_6_LESS (IS_IPHONE && DXSCREEN_WIDTH < 375.0)


#define DRLog(FORMAT, ...) fprintf(stderr,"\n打印方法-------------->%s \n打印行数-------------->:%d \n打印内容-------------->:%s\n", __FUNCTION__, __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

@interface DRScanQRCodeViewController ()<AVCaptureMetadataOutputObjectsDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer; ///< 阅览图层
@property (nonatomic, weak) UIImageView *scanBgView;                    ///< 底框
@property (nonatomic, weak) UIImageView *scanLine;                      ///< 扫码线
@property (nonatomic, weak) UILabel *promptedLabel;                     ///< 提示文本层
@property (nonatomic, strong) UIButton *flashlightButton;       ///< 闪光灯按钮

@property (nonatomic, strong) CADisplayLink *displayLink; //定时器
@property (nonatomic, strong) AVCaptureSession *session;//会话桥梁

@property (nonatomic, assign) BOOL bDone;
@property (nonatomic, assign) __block BOOL isScanSuccess;
@property (nonatomic, assign) __block BOOL isOpenFlashlight;//手电筒是否开启

@end

@implementation DRScanQRCodeViewController

#pragma mark - Life cycle

- (void)dealloc
{
    // 停止会话
//    [self stopScanQRCode];
//    _bDone = NO;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    [self setupNavigation];
    
    [self setupContentView];
    
    [self layoutContentView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!_bDone)
    {
        [self sessionDidRun];
        _bDone = YES;
    }
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self sessionDidRun];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self sessionDidStop];
    [self.displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - <AVCaptureMetadataOutputObjectsDelegate>
- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (self.isScanSuccess) return;
    [self playBeep];
    
    if (metadataObjects.count > 0) {
        self.isScanSuccess = YES;
        
        if ([self.delegate respondsToSelector:@selector(dr_QRCodeScancaptureOutputMetadataObject:)]) {
            [self.delegate dr_QRCodeScancaptureOutputMetadataObject:metadataObjects.lastObject];
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
}
#pragma mark- AVCaptureVideoDataOutputSampleBufferDelegate 感应光度
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
    CFRelease(metadataDict);
    NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
    float brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
    
    NSLog(@"%f",brightnessValue);
    
    
    // 根据brightnessValue的值来打开和关闭闪光灯
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    BOOL result = [device hasTorch];// 判断设备是否有闪光灯
    if ((brightnessValue <= 0) && result) {// 打开闪光灯
        
        //是否已经开启
        BOOL lightOpened = [DRCameraHelper flashlightOpened];
        if (!lightOpened) { //如果光线过暗，自己开启
//            [self flashlightAction:self.flashlightButton];
        }
        self.flashlightButton.hidden = NO;
        
    }else if((brightnessValue > 0) && result) {// 关闭闪光灯
        
        //是否已经开启
        BOOL lightOpened = [DRCameraHelper flashlightOpened];
        if (!lightOpened) { //如果光线过暗，自己开启
            self.flashlightButton.hidden = YES;
        }else{
            self.flashlightButton.hidden = NO;
        }
    }
}

#pragma mark - ******UIImagePickerControllerDelegate******
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *pickerImage = info[UIImagePickerControllerOriginalImage];
    
    CIDetector*detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
    
    NSArray*features = [detector featuresInImage:[CIImage imageWithData:UIImagePNGRepresentation(pickerImage)]];
    
    if (features.count) {
        CIQRCodeFeature *feature = features.firstObject;
        
        NSString *resultStr = feature.messageString;
        
        if ([self.delegate respondsToSelector:@selector(dr_QRCodeAlbumChooseWithResult:)]) {
            [self.delegate dr_QRCodeAlbumChooseWithResult:resultStr];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(dr_QRCodeAlbumChooseWithResult:)]) {
            [self.delegate dr_QRCodeAlbumChooseWithResult:nil];
        }
    }
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{
        //.. done dismissing
    }];
}

#pragma mark - Public methods

- (void)stopScanQRCode
{
    // Stop animation
    if (self.displayLink)
    {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    // 关闭会话
    if (self.session)
    {
        [self.session stopRunning];
        self.session = nil;
    }
}

#pragma mark - Private methods

- (void)commonInit
{
    _isScanSuccess = NO;
}

- (void)setupNavigation
{
    self.navigationItem.title = @"扫一扫";
    
    [self setupHelperButton];
}

#pragma mark - Layout

- (void)setupContentView
{
    // Create session
    __weak typeof(self)weakSelf = self;
    [DRCameraHelper cameraAuthStatusWithSuccessCallback:^(void){
        __strong __typeof(self) strongSelf = weakSelf;
        [strongSelf setupScannerSession];
        [strongSelf sessionDidRun];
    } failedCallback:^(void){
        
    }];
    // Create animation
    DRWeakProxy *proxy = [DRWeakProxy proxyWithTarget:self];
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:proxy selector:@selector(scanAnimation)];
    self.displayLink = displayLink;
    // Setup scanner ui
    [self setupScannerUi];
}

- (void)setupScannerSession
{
    // Create session
    self.session = [self readQRCodeWithMetadataObjects];
    // Scan frame
    AVCaptureMetadataOutput *output = [[self.session outputs] firstObject];
    CGSize cropSize = self.view.bounds.size;
    CGRect cropRect = CGRectMake((DXSCREEN_WIDTH-HMLHQRCodeScanSize)/2.0, [self getScanBgFrameY], HMLHQRCodeScanSize, HMLHQRCodeScanSize);
    output.rectOfInterest = CGRectMake(
                                       cropRect.origin.y/DXSCREEN_HEIGHT,
                                       cropRect.origin.x/cropSize.width,
                                       HMLHQRCodeScanSize/cropSize.height,
                                       HMLHQRCodeScanSize/cropSize.width
                                       );
    // Create preview view
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
}

- (NSString *)devicedIDForQRCode:(NSString *)code
{
    if (!code) return nil;
    if (!code.length) return nil;
    
    NSURLComponents *components = [NSURLComponents componentsWithString:code];
    if (!components.queryItems.count) return nil;
    
    for (NSURLQueryItem *item in components.queryItems)
    {
        if ([item.name isEqualToString:DRLHScanDeviceIDQueryItemName]) return item.value;
    }
    
    return nil;
}

- (CGFloat)getScanBgFrameY
{
    CGFloat scanBgFrameY = HMLHExceediPhone6ScanBgFrameY;
    if (IS_IPHONE_4_OR_LESS)
    {
        scanBgFrameY = HMLHLessiPhone5ScanBgFrameY;
    }
    else if (IS_IPHONE_5)
    {
        scanBgFrameY = HMLHiPhone5ScanBgFrameY;
    }
    return scanBgFrameY;
}

- (void)playBeep
{
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"beep"ofType:@"wav"]], &soundID);
    AudioServicesPlaySystemSound(soundID);
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void)sessionDidRun
{
    if ([DRCameraHelper cameraAuthed])
    {
        [self.session startRunning];
    }
}

- (void)sessionDidStop
{
    if ([DRCameraHelper cameraAuthed])
    {
        [self.session stopRunning];
    }
}
#pragma mark - Event

// 扫描动画
- (void)scanAnimation
{
    CGRect scanLineFrame = self.scanLine.frame;
    CGFloat scanLineFrameY = scanLineFrame.origin.y+CGRectGetMinY(self.scanBgView.frame);
    if (scanLineFrameY >= CGRectGetMaxY(self.scanBgView.frame)-HMLHScanLineHeight)
    {
        scanLineFrame.origin.y = HMLHScanLineHeight-HMLHScanLineTopMargin;
    }
    else
    {
        scanLineFrame.origin.y += HMLHScanLineStep;
    }
    self.scanLine.frame = scanLineFrame;
}
- (void)albumButton:(UIButton *)button
{
    __weak typeof(self)weakSelf = self;
    [DRCameraHelper photoLibraryAuthStatusWithSuccessCallback:^{
        //打开相册
        if ([DRCameraHelper photoLibraryAuthed]) {
            __strong __typeof(self) strongSelf = weakSelf;
//            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
//            picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
//            picker.delegate = strongSelf;
            UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
            imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
            imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            imagePickerController.delegate = weakSelf;
            imagePickerController.modalPresentationStyle = UIModalPresentationPopover;
            
            UIPopoverPresentationController *presentationController = imagePickerController.popoverPresentationController;
//            presentationController.barButtonItem = button;  // display popover from the UIBarButtonItem as an anchor
            presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
            [strongSelf presentViewController:imagePickerController animated:YES completion:nil];
        }
        
    } failedCallback:^{
        
    }];
    
}

//开启手电筒
- (void)flashlightAction:(UIButton *)button
{
    BOOL lightOpened = [DRCameraHelper flashlightOpened];
    [DRCameraHelper openFlashlight:!lightOpened];
}

- (void)setupScannerUi
{
    // Scan Bg view
    UIImageView *scanBgView = [[UIImageView alloc] init];
    scanBgView.image = [UIImage imageNamed:@"hmlh_iot_scan_border"];
    scanBgView.clipsToBounds = YES;
    [self.view addSubview:scanBgView];
    self.scanBgView = scanBgView;
    
    // Scan line
    UIImageView *scanLine = [[UIImageView alloc] init];
    scanLine.image = [UIImage imageNamed:@"hmlh_iot_scan_line"];
    [self.scanBgView addSubview:scanLine];
    self.scanLine = scanLine;
    
    // Prompted Label
    UILabel *promptedLabel = [UILabel new];
    promptedLabel.textAlignment = NSTextAlignmentCenter;
    promptedLabel.textColor = DRHEXRGB(0xB9BEBD);
    promptedLabel.font = [UIFont systemFontOfSize:14];
    promptedLabel.text = DRLHScanPromptedText;
    [self.view addSubview:promptedLabel];
    self.promptedLabel = promptedLabel;
    
    //
    [self.view addSubview:self.flashlightButton];
    
}
- (void)layoutContentView
{
    __weak typeof(self)weakSelf = self;
    
//    UIFont *font = [UIFont systemFontOfSize:14];
    
    const CGFloat promptedTopInterval = 31.0;
//    const CGFloat buttonLeftInterval = 66.0;
//    const CGFloat buttonBottomInterval = IS_IPHONE_4_OR_LESS||IS_IPHONE_5?32.0:52.0;
//    const CGFloat buttonSize = 68.0;
//    const CGFloat labelExpandWidth = 2.0;
    
    self.scanBgView.frame = CGRectMake((DXSCREEN_WIDTH - HMLHQRCodeScanSize)/2, [weakSelf getScanBgFrameY], HMLHQRCodeScanSize, HMLHQRCodeScanSize);
    
    self.scanLine.frame = CGRectMake(self.scanBgView.frame.origin.x, CGRectGetMinY(self.scanBgView.frame) - 1, CGRectGetWidth(self.scanBgView.frame), HMLHScanLineHeight);

    self.promptedLabel.frame = CGRectMake(0, CGRectGetMaxY(self.scanBgView.frame) + promptedTopInterval, DXSCREEN_WIDTH, 30);

    self.flashlightButton.frame = CGRectMake(CGRectGetMaxX(self.scanBgView.frame) - 80, CGRectGetMaxY(self.scanBgView.frame) + 70, 80, 30);
}

#pragma mark - setters/getters

- (AVCaptureVideoPreviewLayer *)previewLayer
{
    if (!_previewLayer)
    {
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        _previewLayer.frame = self.view.bounds;
        _previewLayer.backgroundColor = [UIColor clearColor].CGColor;
        [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    }
    return _previewLayer;
}

- (void)setupHelperButton
{
    UIButton *albumButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50.0, 44.0)];
    [albumButton setTitleColor:DRHEXRGB(0xFFFFFF) forState:UIControlStateNormal];
    [albumButton setTitleColor:DRHEXRGB(0x6A6D6C) forState:UIControlStateHighlighted];
    [albumButton setTitle:@"相册" forState:UIControlStateNormal];
    albumButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
    [albumButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 5, 0, -5)];
    [albumButton addTarget:self action:@selector(albumButton:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:albumButton];
}

- (AVCaptureSession *)readQRCodeWithMetadataObjects
{
    // 1.获取输入设备(摄像头)
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 2.根据输入设备创建输入对象
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:NULL];
    
    // 3.创建输出对象
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    
    // 4.设置代理监听输出对象输出的数据
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // 5.创建会话(桥梁)
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    
    //创建设备输出流(光度)
    AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    //设置为高质量采集率
    [session setSessionPreset:AVCaptureSessionPresetHigh];
    
    // 6.添加输入和输出到会话中
    if ([session canAddInput:input]) {
        [session addInput:input];
    }
    if ([session canAddOutput:output]) {
        [session addOutput:output];
    }
    if ([session canAddOutput:dataOutput]) {
        [session addOutput:dataOutput];
    }
    
    // 注意: 设置输出对象能够解析的类型必须在输出对象添加到会话之后设置, 否则会报错
    // 7.告诉输出对象, 需要输出什么样的数据(支持解析什么样的格式)
    [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeDataMatrixCode,  AVMetadataObjectTypeITF14Code,
AVMetadataObjectTypeInterleaved2of5Code,AVMetadataObjectTypeAztecCode,AVMetadataObjectTypePDF417Code,AVMetadataObjectTypeCode128Code,AVMetadataObjectTypeCode93Code,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeCode39Mod43Code,AVMetadataObjectTypeCode39Code,AVMetadataObjectTypeUPCECode]];
    
    return session;
}

- (UIButton *)flashlightButton
{
    if (!_flashlightButton)
    {
        _flashlightButton = [[UIButton alloc] init];
//        [_flashlightButton setImage:[UIImage imageNamed:@"hmlh_iot_btn_flashlight"] forState:UIControlStateNormal];
        [_flashlightButton setTitle:@"打开手电筒" forState:UIControlStateNormal];
        _flashlightButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_flashlightButton setTitleColor:DRHEXRGB(0xFFFFFF) forState:UIControlStateNormal];
        [_flashlightButton setAdjustsImageWhenHighlighted:NO];
        [_flashlightButton addTarget:self action:@selector(flashlightAction:) forControlEvents:UIControlEventTouchUpInside];
        _flashlightButton.hidden = YES;
    }
    return _flashlightButton;
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
