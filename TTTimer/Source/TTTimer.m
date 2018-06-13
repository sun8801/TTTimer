//
//  TTTimer.m
//  TTTimer
//
//  Created by sun-zt on 2018/6/13.
//  Copyright © 2018年 MOMO. All rights reserved.
//

#import "TTTimer.h"

#define TTLOCK   dispatch_semaphore_wait(TT_lock, DISPATCH_TIME_FOREVER);
#define TTUNLOCK dispatch_semaphore_signal(TT_lock);

@interface TTTimer ()

@end

@implementation TTTimer {
    __weak id TT_target;
    SEL       TT_selector;
    id        TT_userInfo;
    
    BOOL      TT_repeats;
    BOOL      TT_isValid;
    BOOL      TT_isSuspend;
    BOOL      TT_needCallMain;
    BOOL      TT_isSync;
    
    NSTimeInterval TT_timeInterval;
    
    dispatch_source_t    TT_sourceTimer;
    dispatch_queue_t     TT_targetQueue;
    dispatch_semaphore_t TT_lock;
    
    TTTimerCallBlock     TT_timerCallBlock;
}

- (void)dealloc {
    [self invalidate];
}

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                   targetQueue:(nullable dispatch_queue_t)targetQueue
                                        target:(id)target
                                      selector:(SEL)selector
                                      userInfo:(nullable id)userInfo
                                        repeat:(BOOL)yesOrNo {
    TTTimer *timer = [[[self class] alloc] initWithTimeInterval:interval
                                                    targetQueue:targetQueue
                                                         target:target
                                                       selector:selector
                                                       userInfo:userInfo
                                                         repeat:yesOrNo];
    [timer fire];
    
    return timer;
}

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                        target:(id)aTarget
                                      selector:(SEL)aSelector
                                      userInfo:(nullable id)userInfo
                                       repeats:(BOOL)yesOrNo {
    return [[self class] scheduledTimerWithTimeInterval:interval
                                            targetQueue:nil
                                                 target:aTarget
                                               selector:aSelector
                                               userInfo:userInfo
                                                 repeat:yesOrNo];
}

- (instancetype)initWithTimeInterval:(NSTimeInterval)interval
                         targetQueue:(nullable dispatch_queue_t)targetQueue
                              target:(id)target
                            selector:(SEL)selector
                            userInfo:(nullable id)userInfo
                              repeat:(BOOL)yesOrNo {
    self = [super init];
    if (self) {
        TT_target   = target;
        TT_selector = selector;
        TT_repeats  = yesOrNo;
        
        TT_isSuspend= NO;
        
        TT_timeInterval = interval;
        TT_userInfo     = userInfo;
        
        if (interval > 0.0) {
            TT_lock = dispatch_semaphore_create(1);
            if (targetQueue) {
                TT_targetQueue = targetQueue;
            }else {
                TT_targetQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            }
        }
        [self resetTimerIsValidOrNO];
    }
    return self;
}

- (instancetype)initWithTimeInterval:(NSTimeInterval)interval
                         targetQueue:(dispatch_queue_t)targetQueue
                            userInfo:(id)userInfo
                              repeat:(BOOL)yesOrNo
                           callBlock:(TTTimerCallBlock)callBlock {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    self = [self initWithTimeInterval:interval targetQueue:targetQueue target:nil selector:nil userInfo:userInfo repeat:yesOrNo];
#pragma clang diagnostic pop
    if (self) {
        TT_timerCallBlock = callBlock;
        [self resetTimerIsValidOrNO];
    }
    return self;
}

- (void)needCallToMainQueue:(BOOL)isMain isSyncCall:(BOOL)isSync {
    TTLOCK
    TT_needCallMain = isMain;
    TT_isSync = isSync;
    TTUNLOCK;
}

- (void)fire {
    TTLOCK
    if (!TT_sourceTimer && TT_isValid) {
        TT_sourceTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, TT_targetQueue);
        
        dispatch_time_t time_t = dispatch_walltime(NULL, TT_timeInterval * NSEC_PER_SEC);
        if (TT_repeats) {
            dispatch_source_set_timer(TT_sourceTimer, time_t, (TT_timeInterval * NSEC_PER_SEC), _nanoSecondsOfLeeway);
        }
        else {
            dispatch_source_set_timer(TT_sourceTimer, time_t, DISPATCH_TIME_FOREVER, _nanoSecondsOfLeeway);
        }
        
        __weak __typeof(self) weakSelf = self;
        dispatch_source_set_event_handler(TT_sourceTimer, ^{
            if (weakSelf) {
                [weakSelf timerFiredMethod];
            }
        });
        dispatch_resume(TT_sourceTimer);
    }else {
        if (TT_isSuspend && TT_sourceTimer && TT_isValid) {
            dispatch_resume(TT_sourceTimer);
            TT_isSuspend = NO;
        }
    }
    TTUNLOCK
}

- (void)pause {
    TTLOCK
    if (TT_sourceTimer && TT_isValid && !TT_isSuspend) {
        dispatch_suspend(TT_sourceTimer);
        TT_isSuspend = YES;
    }
    TTUNLOCK
}

- (void)invalidate {
    TTLOCK
    if (TT_isValid && TT_sourceTimer) {
        TT_isValid = NO;
        TT_target      = nil;
        TT_selector    = NULL;
        
        if (TT_isSuspend) {
            dispatch_resume(TT_sourceTimer);// 挂起后必须先resume
        }
        dispatch_source_cancel(TT_sourceTimer);
        
        TT_sourceTimer = nil;
    }
    TTUNLOCK
}

#pragma mark - privte
- (void)timerFiredMethod {
    if (!TT_isValid) {
        return;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ((TT_target && TT_selector) || TT_timerCallBlock) {
        dispatch_block_t block_t = ^() {
            if (self->TT_target) {
                [self->TT_target performSelector:self->TT_selector withObject:self];
            }else if (self->TT_timerCallBlock) {
                self->TT_timerCallBlock(self);
            }
        };
        if (TT_needCallMain) {
            BOOL isSync = ![NSThread isMainThread] && TT_isSync;
            isSync? dispatch_sync(dispatch_get_main_queue(), block_t):dispatch_async(dispatch_get_main_queue(), block_t);
        }else {
            block_t();
        }
    }else {
        [self invalidate];
        return;
    }
    
    if (!TT_repeats) {
        [self invalidate];
    }
#pragma clang diagnostic pop
}

- (void)resetTimerIsValidOrNO {
    if ((TT_target || TT_timerCallBlock) && TT_timeInterval > 0) {
        TT_isValid = YES;
    }else {
        TT_isValid = NO;
    }
}

#pragma mark - getter

- (id)userInfo {
    return TT_userInfo;
}

- (NSTimeInterval)timeInterval {
    return TT_timeInterval;
}

- (BOOL)isValid {
    return TT_isValid;
}

@end
