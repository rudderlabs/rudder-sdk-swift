//
//  AppDelegate.m
//  SampleiOSObjC
//
//  Created by Pallab Maiti on 21/03/22.
//

#import "AppDelegate.h"

@import RudderStack;

static NSString *DATA_PLANE_URL = @"https://rudderstacz.dataplane.rudderstack.com";
static NSString *WRITE_KEY = @"1wvsoF3Kx2SczQNlx1dvcqW9ODW";

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    RSConfig *config = [[RSConfig alloc] initWithWriteKey:WRITE_KEY];
    [config dataPlaneURL:DATA_PLANE_URL];
    [config trackLifecycleEvents:YES];
    [config recordScreenViews:YES];
    RSClient *client = [[RSClient alloc] initWithConfig:config];
    [client track:@"track 1" properties:nil option:nil];
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
