#import <Foundation/Foundation.h>
#import <Analytics/Analytics-Swift.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A plugin that sets a given `anonymousId` in the event payload for every event.
 
 **Note**: The `anonymousId` fetched using `RSAAnalytics.anonymousId` would be different from the `anonymousId` set here.
 
 Set this plugin just after the SDK initialization to set the custom `anonymousId` in the event payload for every event:
 ```objc
 [analytics add:[[SetAnonymousIdPlugin alloc] initWithAnonymousId:@"someAnonymousId"]];
 ```
 
 - Parameter anonymousId: The anonymousId to be set in the event payload. Ensure to preserve this value across app launches.
 */
@interface SetAnonymousIdPlugin : NSObject<RSAPlugin>

/**
 Initializes the SetAnonymousIdPlugin with a custom anonymous ID.
 
 @param anonymousId The custom anonymous ID to be set on all events
 @return An initialized SetAnonymousIdPlugin instance
 */
- (instancetype)initWithAnonymousId:(NSString *)anonymousId NS_DESIGNATED_INITIALIZER;

/**
 Standard init is unavailable - use initWithAnonymousId: instead
 */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
