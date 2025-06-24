//
//  CustomOptionPlugin.m
//  ObjCExample
//
//  Created by Satheesh Kannan on 27/05/25.
//

#import "CustomOptionPlugin.h"

#pragma mark - CustomOptionPlugin

@interface CustomOptionPlugin()

@property(nonatomic, retain) RSSAnalytics *client;
@property(nonatomic, retain) RSSOption *option;

@end

@implementation CustomOptionPlugin
@synthesize pluginType;

- (instancetype)initWithOption:(RSSOption *)option
{
    self = [super init];
    if (self) {
        self.option = option;
    }
    return self;
}

- (RSSPluginType)pluginType {
    return RSSPluginTypeOnProcess;
}

- (RSSEvent * _Nullable)intercept:(RSSEvent * _Nonnull)event {
    
    [self addCustomContext:event];
    [self addExternalIds:event];
    [self addIntegrations:event];
    
    return event;
}

- (void)addCustomContext:(RSSEvent *)event {
    NSMutableDictionary *contextDict = [NSMutableDictionary dictionaryWithDictionary: (event.context ?: @{})];
    [contextDict addEntriesFromDictionary: (self.option.customContext ?: @{})];
    event.context = contextDict;
}

- (void)addExternalIds:(RSSEvent *)event {
    NSMutableDictionary *contextDict = [NSMutableDictionary dictionaryWithDictionary: (event.context ?: @{})];
    NSMutableArray *externalIdArray = [NSMutableArray arrayWithArray: (contextDict[@"externalId"] ?: @[])];
    
    // Merge option's externalIds into existing externalIds
    [self.option.externalIds enumerateObjectsUsingBlock:^(RSSExternalId * _Nonnull externalId, NSUInteger idx, BOOL * _Nonnull stop) {
        [externalIdArray addObject:@{@"id": externalId.id, @"type": externalId.type}];
    }];
    
    contextDict[@"externalId"] = externalIdArray;
    event.context = contextDict;
}

- (void)addIntegrations:(RSSEvent *)event {
    NSMutableDictionary *integrationsDict = [NSMutableDictionary dictionaryWithDictionary: (event.integrations ?: @{})];
    [integrationsDict addEntriesFromDictionary: (self.option.integrations ?: @{})];
    event.integrations = integrationsDict;
}

- (void)setup:(RSSAnalytics * _Nonnull)analytics {
    self.client = analytics;
}

- (void)teardown { }

@end
