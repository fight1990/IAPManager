//
//  HXStoreKit.m
//  TestProject
//
//  Created by pengwei on 2018/8/21.
//  Copyright © 2018年 Wei PengWei. All rights reserved.
//

#import "HXStoreKit.h"
#import <StoreKit/StoreKit.h>
#import "HXStoreKeyChainPresenter.h"

const NSString *g_HXThirdPartyManager_PayParam_IAP_OrderStr = @"PayParam_IAP_OrderStr";
const NSString *g_HXThirdPartyManager_PayParam_IAP_ProductIdStr = @"PayParam_IAP_ProductIdStr";

// @See ErrorInfo
const NSString *g_HXThirdPartyManager_ErrorInfo_Code = @"errorCode";
const NSString *g_HXThirdPartyManager_ErrorInfo_Message = @"errorMessage";

NSString* const HXIAPTransactionsUserDefaultsKey = @"HXIAPTransactions";


@interface HXStoreKit()<SKPaymentTransactionObserver, SKProductsRequestDelegate>

@property (strong, nonatomic) HXIAPManagerPayFinishBlock finishBlock;
@property (strong, nonatomic) NSString *tradeID; //订单号

@property (strong, nonatomic) HXStoreKeyChainPresenter* presenter;

@property (strong, nonatomic) NSArray<HXStoreTransaction*> *purchasedProducts;

@end

@implementation HXStoreKit

static HXStoreKit *sharedInstance = nil;

dispatch_queue_t iap_queue() {
    static dispatch_queue_t dispatch_iap_queue;
    static dispatch_once_t onceToken_iap_queue;
    dispatch_once(&onceToken_iap_queue, ^{
        dispatch_iap_queue = dispatch_queue_create("com.iap.queue", DISPATCH_QUEUE_CONCURRENT);
    });
    
    return dispatch_iap_queue;
}

#pragma mark DataInit
- (HXStoreKeyChainPresenter *)presenter {
    if (!_presenter) {
        _presenter = [[HXStoreKeyChainPresenter alloc] init];
    }
    
    return _presenter;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self startManager];
    }
    
    return self;
}

#pragma mark Public;
+ (HXStoreKit*)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[HXStoreKit alloc] init];
    });
    
    return sharedInstance;
}
- (void)startManager {
    dispatch_async(iap_queue(), ^{
        /**
         在程序启动时，设置监听，监听内购支付结果的回调。
         */
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    });
}

- (void)stopManager {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    });
}

///检查本地是否具有未校验成功的IAP订单信息
- (NSArray<HXStoreTransaction*> *)checkIAPTransactionReceipt {
    
    _purchasedProducts = [self.presenter purchasedProducts];

    return _purchasedProducts;
    
}

///校验完成移除本地存储的订单信息
- (void)removeCompleteTransaction:(NSDictionary*)transaction {
    NSAssert(!transaction, @"订单信息不能为空");
    HXStoreTransaction *storeTransaction = [HXStoreTransaction transactionWithDictionary:transaction];
    [self.presenter removeTransaction:storeTransaction];
}

///从APP Store查询用户点击购买的产品信息;获取信息后，根据获取到的商品详情进行支付请求
- (void)payWithParam:(NSDictionary<NSString *, NSString *> *)dicParam
    iapPayFinishBlock:(HXIAPManagerPayFinishBlock)finishBlock {
    
    NSString *tradeId = [dicParam objectForKey:g_HXThirdPartyManager_PayParam_IAP_OrderStr.copy];
    NSString *productsID = [dicParam objectForKey:g_HXThirdPartyManager_PayParam_IAP_ProductIdStr.copy];

    self.tradeID = tradeId;
    self.finishBlock = finishBlock;
    
    if (![SKPaymentQueue canMakePayments]) {

        if (self.finishBlock) {
            self.finishBlock(NO,@{g_HXThirdPartyManager_ErrorInfo_Code.copy : [NSNumber numberWithInteger:HXStoreStatePaymentsDenied] , g_HXThirdPartyManager_ErrorInfo_Message.copy : @"用户不允许程序内付费购买"});
        }
        return;
    }
    
    NSSet *productsSet = [NSSet setWithObjects:productsID, nil];
    SKProductsRequest *productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productsSet];
    productRequest.delegate = self;
    [productRequest start];
}

#pragma mark SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray *myProducts = response.products;
    if ([myProducts count] == 0) {

        if (self.finishBlock) {
            self.finishBlock(NO,@{g_HXThirdPartyManager_ErrorInfo_Code.copy : [NSNumber numberWithInteger:HXStoreStateProductsRequestNone] , g_HXThirdPartyManager_ErrorInfo_Message.copy : @"App Store内购配置无法获取商品信息"});

        }
        return;
    }
    
    //处理成功则发起购买操作
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:[myProducts firstObject]];
    payment.applicationUsername = self.tradeID;
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"内购请求失败原因: %@",error.localizedDescription);
    
    if (self.finishBlock) {
        NSString *errorDescription = error.localizedDescription ? : @"订单请求失败";
        self.finishBlock(NO,@{g_HXThirdPartyManager_ErrorInfo_Code.copy : [NSNumber numberWithInteger:HXStoreStateProductsRequestFailed] , g_HXThirdPartyManager_ErrorInfo_Message.copy : errorDescription});
    }
    
}

- (void)requestDidFinish:(SKRequest *)request {
    NSLog(@"------ 内购请求反馈信息结束 ------");
}

#pragma mark SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
                ///交易完成
            case SKPaymentTransactionStatePurchased: {
                [self completeTransaction:transaction];
                break;
            }
                ///交易失败
            case SKPaymentTransactionStateFailed: {
                [self failedTransaction:transaction];
                break;
            }
                ///恢复已购买商品
            case SKPaymentTransactionStateRestored: {
                [self restoredTransaction:transaction];
                break;
            }
                
            default:
                break;
        }
    }
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    
    HXStoreTransaction *storeTransaction = [[HXStoreTransaction alloc] initWithPaymentTransaction:transaction];
    //对数据进行存储
    [self.presenter persistTransaction:storeTransaction];
    
    //将加密后trabsactionReceiptString发送服务端校验，并本地保存购买凭证
    if (self.finishBlock) {
        self.finishBlock(YES, @{@"ransaction": [HXStoreTransaction dictionaryWithTransaction:storeTransaction], g_HXThirdPartyManager_ErrorInfo_Code.copy : [NSNumber numberWithInteger:HXStoreStateTransactionPurchased] , g_HXThirdPartyManager_ErrorInfo_Message.copy : @"交易支付成功"});
    }
    
//    //校验成功后删除本地记录
//    [self.presenter removeTransaction:storeTransaction];

    ///完整结束此次购买，此处代码必备，否则下次购买提示已经购买该商品
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
//    HXStoreTransaction *storeTransaction = [[HXStoreTransaction alloc] initWithPaymentTransaction:transaction];

    if (transaction.error.code != SKErrorPaymentCancelled) {
        NSLog(@"支付交易失败!");
        
        if (self.finishBlock) {
            self.finishBlock(NO,@{g_HXThirdPartyManager_ErrorInfo_Code.copy : [NSNumber numberWithInteger:HXStoreStateTransactionFailed] , g_HXThirdPartyManager_ErrorInfo_Message.copy : @"交易支付失败"});
        }
    } else {
        NSLog(@"用户取消交易支付");

        if (self.finishBlock) {
            self.finishBlock(NO,@{g_HXThirdPartyManager_ErrorInfo_Code.copy : [NSNumber numberWithInteger:HXStoreStateTransactionCancel] , g_HXThirdPartyManager_ErrorInfo_Message.copy : @"交易支付被取消"});
        }
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}


- (void)restoredTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"恢复购买支付商品");
    
    HXStoreTransaction *storeTransaction = [[HXStoreTransaction alloc] initWithPaymentTransaction:transaction];

    if (self.finishBlock) {
        self.finishBlock(YES, @{@"ransaction": [HXStoreTransaction dictionaryWithTransaction:storeTransaction], g_HXThirdPartyManager_ErrorInfo_Code.copy : [NSNumber numberWithInteger:HXStoreStateTransactionRestored] , g_HXThirdPartyManager_ErrorInfo_Message.copy : @"恢复已购买商品"});
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

@end
