//
//  EventFilteringPlugin.m
//  ObjCExampleApp
//
//  Created by Satheesh Kannan on 31/07/25.
//

#import "EventFilteringPlugin.h"

#pragma mark - EventFilteringPlugin

@interface EventFilteringPlugin()

/// Reference to the analytics client
@property(nonatomic, retain) RSSAnalytics *client;

/// Array of event names that should be filtered out
@property(nonatomic, retain) NSMutableArray *eventsToFilter;

@end

@implementation EventFilteringPlugin
@synthesize pluginType;

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialize with default events to filter
    }
    return self;
}

- (RSSPluginType)pluginType {
    return RSSPluginTypeOnProcess;
}

- (void)setup:(RSSAnalytics * _Nonnull)analytics {
    self.client = analytics;
    // Set up default events to filter - Application lifecycle events that are often noise
    self.eventsToFilter = [NSMutableArray arrayWithArray: @[@"Application Opened", @"Application Backgrounded"]];
}

/**
 Intercepts events and filters out unwanted events based on the configured filter list.
 
 @param event The event to potentially filter
 @return The original event if it should pass through, or nil if it should be filtered out
 */
- (RSSEvent * _Nullable)intercept:(RSSEvent * _Nonnull)event {
    if ([event isKindOfClass:[RSSTrackEvent class]]) {
        RSSTrackEvent *trackEvent = (RSSTrackEvent *)event;
        if ([self shouldFilterEvent:trackEvent]) {
            [RSSLoggerAnalytics verbose:[NSString stringWithFormat:@"EventFilteringPlugin: Event \"%@\" is filtered out.", trackEvent.eventName]];
            return nil; // Filter out this event
        }
    }
    return event; // Allow event to pass through
}

/**
 Determines whether a track event should be filtered based on its event name.
 
 @param trackEvent The track event to evaluate
 @return YES if the event should be filtered out, NO if it should pass through
 */
- (BOOL)shouldFilterEvent:(RSSTrackEvent *)trackEvent {
    return [self.eventsToFilter containsObject:trackEvent.eventName];
}

/**
 Cleans up resources when the plugin is being removed or the analytics client is shutting down.
 */
- (void)teardown {
    [self.eventsToFilter removeAllObjects];
    self.eventsToFilter = nil;
    self.client = nil;
}

@end
