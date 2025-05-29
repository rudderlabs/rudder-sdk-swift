//
//  CustomOptionPlugin.m
//  AnalyticsAppObjC
//
//  Created by Satheesh Kannan on 27/05/25.
//

#import "CustomOptionPlugin.h"

#pragma mark - CustomOptionPlugin

@interface CustomOptionPlugin()

@property(nonatomic, retain) RSAnalytics *client;
@property(nonatomic, retain) RSOption *option;

@end

@implementation CustomOptionPlugin
@synthesize pluginType;

- (instancetype)initWithOption:(RSOption *)option
{
    self = [super init];
    if (self) {
        self.option = option;
    }
    return self;
}

- (RSPluginType)pluginType {
    return RSPluginTypeOnProcess;
}

- (RSEvent * _Nullable)intercept:(RSEvent * _Nonnull)event {
    
    RSEvent *updatedEvent = [event addToContext: self.option.customContext];
    updatedEvent = [event addToIntegrations: self.option.integrations];
    updatedEvent = [event addExternalIds: self.option.externalIds];
    
    return updatedEvent;
}

- (void)setup:(RSAnalytics * _Nonnull)analytics {
    self.client = analytics;
}

- (void)teardown { }

@end
