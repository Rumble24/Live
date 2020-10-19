//
//  AppDelegate.m
//  Live
//
//  Created by 王景伟 on 2020/9/25.
//  Copyright © 2020 王景伟. All rights reserved.
//

#import "AppDelegate.h"
#import "LiveController.h"
#import "MeRecordController.h"
#import "OpenGLController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    LiveController *view = LiveController.new;
    view.title = @"框架";
    
    MeRecordController *record = MeRecordController.new;
    record.title = @"我的";
    
    OpenGLController *open = OpenGLController.new;
    open.title = @"OpenGL";

    UITabBarController *tabbar = [[UITabBarController alloc]init];
    tabbar.viewControllers = @[view,record,open];
    self.window.rootViewController = tabbar;

    return YES;
}

@end
