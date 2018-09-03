//
//  HXStoreTransaction.m
//  TestProject
//
//  Created by pengwei on 2018/8/21.
//  Copyright © 2018年 Wei PengWei. All rights reserved.
//

#import "HXStoreTransaction.h"

NSString* const HXStoreCoderOrderIdKey = @"orderId";
NSString* const HXStoreCoderProductIdentifierKey = @"productIdentifier";
NSString* const HXStoreCoderTransactionDateKey = @"transactionDate";
NSString* const HXStoreCoderTransactionIdentifierKey = @"transactionIdentifier";
NSString* const HXStoreCoderTransactionReceiptStringKey = @"transactionReceiptString";
NSString* const HXStoreCoderTransactionEnvironmentKey = @"transactionEnvironment";


@implementation HXStoreTransaction

- (instancetype)initWithPaymentTransaction:(SKPaymentTransaction*)paymentTransaction {
    if (self = [super init]) {
        
        _orderId = paymentTransaction.payment.applicationUsername;
        _productIdentifier = paymentTransaction.payment.productIdentifier;
        _transactionDate = paymentTransaction.transactionDate.description;
        _transactionIdentifier = paymentTransaction.transactionIdentifier;

        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
        
        NSString *transactionReceiptString = [receiptData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        
        _transactionReceiptString = transactionReceiptString;
        
        NSString *receiptString = [[NSString alloc]initWithData:paymentTransaction.transactionReceipt encoding:NSUTF8StringEncoding];
        NSString *environment=[self environmentForReceipt:receiptString];
        
        if ([environment isEqualToString:@"environment=Sandbox"]) {
            _sandbox = YES;
            
        } else{
            _sandbox = NO;
        }

        
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    
    if (self = [super init]) {
        _orderId = [decoder decodeObjectForKey:HXStoreCoderOrderIdKey];
        _productIdentifier = [decoder decodeObjectForKey:HXStoreCoderProductIdentifierKey];
        _transactionDate = [decoder decodeObjectForKey:HXStoreCoderTransactionDateKey];
        _transactionIdentifier = [decoder decodeObjectForKey:HXStoreCoderTransactionIdentifierKey];
        _transactionReceiptString = [decoder decodeObjectForKey:HXStoreCoderTransactionReceiptStringKey];
        _sandbox = [decoder decodeBoolForKey:HXStoreCoderTransactionEnvironmentKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    
    [coder encodeObject:self.orderId forKey:HXStoreCoderOrderIdKey];
    [coder encodeObject:self.productIdentifier forKey:HXStoreCoderProductIdentifierKey];
    [coder encodeObject:self.transactionDate forKey:HXStoreCoderTransactionDateKey];
    if (self.transactionIdentifier != nil) {
        [coder encodeObject:self.transactionIdentifier forKey:HXStoreCoderTransactionIdentifierKey];
    }
    if (self.transactionReceiptString != nil) {
        [coder encodeObject:self.transactionReceiptString forKey:HXStoreCoderTransactionReceiptStringKey];
    }
    
    [coder encodeBool:self.sandbox forKey:HXStoreCoderTransactionEnvironmentKey];
}

//收据的环境判断；
-(NSString * )environmentForReceipt:(NSString * )str {
    str= [str stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    str=[str stringByReplacingOccurrencesOfString:@" " withString:@""];
    str=[str stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    NSArray *arr=[str componentsSeparatedByString:@";"];
    
    //存储收据环境的变量
    NSString *environment=arr[2];
    return environment;
    
}
+ (NSDictionary*)dictionaryWithTransaction:(HXStoreTransaction*)transaction {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];

    [dictionary setValue:transaction.orderId forKey:@"orderId"];
    [dictionary setValue:transaction.productIdentifier forKey:@"productId"];
    [dictionary setValue:transaction.transactionDate forKey:@"date"];
    [dictionary setValue:transaction.transactionIdentifier forKey:@"transactionId"];
    [dictionary setValue:transaction.transactionReceiptString forKey:@"receipt"];
    [dictionary setValue:[NSNumber numberWithBool:transaction.sandbox] forKey:@"sandbox"];

    return dictionary;
}
+ (HXStoreTransaction*)transactionWithDictionary:(NSDictionary*)dictionary {
    HXStoreTransaction *transaction = [[HXStoreTransaction alloc] init];
    transaction.orderId = [dictionary objectForKey:@"orderId"];
    transaction.productIdentifier = [dictionary objectForKey:@"productId"];
    transaction.transactionDate = [dictionary objectForKey:@"date"];
    transaction.transactionIdentifier = [dictionary objectForKey:@"transactionId"];
    transaction.transactionReceiptString = [dictionary objectForKey:@"receipt"];
    transaction.sandbox = [[dictionary objectForKey:@"sandbox"] boolValue];

    return transaction;
}

+ (NSData*)dataWithTransaction:(HXStoreTransaction*)transaction {
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:transaction];
    [archiver finishEncoding];
    return data;
}

+ (HXStoreTransaction*)transactionWithData:(NSData*)data {
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    HXStoreTransaction *transaction = [unarchiver decodeObject];
    [unarchiver finishDecoding];
    return transaction;
}

- (BOOL)isEqual:(HXStoreTransaction*)object {
    if (object == self) {
        return YES;
    } else {
        return [object.orderId isEqual:self.orderId];
    }
}

- (NSUInteger)hash {
    return [self.orderId hash];
}

@end
