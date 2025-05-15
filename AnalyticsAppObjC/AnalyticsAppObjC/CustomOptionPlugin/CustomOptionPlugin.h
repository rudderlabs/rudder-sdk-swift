//
//  CustomOptionPlugin.h
//  AnalyticsAppObjC
//
//  Created by Satheesh Kannan on 15/05/25.
//

#import <Foundation/Foundation.h>
#import <Analytics/Analytics-Swift.h>

NS_ASSUME_NONNULL_BEGIN
/**
 This class is a processing plugin that updates option values of any event.
 */
@interface CustomOptionPlugin : NSObject<ObjCPlugin>

- (instancetype)initWithOption:(RudderOption *)option NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
