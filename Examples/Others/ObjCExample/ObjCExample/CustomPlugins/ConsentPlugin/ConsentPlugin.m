//
//  ConsentPlugin.m
//  ObjCExampleApp
//
//  Created by Satheesh Kannan on 31/08/26.
//

#import "ConsentPlugin.h"

#pragma mark - ConsentPlugin

@interface ConsentPlugin()

@property(nonatomic, retain) RSSAnalytics *client;
@property(nonatomic, strong) id<ConsentCategoryProvider> provider;

@end

@implementation ConsentPlugin
@synthesize pluginType;

/**
 Initializes the plugin with the specified CMP adapter.

 @param provider The adapter supplying the current consent lists and change
                 notifications.
 @return An initialized instance of ConsentPlugin.
 */
- (instancetype)initWithProvider:(id<ConsentCategoryProvider>)provider
{
    self = [super init];
    if (self) {
        self.provider = provider;
    }
    return self;
}

/**
 Returns the plugin type for this plugin.

 @return RSSPluginTypeUtility, indicating this plugin never intercepts events —
         it only reacts to the CMP and calls setConsent:.
 */
- (RSSPluginType)pluginType {
    return RSSPluginTypeUtility;
}

/**
 Subscribes to the CMP and pushes its current choices to the SDK.

 @param analytics The analytics client instance to be used by the plugin.
 */
- (void)setup:(RSSAnalytics * _Nonnull)analytics {
    self.client = analytics;

    __weak typeof(self) weakSelf = self;
    self.provider.onConsentChanged = ^{
        [weakSelf pushCurrentConsent];
    };

    [self pushCurrentConsent];
}

/**
 Stops listening to the CMP.

 Called when the plugin is removed from the analytics client.
 */
- (void)teardown {
    self.provider.onConsentChanged = nil;
}

/**
 Hands the CMP's current choices to the SDK.

 The supplied lists fully replace the current consent state; omitted values
 clear the corresponding list.
 */
- (void)pushCurrentConsent {
    RSSConsentManagementOptions *options = [[RSSConsentManagementOptions alloc]
                                            initWithAllowedConsentIds:self.provider.allowedConsentIds
                                                     deniedConsentIds:self.provider.deniedConsentIds];
    [self.client setConsent:options];
}

@end
