//
//  AppDelegate.m
//  Live
//
//  Created by 王景伟 on 2020/9/25.
//  Copyright © 2020 王景伟. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "MeRecordController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    ViewController *view = ViewController.new;
    view.title = @"框架";
    
    MeRecordController *record = MeRecordController.new;
    record.title = @"我的";
    
    UITabBarController *tabbar = [[UITabBarController alloc]init];
    tabbar.viewControllers = @[view,record];
    self.window.rootViewController = tabbar;

    return YES;
}

@end
