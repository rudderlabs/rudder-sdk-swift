//
//  CustomDeviceDestination.h
//  ObjCExampleApp
//
//  Created by Satheesh Kannan on 08/12/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomDeviceDestination : NSObject

@property (nonatomic, copy, readonly) NSString *key;

+ (instancetype)createWithApiKey:(NSString *)apiKey;

- (void)trackEvent:(NSString *)event properties:(NSDictionary<NSString *, id> *)properties;
- (void)screen:(NSString *)screenName properties:(NSDictionary<NSString *, id> *)properties;
- (void)group:(NSString *)groupId traits:(NSDictionary<NSString *, id> *)traits;
- (void)identifyUser:(NSString *)userId traits:(NSDictionary<NSString *, id> *)traits;
- (void)aliasUser:(NSString *)userId previousId:(NSString *)previousId;
- (void)flush;
- (void)reset;
- (void)update;

@end

NS_ASSUME_NONNULL_END
