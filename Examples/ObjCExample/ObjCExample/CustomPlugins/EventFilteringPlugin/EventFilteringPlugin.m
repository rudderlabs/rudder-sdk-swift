//
//  EventFilteringPlugin.m
//  ObjCExampleApp
//
//  Created by Satheesh Kannan on 31/07/25.
//

#import "EventFilteringPlugin.h"

#pragma mark - EventFilteringPlugin

@interface EventFilteringPlugin()

/// The analytics instance this plugin is attached to.
@property(nonatomic, retain) RSSAnalytics *client;

/// The list of event names that should be filtered out from the analytics pipeline.
@property(nonatomic, retain) NSMutableArray *eventsToFilter;

@end

@implementation EventFilteringPlugin
@synthesize pluginType;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.eventsToFilter = [NSMutableArray arrayWithArray: @[@"Application Opened", @"Application Backgrounded"]];
    }
    return self;
}

- (instancetype)initWithEventsToFilter:(NSArray<NSString *> *)eventsToFilter {
    self = [super init];
    if (self) {
        self.eventsToFilter = [NSMutableArray arrayWithArray:eventsToFilter];
    }
    return self;
}

- (RSSPluginType)pluginType {
    return RSSPluginTypeOnProcess;
}

- (void)setup:(RSSAnalytics * _Nonnull)analytics {
    self.client = analytics;
}

/**
 Intercepts analytics events and filters out specified track events.

 @param event The event to potentially filter.
 @return The original event if it should be processed, or nil if it should be filtered out.
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

 @param trackEvent The track event to evaluate.
 @return YES if the event should be filtered out, NO if it should pass through.
 */
- (BOOL)shouldFilterEvent:(RSSTrackEvent *)trackEvent {
    return [self.eventsToFilter containsObject:trackEvent.eventName];
}

/** Called when the plugin is being removed or the analytics instance is being torn down. */
- (void)teardown {
    [self.eventsToFilter removeAllObjects];
    self.eventsToFilter = nil;
    self.client = nil;
}

@end
