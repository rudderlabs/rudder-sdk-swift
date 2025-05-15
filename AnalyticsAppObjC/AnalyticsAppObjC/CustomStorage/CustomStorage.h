//
//  CustomStorage.h
//  AnalyticsAppObjC
//
//  Created by Satheesh Kannan on 15/05/25.
//

#import <Foundation/Foundation.h>
#import <Analytics/Analytics-Swift.h>

NS_ASSUME_NONNULL_BEGIN
/**
 The interface of the storage module, capable of handling both `KeyValueStore` and `DataStore` implementation.
 */
@interface CustomStorage : NSObject<Storage>

@property(nonatomic, retain) NSString* writeKey;

- (instancetype)initWithWriteKey:(NSString *)writeKey NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
