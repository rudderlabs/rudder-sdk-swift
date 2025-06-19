//
//  CustomOptionPlugin.h
//  ObjCExample
//
//  Created by Satheesh Kannan on 27/05/25.
//

#import <Foundation/Foundation.h>
#import <RudderStackAnalytics/RudderStackAnalytics-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomOptionPlugin : NSObject<RSAPlugin>

- (instancetype)initWithOption:(RSAOption *)option NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
