//
//  AppDelegate.h
//  TestProject
//
//  Created by pengwei on 2018/8/20.
//  Copyright © 2018年 Wei PengWei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

