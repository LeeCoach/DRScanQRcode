//
//  DRWeakProxy.h
//  DRScanQRcodeDemo
//
//  Created by liguizhi on 2017/11/25.
//  Copyright © 2017年 Liguizhi. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 弱代理对象，处理NSTimer或CADisplayLink导致的循环引用问题
 详见：https://github.com/ibireme/YYKit/blob/master/YYKit/Utility/YYWeakProxy.m
 
 示例:
 
 @implementation MyView
 {
 NSTimer *_timer;
 }
 
 - (void)initTimer
 {
 HMWeakProxy *proxy = [HMWeakProxy proxyWithTarget:self];
 _timer = [NSTimer timerWithTimeInterval:0.1 target:proxy selector:@selector(tick:) userInfo:nil repeats:YES];
 }
 
 - (void)tick:(NSTimer *)timer {...}
 
 @end
 */

@interface DRWeakProxy : NSProxy

/// 代理Target
@property (nullable, nonatomic, weak, readonly) id target;

/**
 根据Target, 创建弱代理对象
 
 @param target Target
 */
- (instancetype)initWithTarget:(id)target;

/**
 根据Target, 创建弱代理对象
 
 @param target Target
 */
+ (instancetype)proxyWithTarget:(id)target;

@end
