#import "SetAnonymousIdPlugin.h"

#pragma mark - SetAnonymousIdPlugin

@interface SetAnonymousIdPlugin()

/// Reference to the analytics client
@property(nonatomic, retain) RSSAnalytics *client;

/// The custom anonymous ID to be set on all events
@property(nonatomic, copy) NSString *anonymousId;

@end

@implementation SetAnonymousIdPlugin
@synthesize pluginType;

- (instancetype)initWithAnonymousId:(NSString *)anonymousId {
    self = [super init];
    if (self) {
        _anonymousId = [anonymousId copy];
    }
    return self;
}

- (RSSPluginType)pluginType {
    return RSSPluginTypeOnProcess;
}

- (void)setup:(RSSAnalytics * _Nonnull)analytics {
    self.client = analytics;
}

- (RSSEvent * _Nullable)intercept:(RSSEvent * _Nonnull)event {
    [self replaceAnonymousIdInEvent:event];
    return event;
}

/**
 Replaces the anonymousId in the event with the custom value.
 
 @param event The event to modify
 */
- (void)replaceAnonymousIdInEvent:(RSSEvent *)event {
    [RSSLoggerAnalytics verbose:[NSString stringWithFormat:@"SetAnonymousIdPlugin: Replacing anonymousId: %@ in the event payload", self.anonymousId]];
    
    event.anonymousId = self.anonymousId;
}

- (void)teardown {
    // Cleanup if needed
}

@end
