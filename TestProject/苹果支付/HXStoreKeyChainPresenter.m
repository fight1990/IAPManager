//
//  HXStoreKeyChainPresenter.m
//  TestProject
//
//  Created by pengwei on 2018/8/21.
//  Copyright © 2018年 Wei PengWei. All rights reserved.
//

#import "HXStoreKeyChainPresenter.h"
#import <Security/Security.h>

NSString* const HXStoreTransactionsKeychainKey = @"HXStoreTransactionsKeychainKey";

@interface HXStoreKeyChainPresenter()

@property (strong, nonatomic) NSMutableArray *transactions;

@end

#pragma mark - Keychain
NSMutableDictionary* HXKeychainGetSearchDictionary(NSString *key) {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    
    NSData *encodedIdentifier = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    dictionary[(__bridge id)kSecAttrGeneric] = encodedIdentifier;
    dictionary[(__bridge id)kSecAttrAccount] = encodedIdentifier;
    
    NSString *serviceName = [NSBundle mainBundle].bundleIdentifier;
    dictionary[(__bridge id)kSecAttrService] = serviceName;
    
    return dictionary;
}

void HXKeychainSetValue(NSData *value, NSString *key) {
    NSMutableDictionary *searchDictionary = HXKeychainGetSearchDictionary(key);
    OSStatus status = errSecSuccess;
    CFTypeRef ignore;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, &ignore) == errSecSuccess) {
        // 数据更新
        if (!value)  {
            status = SecItemDelete((__bridge CFDictionaryRef)searchDictionary);
        } else {
            NSMutableDictionary *updateDictionary = [NSMutableDictionary dictionary];
            updateDictionary[(__bridge id)kSecValueData] = value;
            status = SecItemUpdate((__bridge CFDictionaryRef)searchDictionary, (__bridge CFDictionaryRef)updateDictionary);
        }
    } else if (value) {
        // 添加
        searchDictionary[(__bridge id)kSecValueData] = value;
        status = SecItemAdd((__bridge CFDictionaryRef)searchDictionary, NULL);
    }
    if (status != errSecSuccess) {
        
        NSLog(@"RMStoreKeychainPersistence: failed to set key %@ with error %ld.", key, (long)status);
    }
}

NSData* HXKeychainGetValue(NSString *key) {
    
    NSMutableDictionary *searchDictionary = HXKeychainGetSearchDictionary(key);
    searchDictionary[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    searchDictionary[(__bridge id)kSecReturnData] = (id)kCFBooleanTrue;
    
    CFDataRef value = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, (CFTypeRef *)&value);
    if (status != errSecSuccess && status != errSecItemNotFound) {
        NSLog(@"RMStoreKeychainPersistence: failed to get key %@ with error %ld.", key, (long)status);
    }
    return (__bridge NSData*)value;
}

@implementation HXStoreKeyChainPresenter

#pragma mark - Public
- (void)persistTransaction:(HXStoreTransaction*)transaction{

    [self.transactions addObject:transaction];
    
    NSMutableArray *storeTransactions = [[NSMutableArray alloc] initWithCapacity:[self.transactions count]];
    for (HXStoreTransaction *storeTransaction in self.transactions) {
        NSDictionary *dictionary = [HXStoreTransaction dictionaryWithTransaction:storeTransaction];
        [storeTransactions addObject:dictionary];
    }
    
    [self setTransactionProducts:storeTransactions];
}
- (void)removeTransaction:(HXStoreTransaction*)transaction {
    
    [self.transactions removeObject:transaction];
    
    NSMutableArray *storeTransactions = [[NSMutableArray alloc] initWithCapacity:[self.transactions count]];

    for (HXStoreTransaction *storeTransaction in self.transactions) {
        NSDictionary *dictionary = [HXStoreTransaction dictionaryWithTransaction:storeTransaction];
        [storeTransactions addObject:dictionary];
    }
    
    [self setTransactionProducts:storeTransactions];
}

- (void)removeTransactions {
    [self setTransactionProducts:nil];
}

- (NSArray<HXStoreTransaction*>*)purchasedProducts {
    return self.transactions;
}

#pragma mark - Private
- (NSMutableArray*)transactions{
    if (!_transactions) {
        // Reading the keychain is slow so we cache its values in memory
        NSData *data = HXKeychainGetValue(HXStoreTransactionsKeychainKey);
        NSArray *localTransactions = @[];
        if (data) {
            NSError *error;
            localTransactions = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (!localTransactions) {
                NSLog(@"%s: failed to read JSON data with error %@", __FILE__, error);
            }
        }
        
        NSMutableArray *transactions = [NSMutableArray arrayWithCapacity:localTransactions.count];
        for (NSDictionary *dictionary in localTransactions) {
            HXStoreTransaction *transaction = [HXStoreTransaction transactionWithDictionary:dictionary];
            [transactions addObject:transaction];
        }
        
        _transactions = [transactions mutableCopy];
    }
    return _transactions;
    
}

- (void)setTransactionProducts:(NSMutableArray*)transactions {

    NSData *data = nil;
    if ([transactions count]) {
        NSError *error;
        data = [NSJSONSerialization dataWithJSONObject:transactions options:0 error:&error];
        if (!data) {
            NSLog(@"%s: failed to write JSON data with error %@", __FILE__, error);
        }
    }
    HXKeychainSetValue(data, HXStoreTransactionsKeychainKey);
}

@end
