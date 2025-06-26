//
//  ObjCCompat.m
//  ObjCExample
//
//  Created by Satheesh Kannan on 29/05/25.
//

#import "ObjCCompat.h"
@import RudderStackAnalytics;
#import "CustomOptionPlugin.h"
#import "CustomLogger.h"

@interface ObjCCompat()

@property RSSAnalytics *client;
@property CustomOptionPlugin *customPlugin;

@end

@implementation ObjCCompat

- (instancetype)init {
    if (self) {}
    return self;
}

- (void)initializeAnalyticsSDK {

    NSString *writeKey = @"sample-write-key";
    NSString *dataPlaneUrl = @"https://data-plane.analytics.com";
    
    [RSSLoggerAnalytics setLogLevel: RSSLogLevelVerbose];
    
    RSSConfigurationBuilder *builder = [[RSSConfigurationBuilder alloc] initWithWriteKey:writeKey dataPlaneUrl:dataPlaneUrl];
    [builder setGzipEnabled: YES];
    
    NSArray *flushPolicies = @[[RSSStartupFlushPolicy new], [RSSFrequencyFlushPolicy new], [RSSCountFlushPolicy new]];
    [builder setFlushPolicies: flushPolicies];
    [builder setTrackApplicationLifecycleEvents: YES];

    RSSSessionConfigurationBuilder *sessionBuilder = [RSSSessionConfigurationBuilder new];
    [sessionBuilder setAutomaticSessionTracking: true];
    [sessionBuilder setSessionTimeoutInMillis: @1000];
    
    [builder setSessionConfiguration: [sessionBuilder build]];
    
    self.client = [[RSSAnalytics alloc] initWithConfiguration:[builder build]];
}

- (void)startSession {
    [self.client startSession];
}

- (void)startSession:(NSNumber *)sessionId {
    [self.client startSessionWithSessionId:sessionId];
}

- (void)endSession {
    [self.client endSession];
}

- (void)reset {
    [self.client reset];
}

- (void)flush {
    [self.client flush];
}

- (void)shutdown {
    [self.client shutdown];
}

- (void)addCustomPlugin {
    RSSOptionBuilder *optionBuilder = [RSSOptionBuilder new];
    [optionBuilder setIntegrations:@{@"CleverTap": @YES}];
    [optionBuilder setCustomContext:@{@"plugin_key": @"plugin_value"}];
    [optionBuilder setExternalIds:@[[[RSSExternalId alloc] initWithType:@"external_id_type" id:@"external_id"]]];
    
    // Adding custom plugin..
    self.customPlugin = [[CustomOptionPlugin alloc] initWithOption:[optionBuilder build]];
    [self.client addPlugin: self.customPlugin];
}

- (void)removeCustomPlugin {
    if (self.customPlugin != nil) {
        [self.client removePlugin: self.customPlugin];
        self.customPlugin = nil;
    }
}

- (NSNumber * _Nullable)sessionId {
    return self.client.sessionId;
}

- (void)track {
    NSString *name = @"Sample Track Event";
    NSDictionary *property = [self preparedProperty];
    RSSOption *option = [self preparedOption];
    
    [self.client track: name];
    [self.client track: name options: option];
    [self.client track: name properties: property];
    [self.client track: name properties: property options: option];
}

- (void)screen {
    NSString *screenName = @"Sample Screen Event";
    NSString *categoryName = @"Sample Screen Category";
    NSDictionary *property = [self preparedProperty];
    RSSOption *option = [self preparedOption];
    
    [self.client screen: screenName];
    [self.client screen: screenName options: option];
    [self.client screen: screenName category: categoryName];
    [self.client screen: screenName properties: property];
    [self.client screen: screenName category: categoryName options: option];
    [self.client screen: screenName properties: property options: option];
    [self.client screen: screenName category: categoryName properties: property];
    [self.client screen: screenName category: categoryName properties: property options: option];
}

- (void)group {
    NSString *groupId = @"Sample GroupId";
    NSDictionary *traits = [self preparedProperty];
    RSSOption *option = [self preparedOption];
    
    [self.client group: groupId];
    [self.client group: groupId traits: traits];
    [self.client group: groupId options: option];
    [self.client group: groupId traits: traits options: option];
}

- (void)identify {
    NSString *userId = @"Sample UserId";
    NSDictionary *traits = [self preparedProperty];
    RSSOption *option = [self preparedOption];
    
    [self.client identify: userId];
    [self.client identify: userId traits: traits];
    [self.client identify: userId options: option];
    [self.client identify: userId traits: traits options: option];
    [self.client identifyWithTraits: traits];
    [self.client identifyWithTraits: traits options: option];
}

- (void)alias {
    NSString *newId = @"Sample Alias";
    NSString *previousId = @"Sample PreviousId";
    RSSOption *option = [self preparedOption];
    
    [self.client alias: newId];
    [self.client alias: newId options: option];
    [self.client alias: newId previousId: previousId];
    [self.client alias: newId previousId: previousId options: option];
}

- (NSString * _Nullable)anonymousId {
    return self.client.anonymousId;
}

- (NSString * _Nullable)userId {
    return self.client.userId;
}

- (NSDictionary * _Nullable)traits {
    return self.client.traits;
}

- (void)addCustomLogger {
    CustomLogger *logger = [CustomLogger new];
    [RSSLoggerAnalytics setLogger: logger];
}

- (void)trackDeepLinking {
    [self.client openURL: [NSURL URLWithString:@"https://www.example-test.com"]];
    [self.client openURL: [NSURL URLWithString:@"https://www.example-test.com"] options: @{@"another_property": @"another_value"}];
}

#pragma mark - Helpers

- (NSDictionary *)preparedProperty {
    return @{@"property_key": @"property_value"};
}

- (RSSOption *)preparedOption {
    RSSExternalId *externalId = [[RSSExternalId alloc] initWithType:@"idCardNumber" id:@"12791"];
    
    NSDictionary *integrations = @{@"Amplitude": @YES, @"CleverTap": @NO};
    NSDictionary *customContext = @{
        @"Key_1": @{@"Key1": @"Value1"},
        @"Key_2": @[@"value1", @"value2"],
        @"Key_3": @"Value3",
        @"Key_4": @1234,
        @"Key_5": @5678.9,
        @"Key_6": @YES
    };
    
    RSSOptionBuilder *optionBuilder = [RSSOptionBuilder new];
    [optionBuilder setIntegrations:integrations];
    [optionBuilder setCustomContext:customContext];
    [optionBuilder setExternalIds:@[externalId]];
    
    return [optionBuilder build];
}

@end
