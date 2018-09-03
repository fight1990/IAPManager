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
    
    [[HXStoreKit sharedInstance] payProduct:productID tradeId:orderId success:^(HXStoreTransaction *transactionInfo) {
        
    } failure:^(NSError *error) {
        
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
