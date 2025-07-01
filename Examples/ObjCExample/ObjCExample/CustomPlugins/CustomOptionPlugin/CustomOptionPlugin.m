//
//  CustomOptionPlugin.m
//  ObjCExample
//
//  Created by Satheesh Kannan on 27/05/25.
//

#import "CustomOptionPlugin.h"

#pragma mark - CustomOptionPlugin

@interface CustomOptionPlugin()

@property(nonatomic, retain) RSSAnalytics *client;
@property(nonatomic, retain) RSSOption *option;

@end

@implementation CustomOptionPlugin
@synthesize pluginType;

/**
 Initializes the plugin with the specified RSSOption.
 
 @param option The RSSOption containing custom context, external IDs, and integration
               configurations to be applied to all events.
 @return An initialized instance of CustomOptionPlugin.
 */
- (instancetype)initWithOption:(RSSOption *)option
{
    self = [super init];
    if (self) {
        self.option = option;
    }
    return self;
}

/**
 Returns the plugin type for this plugin.
 
 @return RSSPluginTypeOnProcess, indicating this plugin runs during event processing.
 */
- (RSSPluginType)pluginType {
    return RSSPluginTypeOnProcess;
}

/**
 Intercepts an event and applies custom options to it.
 
 This method enhances the event by applying custom context, external IDs, and
 integration configurations from the stored RSSOption.
 
 @param event The event to be processed.
 @return The modified event with custom options applied.
 */
- (RSSEvent * _Nullable)intercept:(RSSEvent * _Nonnull)event {
    
    [self addCustomContext:event];
    [self addExternalIds:event];
    [self addIntegrations:event];
    
    return event;
}

/**
 Merges custom context data from the option into the event's context.
 
 @param event The event whose context will be updated with custom data.
 */
- (void)addCustomContext:(RSSEvent *)event {
    NSMutableDictionary *contextDict = [NSMutableDictionary dictionaryWithDictionary: (event.context ?: @{})];
    [contextDict addEntriesFromDictionary: (self.option.customContext ?: @{})];
    event.context = contextDict;
}

/**
 Adds external IDs from the option to the event's context.
 
 External IDs are appended to any existing external IDs in the event context.
 Each external ID is converted to a dictionary with 'id' and 'type' keys.
 
 @param event The event whose context will be updated with external IDs.
 */
- (void)addExternalIds:(RSSEvent *)event {
    NSMutableDictionary *contextDict = [NSMutableDictionary dictionaryWithDictionary: (event.context ?: @{})];
    NSMutableArray *externalIdArray = [NSMutableArray arrayWithArray: (contextDict[@"externalId"] ?: @[])];
    
    // Merge option's externalIds into existing externalIds
    [self.option.externalIds enumerateObjectsUsingBlock:^(RSSExternalId * _Nonnull externalId, NSUInteger idx, BOOL * _Nonnull stop) {
        [externalIdArray addObject:@{@"id": externalId.id, @"type": externalId.type}];
    }];
    
    contextDict[@"externalId"] = externalIdArray;
    event.context = contextDict;
}

/**
 Merges integration configurations from the option into the event's integrations.
 
 @param event The event whose integrations will be updated with custom configurations.
 */
- (void)addIntegrations:(RSSEvent *)event {
    NSMutableDictionary *integrationsDict = [NSMutableDictionary dictionaryWithDictionary: (event.integrations ?: @{})];
    [integrationsDict addEntriesFromDictionary: (self.option.integrations ?: @{})];
    event.integrations = integrationsDict;
}

/**
 Sets up the plugin with the provided analytics client.
 
 @param analytics The analytics client instance to be used by the plugin.
 */
- (void)setup:(RSSAnalytics * _Nonnull)analytics {
    self.client = analytics;
}

/**
 Performs teardown operations for the plugin.
 
 Called when the plugin is removed from the analytics client.
 */
- (void)teardown { }

@end
