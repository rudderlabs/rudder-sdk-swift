//
//  AnalyticsManager.m
//  AnalyticsAppObjC
//
//  Created by Satheesh Kannan on 27/05/25.
//

#import "AnalyticsManager.h"

@interface AnalyticsManager()

@property(nonatomic, retain) RSAnalytics *client;

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
    
    RSConfigurationBuilder *builder = [[RSConfigurationBuilder alloc] initWithWriteKey:writeKey dataPlaneUrl:dataPlaneUrl];
    [builder setLogLevel: RSLogLevelVerbose];
    [builder setOptOut: NO];
    [builder setGzipEnabled: YES];
    
    NSArray *flushPolicies = @[[RSStartupFlushPolicy new], [RSFrequencyFlushPolicy new], [RSCountFlushPolicy new]];
    [builder setFlushPolicies: flushPolicies];
    [builder setCollectDeviceId: YES];
    [builder setTrackApplicationLifecycleEvents: YES];

    RSSessionConfigurationBuilder *sessionBuilder = [RSSessionConfigurationBuilder new];
    [builder setSessionConfiguration: [sessionBuilder build]];
    [builder setStorageMode: RSStorageModeMemory];
    
    self.client = [[RSAnalytics alloc] initWithConfiguration:[builder build]];
/*
    config.storage = [[CustomStorage alloc] initWithWriteKey:writeKey];
        
    // Adding custom plugin..
    RudderOption *option = [[RudderOption alloc] initWithIntegrations:@{@"CleverTap": @YES} customContext:@{@"plugin_key": @"plugin_value"} externalIds:@[[[ExternalId alloc] initWithType:@"external_id_type" id:@"external_id"]]];
    CustomOptionPlugin *optionPlugin = [[CustomOptionPlugin alloc] initWithOption:option];
    [self.client addPlugin:optionPlugin];
    
    // Adding custom Logger..
    CustomLogger *logger = [CustomLogger new];
    [self.client setLogger:logger];
 */
}

- (void)identify:(NSString * _Nonnull)userId traits:(NSDictionary<NSString *,id> * _Nullable)traits options:(RSOption* _Nullable)option {
    [self.client identify:userId traits:traits options:option];
}

- (void)track:(NSString * _Nonnull)name properties:(NSDictionary<NSString *,id> * _Nullable)properties options:(RSOption* _Nullable)option {
    [self.client track:name properties:properties options:option];
}

- (void)screen:(NSString * _Nonnull)name category:(NSString * _Nullable)category properties:(NSDictionary<NSString *,id> * _Nullable)properties options:(RSOption* _Nullable)option {
    [self.client screen:name category:category properties:properties options:option];
}

- (void)group:(NSString * _Nonnull)groupId traits:(NSDictionary<NSString *,id> * _Nullable)traits options:(RSOption* _Nullable)option {
    [self.client group:groupId traits:traits options:option];
}

- (void)alias:(NSString * _Nonnull)newId previousId:(NSString* _Nullable)previousId options:(RSOption* _Nullable)option {
    [self.client alias:newId previousId:previousId options:option];
}

- (void)flush {
    [self.client flush];
}

- (void)reset:(BOOL)clearAnonymousId {
    [self.client reset:clearAnonymousId];
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

- (void)setAnonymousId:(NSString *)anonymousId {
    self.client.anonymousId = anonymousId;
}

- (NSNumber * _Nullable)sessionId {
    return self.client.sessionId;
}

@end
