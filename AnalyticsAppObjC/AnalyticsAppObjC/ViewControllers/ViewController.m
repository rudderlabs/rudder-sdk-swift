//
//  ViewController.m
//  AnalyticsAppObjC
//
//  Created by Satheesh Kannan on 07/05/25.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
#import "AnalyticsManager.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSDictionary<NSNumber *, NSString *> *tableRowTitles;
@property (nonatomic, strong) NSArray<NSNumber*> *tableRows;

@end


@implementation ViewController {
    NSString *_cellIdentifier;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"AnalyticsAppObjc";
    [self setupTableView];
}

- (void)setupTableView {
    _cellIdentifier = @"Cell";
    
    self.tableRowTitles = @{@(ActionTypeIdentify): @"Identify", @(ActionTypeAlias): @"Alias", @(ActionTypeTrack): @"Track", @(ActionTypeMultipleTrack): @"Multipletrack", @(ActionTypeScreen): @"Screen", @(ActionTypeGroup): @"Group", @(ActionTypeFlush): @"Flush", @(ActionTypeUpdateAnonymousId): @"Update AnonymousId", @(ActionTypeReadAnonymousId): @"Read AnonymousId", @(ActionTypeReset): @"Reset", @(ActionTypeResetWithAnonymousId): @"Reset with AnonymousId", @(ActionTypeStartSession): @"Start Session", @(ActionTypeStartSessionWithSessionId): @"Start Session with SessionId", @(ActionTypeReadSessionId): @"Read SessionId", @(ActionTypeEndSession): @"End Session", @(ActionTypeShutdown): @"Shutdown", @(ActionTypeReInitializeSDK): @"Re-Initialize SDK"};
    
    self.tableRows = @[@(ActionTypeIdentify), @(ActionTypeAlias), @(ActionTypeTrack), @(ActionTypeMultipleTrack), @(ActionTypeScreen), @(ActionTypeGroup), @(ActionTypeFlush), @(ActionTypeUpdateAnonymousId), @(ActionTypeReadAnonymousId), @(ActionTypeReset), @(ActionTypeResetWithAnonymousId), @(ActionTypeStartSession), @(ActionTypeStartSessionWithSessionId), @(ActionTypeReadSessionId), @(ActionTypeEndSession), @(ActionTypeShutdown), @(ActionTypeReInitializeSDK)];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableRows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:_cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:_cellIdentifier];
    }
    
    NSNumber *actionType = self.tableRows[indexPath.row];
    cell.textLabel.text = self.tableRowTitles[actionType];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *actionNumber = self.tableRows[indexPath.row];
    ActionType actionType = (ActionType)[actionNumber integerValue];
    
    switch (actionType) {
        case ActionTypeIdentify: {
            ExternalId *externalId = [[ExternalId alloc] initWithType:@"idCardNumber" id:@"12791"];

            NSDictionary *integrations = @{@"Amplitude": @NO};
            NSDictionary *customContext = @{@"identify_key1": @"identify_value1"};

            RudderOption *option = [[RudderOption alloc] initWithIntegrations:integrations
                                                                 customContext:customContext
                                                                  externalIds:@[externalId]];
            
            [[AnalyticsManager sharedManager] identify:@"12345" traits:@{@"IdentifyTraits_key1": @"IdentifyTraits_value1"} options:option];
            break;
        }
            
        case ActionTypeAlias: {
            ExternalId *externalId = [[ExternalId alloc] initWithType:@"idCardNumber" id:@"12791"];

            NSDictionary *integrations = @{@"Amplitude": @NO};
            NSDictionary *customContext = @{@"identify_key1": @"identify_value1"};

            RudderOption *option = [[RudderOption alloc] initWithIntegrations:integrations
                                                                 customContext:customContext
                                                                  externalIds:@[externalId]];
            
            [[AnalyticsManager sharedManager] alias:@"123_alias_123" previousId:Nil options:option];
            break;
        }
    
        case ActionTypeTrack: {
            ExternalId *externalId = [[ExternalId alloc] initWithType:@"idCardNumber" id:@"12791"];
            
            NSDictionary *integrations = @{@"Amplitude": @YES, @"CleverTap": @NO};
            NSDictionary *customContext = @{
                @"SK1": @{@"Key1": @"Value1"},
                @"SK2": @[@"value1", @"value2"],
                @"SK3": @"Value3",
                @"SK4": @1234,
                @"SK5": @5678.9,
                @"SK6": @YES
            };
            
            RudderOption *option = [[RudderOption alloc] initWithIntegrations:integrations
                                                                customContext:customContext
                                                                  externalIds:@[externalId]];
            [[AnalyticsManager sharedManager] track:[NSString stringWithFormat:@"Track at %@", [NSDate date]] properties:@{@"key": @"value"} options:option];
            break;
        }
            
        case ActionTypeMultipleTrack: {
            ExternalId *externalId = [[ExternalId alloc] initWithType:@"idCardNumber" id:@"12791"];

            NSDictionary *integrations = @{@"Amplitude": @YES, @"CleverTap": @NO};
            NSDictionary *customContext = @{ @"SK123": @{@"Key123": @"Value123"}};

            RudderOption *option = [[RudderOption alloc] initWithIntegrations:integrations
                                                                 customContext:customContext
                                                                  externalIds:@[externalId]];
            for (int i = 0; i < 50; i++) {
                [[AnalyticsManager sharedManager] track:[NSString stringWithFormat:@"Track %d", i+1] properties:Nil options:option];
            }
            break;
        }
            
        case ActionTypeScreen: {
            ExternalId *externalId = [[ExternalId alloc] initWithType:@"idCardNumber" id:@"12791"];

            NSDictionary *integrations = @{@"Facebook": @NO};
            NSDictionary *customContext = @{@"SK": @{@"Key1": @"Value1"}};

            RudderOption *option = [[RudderOption alloc] initWithIntegrations:integrations
                                                                 customContext:customContext
                                                                  externalIds:@[externalId]];
            [[AnalyticsManager sharedManager] screen:@"Analytics Screen" category:Nil properties:@{@"key": @"value"} options:option];
            break;
        }
            
        case ActionTypeGroup: {
            ExternalId *externalId1 = [[ExternalId alloc] initWithType:@"idCardNumber" id:@"12791"];
            ExternalId *externalId2 = [[ExternalId alloc] initWithType:@"official_idCardNumber" id:@"AB123CD"];

            NSDictionary *twitterConfig = @{@"isEnabled": @YES, @"consumerKey": @"consumerSecret"};
            NSDictionary *integrations = @{@"Firebase": @NO, @"Twitter": twitterConfig};
            NSDictionary *customContext = @{@"SK": @{@"Key1": @"Value1"}};

            RudderOption *option = [[RudderOption alloc] initWithIntegrations:integrations
                                                                 customContext:customContext
                                                                  externalIds:@[externalId1, externalId2]];
            [[AnalyticsManager sharedManager] group:@"group_id" traits:@{@"key": @"value"} options:option];
            break;
        }
            
        case ActionTypeFlush: {
            [[AnalyticsManager sharedManager] flush];
            break;
        }
            
        case ActionTypeUpdateAnonymousId: {
            [[AnalyticsManager sharedManager] setAnonymousId:@"new_anonymous_id"];
            break;
        }
            
        case ActionTypeReadAnonymousId: {
            NSString *anonymousId = [[AnalyticsManager sharedManager] anonymousId];
            [LoggerAnalytics debug:[NSString stringWithFormat:@"Current Anonymous Id: %@", (anonymousId == Nil) ? @"Nil" : anonymousId]];
            break;
        }
            
        case ActionTypeReset: {
            [[AnalyticsManager sharedManager] reset:NO];
            break;
        }
            
        case ActionTypeResetWithAnonymousId: {
            [[AnalyticsManager sharedManager] reset:YES];
            break;
        }
            
        case ActionTypeStartSession: {
            [[AnalyticsManager sharedManager] startSession];
            break;
        }
            
        case ActionTypeStartSessionWithSessionId: {
            [[AnalyticsManager sharedManager] startSession: @12312312345];
            break;
        }
            
        case ActionTypeReadSessionId: {
            NSNumber *sessionId = [[AnalyticsManager sharedManager] sessionId];
            if (sessionId) {
                [LoggerAnalytics debug:[NSString stringWithFormat:@"Current Session Id: %llu", sessionId.unsignedLongLongValue]];
            } else {
                [LoggerAnalytics debug:@"No active session found."];
            }
            break;
        }
            
        case ActionTypeEndSession: {
            [[AnalyticsManager sharedManager] endSession];
            break;
        }
            
        case ActionTypeShutdown: {
            [[AnalyticsManager sharedManager] shutdown];
            break;
        }
            
        case ActionTypeReInitializeSDK: {
            [[AnalyticsManager sharedManager] initializeAnalyticsSDK];
            break;
        }
            
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end

