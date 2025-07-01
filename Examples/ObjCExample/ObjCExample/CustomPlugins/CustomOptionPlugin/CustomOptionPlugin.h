//
//  CustomOptionPlugin.h
//  ObjCExample
//
//  Created by Satheesh Kannan on 27/05/25.
//

#import <Foundation/Foundation.h>
@import RudderStackAnalytics;

NS_ASSUME_NONNULL_BEGIN

/**
 * CustomOptionPlugin
 *
 * A plugin that automatically applies custom options to all analytics events.
 * This plugin enhances events by adding custom context data, external IDs, and
 * integration configurations from a provided RSSOption object.
 *
 * The plugin performs the following operations on each event:
 * - Merges custom context data into the event's context
 * - Adds external IDs to the event's context
 * - Merges integration settings into the event's integrations
 *
 * ## Usage
 * ```objc
 *     // Create custom option with desired configurations
 *     RSSOptionBuilder *optionBuilder = [RSSOptionBuilder new];
 *     [optionBuilder setCustomContext:@{@"app_version": @"1.0.0", @"environment": @"production"}];
 *
 *     // Create the plugin
 *     CustomOptionPlugin *plugin = [[CustomOptionPlugin alloc] initWithOption:[optionBuilder build]];
 *
 *     // Add to your analytics instance
 *     [analytics addPlugin:plugin];
 * ```
 */
@interface CustomOptionPlugin : NSObject<RSSPlugin>

/**
 * Initializes a new instance of CustomOptionPlugin with the specified option.
 *
 * @param option The RSSOption containing custom context, external IDs, and integration
 *               configurations that will be applied to each event.
 * @return A configured CustomOptionPlugin instance.
 */
- (instancetype)initWithOption:(RSSOption *)option NS_DESIGNATED_INITIALIZER;

/**
 * Default initializer is unavailable. Use initWithOption: instead.
 */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
