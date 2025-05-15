//
//  CustomStorage.h
//  AnalyticsAppObjC
//
//  Created by Satheesh Kannan on 15/05/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomStorage : NSObject

@property(nonatomic, retain) NSString* writeKey;

- (instancetype)initWithWriteKey:(NSString *)writeKey NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
