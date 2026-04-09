//
//  SetATTTrackingStatusPlugin.m
//  ObjCExampleApp
//
//  Created by Satheesh Kannan on 18/12/25.
//

#import "SetATTTrackingStatusPlugin.h"

#pragma mark - SetATTTrackingStatusPlugin

@interface SetATTTrackingStatusPlugin()

@property(nonatomic, strong) RSSAnalytics *client;
@property(nonatomic, assign) NSUInteger attTrackingStatus;

@end

@implementation SetATTTrackingStatusPlugin
@synthesize pluginType;

/**
 Initializes the plugin with the specified ATT tracking status.
 
 @param attTrackingStatus The ATT tracking status value (0-3) to be added to the event context.
 @return An initialized instance of SetATTTrackingStatusPlugin.
 */
-(instancetype)initWithATTTrackingStatus:(NSUInteger)attTrackingStatus
{
    self = [super init];
    if (self) {
        if (attTrackingStatus > 3) {
            [RSSLoggerAnalytics debug:[NSString stringWithFormat:@"SetATTTrackingStatusPlugin: Invalid attTrackingStatus %lu provided. Defaulting to 0.", (unsigned long)attTrackingStatus]];
            self.attTrackingStatus = 0;
        } else {
            self.attTrackingStatus = attTrackingStatus;
        }
    }
    return self;
}

/**
 Returns the plugin type for this plugin.
 
 @return RSSPluginTypePreProcess, indicating this plugin runs before event processing.
 */
- (RSSPluginType)pluginType {
    return RSSPluginTypePreProcess;
}

/**
 Sets up the plugin with the provided analytics client.
 
 @param analytics The analytics client instance to be used by the plugin.
 */
- (void)setup:(RSSAnalytics * _Nonnull)analytics {
    self.client = analytics;
}

/**
 Intercepts an event and adds the ATT tracking status to its context.
 
 @param event The event to be processed.
 @return The modified event with the ATT tracking status added to the device context.
 */
- (RSSEvent * _Nullable)intercept:(RSSEvent * _Nonnull)event {
    [self addATTTrackingStatus:event];
    return event;
}

/**
 Adds the ATT tracking status to the device section of an event's context.
 
 @param event The event whose context will be updated.
 */
- (void)addATTTrackingStatus:(RSSEvent *)event {
    NSMutableDictionary *contextDict = [NSMutableDictionary dictionaryWithDictionary: (event.context ?: @{})];
    NSMutableDictionary *deviceInfoDict = [NSMutableDictionary dictionaryWithDictionary: (contextDict[@"device"] ?: @{})];
    
    deviceInfoDict[@"attTrackingStatus"] = @(self.attTrackingStatus);
    contextDict[@"device"] = deviceInfoDict;
    
    event.context = contextDict;
    
    // Log the action for debugging purposes
    [RSSLoggerAnalytics debug:[NSString stringWithFormat:@"SetATTTrackingStatusPlugin: Setting attTrackingStatus: %lu in event context.device", (unsigned long)self.attTrackingStatus]];
}

/**
 Performs teardown operations for the plugin.
 
 Called when the plugin is removed from the analytics client.
 */
- (void)teardown {
    /* Cleanup if needed */
}

@end
