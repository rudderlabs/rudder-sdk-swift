//
//  AnalyticsManager.h
//  ObjCExample
//
//  Created by Satheesh Kannan on 27/05/25.
//

#import <Foundation/Foundation.h>
@import RudderStackAnalytics;

NS_ASSUME_NONNULL_BEGIN

/**
 * AnalyticsManager
 *
 * A singleton wrapper class that provides a simplified interface for the RudderStackAnalytics SDK.
 * This manager handles SDK initialization, configuration, and provides convenient methods for
 * tracking analytics events throughout the application.
 *
 * Features:
 * - Singleton pattern for centralized analytics management
 * - Pre-configured SDK setup with custom logger and plugins
 * - Complete analytics event tracking (identify, track, screen, group, alias)
 * - Session management capabilities
 * - Deep linking support
 * - SDK lifecycle management (flush, reset, shutdown)
 *
 * ## Usage
 * ```objc
 *     // Initialize the SDK
 *     [[AnalyticsManager sharedManager] initializeAnalyticsSDK];
 *
 *     // Track events
 *     [[AnalyticsManager sharedManager] track:@"Button Clicked"
 *                                   properties:@{@"button_name": @"signup"}
 *                                      options:nil];
 *
 *     // Identify users
 *     [[AnalyticsManager sharedManager] identify:@"user123"
 *                                         traits:@{@"email": @"user@example.com"}
 *                                        options:nil];
 * ```
 */
@interface AnalyticsManager : NSObject

+ (instancetype)sharedManager;

- (void)initializeAnalyticsSDK;

- (void)identify:(NSString * _Nullable)userId traits:(NSDictionary<NSString *,id> * _Nullable)traits options:(RSSOption* _Nullable)option;
- (void)track:(NSString * _Nonnull)name properties:(NSDictionary<NSString *,id> * _Nullable)properties options:(RSSOption* _Nullable)option;
- (void)screen:(NSString * _Nonnull)name category:(NSString * _Nullable)category properties:(NSDictionary<NSString *,id> * _Nullable)properties options:(RSSOption* _Nullable)option;
- (void)group:(NSString * _Nonnull)groupId traits:(NSDictionary<NSString *,id> * _Nullable)traits options:(RSSOption* _Nullable)option;
- (void)alias:(NSString * _Nonnull)newId previousId:(NSString* _Nullable)previousId options:(RSSOption* _Nullable)option;
- (void)flush;
- (void)reset;
- (void)startSession;
- (void)startSession:(NSNumber *)sessionId;
- (void)endSession;
- (void)shutdown;
- (NSString * _Nullable)anonymousId;
- (NSNumber * _Nullable)sessionId;
- (void)openURL:(NSURL * _Nonnull)url options:(NSDictionary<NSString *, id> * _Nullable)options;

@end

NS_ASSUME_NONNULL_END


#pragma mark - Analytics ActionType

typedef NS_ENUM(NSInteger, ActionType) {
    ActionTypeIdentify,
    ActionTypeAlias,
    ActionTypeTrack,
    ActionTypeMultipleTrack,
    ActionTypeScreen,
    ActionTypeGroup,
    ActionTypeFlush,
    ActionTypeUpdateAnonymousId,
    ActionTypeReadAnonymousId,
    ActionTypeReset,
    ActionTypeStartSession,
    ActionTypeStartSessionWithSessionId,
    ActionTypeReadSessionId,
    ActionTypeEndSession,
    ActionTypeShutdown,
    ActionTypeReInitializeSDK
};
