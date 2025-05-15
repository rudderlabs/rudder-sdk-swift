//
//  CustomOptionPlugin.h
//  AnalyticsAppObjC
//
//  Created by Satheesh Kannan on 15/05/25.
//

#import <Foundation/Foundation.h>
#import <Analytics/Analytics-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomOptionPlugin : NSObject<ObjCPlugin>

- (instancetype)initWithOption:(RudderOption *)option NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
