//
//  AnalyticsManager.m
//  ObjCExample
//
//  Created by Satheesh Kannan on 27/05/25.
//

#import "AnalyticsManager.h"
#import "CustomLogger.h"
#import "CustomOptionPlugin.h"

@interface AnalyticsManager()

@property(nonatomic, retain) RSSAnalytics *client;

@end

@implementation AnalyticsManager

+ (instancetype)sharedManager {
    static AnalyticsManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AnalyticsManager alloc] init];
    });
    return sharedInstance;
}

- (void)initializeAnalyticsSDK {

    NSString *writeKey = @"sample-write-key";
    NSString *dataPlaneUrl = @"https://data-plane.analytics.com";
    
    RSSConfigurationBuilder *builder = [[RSSConfigurationBuilder alloc] initWithWriteKey:writeKey dataPlaneUrl:dataPlaneUrl];
    [builder setGzipEnabled: YES];
    
    NSArray *flushPolicies = @[[RSSStartupFlushPolicy new], [RSSFrequencyFlushPolicy new], [RSSCountFlushPolicy new]];
    [builder setFlushPolicies: flushPolicies];
    [builder setCollectDeviceId: YES];
    [builder setTrackApplicationLifecycleEvents: YES];

    RSSSessionConfigurationBuilder *sessionBuilder = [RSSSessionConfigurationBuilder new];
    [builder setSessionConfiguration: [sessionBuilder build]];
    
    // Adding custom Logger..
    [RSSLoggerAnalytics setLogLevel: RSSLogLevelVerbose];
    CustomLogger *logger = [CustomLogger new];
    [RSSLoggerAnalytics setLogger:logger];
    
    self.client = [[RSSAnalytics alloc] initWithConfiguration:[builder build]];
    
    RSSOptionBuilder *optionBuilder = [RSSOptionBuilder new];
    [optionBuilder setIntegrations:@{@"CleverTap": @YES}];
    [optionBuilder setCustomContext:@{@"plugin_key": @"plugin_value"}];
    [optionBuilder setExternalIds:@[[[RSSExternalId alloc] initWithType:@"external_id_type" id:@"external_id"]]];
    
    // Adding custom plugin..
    CustomOptionPlugin *plugin = [[CustomOptionPlugin alloc] initWithOption:[optionBuilder build]];
    [self.client addPlugin:plugin];
}

- (void)identify:(NSString * _Nullable)userId traits:(NSDictionary<NSString *,id> * _Nullable)traits options:(RSSOption* _Nullable)option {
    [self.client identify:userId traits:traits options:option];
}

- (void)track:(NSString * _Nonnull)name properties:(NSDictionary<NSString *,id> * _Nullable)properties options:(RSSOption* _Nullable)option {
    [self.client track:name properties:properties options:option];
}

- (void)screen:(NSString * _Nonnull)name category:(NSString * _Nullable)category properties:(NSDictionary<NSString *,id> * _Nullable)properties options:(RSSOption* _Nullable)option {
    [self.client screen:name category:category properties:properties options:option];
}

- (void)group:(NSString * _Nonnull)groupId traits:(NSDictionary<NSString *,id> * _Nullable)traits options:(RSSOption* _Nullable)option {
    [self.client group:groupId traits:traits options:option];
}

- (void)alias:(NSString * _Nonnull)newId previousId:(NSString* _Nullable)previousId options:(RSSOption* _Nullable)option {
    [self.client alias:newId previousId:previousId options:option];
}

- (void)flush {
    [self.client flush];
}

- (void)reset {
    [self.client reset];
}

- (void)resetWithOptions {
    RSSResetOptionsBuilder *builder = [RSSResetOptionsBuilder new];
    [builder setResetAnonymousId: YES];
    [builder setResetUserId: YES];
    [builder setResetTraits: YES];
    [builder setResetSession: YES];
    
    [self.client resetWithOptions: [builder build]];
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

- (void)shutdown {
    [self.client shutdown];
}

- (NSString * _Nullable)anonymousId {
    return self.client.anonymousId;
}

- (NSNumber * _Nullable)sessionId {
    return self.client.sessionId;
}

- (void)openURL:(NSURL * _Nonnull)url options:(NSDictionary<NSString *, id> * _Nullable)options {
    [self.client openURL:url options:options];
}

@end
