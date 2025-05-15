//
//  AnalyticsManager.m
//  AnalyticsAppObjC
//
//  Created by Satheesh Kannan on 15/05/25.
//

#import "AnalyticsManager.h"
#import "CustomStorage.h"
#import "CustomOptionPlugin.h"
#import "CustomLogger.h"

@interface AnalyticsManager()

@property(nonatomic, retain) AnalyticsClient *client;

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
    
    NSString *writeKey = @"2vPgTJJHX8Z1fpU8DWjDGlmyJpF";
    NSString *dataPlaneUrl = @"https://rudderstacfbtt.dataplane.rudderstack.com";
    
    Configuration *config = [[Configuration alloc] initWithWriteKey:writeKey dataPlaneUrl:dataPlaneUrl];
    
    config.controlPlaneUrl = Constants.defaultConfig.controlPlaneUrl;
    config.logLevel = LogLevelVerbose;
    config.optOut = NO;
    config.gzipEnabled = Constants.defaultConfig.gzipEnabled;
    config.flushPolicies = @[[StartupFlushPolicy new], [FrequencyFlushPolicy new], [[CountFlushPolicy alloc] initWithFlushCount:1]];
    config.collectDeviceId = Constants.defaultConfig.willCollectDeviceId;
    config.trackApplicationLifecycleEvents = Constants.defaultConfig.willTrackLifecycleEvents;
    config.sessionConfiguration = [[SessionConfiguration alloc] init];
    config.storage = [[CustomStorage alloc] initWithWriteKey:writeKey];
    
    self.client = [[AnalyticsClient alloc] initWithConfiguration:config];
    
    // Adding custom plugin..
    RudderOption *option = [[RudderOption alloc] initWithIntegrations:@{@"CleverTap": @YES} customContext:@{@"plugin_key": @"plugin_value"} externalIds:@[[[ExternalId alloc] initWithType:@"external_id_type" id:@"external_id"]]];
    CustomOptionPlugin *optionPlugin = [[CustomOptionPlugin alloc] initWithOption:option];
    [self.client addPlugin:optionPlugin];
    
    // Adding custom Logger..
    CustomLogger *logger = [CustomLogger new];
    [self.client setLogger:logger];
}

- (void)identify:(NSString * _Nonnull)userId traits:(NSDictionary<NSString *,id> * _Nullable)traits options:(RudderOption* _Nullable)option {
    [self.client identify:userId traits:traits options:option];
}

- (void)track:(NSString * _Nonnull)name properties:(NSDictionary<NSString *,id> * _Nullable)properties options:(RudderOption* _Nullable)option {
    [self.client track:name properties:properties options:option];
}

- (void)screen:(NSString * _Nonnull)name category:(NSString * _Nullable)category properties:(NSDictionary<NSString *,id> * _Nullable)properties options:(RudderOption* _Nullable)option {
    [self.client screen:name category:category properties:properties options:option];
}

- (void)group:(NSString * _Nonnull)groupId traits:(NSDictionary<NSString *,id> * _Nullable)traits options:(RudderOption* _Nullable)option {
    [self.client group:groupId traits:traits options:option];
}

- (void)alias:(NSString * _Nonnull)newId previousId:(NSString* _Nullable)previousId options:(RudderOption* _Nullable)option {
    [self.client alias:newId previousId:previousId options:option];
}

- (void)flush {
    [self.client flush];
}

- (void)reset:(BOOL)clearAnonymousId {
    [self.client reset:clearAnonymousId];
}

- (void)startSession {
    [self.client startSessionWithSessionId:Nil];
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

- (void)setAnonymousId:(NSString *)anonymousId {
    self.client.anonymousId = anonymousId;
}

- (NSNumber *)sessionId {
    return self.client.sessionId;
}
@end
