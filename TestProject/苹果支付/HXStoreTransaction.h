//
//  HXStoreTransaction.h
//  TestProject
//
//  Created by pengwei on 2018/8/21.
//  Copyright © 2018年 Wei PengWei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface HXStoreTransaction : NSObject<NSCoding>

@property(nonatomic, copy) NSString *orderId;
@property(nonatomic, copy) NSString *productIdentifier;
@property(nonatomic, copy) NSString *transactionDate;
@property(nonatomic, copy) NSString *transactionIdentifier;
@property(nonatomic, copy) NSString *transactionReceiptString;
@property(nonatomic, assign) BOOL sandbox;

- (instancetype)initWithPaymentTransaction:(SKPaymentTransaction*)paymentTransaction;

+ (NSDictionary*)dictionaryWithTransaction:(HXStoreTransaction*)transaction;
+ (HXStoreTransaction*)transactionWithDictionary:(NSDictionary*)dictionary;

- (BOOL)isEqual:(id)object;

@end
