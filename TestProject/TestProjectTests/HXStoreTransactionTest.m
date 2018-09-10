//
//  HXStoreTransactionTest.m
//  TestProjectTests
//
//  Created by butcher on 2018/8/26.
//  Copyright © 2018年 Wei PengWei. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HXStoreTransaction.h"
#import <OCMock/OCMock.h>

@interface HXStoreTransactionTest : XCTestCase

@end

@implementation HXStoreTransactionTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
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

- (void)testInitWithPaymentTransaction
{
    SKPaymentTransaction *paymentTransaction = [self mockPaymentTransactionOfProductIdentifer:@"9read_year_04"];
    
    HXStoreTransaction *transaction = [[HXStoreTransaction alloc] initWithPaymentTransaction:paymentTransaction];
    
    NSString *transactionReceiptString = [paymentTransaction.transactionReceipt base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];

    
    SKPayment *payment = paymentTransaction.payment;
    XCTAssertNotNil(transaction, @"");
    XCTAssertEqualObjects(transaction.productIdentifier, payment.productIdentifier, @"");
    XCTAssertEqualObjects(transaction.transactionDate, paymentTransaction.transactionDate, @"");
    XCTAssertEqualObjects(transaction.transactionIdentifier, paymentTransaction.transactionIdentifier, @"");
    XCTAssertEqualObjects(transaction.transactionReceiptString, transactionReceiptString, @"");

}

#pragma mark - NSCoding

- (void)testCoding
{
    HXStoreTransaction *transaction = [[HXStoreTransaction alloc] init];
    transaction.productIdentifier = @"test";
    transaction.transactionDate = [[NSDate date] description];
    transaction.transactionIdentifier = @"transaction";
    transaction.transactionReceiptString = @"1231231123";
    
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:transaction];
    [archiver finishEncoding];
    
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    HXStoreTransaction *decodedTransaction = [unarchiver decodeObject];
    
    XCTAssertNotNil(decodedTransaction, @"");
    XCTAssertEqualObjects(decodedTransaction.productIdentifier, transaction.productIdentifier, @"");
    XCTAssertEqualObjects(decodedTransaction.transactionDate, transaction.transactionDate, @"");
    XCTAssertEqualObjects(decodedTransaction.transactionIdentifier, transaction.transactionIdentifier, @"");
    XCTAssertEqualObjects(decodedTransaction.transactionReceiptString, transaction.transactionReceiptString, @"");
}

#pragma mark - Private

- (SKPaymentTransaction*)mockPaymentTransactionOfProductIdentifer:(NSString*)productIdentifier
{
    id transaction = [OCMockObject mockForClass:[SKPaymentTransaction class]];
    [[[transaction stub] andReturn:[NSDate date]] transactionDate];
    [[[transaction stub] andReturn:@"transaction"] transactionIdentifier];
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    [[[transaction stub] andReturn:[NSData data]] transactionReceipt];
#endif
    id payment = [OCMockObject mockForClass:[SKPayment class]];
    [[[payment stub] andReturn:productIdentifier] productIdentifier];
    [[[transaction stub] andReturn:payment] payment];
    return transaction;
}
@end
