//
//  FirstViewController.m
//  TestProject
//
//  Created by butcher on 2018/9/10.
//  Copyright © 2018年 Wei PengWei. All rights reserved.
//

#import "FirstViewController.h"
#import "HXStoreKit.h"

@interface FirstViewController ()

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (IBAction)shoppingAction:(id)sender {
    
    NSString *productID = @"9read_year_06";
    NSString *orderId = [NSString stringWithFormat:@"%@-%@",productID,[NSDate date]];

    [[HXStoreKit sharedInstance] payWithParam:@{[g_HXThirdPartyManager_PayParam_IAP_OrderStr copy]:orderId,[g_HXThirdPartyManager_PayParam_IAP_ProductIdStr copy]:productID} iapPayFinishBlock:^(BOOL success, NSDictionary *message) {
        NSLog(@"支付结果2 ：%d - %@",success, message);
    }];
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
