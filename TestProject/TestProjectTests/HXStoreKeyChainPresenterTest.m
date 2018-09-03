//
//  HXStoreKeyChainPresenter.m
//  TestProjectTests
//
//  Created by butcher on 2018/8/26.
//  Copyright © 2018年 Wei PengWei. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HXStoreKeychainPresenter.h"
#import "HXStoreTransaction.h"
#import <OCMock/OCMock.h>
#import <objc/runtime.h>

@interface NSBundle(bundleIdentifier)

@end

extern void HXKeychainSetValue(NSData *value, NSString *key);
extern NSString* const HXStoreTransactionsKeychainKey;

/**
 [NSBundle bundleIdentifier] returns nil during unit tests. Since RMStoreKeychainPersistence uses it as the keychain service value we have to swizzle it to return a value.
 */
@implementation NSBundle(bundleIdentifier)

- (NSString*)swizzled_bundleIdentifier {
    return @"test";
}

+(void)load {
    Method original = class_getInstanceMethod(self, @selector(bundleIdentifier));
    Method swizzle = class_getInstanceMethod(self, @selector(swizzled_bundleIdentifier));
    method_exchangeImplementations(original, swizzle);
}

@end

@interface HXStoreKeyChainPresenterTest : XCTestCase {
    
    HXStoreKeyChainPresenter *_persistor;

}

@end

@implementation HXStoreKeyChainPresenterTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _persistor = [[HXStoreKeyChainPresenter alloc] init];

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [_persistor removeTransactions];

    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)testPersistTransaction
{
    SKPaymentTransaction *transaction = [self mockTransactionOfProductIdentifer:@"test"];
    HXStoreTransaction *storeTransaction = [[HXStoreTransaction alloc] initWithPaymentTransaction:transaction];
    [_persistor persistTransaction:storeTransaction];
    
    XCTAssertTrue([_persistor purchasedProducts], @"");
}

- (void)testRemoveTransactions
{
    SKPaymentTransaction *transaction = [self mockTransactionOfProductIdentifer:@"test"];
    [self keychainPersistTransaction:transaction];
    
    [_persistor removeTransactions];
    
    XCTAssertFalse([_persistor purchasedProducts], @"");
}

#pragma mark - Private

- (void)keychainPersistTransaction:(SKPaymentTransaction*)transaction
{
    NSDictionary *dictionary = @{transaction.payment.productIdentifier : @1};
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    HXKeychainSetValue(data, HXStoreTransactionsKeychainKey);
}

- (SKPaymentTransaction*)mockTransactionOfProductIdentifer:(NSString*)productIdentifier
{
    id transaction = [OCMockObject mockForClass:[SKPaymentTransaction class]];
    id payment = [OCMockObject mockForClass:[SKPayment class]];
    [[[payment stub] andReturn:productIdentifier] productIdentifier];
    [[[transaction stub] andReturn:payment] payment];
    
    return transaction;
}
@end
