//
//  CustomOptionPlugin.h
//  ObjCExample
//
//  Created by Satheesh Kannan on 27/05/25.
//

#import <Foundation/Foundation.h>
@import RudderStackAnalytics;

NS_ASSUME_NONNULL_BEGIN

@interface CustomOptionPlugin : NSObject<RSSPlugin>

- (instancetype)initWithOption:(RSSOption *)option NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
