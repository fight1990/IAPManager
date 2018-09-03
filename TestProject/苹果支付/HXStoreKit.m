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

#define SandBoxReceiptURL @"https://sandbox.itunes.apple.com/verifyReceipt"
#define AppStoreReceiptURL @"https://buy.itunes.apple.com/verifyReceipt"

NSString* const HXIAPTransactionsUserDefaultsKey = @"HXIAPTransactions";

typedef void (^HXProductsRequestFailureBlock)(NSError *error);
typedef void (^HXProductsRequestSuccessBlock)(HXStoreTransaction *transactionInfo);

@interface HXStoreKit()<SKPaymentTransactionObserver, SKProductsRequestDelegate>

@property (strong, nonatomic) HXProductsRequestSuccessBlock successBlock;
@property (strong, nonatomic) HXProductsRequestFailureBlock failureBlock;
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
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
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
         在程序启动时，设置监听，监听是否有未完成订单，有的话恢复订单。
         */
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        /**
         在程序启动时，检测本地是否有receipt文件，有的话，去二次验证。
         */
        [self checkIAPTransactionReceipt];
    });
}

- (void)stopManager {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    });
}

///检查本地是否具有未校验成功的IAP订单信息
- (void)checkIAPTransactionReceipt {
    
    _purchasedProducts = [self.presenter purchasedProducts];

    if ([_purchasedProducts count]) {
        NSLog(@"含有未校验订单");
        
        for (HXStoreTransaction *transaction in _purchasedProducts) {
            //订单校验
            
            //校验完成移除订单
            [self.presenter removeTransaction:transaction];
        }
    }
    
}

///从APP Store查询用户点击购买的产品信息;获取信息后，根据获取到的商品详情进行支付请求
- (void)payProduct:(NSString*)productsID
           tradeId:(NSString*)tradeId
           success:(void (^)(HXStoreTransaction *transactionInfo))successBlock
           failure:(void (^)(NSError *error))failureBlock {

    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
    self.tradeID = tradeId;
    
    if (![SKPaymentQueue canMakePayments]) {

        if (self.failureBlock) {
            NSError *error = [NSError errorWithDomain:AppStoreReceiptURL code:HXStoreStatePaymentsDenied userInfo:@{NSLocalizedDescriptionKey:@"您的手机不允许程序内付费购买"}];
            self.failureBlock(error);
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

        if (self.failureBlock) {
            NSError *error = [NSError errorWithDomain:AppStoreReceiptURL code:HXStoreStateProductsRequestNone userInfo:@{NSLocalizedDescriptionKey:@"App Store内购配置无法获取商品信息"}];
            self.failureBlock(error);
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
    
    if (self.failureBlock) {
        NSString *errorDescription = error.localizedDescription ? : @"订单请求失败";
        NSError *error = [NSError errorWithDomain:AppStoreReceiptURL code:HXStoreStateProductsRequestFailed userInfo:@{NSLocalizedDescriptionKey:errorDescription}];
        self.failureBlock(error);
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
                ///商品添加进购物列表
            case SKPaymentTransactionStatePurchasing: {
                
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
    
    
    
    //校验成功后删除本地记录
    [self.presenter removeTransaction:storeTransaction];
    if (self.successBlock) {
        self.successBlock(storeTransaction);
    }

    ///完整结束此次购买，此处代码必备，否则下次购买提示已经购买该商品
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
//    HXStoreTransaction *storeTransaction = [[HXStoreTransaction alloc] initWithPaymentTransaction:transaction];

    if (transaction.error.code != SKErrorPaymentCancelled) {
        NSLog(@"支付交易失败!");

        if (self.failureBlock) {
            NSError *error = [NSError errorWithDomain:AppStoreReceiptURL code:HXStoreStateTransactionFailed userInfo:@{NSLocalizedDescriptionKey:@"交易支付失败"}];
            self.failureBlock(error);
        }
    } else {
        NSLog(@"用户取消交易支付");
    
        if (self.failureBlock) {
            NSError *error = [NSError errorWithDomain:AppStoreReceiptURL code:HXStoreStateTransactionCancel userInfo:@{NSLocalizedDescriptionKey:@"交易支付被取消"}];
            self.failureBlock(error);
        }
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}


- (void)restoredTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"恢复购买支付商品");
    
//    HXStoreTransaction *storeTransaction = [[HXStoreTransaction alloc] initWithPaymentTransaction:transaction];

    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];

    if (self.failureBlock) {
        NSError *error = [NSError errorWithDomain:AppStoreReceiptURL code:HXStoreStateTransactionRestored userInfo:@{NSLocalizedDescriptionKey:@"恢复已购买商品"}];
        self.failureBlock(error);
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

@end
