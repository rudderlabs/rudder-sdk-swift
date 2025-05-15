//
//  CustomOptionPlugin.m
//  AnalyticsAppObjC
//
//  Created by Satheesh Kannan on 15/05/25.
//

#import "CustomOptionPlugin.h"

#pragma mark - CustomOptionPlugin

@interface CustomOptionPlugin()

@property(nonatomic, retain) AnalyticsClient *client;
@property(nonatomic, retain) RudderOption *option;

@end

@implementation CustomOptionPlugin
@synthesize pluginType;

- (instancetype)initWithOption:(RudderOption *)option
{
    self = [super init];
    if (self) {
        self.option = option;
    }
    return self;
}

- (PluginType)pluginType {
    return PluginTypeOnProcess;
}

- (ObjCEvent * _Nullable)intercept:(ObjCEvent * _Nonnull)event {
    
    ObjCEvent *updatedEvent = [event addToContext: self.option.customContext];
    updatedEvent = [event addToIntegrations: self.option.integrations];
    updatedEvent = [event addExternalIds: self.option.externalIds];
    
    return updatedEvent;
}

- (void)setup:(AnalyticsClient * _Nonnull)analytics {
    self.client = analytics;
}

- (void)teardown { }

@end
