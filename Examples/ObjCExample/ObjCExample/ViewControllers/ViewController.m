//
//  ViewController.m
//  ObjCExample
//
//  Created by Satheesh Kannan on 07/05/25.
//

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
    self.title = @"ObjCExample";
    [self setupTableView];
}

- (void)setupTableView {
    _cellIdentifier = @"Cell";
    
    self.tableRowTitles = @{@(ActionTypeIdentify): @"Identify", @(ActionTypeAlias): @"Alias", @(ActionTypeTrack): @"Track", @(ActionTypeMultipleTrack): @"Multipletrack", @(ActionTypeScreen): @"Screen", @(ActionTypeGroup): @"Group", @(ActionTypeFlush): @"Flush", @(ActionTypeReadAnonymousId): @"Read AnonymousId", @(ActionTypeReset): @"Reset", @(ActionTypeStartSession): @"Start Session", @(ActionTypeStartSessionWithSessionId): @"Start Session with SessionId", @(ActionTypeReadSessionId): @"Read SessionId", @(ActionTypeEndSession): @"End Session", @(ActionTypeShutdown): @"Shutdown", @(ActionTypeReInitializeSDK): @"Re-Initialize SDK"};
    
    self.tableRows = @[@(ActionTypeIdentify), @(ActionTypeAlias), @(ActionTypeTrack), @(ActionTypeMultipleTrack), @(ActionTypeScreen), @(ActionTypeGroup), @(ActionTypeFlush), @(ActionTypeReadAnonymousId), @(ActionTypeReset), @(ActionTypeStartSession), @(ActionTypeStartSessionWithSessionId), @(ActionTypeReadSessionId), @(ActionTypeEndSession), @(ActionTypeShutdown), @(ActionTypeReInitializeSDK)];
    
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
            RSSExternalId *externalId = [[RSSExternalId alloc] initWithType:@"idCardNumber" id:@"12791"];

            NSDictionary *integrations = @{@"Amplitude": @NO};
            NSDictionary *customContext = @{@"identify_key1": @"identify_value1"};

            RSSOptionBuilder *optionBuilder = [RSSOptionBuilder new];
            [optionBuilder setIntegrations:integrations];
            [optionBuilder setCustomContext:customContext];
            [optionBuilder setExternalIds:@[externalId]];
            
            [[AnalyticsManager sharedManager] identify:@"12345" traits:@{@"IdentifyTraits_key1": @"IdentifyTraits_value1"} options:[optionBuilder build]];
            break;
        }
            
        case ActionTypeAlias: {
            RSSExternalId *externalId = [[RSSExternalId alloc] initWithType:@"idCardNumber" id:@"12791"];

            NSDictionary *integrations = @{@"Amplitude": @NO};
            NSDictionary *customContext = @{@"identify_key1": @"identify_value1"};

            RSSOptionBuilder *optionBuilder = [RSSOptionBuilder new];
            [optionBuilder setIntegrations:integrations];
            [optionBuilder setCustomContext:customContext];
            [optionBuilder setExternalIds:@[externalId]];
            
            [[AnalyticsManager sharedManager] alias:@"123_alias_123" previousId:Nil options:[optionBuilder build]];
            break;
        }
    
        case ActionTypeTrack: {
            RSSExternalId *externalId = [[RSSExternalId alloc] initWithType:@"idCardNumber" id:@"12791"];
            
            NSDictionary *integrations = @{@"Amplitude": @YES, @"CleverTap": @NO};
            NSDictionary *customContext = @{
                @"Key_1": @{@"Key1": @"Value1"},
                @"Key_2": @[@"value1", @"value2"],
                @"Key_3": @"Value3",
                @"Key_4": @1234,
                @"Key_5": @5678.9,
                @"Key_6": @YES,
                @"Key_7": [NSURL URLWithString:@"https://www.rsa-test.com/"]
            };
            
            RSSOptionBuilder *optionBuilder = [RSSOptionBuilder new];
            [optionBuilder setIntegrations:integrations];
            [optionBuilder setCustomContext:customContext];
            [optionBuilder setExternalIds:@[externalId]];
            
            [[AnalyticsManager sharedManager] track:[NSString stringWithFormat:@"Track at %@", [NSDate date]] properties:@{@"key": @"value"} options:[optionBuilder build]];
            break;
        }
            
        case ActionTypeMultipleTrack: {
            RSSExternalId *externalId = [[RSSExternalId alloc] initWithType:@"idCardNumber" id:@"12791"];

            NSDictionary *integrations = @{@"Amplitude": @YES, @"CleverTap": @NO};
            NSDictionary *customContext = @{ @"Key_1": @{@"Key123": @"Value123"}};

            RSSOptionBuilder *optionBuilder = [RSSOptionBuilder new];
            [optionBuilder setIntegrations:integrations];
            [optionBuilder setCustomContext:customContext];
            [optionBuilder setExternalIds:@[externalId]];
            
            for (int i = 0; i < 50; i++) {
                [[AnalyticsManager sharedManager] track:[NSString stringWithFormat:@"Track %d", i+1] properties:Nil options:[optionBuilder build]];
            }
            break;
        }
            
        case ActionTypeScreen: {
            RSSExternalId *externalId = [[RSSExternalId alloc] initWithType:@"idCardNumber" id:@"12791"];

            NSDictionary *integrations = @{@"Facebook": @NO};
            NSDictionary *customContext = @{@"Key_1": @{@"Key1": @"Value1"}};

            RSSOptionBuilder *optionBuilder = [RSSOptionBuilder new];
            [optionBuilder setIntegrations:integrations];
            [optionBuilder setCustomContext:customContext];
            [optionBuilder setExternalIds:@[externalId]];
            
            [[AnalyticsManager sharedManager] screen:@"Analytics Screen" category:Nil properties:@{@"key": @"value"} options:[optionBuilder build]];
            break;
        }
            
        case ActionTypeGroup: {
            RSSExternalId *externalId1 = [[RSSExternalId alloc] initWithType:@"idCardNumber" id:@"12791"];
            RSSExternalId *externalId2 = [[RSSExternalId alloc] initWithType:@"official_idCardNumber" id:@"AB123CD"];

            NSDictionary *twitterConfig = @{@"isEnabled": @YES, @"consumerKey": @"consumerSecret"};
            NSDictionary *integrations = @{@"Firebase": @NO, @"Twitter": twitterConfig};
            NSDictionary *customContext = @{@"Key_1": @{@"Key1": @"Value1"}};

            RSSOptionBuilder *optionBuilder = [RSSOptionBuilder new];
            [optionBuilder setIntegrations:integrations];
            [optionBuilder setCustomContext:customContext];
            [optionBuilder setExternalIds:@[externalId1, externalId2]];
            
            [[AnalyticsManager sharedManager] group:@"group_id" traits:@{@"key": @"value"} options:[optionBuilder build]];
            break;
        }
            
        case ActionTypeFlush: {
            [[AnalyticsManager sharedManager] flush];
            break;
        }
            
        case ActionTypeReadAnonymousId: {
            NSString *anonymousId = [[AnalyticsManager sharedManager] anonymousId];
            [RSSLoggerAnalytics debug:[NSString stringWithFormat:@"Current Anonymous Id: %@", (anonymousId == Nil) ? @"Nil" : anonymousId]];
            break;
        }
            
        case ActionTypeReset: {
            [[AnalyticsManager sharedManager] reset];
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
                [RSSLoggerAnalytics debug:[NSString stringWithFormat:@"Current Session Id: %llu", sessionId.unsignedLongLongValue]];
            } else {
                [RSSLoggerAnalytics debug:@"No active session found."];
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
