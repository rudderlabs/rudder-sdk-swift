#import "SetAnonymousIdPlugin.h"

#pragma mark - SetAnonymousIdPlugin

@interface SetAnonymousIdPlugin()

/// Reference to the analytics client
@property(nonatomic, retain) RSAAnalytics *client;

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

- (RSAPluginType)pluginType {
    return RSAPluginTypeOnProcess;
}

- (void)setup:(RSAAnalytics * _Nonnull)analytics {
    self.client = analytics;
}

- (RSAEvent * _Nullable)intercept:(RSAEvent * _Nonnull)event {
    [self replaceAnonymousIdInEvent:event];
    return event;
}

/**
 Replaces the anonymousId in the event with the custom value.
 
 @param event The event to modify
 */
- (void)replaceAnonymousIdInEvent:(RSAEvent *)event {
    [RSALoggerAnalytics verbose:[NSString stringWithFormat:@"SetAnonymousIdPlugin: Replacing anonymousId: %@ in the event payload", self.anonymousId]];
    
    event.anonymousId = self.anonymousId;
}

- (void)teardown {
    // Cleanup if needed
}

@end
