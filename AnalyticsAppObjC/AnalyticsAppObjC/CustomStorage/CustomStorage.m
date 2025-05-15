//
//  CustomStorage.m
//  AnalyticsAppObjC
//
//  Created by Satheesh Kannan on 15/05/25.
//

#import "CustomStorage.h"
#import <Analytics/Analytics-Swift.h>

#pragma mark - CustomStorage
@interface CustomStorage () {
    NSString *_fileBatchPrefix;
    NSUInteger _maxBatchSize;
    NSString *_fileBatchSentAtSuffix;
    NSString *_fileBatchSuffix;
    NSString *_memoryIndex;
}
@property(nonatomic) NSUserDefaults *keyValueStore;
@property(nonatomic) NSMutableArray<EventDataItem *> *dataItems;
@property (nonatomic, strong) dispatch_queue_t queue;
@end


@implementation CustomStorage

#pragma mark - Init
- (instancetype)initWithWriteKey:(NSString *)writeKey
{
    self = [super init];
    if (self) {
        _writeKey = writeKey;
        _keyValueStore = [[NSUserDefaults alloc] initWithSuiteName: [NSString stringWithFormat:@"KeyValueStore•%@", writeKey]];
        _dataItems = [NSMutableArray array];
        _queue = dispatch_queue_create("com.objectivec.memorystore.queue", DISPATCH_QUEUE_SERIAL);
    }
    
    _fileBatchPrefix = @"{\"batch\":[";
    _maxBatchSize = 500 * 1024;
    _fileBatchSentAtSuffix = @"],\"sentAt\":\"";
    _fileBatchSuffix = @"\"}";
    _memoryIndex = @"rudderstack.event.memory.index.";
    
    return self;
}

#pragma mark - Basic Operations
- (void)storeEvent:(NSString *)event {
    EventDataItem *dataItem = [self currentDataItem] ?: [[EventDataItem alloc] initWithBatch: _fileBatchPrefix];
    BOOL isNewEntry = [dataItem.batch isEqualToString: _fileBatchPrefix];
    
    if (dataItem.batch.length > _maxBatchSize) {
        [self finish];
        NSLog(@"Batch size exceeded. Closing the current batch...");
        [self storeEvent:event];
        return;
    }
    
    NSString *content = isNewEntry ? event : [NSString stringWithFormat:@",%@", event];
    dataItem.batch = [dataItem.batch stringByAppendingString:content];
    
    [self appendDataItem:dataItem];
}

- (void)finish {
    EventDataItem *currentDataItem = [self currentDataItem];
    if (!currentDataItem) return;
    
    NSString *suffix = [NSString stringWithFormat:@"%@%@%@", _fileBatchSentAtSuffix, [self currentTimeStamp], _fileBatchSuffix];
    currentDataItem.batch = [currentDataItem.batch stringByAppendingString:suffix];
    currentDataItem.isClosed = YES;
    
    [self appendDataItem:currentDataItem];
    [self.keyValueStore removeObjectForKey:[self currentDataItemKey]];
}

- (void)appendDataItem:(EventDataItem *)item {
    NSUInteger existingIndex = [self.dataItems indexOfObjectPassingTest:^BOOL(EventDataItem *obj, NSUInteger idx, BOOL *stop) {
        return [obj.reference isEqualToString:item.reference];
    }];
    
    if (existingIndex != NSNotFound) {
        [self.dataItems replaceObjectAtIndex:existingIndex withObject:item];
    } else {
        [self.dataItems addObject:item];
    }
    
    [self.keyValueStore setObject:item.reference forKey:[self currentDataItemKey]];
}

- (BOOL)removeItemUsingId:(NSString *)itemId {
    __block BOOL success = NO;
    NSUInteger index = [self.dataItems indexOfObjectPassingTest:^BOOL(EventDataItem *obj, NSUInteger idx, BOOL *stop) {
        return [obj.reference isEqualToString:itemId];
    }];
    
    if (index != NSNotFound) {
        [self.dataItems removeObjectAtIndex:index];
        NSLog(@"Item removed: %@", itemId);
        success = YES;
    }
    return success;
}

#pragma mark - Helpers
- (NSString *)currentDataItemKey {
    return [_memoryIndex stringByAppendingString:self.writeKey];
}

- (nullable NSString *)currentDataItemId {
    return [self.keyValueStore objectForKey:[self currentDataItemKey]];
}

- (NSString *)currentTimeStamp {
    NSDate *now = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    // Set ISO 8601 format manually
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssXXXXX";
    
    return [formatter stringFromDate:now];
}

- (nullable EventDataItem *)currentDataItem {
    NSString *itemId = [self currentDataItemId];
    if (!itemId) return nil;
    
    __block EventDataItem *foundItem = nil;
    [self.dataItems enumerateObjectsUsingBlock:^(EventDataItem *item, NSUInteger idx, BOOL *stop) {
        if ([item.reference isEqualToString:itemId]) {
            foundItem = item;
            *stop = YES;
        }
    }];
    
    return foundItem;
}

#pragma mark - DataStore

- (void)write:(NSString * _Nonnull)event completionHandler:(void (^ _Nonnull)(void))completionHandler {
    dispatch_async(self.queue, ^{
        [self storeEvent: event];
        completionHandler();
    });
}

- (void)read:(void (^ _Nonnull)(EventDataResult * _Nonnull))completionHandler {
    dispatch_async(self.queue, ^{
        NSArray<EventDataItem *> *filtered = [self.dataItems filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(EventDataItem *item, NSDictionary *bindings) {
            return [item.batch hasSuffix:self->_fileBatchSuffix] && item.isClosed;
        }]];
        
        EventDataItem *current = [self currentDataItem];
        if (current) {
            NSPredicate *excludeCurrent = [NSPredicate predicateWithFormat:@"reference != %@", current.reference];
            filtered = [filtered filteredArrayUsingPredicate:excludeCurrent];
        }
        
        completionHandler([[EventDataResult alloc] initWithDataItems:filtered]);
    });
}

- (void)remove:(NSString * _Nonnull)eventReference completionHandler:(void (^ _Nonnull)(BOOL))completionHandler {
    dispatch_async(self.queue, ^{
        BOOL success = [self removeItemUsingId:eventReference];
        completionHandler(success);
    });
}

- (void)rollover:(void (^ _Nonnull)(void))completionHandler {
    dispatch_async(self.queue, ^{
        [self finish];
        completionHandler();
    });
}

#pragma mark - KeyValueStore

- (id _Nullable)readValueForKey:(NSString * _Nonnull)key {
    return [self.keyValueStore objectForKey:key];
}

- (void)removeValueForKey:(NSString * _Nonnull)key {
    [self.keyValueStore removeObjectForKey:key];
}

- (void)writeValue:(id _Nullable)value forkey:(NSString * _Nonnull)key {
    [self.keyValueStore setValue:value forKey:key];
}

@end
