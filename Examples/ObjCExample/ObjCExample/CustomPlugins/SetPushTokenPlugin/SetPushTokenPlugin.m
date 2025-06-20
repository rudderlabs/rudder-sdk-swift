//
//  SetPushTokenPlugin.m
//  ObjCExample
//
//  Created by Satheesh Kannan on 12/06/25.
//

#import "SetPushTokenPlugin.h"

#pragma mark - SetPushTokenPlugin

@interface SetPushTokenPlugin()

@property(nonatomic, retain) RSAAnalytics *client;
@property(nonatomic, retain) NSString *pushToken;

@end

@implementation SetPushTokenPlugin
@synthesize pluginType;

/**
 Initializes the plugin with the specified push notification token.
 
 @param pushToken The device push notification token to be added to the event context.
 @return An initialized instance of SetPushTokenPlugin.
 */
-(instancetype)initWithPushToken:(NSString *)pushToken
{
    self = [super init];
    if (self) {
        self.pushToken = pushToken;
    }
    return self;
}

/**
 Returns the plugin type for this plugin.
 
 @return RSAPluginTypeOnProcess, indicating this plugin runs during event processing.
 */
- (RSAPluginType)pluginType {
    return RSAPluginTypeOnProcess;
}

/**
 Intercepts an event and adds the push token to its context.
 
 @param event The event to be processed.
 @return The modified event with the push token added to the device context.
 */
- (RSAEvent * _Nullable)intercept:(RSAEvent * _Nonnull)event {
    [self addPushToken:event];
    return event;
}

/**
 Adds the push token to the device section of an event's context.
 
 @param event The event whose context will be updated.
 */
- (void)addPushToken:(RSAEvent *)event {
    NSMutableDictionary *contextDict = [NSMutableDictionary dictionaryWithDictionary: (event.context ?: @{})];
    NSMutableDictionary *deviceInfoDict = [NSMutableDictionary dictionaryWithDictionary: (contextDict[@"device"] ?: @{})];
    
    deviceInfoDict[@"token"] = self.pushToken;
    contextDict[@"device"] = deviceInfoDict;
    
    event.context = contextDict;
}

/**
 Sets up the plugin with the provided analytics client.
 
 @param analytics The analytics client instance to be used by the plugin.
 */
- (void)setup:(RSAAnalytics * _Nonnull)analytics {
    self.client = analytics;
}

/**
 Performs teardown operations for the plugin.
 
 Called when the plugin is removed from the analytics client.
 */
- (void)teardown {
    /* Cleanup if needed */
}

@end
