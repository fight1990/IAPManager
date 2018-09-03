//
//  HXStoreUserDefaultsPresenter.m
//  TestProject
//
//  Created by pengwei on 2018/8/21.
//  Copyright © 2018年 Wei PengWei. All rights reserved.
//

#import "HXStoreUserDefaultsPresenter.h"

NSString* const HXStoreTransactionsUserDefaultsKey = @"HXStoreTransactionsUserDefaultsKey";

@implementation HXStoreUserDefaultsPresenter

#pragma mark HXStorePresenter
- (void)persistTransaction:(HXStoreTransaction*)transaction {
    if (transaction) {
        NSUserDefaults *defaults = [self userDefaults];
        NSArray *transactions = [defaults objectForKey:HXStoreTransactionsUserDefaultsKey] ? : @{};
        
        NSMutableArray *updatedTransactions = [NSMutableArray arrayWithArray:transactions];
        
        NSData *data = [HXStoreTransaction dataWithTransaction:transaction];
        [updatedTransactions addObject:data];
        [self setTransactionProducts:updatedTransactions];
    }
}
#pragma mark - Public
- (void)removeTransaction:(HXStoreTransaction*)transaction {
    NSMutableArray<HXStoreTransaction*> *transactions = [[self purchasedProducts] mutableCopy];

    [transactions removeObject:transaction];

    [self setTransactionProducts:transactions];
}

- (void)removeTransactions {
    NSUserDefaults *defaults = [self userDefaults];
    [defaults removeObjectForKey:HXStoreTransactionsUserDefaultsKey];
    [defaults synchronize];
}

- (NSArray<HXStoreTransaction*>*)purchasedProducts{
    
    NSUserDefaults *defaults = [self userDefaults];
    NSArray *localTransactions = [defaults objectForKey:HXStoreTransactionsUserDefaultsKey];
    NSMutableArray *transactions = [NSMutableArray arrayWithCapacity:localTransactions.count];
    for (NSData *data in localTransactions) {
        HXStoreTransaction *transaction = [HXStoreTransaction transactionWithData:data];
        [transactions addObject:transaction];
    }
    return transactions;
}

#pragma mark - Private
- (NSUserDefaults *)userDefaults {
    return [NSUserDefaults standardUserDefaults];
}

- (void)setTransactionProducts:(NSArray*)transactions{
    
    NSUserDefaults *defaults = [self userDefaults];

    [defaults setObject:transactions forKey:HXStoreTransactionsUserDefaultsKey];
    [defaults synchronize];
}

@end
