//
//  HXStoreKit.h
//  TestProject
//
//  Created by pengwei on 2018/8/21.
//  Copyright © 2018年 Wei PengWei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HXStoreTransaction.h"
extern const NSString *g_HXThirdPartyManager_PayParam_IAP_OrderStr;
extern const NSString *g_HXThirdPartyManager_PayParam_IAP_ProductIdStr;

// @See ErrorInfo
extern const NSString *g_HXThirdPartyManager_ErrorInfo_Code;
extern const NSString *g_HXThirdPartyManager_ErrorInfo_Message;

typedef void (^HXIAPManagerPayFinishBlock)(BOOL success, NSDictionary *message);

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
 开启IAP支付结果监听工具
 */
- (void)startManager;

/**
 结束IAP支付结果监听工具
 */
- (void)stopManager;

/**
 检查本地未校验成功的IAP订单信息

 @return 未校验成功IAP订单信息集合
 */
- (NSArray<HXStoreTransaction*> *)checkIAPTransactionReceipt;

/**
 校验完成移除本地存储的订单信息
 
 @param transaction 订单信息
 */
- (void)removeCompleteTransaction:(HXStoreTransaction*)transaction;

/**
 苹果内购支付

 @param productsID 商品ID
 @param tradeId 平台订单号
 @param successBlock 内购交易支付回调
 @param failureBlock 内购交易失败回调
 */

/**
 苹果内购 - 支付接口

 @param dicParam 参数
 @param finishBlock 完成回调Block
 */
- (void)payWithParam:(NSDictionary<NSString *, NSString *> *)dicParam
    iapPayFinishBlock:(HXIAPManagerPayFinishBlock)finishBlock;

@end
