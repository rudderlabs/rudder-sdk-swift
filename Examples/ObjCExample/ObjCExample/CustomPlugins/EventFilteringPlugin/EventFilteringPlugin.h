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
 A plugin that filters out specific events from being processed by the analytics pipeline.
 
 By default, this plugin filters out "Application Opened" and "Application Backgrounded" events.
 This is useful for reducing noise in analytics data by excluding automated lifecycle events
 that may not be relevant for your specific use case.
 
 **Note**: Filtered events are completely removed from the processing pipeline and will not be sent to any destinations.
 
 Set this plugin just after the SDK initialization to start filtering events:
 ```objective-c
 [analytics add:[[EventFilteringPlugin alloc] init]];
 ```
 
 The plugin logs when events are filtered for debugging purposes.
 */
@interface EventFilteringPlugin : NSObject<RSSPlugin>

/**
 Initializes the EventFilteringPlugin with default filtering rules.
  
 @return An initialized EventFilteringPlugin instance
 */
- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
