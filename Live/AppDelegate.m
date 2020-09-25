//
//  AppDelegate.m
//  Live
//
//  Created by 王景伟 on 2020/9/25.
//  Copyright © 2020 王景伟. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    
    self.window.rootViewController = [[UINavigationController alloc]initWithRootViewController:ViewController.new];
    
    [self.window makeKeyAndVisible];
    return YES;
}

@end
