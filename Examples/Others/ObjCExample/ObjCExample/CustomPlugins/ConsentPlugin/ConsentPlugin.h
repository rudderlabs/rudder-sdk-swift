//
//  ConsentPlugin.h
//  ObjCExampleApp
//
//  Created by Satheesh Kannan on 31/08/26.
//

#import <Foundation/Foundation.h>
@import RudderStackAnalytics;

NS_ASSUME_NONNULL_BEGIN

/**
 * ConsentCategoryProvider
 *
 * The slice of a Consent Management Platform that ConsentPlugin depends on.
 * Adapt this to whichever CMP the app uses — the plugin needs only the two ID
 * lists and a notification for when the user changes their choices.
 */
@protocol ConsentCategoryProvider <NSObject>

/** Consent category IDs the user has granted. */
@property (nonatomic, copy, readonly) NSArray<NSString *> *allowedConsentIds;

/** Consent category IDs the user has denied. */
@property (nonatomic, copy, readonly) NSArray<NSString *> *deniedConsentIds;

/** Invoked by the CMP whenever the user's choices change. */
@property (nonatomic, copy, nullable) void (^onConsentChanged)(void);

@end

/**
 * ConsentPlugin
 *
 * A sample pattern for bridging a Consent Management Platform into the SDK.
 * This is example code, not SDK API — copy it into your project and adapt it
 * to your CMP.
 *
 * The plugin never modifies the event context — it does not implement
 * intercept: at all. The SDK owns context.consentManagement and stamps it from
 * the state recorded by setConsent:; a plugin writing that key is overwritten
 * by the SDK and logs a warning.
 *
 * ## Usage
 * ```objc
 *     ConsentPlugin *plugin = [[ConsentPlugin alloc] initWithProvider:myCmpAdapter];
 *     [analytics addPlugin:plugin];
 * ```
 * Adding the plugin pushes whatever the CMP already knows, then keeps the SDK
 * in sync as the user changes their choices.
 */
@interface ConsentPlugin : NSObject<RSSPlugin>

/**
 * Initializes a new instance backed by the given CMP adapter.
 *
 * @param provider The CMP adapter supplying the current consent lists and
 *                 change notifications.
 * @return A configured ConsentPlugin instance.
 */
- (instancetype)initWithProvider:(id<ConsentCategoryProvider>)provider NS_DESIGNATED_INITIALIZER;

/**
 * Default initializer is unavailable. Use initWithProvider: instead.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Hands the CMP's current choices to the SDK. The new lists fully replace the
 * previous consent state and apply from the next event onward.
 */
- (void)pushCurrentConsent;

@end

NS_ASSUME_NONNULL_END
