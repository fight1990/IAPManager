//
//  ViewController.m
//  TestProject
//
//  Created by pengwei on 2018/8/20.
//  Copyright © 2018年 Wei PengWei. All rights reserved.
//

#import "ViewController.h"
#import "HXStoreKit.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[HXStoreKit sharedInstance] startManager];
}

- (IBAction)productOneAction:(UIButton*)sender {
    ///9read_year_04 9read_year_05 9read_year_06
    NSString *productID = @"9read_year_04";
    if (sender.tag == 101) {
        productID = @"9read_year_05";
    } else if (sender.tag == 102) {
        productID = @"9read_year_06";
    }
    
    NSString *orderId = [NSString stringWithFormat:@"%@-%@",productID,[NSDate date]];
    
     [[HXStoreKit sharedInstance] payWithParam:@{[g_HXThirdPartyManager_PayParam_IAP_OrderStr copy]:orderId,[g_HXThirdPartyManager_PayParam_IAP_ProductIdStr copy]:productID} iapPayFinishBlock:^(BOOL success, NSDictionary *message) {
        NSLog(@"支付结果1 ：%d - %@",success, message);

    }];
    
}
- (IBAction)clearLocalData:(id)sender {
    NSArray<HXStoreTransaction*> *transactions = [[HXStoreKit sharedInstance] checkIAPTransactionReceipt];

    for (HXStoreTransaction *store in transactions) {
        [[HXStoreKit sharedInstance] removeCompleteTransaction:store];
    }
}
- (IBAction)removeLastOrder:(id)sender {
    NSArray<HXStoreTransaction*> *transactions = [[HXStoreKit sharedInstance] checkIAPTransactionReceipt];
    
    NSDictionary *item = [HXStoreTransaction dictionaryWithTransaction:[transactions lastObject]];
    [[HXStoreKit sharedInstance] removeCompleteTransaction:[transactions lastObject]];

    NSLog(@"删除的此本地藏品: %@", item);
}

- (IBAction)allAction:(id)sender {
    NSArray<HXStoreTransaction*> *transactions = [[HXStoreKit sharedInstance] checkIAPTransactionReceipt];
    
    for (HXStoreTransaction *store in transactions) {
        NSDictionary *item = [HXStoreTransaction dictionaryWithTransaction:store];
        NSLog(@"本地藏品: %@", item);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
