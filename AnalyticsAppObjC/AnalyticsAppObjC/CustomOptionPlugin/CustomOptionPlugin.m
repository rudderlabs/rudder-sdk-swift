//
//  CustomOptionPlugin.m
//  AnalyticsAppObjC
//
//  Created by Satheesh Kannan on 27/05/25.
//

#import "CustomOptionPlugin.h"

#pragma mark - CustomOptionPlugin

@interface CustomOptionPlugin()

@property(nonatomic, retain) RSAAnalytics *client;
@property(nonatomic, retain) RSAOption *option;

@end

@implementation CustomOptionPlugin
@synthesize pluginType;

- (instancetype)initWithOption:(RSAOption *)option
{
    self = [super init];
    if (self) {
        self.option = option;
    }
    return self;
}

- (RSAPluginType)pluginType {
    return RSAPluginTypeOnProcess;
}

- (RSAEvent * _Nullable)intercept:(RSAEvent * _Nonnull)event {
    
    RSAEvent *updatedEvent = [event addToContext: self.option.customContext];
    updatedEvent = [event addToIntegrations: self.option.integrations];
    updatedEvent = [event addExternalIds: self.option.externalIds];
    
    return updatedEvent;
}

- (void)setup:(RSAAnalytics * _Nonnull)analytics {
    self.client = analytics;
}

- (void)teardown { }

@end
