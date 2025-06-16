//
//  AnalyticsManager.m
//  AnalyticsAppObjC
//
//  Created by Satheesh Kannan on 27/05/25.
//

#import "AnalyticsManager.h"
#import "CustomLogger.h"
#import "CustomOptionPlugin.h"

@interface AnalyticsManager()

@property(nonatomic, retain) RSAAnalytics *client;

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
    
    RSAConfigurationBuilder *builder = [[RSAConfigurationBuilder alloc] initWithWriteKey:writeKey dataPlaneUrl:dataPlaneUrl];
    [builder setLogLevel: RSALogLevelVerbose];
    [builder setGzipEnabled: YES];
    
    NSArray *flushPolicies = @[[RSAStartupFlushPolicy new], [RSAFrequencyFlushPolicy new], [RSACountFlushPolicy new]];
    [builder setFlushPolicies: flushPolicies];
    [builder setCollectDeviceId: YES];
    [builder setTrackApplicationLifecycleEvents: YES];

    RSASessionConfigurationBuilder *sessionBuilder = [RSASessionConfigurationBuilder new];
    [builder setSessionConfiguration: [sessionBuilder build]];
    
    self.client = [[RSAAnalytics alloc] initWithConfiguration:[builder build]];
   
    // Adding custom Logger..
    CustomLogger *logger = [CustomLogger new];
    [self.client setCustomLogger:logger];
    
    RSAOptionBuilder *optionBuilder = [RSAOptionBuilder new];
    [optionBuilder setIntegrations:@{@"CleverTap": @YES}];
    [optionBuilder setCustomContext:@{@"plugin_key": @"plugin_value"}];
    [optionBuilder setExternalIds:@[[[RSAExternalId alloc] initWithType:@"external_id_type" id:@"external_id"]]];
    
    // Adding custom plugin..
    CustomOptionPlugin *plugin = [[CustomOptionPlugin alloc] initWithOption:[optionBuilder build]];
    [self.client addPlugin:plugin];
}

- (void)identify:(NSString * _Nonnull)userId traits:(NSDictionary<NSString *,id> * _Nullable)traits options:(RSAOption* _Nullable)option {
    [self.client identify:userId traits:traits options:option];
}

- (void)track:(NSString * _Nonnull)name properties:(NSDictionary<NSString *,id> * _Nullable)properties options:(RSAOption* _Nullable)option {
    [self.client track:name properties:properties options:option];
}

- (void)screen:(NSString * _Nonnull)name category:(NSString * _Nullable)category properties:(NSDictionary<NSString *,id> * _Nullable)properties options:(RSAOption* _Nullable)option {
    [self.client screen:name category:category properties:properties options:option];
}

- (void)group:(NSString * _Nonnull)groupId traits:(NSDictionary<NSString *,id> * _Nullable)traits options:(RSAOption* _Nullable)option {
    [self.client group:groupId traits:traits options:option];
}

- (void)alias:(NSString * _Nonnull)newId previousId:(NSString* _Nullable)previousId options:(RSAOption* _Nullable)option {
    [self.client alias:newId previousId:previousId options:option];
}

- (void)flush {
    [self.client flush];
}

- (void)reset {
    [self.client reset];
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

@end
