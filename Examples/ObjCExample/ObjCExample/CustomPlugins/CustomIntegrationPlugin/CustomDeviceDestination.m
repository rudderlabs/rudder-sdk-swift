//
//  CustomDeviceDestination.m
//  ObjCExampleApp
//
//  Created by Satheesh Kannan on 08/12/25.
//

#import "CustomDeviceDestination.h"
@import RudderStackAnalytics;

#pragma mark - CustomDeviceDestination

@interface CustomDeviceDestination()

- (instancetype)initWithKey:(NSString *)key;

@end


#pragma mark - Implementation

@implementation CustomDeviceDestination

#pragma mark - Initializers

-(instancetype)initWithKey:(NSString *)key {
    self = [super init];
    if (self) {
        _key = key;
    }
    return self;
}

+ (instancetype)createWithApiKey:(NSString *)apiKey {
    [NSThread sleepForTimeInterval:1.0];
    
    [RSSLoggerAnalytics debug: [NSString stringWithFormat: @"SampleDestinationSdk: SDK created with API key %@", apiKey]];
    return [[self alloc] initWithKey:apiKey];
}

#pragma mark - Events
- (void)trackEvent:(NSString *)event properties:(NSDictionary<NSString *, id> *)properties {
    [RSSLoggerAnalytics debug: [NSString stringWithFormat: @"SampleDestinationSdk: track event %@ with properties %@", event, properties]];
}

- (void)screen:(NSString *)screenName properties:(NSDictionary<NSString *, id> *)properties {
    [RSSLoggerAnalytics debug: [NSString stringWithFormat: @"SampleDestinationSdk: screen event %@ with properties %@", screenName, properties]];
}

- (void)group:(NSString *)groupId traits:(NSDictionary<NSString *, id> *)traits {
    [RSSLoggerAnalytics debug: [NSString stringWithFormat: @"SampleDestinationSdk: group event %@ with traits %@", groupId, traits]];
}

- (void)identifyUser:(NSString *)userId traits:(NSDictionary<NSString *, id> *)traits {
    [RSSLoggerAnalytics debug: [NSString stringWithFormat: @"SampleDestinationSdk: identify user %@ with traits %@", userId, traits]];
}

- (void)aliasUser:(NSString *)userId previousId:(NSString *)previousId {
    [RSSLoggerAnalytics debug: [NSString stringWithFormat: @"SampleDestinationSdk: alias user %@ with previous ID %@", userId, previousId]];
}

- (void)flush {
    [RSSLoggerAnalytics debug: [NSString stringWithFormat: @"SampleDestinationSdk: flush"]];
}

- (void)reset {
    [RSSLoggerAnalytics debug: [NSString stringWithFormat: @"SampleDestinationSdk: reset"]];
}

- (void)update {
    [RSSLoggerAnalytics debug: [NSString stringWithFormat: @"SampleDestinationSdk: update"]];
}

@end
