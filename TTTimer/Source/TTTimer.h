//
//  TTTimer.h
//  TTTimer
//
//  Created by sun-zt on 2018/6/13.
//  Copyright © 2018年 MOMO. All rights reserved.
//使用dispatch_source_t实现的timer，不会显式的retain timer的target，
//可以指定dispatch_source_t的queue，如果不指定会使用系统的dispatch_global_queue

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TTTimer;

typedef void(^TTTimerCallBlock)(TTTimer *timer);

@interface TTTimer : NSObject

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)interval targetQueue:(nullable dispatch_queue_t)targetQueue target:(id)target selector:(SEL)selector userInfo:(nullable id)userInfo repeat:(BOOL)yesOrNo;

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)interval target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo;

//--------------------需主动调用 fire------------------------//
- (instancetype)initWithTimeInterval:(NSTimeInterval)interval targetQueue:(nullable dispatch_queue_t)targetQueue target:(id)target selector:(SEL)selector userInfo:(nullable id)userInfo repeat:(BOOL)yesOrNo;

- (instancetype)initWithTimeInterval:(NSTimeInterval)interval targetQueue:(nullable dispatch_queue_t)targetQueue userInfo:(nullable id)userInfo repeat:(BOOL)yesOrNo callBlock:(TTTimerCallBlock)callBlock;

@property (nullable, readonly, strong) id            userInfo;

@property (readonly) NSTimeInterval                  timeInterval;

@property (readonly, getter=isValid)BOOL             valid;

//The nanosecond leeway for the timer. 精确度 默认0
@property (nonatomic, assign) NSInteger              nanoSecondsOfLeeway;

/**
 设置timer回调是否返回主线程回调，默认在这是的targetQueue中

 @param isMain 是否返回主线程
 @param isSync if isMain == YES 》isSync YES sync or async mainqueue
 */
- (void)needCallToMainQueue:(BOOL)isMain isSyncCall:(BOOL)isSync;

- (void)invalidate;

- (void)fire;

- (void)pause;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
