//
//  CustomLogger.m
//  AnalyticsAppObjC
//
//  Created by Satheesh Kannan on 15/05/25.
//

#import "CustomLogger.h"

@implementation CustomLogger

- (void)verbose:(NSString * _Nonnull)log {
    NSLog(@"[Analytics-ObjC] :: Verbose :: %@", log);
}

- (void)debug:(NSString * _Nonnull)log {
    NSLog(@"[Analytics-ObjC] :: Debug :: %@", log);
}

- (void)info:(NSString * _Nonnull)log {
    NSLog(@"[Analytics-ObjC] :: Info :: %@", log);
}

- (void)warn:(NSString * _Nonnull)log {
    NSLog(@"[Analytics-ObjC] :: Warn :: %@", log);
}

- (void)errorLog:(NSString * _Nonnull)log error:(NSError * _Nullable)error {
    NSLog(@"[Analytics-ObjC] :: Error :: %@", log);
    if (error != nil) {
        NSLog(@"[Analytics-ObjC] :: Error Details :: %@", [error debugDescription]);
    }
}

@end
