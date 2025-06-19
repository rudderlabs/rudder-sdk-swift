//
//  SetPushTokenPlugin.h
//  AnalyticsAppObjC
//
//  Created by Satheesh Kannan on 12/06/25.
//

#import <Foundation/Foundation.h>
#import <Analytics/Analytics-Swift.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * SetPushTokenPlugin
 *
 * A plugin that automatically adds the device push notification token to all analytics events.
 * The token is added to the device section in the event context.
 *
 * ## Usage
 * ```objc
 *     // Create the plugin
 *     SetPushTokenPlugin *plugin = [[SetPushTokenPlugin alloc] initWithPushToken:tokenString];
 *
 *     // Add to your analytics instance
 *     [analytics addPlugin:plugin];
 * }
 * ```
 */
@interface SetPushTokenPlugin : NSObject<RSAPlugin>

/**
 * Initializes a new instance of SetPushTokenPlugin with the specified push token.
 *
 * @param pushToken The device push token as a string, which will be added to each event.
 * @return A configured SetPushTokenPlugin instance.
 */
- (instancetype)initWithPushToken:(NSString *)pushToken NS_DESIGNATED_INITIALIZER;

/**
 * Default initializer is unavailable. Use initWithPushToken: instead.
 */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
