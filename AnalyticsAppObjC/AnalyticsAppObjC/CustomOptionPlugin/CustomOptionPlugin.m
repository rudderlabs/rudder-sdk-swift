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
    
    NSMutableDictionary *contextDict = [NSMutableDictionary dictionaryWithDictionary: event.context];
    [contextDict addEntriesFromDictionary: self.option.customContext];
    
    NSMutableArray *externalIdArray = [NSMutableArray arrayWithArray: contextDict[@"externalId"]];
    [self.option.externalIds enumerateObjectsUsingBlock:^(RSAExternalId * _Nonnull eId, NSUInteger idx, BOOL * _Nonnull stop) {
        [externalIdArray addObject:@{@"id": eId.id, @"type": eId.type}];
    }];
    contextDict[@"externalId"] = externalIdArray;
    event.context = contextDict;
    
    NSMutableDictionary *integrationsDict = [NSMutableDictionary dictionaryWithDictionary: event.integrations];
    [integrationsDict addEntriesFromDictionary: self.option.integrations];
    event.integrations = integrationsDict;
    
    return event;
}

- (void)setup:(RSAAnalytics * _Nonnull)analytics {
    self.client = analytics;
}

- (void)teardown { }

@end
