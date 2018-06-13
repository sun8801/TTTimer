//
//  TTViewController.m
//  TTTimer
//
//  Created by sun-zt on 2018/6/13.
//  Copyright © 2018年 MOMO. All rights reserved.
//

#import "TTViewController.h"
#import "TTTimer.h"

@interface TTViewController ()

@property (nonatomic, strong) TTTimer *timer;

@end

@implementation TTViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    self.timer = [[TTTimer alloc] initWithTimeInterval:1.f targetQueue:nil target:self selector:@selector(timerFire:) userInfo:nil repeat:YES];
    
    __weak typeof(self) weakSelf = self;
    self.timer = [[TTTimer alloc] initWithTimeInterval:1.f targetQueue:nil userInfo:nil repeat:YES callBlock:^(TTTimer * _Nonnull timer) {
        NSLog(@">>>>block>>%@>",weakSelf);
    }];
}

- (IBAction)fire:(UIButton *)sender {
    [self.timer fire];
}

- (IBAction)pause:(UIButton *)sender {
    [self.timer pause];
}
- (IBAction)ttSupend:(UIButton *)sender {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@">>>>suspend>>:");
    });
}

- (void)timerFire:(TTTimer *)timer {
    NSLog(@">>>>>>>>>:%@", timer);
}

@end
