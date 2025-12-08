//
//  SampleDestination.m
//  ObjCExampleApp
//
//  Created by Satheesh Kannan on 08/12/25.
//

#import "SampleDestination.h"

@interface SampleDestination()

- (instancetype)initWithKey:(NSString *)key;

@end


@implementation SampleDestination

-(instancetype)initWithKey:(NSString *)key {
    self = [super init];
    if (self) {
        _key = key;
    }
    return self;
}

+ (instancetype)createWithApiKey:(NSString *)apiKey {
    [NSThread sleepForTimeInterval:1.0];
    
    [RSSLoggerAnalytics debug: [NSString stringWithFormat: @"CustomDeviceDestination: SDK created with API key %@", apiKey]];
    return [[self alloc] initWithKey:apiKey];
}

- (void)trackEvent:(NSString *)event properties:(NSDictionary<NSString *, id> *)properties {
    [RSSLoggerAnalytics debug: [NSString stringWithFormat: @"CustomDeviceDestination: track event %@ with properties %@", event, properties]];
}

- (void)screen:(NSString *)screenName properties:(NSDictionary<NSString *, id> *)properties {
    [RSSLoggerAnalytics debug: [NSString stringWithFormat: @"CustomDeviceDestination: screen event %@ with properties %@", screenName, properties]];
}

- (void)group:(NSString *)groupId traits:(NSDictionary<NSString *, id> *)traits {
    [RSSLoggerAnalytics debug: [NSString stringWithFormat: @"CustomDeviceDestination: group event %@ with traits %@", groupId, traits]];
}

- (void)identifyUser:(NSString *)userId traits:(NSDictionary<NSString *, id> *)traits {
    [RSSLoggerAnalytics debug: [NSString stringWithFormat: @"CustomDeviceDestination: identify user %@ with traits %@", userId, traits]];
}

- (void)aliasUser:(NSString *)userId previousId:(NSString *)previousId {
    [RSSLoggerAnalytics debug: [NSString stringWithFormat: @"CustomDeviceDestination: alias user %@ with previous ID %@", userId, previousId]];
}

- (void)flush {
    [RSSLoggerAnalytics debug: [NSString stringWithFormat: @"CustomDeviceDestination: flush"]];
}

- (void)reset {
    [RSSLoggerAnalytics debug: [NSString stringWithFormat: @"CustomDeviceDestination: reset"]];
}

- (void)update {
    [RSSLoggerAnalytics debug: [NSString stringWithFormat: @"CustomDeviceDestination: update"]];
}

@end
