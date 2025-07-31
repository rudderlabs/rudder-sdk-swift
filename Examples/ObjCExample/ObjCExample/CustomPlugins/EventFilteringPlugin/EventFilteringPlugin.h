//
//  EventFilteringPlugin.h
//  ObjCExampleApp
//
//  Created by Satheesh Kannan on 31/07/25.
//

#import <Foundation/Foundation.h>
@import RudderStackAnalytics;

NS_ASSUME_NONNULL_BEGIN

@interface EventFilteringPlugin : NSObject<RSSPlugin>

- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
