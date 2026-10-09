//
//  SUAppcast.m  (stub)   --  see the kill-switch note in SUAppcast.h
//

#import "SUAppcast.h"
#import "SUAppcastItem.h"
#import "SPUDownloadData.h"
#import "SparkleStubInternal.h"

@implementation SUAppcast

- (instancetype)initWithDomain:(NSString *)domain
{
    STUB_LOG_SEL();
    self = [super init];
    if (self) {
        _domain = [domain copy];
        _items  = @[];
    }
    return self;
}

- (void)fetchAppcastFromURL:(NSURL *)appcastURL
               inBackground:(BOOL)background
            completionBlock:(SUAppcastCompletionBlock)completionBlock
{
    // completionBlock: is not invoked. Hosts read "no callback" as "no news".
    // A callback carrying (nil, nil) breaks Swift callers whose parameters are
    // non-optional.
    STUB_LOG(@"fetchAppcastFromURL:%@ background=%d -- refusing to fetch", appcastURL, background);
}

- (NSArray<SUAppcastItem *> *)parseAppcastItemsFromXMLFile:(NSString *)xmlFile error:(id _Nullable __autoreleasing * _Nullable)error
{
    STUB_LOG(@"parseAppcastItemsFromXMLFile:%@ -- returning 0 items", xmlFile);
    if (error != NULL) {
        *error = nil;
    }
    return @[];
}

- (NSArray<SUAppcastItem *> *)parseAppcastItemsFromXMLData:(NSData *)xmlData error:(id _Nullable __autoreleasing * _Nullable)error
{
    STUB_LOG(@"parseAppcastItemsFromXMLData (%lu bytes) -- returning 0 items",
             (unsigned long)xmlData.length);
    if (error != NULL) {
        *error = nil;
    }
    return @[];
}

- (id)bestNodeInNodes:(NSArray *)nodes             { return nil; }
- (NSDictionary *)attributesOfNode:(id)node        { return nil; }
- (NSString *)sparkleNamespacedNameOfNode:(id)node { return nil; }
- (void)reportError:(NSError *)error               { STUB_LOG(@"reportError: %@", error); }

- (SUAppcast *)copyWithoutDeltaUpdates
{
    return [[SUAppcast alloc] initWithDomain:self.domain];
}

// An array, not nil: Telegram bridges this to a Swift [SUAppcastItem].
- (NSArray<SUAppcastItem *> *)items { return _items ?: @[]; }

// SPUDownloaderDelegate -- inert.
- (void)downloaderDidSetDestinationName:(NSString *)destinationName
                     temporaryDirectory:(NSString *)temporaryDirectory { STUB_LOG_SEL(); }
- (void)downloaderDidReceiveExpectedContentLength:(int64_t)expectedContentLength { STUB_LOG_SEL(); }
- (void)downloaderDidReceiveDataOfLength:(uint64_t)length { STUB_LOG_SEL(); }
- (void)downloaderDidFinishWithTemporaryDownloadData:(SPUDownloadData *)downloadData { STUB_LOG_SEL(); }
- (void)downloaderDidFailWithError:(NSError *)error { STUB_LOG_SEL(); }

@end
