//
//  HXStoreKeyChainPresenter.h
//  TestProject
//
//  Created by pengwei on 2018/8/21.
//  Copyright © 2018年 Wei PengWei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HXStoreTransaction.h"

@interface HXStoreKeyChainPresenter : NSObject

/**
 将交易订单信息进行本地存储
 
 @param transaction 交易订单信息对象
 */
- (void)persistTransaction:(HXStoreTransaction*)transaction;

/**
 移除指定订单信息

 @param transaction 交易订单信息对象
 */
- (void)removeTransaction:(HXStoreTransaction*)transaction;

/**
 移除本地所有交易订单信息
 */
- (void)removeTransactions;

/**
 获取本地存储（即未校验订单）的指定商品
 */
- (NSArray<HXStoreTransaction*>*)purchasedProducts;

@end
