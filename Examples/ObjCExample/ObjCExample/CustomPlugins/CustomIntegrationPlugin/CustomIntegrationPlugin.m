//
//  CustomIntegrationPlugin.m
//  ObjCExampleApp
//
//  Created by Satheesh Kannan on 08/12/25.
//

#import "CustomIntegrationPlugin.h"
#import "CustomDeviceDestination.h"

@interface CustomIntegrationPlugin()

@property CustomDeviceDestination *destination;

@end


@implementation CustomIntegrationPlugin

@synthesize pluginType;
@synthesize key;

- (NSString*)key {
    return @"CustomIntegrationKey";
}

- (RSSPluginType)pluginType {
    return RSSPluginTypeTerminal;
}

- (BOOL)createWithDestinationConfig:(NSDictionary<NSString *,id> * _Nonnull)destinationConfig error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    if (_destination == nil) {
        _destination = [CustomDeviceDestination createWithApiKey:@"MyCustomDeviceDestination"];
    }
    return YES;
}

- (BOOL)updateWithDestinationConfig:(NSDictionary<NSString *,id> *)destinationConfig error:(NSError * _Nullable __autoreleasing *)error {
    [_destination update];
    return YES;
}

- (id _Nullable)getDestinationInstance { 
    return self.destination;
}

- (void)track:(RSSTrackEvent *)payload {
    [_destination trackEvent:payload.eventName properties:payload.properties ?: @{}];
}

- (void)screen:(RSSScreenEvent *)payload {
    [_destination screen:payload.screenName properties:payload.properties ?: @{}];
}

- (void)group:(RSSGroupEvent *)payload {
    [_destination group:payload.groupId traits:payload.traits ?: @{}];
}

- (void)identify:(RSSIdentifyEvent *)payload {
    [_destination identifyUser:payload.userId ?: @"" traits:payload.traits ?: @{}];
}

- (void)alias:(RSSAliasEvent *)payload {
    [_destination aliasUser:payload.userId ?: @"" previousId:payload.previousId];
}

- (void)flush {
    [_destination flush];
}

- (void)reset {
    [_destination reset];
}

@end
