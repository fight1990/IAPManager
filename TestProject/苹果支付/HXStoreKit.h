//
//  HXStoreKit.h
//  TestProject
//
//  Created by pengwei on 2018/8/21.
//  Copyright © 2018年 Wei PengWei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HXStoreTransaction.h"

///错误码信息
typedef NS_ENUM(NSInteger, HXStoreState) {
    HXStoreStateTransactionPurchased = 0,       //购买支付成功
    HXStoreStateTransactionRestored = -101,     //恢复已支付购买
    HXStoreStateTransactionFailed = -102,       //购买支付失败
    HXStoreStateTransactionCancel = -103,       //购买支付取消
    HXStoreStatePaymentsDenied = -104,          //购买权限受限
    HXStoreStateProductsRequestFailed = -105,   //订单请求失败
    HXStoreStateProductsRequestNone = -106      //订单请求返回无商品信息
};

@interface HXStoreKit : NSObject

+ (HXStoreKit*)sharedInstance;

/**
 启动工具
 */
- (void)startManager;

/**
 结束工具
 */
- (void)stopManager;

/**
 苹果内购支付

 @param productsID 商品ID
 @param tradeId 平台订单号
 @param successBlock 内购交易支付回调
 @param failureBlock 内购交易失败回调
 */
- (void)payProduct:(NSString*)productsID
           tradeId:(NSString*)tradeId
           success:(void (^)(HXStoreTransaction *transactionInfo))successBlock
           failure:(void (^)(NSError *error))failureBlock;

@end
