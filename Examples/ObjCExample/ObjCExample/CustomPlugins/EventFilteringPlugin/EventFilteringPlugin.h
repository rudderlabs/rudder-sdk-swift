//
//  EventFilteringPlugin.h
//  ObjCExampleApp
//
//  Created by Satheesh Kannan on 31/07/25.
//

#import <Foundation/Foundation.h>
@import RudderStackAnalytics;

NS_ASSUME_NONNULL_BEGIN

/**
 This plugin filters out specific analytics events from being processed in the analytics pipeline.
 It allows you to prevent certain track events from being tracked or sent to destinations.

 By default, this plugin filters out "Application Opened" and "Application Backgrounded" events.
 You can also provide a custom list of event names to filter using `initWithEventsToFilter:`.

 @code
 // Using default filter list
 [analytics add:[[EventFilteringPlugin alloc] init]];

 // Using a custom filter list
 NSArray *eventsToFilter = @[@"Event 1", @"Event 2"];
 [analytics add:[[EventFilteringPlugin alloc] initWithEventsToFilter:eventsToFilter]];
 @endcode
 */
@interface EventFilteringPlugin : NSObject<RSSPlugin>

/**
 Initializes the plugin with the default filter list: "Application Opened" and "Application Backgrounded".

 @return An initialized EventFilteringPlugin instance.
 */
- (instancetype)init;

/**
 Initializes the plugin with a custom list of event names to filter out.

 @param eventsToFilter An array of event names that should be filtered from the analytics pipeline.
 @return An initialized EventFilteringPlugin instance.
 */
- (instancetype)initWithEventsToFilter:(NSArray<NSString *> *)eventsToFilter;

@end

NS_ASSUME_NONNULL_END
