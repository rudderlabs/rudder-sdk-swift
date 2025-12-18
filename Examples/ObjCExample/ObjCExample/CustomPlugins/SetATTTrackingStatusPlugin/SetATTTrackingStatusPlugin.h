//
//  SetATTTrackingStatusPlugin.h
//  ObjCExampleApp
//
//  Created by Satheesh Kannan on 18/12/25.
//

#import <Foundation/Foundation.h>
@import RudderStackAnalytics;

NS_ASSUME_NONNULL_BEGIN

/**
 *
 * A plugin that automatically sets the ATT (App Tracking Transparency) tracking status
 * to all analytics events. The tracking status is added to the device section in the event context.
 *
 * This plugin runs in the preProcess phase, meaning it modifies events before they are processed
 * by other plugins or sent to destinations.
 *
 * ## Usage
 * ```objc
 *     // Create the plugin with ATT tracking status (0-3)
 *     SetATTTrackingStatusPlugin *plugin = [[SetATTTrackingStatusPlugin alloc] initWithATTTrackingStatus:3];
 *
 *     // Add to your analytics instance immediately after SDK initialization
 *     [analytics addPlugin:plugin];
 * ```
 *
 * @note The attTrackingStatus parameter should be an integer value from 0 to 3,
 *       representing the ATT authorization status.
 */
@interface SetATTTrackingStatusPlugin : NSObject<RSSPlugin>

/**
 * Initializes a new instance of SetATTTrackingStatusPlugin with the specified ATT tracking status.
 *
 * @param attTrackingStatus The ATT tracking status as an unsigned integer (0-3),
 *                           which will be added to each event's context.device.
 * @return A configured SetATTTrackingStatusPlugin instance.
 */
- (instancetype)initWithATTTrackingStatus:(NSUInteger)attTrackingStatus NS_DESIGNATED_INITIALIZER;

/**
 * Default initializer is unavailable. Use initWithATTTrackingStatus: instead.
 */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
