//
//  CustomOptionPlugin.m
//  ObjCExample
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
    
    [self addCustomContext:event];
    [self addExternalIds:event];
    [self addIntegrations:event];
    
    return event;
}

- (void)addCustomContext:(RSAEvent *)event {
    NSMutableDictionary *contextDict = [NSMutableDictionary dictionaryWithDictionary: (event.context ?: @{})];
    [contextDict addEntriesFromDictionary: (self.option.customContext ?: @{})];
    event.context = contextDict;
}

- (void)addExternalIds:(RSAEvent *)event {
    NSMutableDictionary *contextDict = [NSMutableDictionary dictionaryWithDictionary: (event.context ?: @{})];
    NSMutableArray *externalIdArray = [NSMutableArray arrayWithArray: (contextDict[@"externalId"] ?: @[])];
    
    // Merge option's externalIds into existing externalIds
    [self.option.externalIds enumerateObjectsUsingBlock:^(RSAExternalId * _Nonnull externalId, NSUInteger idx, BOOL * _Nonnull stop) {
        [externalIdArray addObject:@{@"id": externalId.id, @"type": externalId.type}];
    }];
    
    contextDict[@"externalId"] = externalIdArray;
    event.context = contextDict;
}

- (void)addIntegrations:(RSAEvent *)event {
    NSMutableDictionary *integrationsDict = [NSMutableDictionary dictionaryWithDictionary: (event.integrations ?: @{})];
    [integrationsDict addEntriesFromDictionary: (self.option.integrations ?: @{})];
    event.integrations = integrationsDict;
}

- (void)setup:(RSAAnalytics * _Nonnull)analytics {
    self.client = analytics;
}

- (void)teardown { }

@end
