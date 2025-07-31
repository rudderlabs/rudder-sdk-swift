//
//  EventFilteringPlugin.m
//  ObjCExampleApp
//
//  Created by Satheesh Kannan on 31/07/25.
//

#import "EventFilteringPlugin.h"

@interface EventFilteringPlugin()

@property(nonatomic, retain) RSSAnalytics *client;
@property(nonatomic, retain) NSMutableArray *eventsToFilter;

@end

@implementation EventFilteringPlugin
@synthesize pluginType;

-(instancetype)init
{
    self = [super init];
    if (self) {}
    return self;
}

- (RSSPluginType)pluginType {
    return RSSPluginTypeOnProcess;
}

- (void)setup:(RSSAnalytics * _Nonnull)analytics {
    self.client = analytics;
    self.eventsToFilter = [NSMutableArray arrayWithArray: @[@"Application Opened", @"Application Backgrounded"]];
}

- (RSSEvent *)intercept:(RSSEvent *)event {
    if ([event isKindOfClass:[RSSTrackEvent class]]) {
        RSSTrackEvent *trackEvent = (RSSTrackEvent *)event;
        if ([self.eventsToFilter containsObject: trackEvent.eventName]) {
            [RSSLoggerAnalytics verbose:[NSString stringWithFormat:@"EventFilteringPlugin: Event \"%@\" is filtered out.", trackEvent.eventName]];
            return nil;
        }
    }
    return event;
}

- (void)teardown {
    [self.eventsToFilter removeAllObjects];
}

@end
