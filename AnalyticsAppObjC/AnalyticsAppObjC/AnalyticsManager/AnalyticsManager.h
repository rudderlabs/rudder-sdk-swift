//
//  AnalyticsManager.h
//  AnalyticsAppObjC
//
//  Created by Satheesh Kannan on 27/05/25.
//

#import <Foundation/Foundation.h>
#import <Analytics/Analytics-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface AnalyticsManager : NSObject

+ (instancetype)sharedManager;

- (void)initializeAnalyticsSDK;

- (void)identify:(NSString * _Nonnull)userId traits:(NSDictionary<NSString *,id> * _Nullable)traits options:(RSAOption* _Nullable)option;
- (void)track:(NSString * _Nonnull)name properties:(NSDictionary<NSString *,id> * _Nullable)properties options:(RSAOption* _Nullable)option;
- (void)screen:(NSString * _Nonnull)name category:(NSString * _Nullable)category properties:(NSDictionary<NSString *,id> * _Nullable)properties options:(RSAOption* _Nullable)option;
- (void)group:(NSString * _Nonnull)groupId traits:(NSDictionary<NSString *,id> * _Nullable)traits options:(RSAOption* _Nullable)option;
- (void)alias:(NSString * _Nonnull)newId previousId:(NSString* _Nullable)previousId options:(RSAOption* _Nullable)option;
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
